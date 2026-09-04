import Foundation
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
//import PhoneNumberFormat
// Keep the import commented out and do not add //submodules/PhoneNumberFormat to this
// module's deps. Bazel rejects it as a cycle and aborts analysis of //Telegram:Telegram
// before a single file compiles (that is what broke CI run #145):
//   AccountContext -> InAppPurchaseManager -> TelegramStringFormatting
//     -> LocalizedPeerData -> PhoneNumberFormat -> AccountContext
// A nameless contact therefore stays untitled here, exactly as upstream ships it.

public extension EnginePeer {
    var compactDisplayTitle: String {
        switch self {
        case let .user(user):
            if let firstName = user.firstName, !firstName.isEmpty {
                return firstName
            } else if let lastName = user.lastName, !lastName.isEmpty {
                return lastName
            } else if let _ = user.phone {
                return "" //formatPhoneNumber("+\(phone)")
            } else {
                return "Deleted Account"
            }
        case let .legacyGroup(group):
            return group.title
        case let .channel(channel):
            return channel.title
        case let .community(community):
            return community.title
        case .secretChat:
            return ""
        }
    }

    func displayTitle(strings: PresentationStrings, displayOrder: PresentationPersonNameOrder) -> String {
        switch self {
        case let .user(user):
            if user.id.isReplies {
                return strings.DialogList_Replies
            }
            if let firstName = user.firstName, !firstName.isEmpty {
                if let lastName = user.lastName, !lastName.isEmpty {
                    switch displayOrder {
                    case .firstLast:
                        return "\(firstName) \(lastName)"
                    case .lastFirst:
                        return "\(lastName) \(firstName)"
                    }
                } else {
                    return firstName
                }
            } else if let lastName = user.lastName, !lastName.isEmpty {
                return lastName
            } else if let _ = user.phone {
                // Telewhite: hide toggle covers phone + username only. Never redact the
                // NAME with a dash — a nameless user simply shows no title (as stock does).
                return "" //formatPhoneNumber("+\(phone)")
            } else {
                return strings.User_DeletedAccount
            }
        case let .legacyGroup(group):
            return group.title
        case let .channel(channel):
            return channel.title
        case let .community(community):
            return community.title
        case .secretChat:
            return ""
        }
    }
}

public extension EnginePeer.IndexName {
    func isLessThan(other: EnginePeer.IndexName, ordering: PresentationPersonNameOrder) -> ComparisonResult {
        switch self {
        case let .title(lhsTitle, _):
            let rhsString: String
            switch other {
            case let .title(title, _):
                rhsString = title
            case let .personName(first, last, _, _):
                switch ordering {
                case .firstLast:
                    if first.isEmpty {
                        rhsString = last
                    } else {
                        rhsString = first + last
                    }
                case .lastFirst:
                    if last.isEmpty {
                        rhsString = first
                    } else {
                        rhsString = last + first
                    }
                }
            }
            return lhsTitle.caseInsensitiveCompare(rhsString)
        case let .personName(lhsFirst, lhsLast, _, _):
            let lhsString: String
            switch ordering {
            case .firstLast:
                if lhsFirst.isEmpty {
                    lhsString = lhsLast
                } else {
                    lhsString = lhsFirst + lhsLast
                }
            case .lastFirst:
                if lhsLast.isEmpty {
                    lhsString = lhsFirst
                } else {
                    lhsString = lhsLast + lhsFirst
                }
            }
            let rhsString: String
            switch other {
            case let .title(title, _):
                rhsString = title
            case let .personName(first, last, _, _):
                switch ordering {
                case .firstLast:
                    if first.isEmpty {
                        rhsString = last
                    } else {
                        rhsString = first + last
                    }
                case .lastFirst:
                    if last.isEmpty {
                        rhsString = first
                    } else {
                        rhsString = last + first
                    }
                }
            }
            return lhsString.caseInsensitiveCompare(rhsString)
        }
    }
}
