import Foundation
import UIKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import ChatPresentationInterfaceState
import ChatNavigationButton
import Display
import SettingsUI

private func telewhiteGhostModeIcon(theme: PresentationTheme, isEnabled: Bool) -> UIImage? {
    let foregroundColor = isEnabled ? theme.list.itemAccentColor : theme.rootController.navigationBar.buttonColor

    return generateImage(CGSize(width: 30.0, height: 30.0), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))

        context.setFillColor(foregroundColor.cgColor)
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: 8.0, y: 24.0))
        bodyPath.addLine(to: CGPoint(x: 8.0, y: 13.8))
        bodyPath.addCurve(to: CGPoint(x: 15.0, y: 6.5), controlPoint1: CGPoint(x: 8.0, y: 9.5), controlPoint2: CGPoint(x: 10.9, y: 6.5))
        bodyPath.addCurve(to: CGPoint(x: 22.0, y: 13.8), controlPoint1: CGPoint(x: 19.1, y: 6.5), controlPoint2: CGPoint(x: 22.0, y: 9.5))
        bodyPath.addLine(to: CGPoint(x: 22.0, y: 24.0))
        bodyPath.addLine(to: CGPoint(x: 19.2, y: 21.4))
        bodyPath.addLine(to: CGPoint(x: 16.4, y: 24.0))
        bodyPath.addLine(to: CGPoint(x: 13.6, y: 21.4))
        bodyPath.addLine(to: CGPoint(x: 10.8, y: 24.0))
        bodyPath.close()
        context.addPath(bodyPath.cgPath)
        context.fillPath()

        context.setBlendMode(.clear)
        context.fillEllipse(in: CGRect(x: 11.0, y: 13.2, width: 2.8, height: 3.2))
        context.fillEllipse(in: CGRect(x: 16.2, y: 13.2, width: 2.8, height: 3.2))
        context.setBlendMode(.normal)

        if isEnabled {
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            context.setLineWidth(1.5)
            context.setLineCap(.round)
            context.move(to: CGPoint(x: 9.5, y: 7.5))
            context.addLine(to: CGPoint(x: 20.5, y: 22.5))
            context.strokePath()
        }
    })
}

