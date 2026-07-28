import Postbox
import SwiftSignalKit
import TelegramApi

/// Why we do (or do not) know when the recipient read one of our outgoing messages.
///
/// This exists because `messageReadStats` deliberately swallows the RPC error and returns
/// empty stats, which collapses four very different situations into one indistinguishable
/// "no data" case. For the tap-the-checkmarks readout we want to tell the user *why* there
/// is no timestamp, so this keeps the server's reason instead of discarding it.
public enum TelewhiteOutgoingReadDate: Equatable {
    /// The recipient read it, at this Unix timestamp.
    case read(timestamp: Int32)
    /// Delivered, but genuinely not opened yet (`MESSAGE_NOT_READ_YET`).
    case notReadYet
    /// They hide their read times, so the server refuses to tell us
    /// (`USER_PRIVACY_RESTRICTED`).
    case hiddenByRecipient
    /// We hide *our* read times, so by reciprocity the server withholds theirs
    /// (`YOUR_PRIVACY_RESTRICTED`). Actionable: the user can turn this off.
    case hiddenByOwnPrivacy
    /// Read dates are not a concept here: groups/channels, non-cloud messages, incoming
    /// messages, or an unexpected server error.
    case unavailable
}

func _internal_telewhiteOutgoingReadDate(account: Account, id: MessageId) -> Signal<TelewhiteOutgoingReadDate, NoError> {
    // Read dates only exist for our own cloud messages in one-to-one chats. Everything else
    // is answered locally so we never spend a round trip on a question with no answer.
    guard id.namespace == Namespaces.Message.Cloud, id.peerId.namespace == Namespaces.Peer.CloudUser else {
        return .single(.unavailable)
    }

    return account.postbox.transaction { transaction -> Peer? in
        return transaction.getPeer(id.peerId)
    }
    |> mapToSignal { peer -> Signal<TelewhiteOutgoingReadDate, NoError> in
        guard let peer, let inputPeer = apiInputPeer(peer) else {
            return .single(.unavailable)
        }
        return account.network.request(Api.functions.messages.getOutboxReadDate(peer: inputPeer, msgId: id.id))
        |> map { result -> TelewhiteOutgoingReadDate in
            switch result {
            case let .outboxReadDate(data):
                return .read(timestamp: data.date)
            }
        }
        |> `catch` { error -> Signal<TelewhiteOutgoingReadDate, NoError> in
            let description = error.errorDescription ?? ""
            if description.hasPrefix("MESSAGE_NOT_READ_YET") {
                return .single(.notReadYet)
            } else if description.hasPrefix("USER_PRIVACY_RESTRICTED") {
                return .single(.hiddenByRecipient)
            } else if description.hasPrefix("YOUR_PRIVACY_RESTRICTED") {
                return .single(.hiddenByOwnPrivacy)
            } else {
                return .single(.unavailable)
            }
        }
    }
}
