import Foundation
import SwiftSignalKit
import TelegramApi
import MtProtoKit

// Telewhite: keeps the account reported as offline across actions that make the server
// mark it online — above all sending a message.
//
// Why a burst of requests instead of one: the server flips the account online while it
// processes the send, and we cannot order our request after it (this MtProtoKit has no
// `invokeAfterMsg` wrapper). The previous implementation fired a single
// `updateStatus(offline:)` from `applySentMessage`, i.e. only once the server's reply had
// come back. That left the online flag standing for the whole round trip — and for the
// entire upload on photos and voice messages, which is seconds, not milliseconds. A
// contact with the chat open received `updateUserStatus(online)` and saw "online" before
// our correction landed.
//
// So the burst starts when the request is *issued*, not when it completes, and keeps
// pulsing offline on a decaying interval until well after the send settles. Overlapping
// sends share a single burst: each new send pushes the deadline out rather than starting
// a competing loop, which keeps the request count flat when sending an album.
final class TelewhitePresenceGuard {
    static let shared = TelewhitePresenceGuard()

    /// How long a burst keeps pulsing after the most recent triggering action.
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

    /// Starts — or extends — an offline burst. Safe to call as often as needed.
    static func assertOffline(network: Network) {
        guard self.shouldSuppressPresence() else {
            return
        }
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
        self.pulse(network: network, delay: 0.0, step: 0)
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
            // Dense while the server is likely to flip us online, then steady so a slow
            // upload stays covered without a request every quarter second.
            let nextDelay: Double
            switch step {
                case 0:
                    nextDelay = 0.25
                case 1:
                    nextDelay = 0.5
                case 2:
                    nextDelay = 1.0
                default:
                    nextDelay = 1.5
            }
            strongSelf.pulse(network: network, delay: nextDelay, step: step + 1)
        })
    }
}
