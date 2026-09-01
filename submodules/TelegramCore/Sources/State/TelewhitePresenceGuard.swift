import Foundation
import SwiftSignalKit
import TelegramApi
import MtProtoKit

// Telewhite: keeps the account reported as offline across actions that make the server
// mark it online — above all sending a message.
//
// Two layers, because neither covers everything on its own.
//
// 1. A *chained* offline packet. MTProto can order one request after another server-side
//    (`invokeAfterMsg`), and this MtProtoKit does support it: `MTRequest.shouldDependOnRequest`
//    is turned into constructor 0xcb9f372d in MTRequestMessageService, and `Network.request`
//    already exposes it through its `tag:` parameter — message sending itself uses that to
//    stay ordered (`PendingMessageRequestDependencyTag`). So the offline packet is bound to
//    the send and executed by the server immediately after it, in the same container, with no
//    round trip. An earlier comment here claimed the wrapper did not exist and that a burst
//    was the only option; that was wrong.
//
// 2. A decaying burst, kept as a fallback. The chain covers the instant of the send, but not
//    everything: `invokeAfterMsg` is dropped if the request it depends on fails, no chain is
//    formed when the triggering action is not a message send (marking read, uploading), and a
//    photo or voice upload keeps the account online for seconds while the file transfers —
//    long after the send request itself was processed. The burst is sparser than it used to
//    be: the dense 0.25s step existed to catch the flip at send time, which the chain now
//    handles precisely.
//
// Overlapping sends share a single burst: each new action pushes the deadline out rather than
// starting a competing loop, which keeps the request count flat when sending an album.

/// Binds a request to the most recent pending message send, so the server runs it right after.
///
/// Matching any `PendingMessageRequestDependencyTag` is deliberate: MtProtoKit walks its
/// pending requests in reverse and stops at the first match, so this picks the latest send.
/// When nothing matches — the common case for a read receipt — no wrapper is added and the
/// request goes out on its own, which is exactly the desired fallback.
private final class TelewhitePresenceAfterSendTag: NetworkRequestDependencyTag {
    func shouldDependOn(other: NetworkRequestDependencyTag) -> Bool {
        return other is PendingMessageRequestDependencyTag
    }
}

final class TelewhitePresenceGuard {
    static let shared = TelewhitePresenceGuard()

    /// How long the fallback burst keeps pulsing after the most recent triggering action.
    /// Sized for an upload rather than for a round trip — the chain covers the round trip.
    private static let burstDuration: Double = 8.0

    private let lock = NSLock()
    private var burstEndsAt: Double = 0.0
    private var isPulsing: Bool = false

    private init() {
    }

    /// True when presence must stay hidden: global Ghost Mode, the standalone "Hide Online
    /// Status" toggle, or *any* chat having per-chat ghost enabled.
    ///
    /// Deliberately not parameterised by chat. Online status in Telegram is a property of
    /// the account, not of a conversation, so there is no such thing as being online for
    /// one contact and offline for another: enabling ghost for a single chat has to force
    /// the whole account offline. Checking the destination chat here would have been a bug —
    /// sending to an ordinary chat would flip the account online and undo the hiding that a
    /// per-chat ghost elsewhere is relying on.
    static func shouldSuppressPresence() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "telewhite.mods.ghostMode") || defaults.bool(forKey: "telewhite.mods.hideOnlineStatus") {
            return true
        }
        return !(defaults.array(forKey: "telewhite.mods.ghostPeerIds") as? [NSNumber] ?? []).isEmpty
    }

    /// Chains an offline packet to the pending send and starts — or extends — the fallback
    /// burst. Safe to call as often as needed.
    static func assertOffline(network: Network) {
        guard self.shouldSuppressPresence() else {
            return
        }
        let chained: Signal<Api.Bool, MTRpcError> = network.request(Api.functions.account.updateStatus(offline: .boolTrue), tag: TelewhitePresenceAfterSendTag())
        let _ = chained.start()

        self.shared.beginBurst(network: network)
    }

    private func beginBurst(network: Network) {
        let deadline = CFAbsoluteTimeGetCurrent() + TelewhitePresenceGuard.burstDuration

        self.lock.lock()
        self.burstEndsAt = max(self.burstEndsAt, deadline)
        let alreadyPulsing = self.isPulsing
        self.isPulsing = true
        self.lock.unlock()

        if alreadyPulsing {
            // A burst is already running; it just picked up the extended deadline.
            return
        }
        // Starts at 1.0 rather than 0.0: the chained packet above already covers this
        // instant, so firing another one here would be a duplicate of it.
        self.pulse(network: network, delay: 1.0, step: 0)
    }

    private func pulse(network: Network, delay: Double, step: Int) {
        Queue.concurrentDefaultQueue().after(delay, { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let request: Signal<Api.Bool, MTRpcError> = network.request(Api.functions.account.updateStatus(offline: .boolTrue))
            let _ = request.start()

            strongSelf.lock.lock()
            let shouldContinue = CFAbsoluteTimeGetCurrent() < strongSelf.burstEndsAt
            if !shouldContinue {
                strongSelf.isPulsing = false
            }
            strongSelf.lock.unlock()

            guard shouldContinue else {
                return
            }
            // Steady rather than decaying-from-dense: this loop now only has to keep a slow
            // upload covered, so a packet every 1.5-2s is enough and costs far fewer
            // requests than the old 0.25s opening step.
            let nextDelay: Double
            switch step {
                case 0:
                    nextDelay = 1.5
                default:
                    nextDelay = 2.0
            }
            strongSelf.pulse(network: network, delay: nextDelay, step: step + 1)
        })
    }
}