func leftNavigationButtonForChatInterfaceState(_ presentationInterfaceState: ChatPresentationInterfaceState, subject: ChatControllerSubject?, strings: PresentationStrings, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?) -> ChatNavigationButton? {
    if let _ = presentationInterfaceState.interfaceState.selectionState {
        if case .messageOptions = presentationInterfaceState.subject {
            return nil
        }
        if let _ = presentationInterfaceState.reportReason {
            return ChatNavigationButton(action: .spacer, buttonItem: UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil))
        }
        if case .replyThread = presentationInterfaceState.chatLocation {
            return nil
        }
        if let currentButton = currentButton, currentButton.action == .clearHistory {
            return currentButton
        } else if let peer = presentationInterfaceState.renderedPeer?.peer {
            let canClear: Bool
            var title = strings.Conversation_ClearAll
            if case .scheduledMessages = presentationInterfaceState.subject {
                canClear = true
                title = strings.ScheduledMessages_ClearAll
            } else {
                if peer is TelegramUser || peer is TelegramGroup || peer is TelegramSecretChat {
                    canClear = true
                } else if let peer = peer as? TelegramChannel, case .group = peer.info, peer.addressName == nil && presentationInterfaceState.peerGeoLocation == nil {
                    canClear = true
                } else if let peer = peer as? TelegramChannel {
                    if case .broadcast = peer.info {
                        title = strings.Conversation_ClearChannel
                    }
                    if peer.hasPermission(.changeInfo) {
                        canClear = true
                    } else {
                        canClear = false
                    }
                } else {
                    canClear = false
                }
            }

            if canClear {
                let buttonItem = UIBarButtonItem(title: strings.Conversation_ClearAll, style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = title
                return ChatNavigationButton(action: .clearHistory, buttonItem: buttonItem)
            } else {
                title = strings.Conversation_ClearCache
                let buttonItem = UIBarButtonItem(title: strings.Conversation_ClearCache, style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = title
                return ChatNavigationButton(action: .clearCache, buttonItem: buttonItem)
            }
        }
    }

    if case let .customChatContents(customChatContents) = presentationInterfaceState.subject {
        switch customChatContents.kind {
        case .hashTagSearch:
            break
        case .quickReplyMessageInput, .businessLinkSetup:
            if let currentButton = currentButton, currentButton.action == .dismiss {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(title: "___close", style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Common_Close
                return ChatNavigationButton(action: .dismiss, buttonItem: buttonItem)
            }
        }
    }

    return nil
}

func rightNavigationButtonForChatInterfaceState(context: AccountContext, presentationInterfaceState: ChatPresentationInterfaceState, strings: PresentationStrings, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?, chatInfoNavigationButton: ChatNavigationButton?, moreInfoNavigationButton: ChatNavigationButton?) -> ChatNavigationButton? {
    if case .standard(.previewing) = presentationInterfaceState.mode {
        return nil
    }
    var hasMessages = false
    if let chatHistoryState = presentationInterfaceState.chatHistoryState {
        if case .loaded(false, _) = chatHistoryState {
            hasMessages = true
        }
    }

    if let _ = presentationInterfaceState.interfaceState.selectionState {
        if case .messageOptions = presentationInterfaceState.subject {
            return nil
        }
        if let currentButton = currentButton, currentButton.action == .cancelMessageSelection {
            return currentButton
        } else {
            let buttonItem = UIBarButtonItem(title: "___done", style: .plain, target: target, action: selector)
            buttonItem.accessibilityLabel = strings.Common_Cancel
            return ChatNavigationButton(action: .cancelMessageSelection, buttonItem: buttonItem)
        }
    }

    if case let .replyThread(message) = presentationInterfaceState.chatLocation, message.peerId == context.account.peerId {
        let isTags = presentationInterfaceState.hasSearchTags

        if case .search(isTags) = currentButton?.action {
            return currentButton
        } else {
            let buttonItem = UIBarButtonItem(image: isTags ? PresentationResourcesRootController.navigationCompactTagsSearchIcon(presentationInterfaceState.theme) : PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
            buttonItem.accessibilityLabel = strings.Conversation_Search
            return ChatNavigationButton(action: .search(hasTags: isTags), buttonItem: buttonItem)
        }
    }

    if let channel = presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isMonoForum, case .peer = presentationInterfaceState.chatLocation {
        let displaySearch = hasMessages

        if displaySearch {
            if case .search(false) = currentButton?.action {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Conversation_Search
                return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
            }
        } else {
            return nil
        }
    }

    if let user = presentationInterfaceState.renderedPeer?.peer as? TelegramUser, user.isForum, case .peer = presentationInterfaceState.chatLocation {
        let displaySearch = hasMessages

        if displaySearch {
            if case .search(false) = currentButton?.action {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Conversation_Search
                return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
            }
        } else {
            return nil
        }
    }

    if let channel = presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isForumOrMonoForum, let moreInfoNavigationButton = moreInfoNavigationButton {
        if case .replyThread = presentationInterfaceState.chatLocation {
        } else {
            if case .pinnedMessages = presentationInterfaceState.subject {
            } else {
                return moreInfoNavigationButton
            }
        }
    }

    if let user = presentationInterfaceState.renderedPeer?.peer as? TelegramUser, let botInfo = user.botInfo, botInfo.flags.contains(.hasForum), let moreInfoNavigationButton = moreInfoNavigationButton {
        if case .pinnedMessages = presentationInterfaceState.subject {
        } else {
            return moreInfoNavigationButton
        }
    }

    if case .messageOptions = presentationInterfaceState.subject {
        return nil
    }

    if case .pinnedMessages = presentationInterfaceState.subject {
        return nil
    }

    if case let .customChatContents(customChatContents) = presentationInterfaceState.subject {
        switch customChatContents.kind {
        case .hashTagSearch:
            return nil
        case let .quickReplyMessageInput(_, shortcutType):
            switch shortcutType {
            case .generic:
                if let currentButton = currentButton, currentButton.action == .edit {
                    return currentButton
                } else {
                    let buttonItem = UIBarButtonItem(title: strings.Common_Edit, style: .plain, target: target, action: selector)
                    buttonItem.accessibilityLabel = strings.Common_Done
                    return ChatNavigationButton(action: .edit, buttonItem: buttonItem)
                }
            case .greeting, .away:
                return nil
            }
        case .businessLinkSetup:
            if let currentButton = currentButton, currentButton.action == .edit {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(title: strings.Common_Edit, style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Common_Done
                return ChatNavigationButton(action: .edit, buttonItem: buttonItem)
            }
        }
    }

    if case .replyThread = presentationInterfaceState.chatLocation {
        if let channel = presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isForumOrMonoForum {
        } else if hasMessages {
            if case .search = currentButton?.action {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Conversation_Search
                return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
            }
        } else {
            if case .spacer = currentButton?.action {
                return currentButton
            } else {
                return ChatNavigationButton(action: .spacer, buttonItem: UIBarButtonItem(title: "", style: .plain, target: target, action: selector))
            }
        }
    }
    if case let .peer(peerId) = presentationInterfaceState.chatLocation {
        if peerId.isRepliesOrVerificationCodes {
            if hasMessages {
                if case .search = currentButton?.action {
                    return currentButton
                } else {
                    let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                    buttonItem.accessibilityLabel = strings.Conversation_Search
                    return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
                }
            } else {
                if case .spacer = currentButton?.action {
                    return currentButton
                } else {
                    return ChatNavigationButton(action: .spacer, buttonItem: UIBarButtonItem(title: "", style: .plain, target: target, action: selector))
                }
            }
        }
    }

    if case .scheduledMessages = presentationInterfaceState.subject {
        return chatInfoNavigationButton
    }

    if case .standard(.previewing) = presentationInterfaceState.mode {
        return chatInfoNavigationButton
    } else if let peerId = presentationInterfaceState.chatLocation.peerId {
        if presentationInterfaceState.accountPeerId == peerId {
            var displaySearchButton = false

            if case .replyThread = presentationInterfaceState.chatLocation {
                displaySearchButton = true
            }

            if case .scheduledMessages = presentationInterfaceState.subject {
                return chatInfoNavigationButton
            } else {
                displaySearchButton = true
            }

            if displaySearchButton {
                let isTags = presentationInterfaceState.hasSearchTags

                if case .search(isTags) = currentButton?.action {
                    return currentButton
                } else {
                    let buttonItem = UIBarButtonItem(image: isTags ? PresentationResourcesRootController.navigationCompactTagsSearchIcon(presentationInterfaceState.theme) : PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                    buttonItem.accessibilityLabel = strings.Conversation_Search
                    return ChatNavigationButton(action: .search(hasTags: isTags), buttonItem: buttonItem)
                }
            }
        }
    }

    return chatInfoNavigationButton
}

func secondaryRightNavigationButtonForChatInterfaceState(context: AccountContext, presentationInterfaceState: ChatPresentationInterfaceState, strings: PresentationStrings, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?, chatInfoNavigationButton: ChatNavigationButton?, moreInfoNavigationButton: ChatNavigationButton?) -> ChatNavigationButton? {
    if presentationInterfaceState.interfaceState.selectionState != nil {
        return nil
    }

    if case .standard(.default) = presentationInterfaceState.mode, presentationInterfaceState.subject == nil, let user = presentationInterfaceState.renderedPeer?.chatMainPeer as? TelegramUser, user.id != context.account.peerId, !user.id.isSecretChat, user.isGenericUser {
        let isEnabled = TelewhiteModsSettings.current.ghostMode
        if currentButton?.action == .toggleGhostMode(isEnabled: isEnabled) {
            return currentButton
        } else {
            let buttonItem = UIBarButtonItem(image: telewhiteGhostModeIcon(theme: presentationInterfaceState.theme, isEnabled: isEnabled), style: .plain, target: target, action: selector)
            buttonItem.accessibilityLabel = isEnabled ? "Disable Ghost Mode" : "Enable Ghost Mode"
            return ChatNavigationButton(action: .toggleGhostMode(isEnabled: isEnabled), buttonItem: buttonItem)
        }
    }

    if case .standard(.default) = presentationInterfaceState.mode {
        if case .peer(context.account.peerId) = presentationInterfaceState.chatLocation, presentationInterfaceState.subject != .scheduledMessages, presentationInterfaceState.hasSavedChats {
            return moreInfoNavigationButton
        }
    }

    return nil
}
