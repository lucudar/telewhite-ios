import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI
import PromptUI
import TelegramCore
import TelegramUIPreferences

public struct TelewhiteModsSettings: Equatable {
    public static let didChangeNotification = Notification.Name("TelewhiteModsSettingsDidChange")

    public var ghostMode: Bool
    public var ghostChatButtonEnabled: Bool
    public var preserveDeletedMessages: Bool
    public var hideOnlineStatus: Bool
    public var hideTypingStatus: Bool
    public var hideReadReceipts: Bool
    public var screenshotProtectionBypass: Bool
    public var contentRestrictionBypass: Bool
    public var hidePhoneInSettings: Bool
    public var hideStories: Bool
    public var ghostStories: Bool
    public var compactChatList: Bool
    public var chatSplitLandscape: Bool
    public var amoledMode: Bool
    public var showUserIds: Bool
    public var showChatIds: Bool
    public var showMessageIds: Bool
    public var ghostPeerIds: Set<Int64>
    public var autoTranslateEnglish: Bool
    public var translationTargetLanguage: String
    public var oneTimeMediaUnlimited: Bool
    public var downloadOneTimeMedia: Bool
    public var downloadStories: Bool
    public var accentColorOverride: Int64?
    public var bubbleColorOverride: Int64?
    public var chatBackgroundColorOverride: Int64?
    public var chatBackgroundGradientOverride: [Int64]?
    public var bubbleCornerRadiusOverride: Int32?
    public var chatFontSizeOverride: Int32
    public var outgoingTranslateButtonEnabled: Bool
    public var outgoingTranslationPeerIds: Set<Int64>
    public var outgoingTranslationLanguages: [Int64: String]
    public var openRouterApiKey: String
    public var forwardHideNamesByDefault: Bool
    public var showPreviousEditedText: Bool
    public var autoCacheCleanup: Bool
    public var cacheLimitGigabytes: Int32
    public var channelHideReactions: Bool
    public var channelHideComments: Bool
    public var channelHideShareButton: Bool
    public var hdPhotos: Bool
    public var translateVoiceMessages: Bool
    public var quickForwardToSaved: Bool

    private enum Key {
        static let ghostMode = "telewhite.mods.ghostMode"
        static let ghostChatButtonEnabled = "telewhite.mods.ghostChatButtonEnabled"
        static let preserveDeletedMessages = "telewhite.mods.preserveDeletedMessages"
        static let hideOnlineStatus = "telewhite.mods.hideOnlineStatus"
        static let hideTypingStatus = "telewhite.mods.hideTypingStatus"
        static let hideReadReceipts = "telewhite.mods.hideReadReceipts"
        static let screenshotProtectionBypass = "telewhite.mods.screenshotProtectionBypass"
        static let contentRestrictionBypass = "telewhite.mods.contentRestrictionBypass"
        static let hidePhoneInSettings = "telewhite.mods.hidePhoneInSettings"
        static let hideStories = "telewhite.mods.hideStories"
        static let ghostStories = "telewhite.mods.ghostStories"
        static let compactChatList = "telewhite.mods.compactChatList"
        static let chatSplitLandscape = "telewhite.mods.chatSplitLandscape"
        static let amoledMode = "telewhite.mods.amoledMode"
        static let showUserIds = "telewhite.mods.showUserIds"
        static let showChatIds = "telewhite.mods.showChatIds"
        static let showMessageIds = "telewhite.mods.showMessageIds"
        static let ghostPeerIds = "telewhite.mods.ghostPeerIds"
        static let autoTranslateEnglish = "telewhite.mods.autoTranslateEnglish"
        static let translationTargetLanguage = "telewhite.mods.translationTargetLanguage"
        static let oneTimeMediaUnlimited = "telewhite.mods.oneTimeMediaUnlimited"
        static let downloadOneTimeMedia = "telewhite.mods.downloadOneTimeMedia"
        static let downloadStories = "telewhite.mods.downloadStories"
        static let accentColor = "telewhite.mods.accentColor"
        static let bubbleColor = "telewhite.mods.bubbleColor"
        static let chatBackgroundColor = "telewhite.mods.chatBackgroundColor"
        static let chatBackgroundGradient = "telewhite.mods.chatBackgroundGradient"
        static let bubbleCornerRadius = "telewhite.mods.bubbleCornerRadius"
        static let chatFontSizeOverride = "telewhite.mods.chatFontSizeOverride"
        static let outgoingTranslateButtonEnabled = "telewhite.mods.outgoingTranslateButtonEnabled"
        static let outgoingTranslationPeerIds = "telewhite.mods.outgoingTranslationPeerIds"
        static let outgoingTranslationLanguages = "telewhite.mods.outgoingTranslationLanguages"
        static let openRouterApiKey = "telewhite.mods.openRouterApiKey"
        static let forwardHideNamesByDefault = "telewhite.mods.forwardHideNamesByDefault"
        static let showPreviousEditedText = "telewhite.mods.showPreviousEditedText"
        static let autoCacheCleanup = "telewhite.mods.autoCacheCleanup"
        static let cacheLimitGigabytes = "telewhite.mods.cacheLimitGigabytes"
        static let channelHideReactions = "telewhite.mods.channelHideReactions"
        static let channelHideComments = "telewhite.mods.channelHideComments"
        static let channelHideShareButton = "telewhite.mods.channelHideShareButton"
        static let hdPhotos = "telewhite.mods.hdPhotos"
        static let translateVoiceMessages = "telewhite.mods.translateVoiceMessages"
        static let quickForwardToSaved = "telewhite.mods.quickForwardToSaved"
    }
    
    public static var current: TelewhiteModsSettings {
        let defaults = UserDefaults.standard
        return TelewhiteModsSettings(
            // Telewhite: global Ghost Mode is an optional master switch; the granular
            // stealth toggles below are independent and persist on their own keys.
            ghostMode: defaults.bool(forKey: Key.ghostMode),
            ghostChatButtonEnabled: defaults.object(forKey: Key.ghostChatButtonEnabled) as? Bool ?? true,
            preserveDeletedMessages: defaults.bool(forKey: Key.preserveDeletedMessages),
            hideOnlineStatus: defaults.bool(forKey: Key.hideOnlineStatus),
            hideTypingStatus: defaults.bool(forKey: Key.hideTypingStatus),
            hideReadReceipts: defaults.bool(forKey: Key.hideReadReceipts),
            screenshotProtectionBypass: defaults.bool(forKey: Key.screenshotProtectionBypass),
            contentRestrictionBypass: defaults.bool(forKey: Key.contentRestrictionBypass),
            hidePhoneInSettings: defaults.bool(forKey: Key.hidePhoneInSettings),
            hideStories: defaults.bool(forKey: Key.hideStories),
            ghostStories: defaults.bool(forKey: Key.ghostStories),
            compactChatList: defaults.bool(forKey: Key.compactChatList),
            chatSplitLandscape: defaults.bool(forKey: Key.chatSplitLandscape),
            amoledMode: defaults.bool(forKey: Key.amoledMode),
            showUserIds: defaults.bool(forKey: Key.showUserIds),
            showChatIds: defaults.bool(forKey: Key.showChatIds),
            showMessageIds: defaults.bool(forKey: Key.showMessageIds),
            ghostPeerIds: Set((defaults.array(forKey: Key.ghostPeerIds) as? [NSNumber] ?? []).map { $0.int64Value }),
            autoTranslateEnglish: defaults.object(forKey: Key.autoTranslateEnglish) as? Bool ?? true,
            translationTargetLanguage: defaults.string(forKey: Key.translationTargetLanguage) ?? "ru",
            oneTimeMediaUnlimited: defaults.bool(forKey: Key.oneTimeMediaUnlimited),
            downloadOneTimeMedia: defaults.bool(forKey: Key.downloadOneTimeMedia),
            downloadStories: defaults.bool(forKey: Key.downloadStories),
            accentColorOverride: (defaults.object(forKey: Key.accentColor) as? NSNumber)?.int64Value,
            bubbleColorOverride: (defaults.object(forKey: Key.bubbleColor) as? NSNumber)?.int64Value,
            chatBackgroundColorOverride: (defaults.object(forKey: Key.chatBackgroundColor) as? NSNumber)?.int64Value,
            chatBackgroundGradientOverride: (defaults.array(forKey: Key.chatBackgroundGradient) as? [NSNumber]).flatMap { numbers in numbers.count >= 2 ? numbers.map { $0.int64Value } : nil },
            bubbleCornerRadiusOverride: (defaults.object(forKey: Key.bubbleCornerRadius) as? NSNumber)?.int32Value,
            chatFontSizeOverride: (defaults.object(forKey: Key.chatFontSizeOverride) as? NSNumber)?.int32Value ?? 0,
            outgoingTranslateButtonEnabled: defaults.object(forKey: Key.outgoingTranslateButtonEnabled) as? Bool ?? true,
            outgoingTranslationPeerIds: Set((defaults.array(forKey: Key.outgoingTranslationPeerIds) as? [NSNumber] ?? []).map { $0.int64Value }),
            outgoingTranslationLanguages: {
                var result: [Int64: String] = [:]
                if let stored = defaults.dictionary(forKey: Key.outgoingTranslationLanguages) as? [String: String] {
                    for (key, value) in stored {
                        if let rawId = Int64(key) {
                            result[rawId] = value
                        }
                    }
                }
                return result
            }(),
            openRouterApiKey: defaults.string(forKey: Key.openRouterApiKey) ?? "",
            forwardHideNamesByDefault: defaults.bool(forKey: Key.forwardHideNamesByDefault),
            showPreviousEditedText: defaults.object(forKey: Key.showPreviousEditedText) as? Bool ?? true,
            autoCacheCleanup: defaults.bool(forKey: Key.autoCacheCleanup),
            cacheLimitGigabytes: max(1, (defaults.object(forKey: Key.cacheLimitGigabytes) as? NSNumber)?.int32Value ?? 5),
            channelHideReactions: defaults.bool(forKey: Key.channelHideReactions),
            channelHideComments: defaults.bool(forKey: Key.channelHideComments),
            channelHideShareButton: defaults.bool(forKey: Key.channelHideShareButton),
            hdPhotos: defaults.object(forKey: Key.hdPhotos) as? Bool ?? false,
            translateVoiceMessages: defaults.bool(forKey: Key.translateVoiceMessages),
            quickForwardToSaved: defaults.bool(forKey: Key.quickForwardToSaved)
        )
    }

    public func isGhostEnabled(for peerId: EnginePeer.Id?) -> Bool {
        guard let peerId else {
            return false
        }
        return self.ghostPeerIds.contains(peerId.toInt64())
    }

    public func withToggledGhostPeer(_ peerId: EnginePeer.Id) -> TelewhiteModsSettings {
        var updated = self
        let rawId = peerId.toInt64()
        if updated.ghostPeerIds.contains(rawId) {
            updated.ghostPeerIds.remove(rawId)
        } else {
            updated.ghostPeerIds.insert(rawId)
        }
        return updated
    }

    public func isOutgoingTranslationEnabled(for peerId: EnginePeer.Id?) -> Bool {
        guard let peerId else {
            return false
        }
        return self.outgoingTranslationPeerIds.contains(peerId.toInt64())
    }

    public func outgoingTranslationLanguage(for peerId: EnginePeer.Id?) -> String {
        guard let peerId else {
            return "en"
        }
        return self.outgoingTranslationLanguages[peerId.toInt64()] ?? "en"
    }

    public func withToggledOutgoingTranslationPeer(_ peerId: EnginePeer.Id) -> TelewhiteModsSettings {
        var updated = self
        let rawId = peerId.toInt64()
        if updated.outgoingTranslationPeerIds.contains(rawId) {
            updated.outgoingTranslationPeerIds.remove(rawId)
        } else {
            updated.outgoingTranslationPeerIds.insert(rawId)
        }
        return updated
    }

    public func withOutgoingTranslationLanguage(_ language: String, for peerId: EnginePeer.Id) -> TelewhiteModsSettings {
        var updated = self
        let rawId = peerId.toInt64()
        updated.outgoingTranslationLanguages[rawId] = language
        updated.outgoingTranslationPeerIds.insert(rawId)
        return updated
    }
    
    public func save() {
        let defaults = UserDefaults.standard
        defaults.set(self.ghostMode, forKey: Key.ghostMode)
        defaults.set(self.ghostChatButtonEnabled, forKey: Key.ghostChatButtonEnabled)
        defaults.set(self.preserveDeletedMessages, forKey: Key.preserveDeletedMessages)
        defaults.set(self.hideOnlineStatus, forKey: Key.hideOnlineStatus)
        defaults.set(self.hideTypingStatus, forKey: Key.hideTypingStatus)
        defaults.set(self.hideReadReceipts, forKey: Key.hideReadReceipts)
        defaults.set(self.screenshotProtectionBypass, forKey: Key.screenshotProtectionBypass)
        defaults.set(self.contentRestrictionBypass, forKey: Key.contentRestrictionBypass)
        defaults.set(self.hidePhoneInSettings, forKey: Key.hidePhoneInSettings)
        defaults.set(self.hideStories, forKey: Key.hideStories)
        defaults.set(self.ghostStories, forKey: Key.ghostStories)
        defaults.set(self.compactChatList, forKey: Key.compactChatList)
        defaults.set(self.chatSplitLandscape, forKey: Key.chatSplitLandscape)
        TelewhiteSplitViewSettings.splitInCompactLandscape = self.chatSplitLandscape
        defaults.set(self.amoledMode, forKey: Key.amoledMode)
        defaults.set(self.showUserIds, forKey: Key.showUserIds)
        defaults.set(self.showChatIds, forKey: Key.showChatIds)
        defaults.set(self.showMessageIds, forKey: Key.showMessageIds)
        defaults.set(self.ghostPeerIds.map { NSNumber(value: $0) }, forKey: Key.ghostPeerIds)
        defaults.set(self.autoTranslateEnglish, forKey: Key.autoTranslateEnglish)
        defaults.set(self.translationTargetLanguage, forKey: Key.translationTargetLanguage)
        defaults.set(self.oneTimeMediaUnlimited, forKey: Key.oneTimeMediaUnlimited)
        defaults.set(self.downloadOneTimeMedia, forKey: Key.downloadOneTimeMedia)
        defaults.set(self.downloadStories, forKey: Key.downloadStories)
        if let value = self.accentColorOverride {
            defaults.set(NSNumber(value: value), forKey: Key.accentColor)
        } else {
            defaults.removeObject(forKey: Key.accentColor)
        }
        if let value = self.bubbleColorOverride {
            defaults.set(NSNumber(value: value), forKey: Key.bubbleColor)
        } else {
            defaults.removeObject(forKey: Key.bubbleColor)
        }
        if let value = self.chatBackgroundColorOverride {
            defaults.set(NSNumber(value: value), forKey: Key.chatBackgroundColor)
        } else {
            defaults.removeObject(forKey: Key.chatBackgroundColor)
        }
        if let value = self.chatBackgroundGradientOverride, value.count >= 2 {
            defaults.set(value.map { NSNumber(value: $0) }, forKey: Key.chatBackgroundGradient)
        } else {
            defaults.removeObject(forKey: Key.chatBackgroundGradient)
        }
        if let value = self.bubbleCornerRadiusOverride {
            defaults.set(NSNumber(value: value), forKey: Key.bubbleCornerRadius)
        } else {
            defaults.removeObject(forKey: Key.bubbleCornerRadius)
        }
        defaults.set(self.chatFontSizeOverride, forKey: Key.chatFontSizeOverride)
        defaults.set(self.outgoingTranslateButtonEnabled, forKey: Key.outgoingTranslateButtonEnabled)
        defaults.set(self.outgoingTranslationPeerIds.map { NSNumber(value: $0) }, forKey: Key.outgoingTranslationPeerIds)
        defaults.set(Dictionary(uniqueKeysWithValues: self.outgoingTranslationLanguages.map { (String($0.key), $0.value) }), forKey: Key.outgoingTranslationLanguages)
        defaults.set(self.openRouterApiKey, forKey: Key.openRouterApiKey)
        defaults.set(self.forwardHideNamesByDefault, forKey: Key.forwardHideNamesByDefault)
        defaults.set(self.showPreviousEditedText, forKey: Key.showPreviousEditedText)
        defaults.set(self.autoCacheCleanup, forKey: Key.autoCacheCleanup)
        defaults.set(self.cacheLimitGigabytes, forKey: Key.cacheLimitGigabytes)
        defaults.set(self.channelHideReactions, forKey: Key.channelHideReactions)
        defaults.set(self.channelHideComments, forKey: Key.channelHideComments)
        defaults.set(self.channelHideShareButton, forKey: Key.channelHideShareButton)
        defaults.set(self.hdPhotos, forKey: Key.hdPhotos)
        defaults.set(self.translateVoiceMessages, forKey: Key.translateVoiceMessages)
        defaults.set(self.quickForwardToSaved, forKey: Key.quickForwardToSaved)
        NotificationCenter.default.post(name: TelewhiteModsSettings.didChangeNotification, object: nil)
    }

    public static func signal() -> Signal<TelewhiteModsSettings, NoError> {
        return Signal { subscriber in
            subscriber.putNext(TelewhiteModsSettings.current)
            let observer = NotificationCenter.default.addObserver(forName: TelewhiteModsSettings.didChangeNotification, object: nil, queue: .main, using: { _ in
                subscriber.putNext(TelewhiteModsSettings.current)
            })
            return ActionDisposable {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

enum TelewhiteCustomColorTarget {
    case accent
    case bubble
    case background
}

private final class TelewhiteModsControllerArguments {
    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void
    let updateTranslationSettings: (@escaping (TranslationSettings) -> TranslationSettings) -> Void
    let openTab: (TelewhiteModsTab) -> Void
    let promptCustomColor: (TelewhiteCustomColorTarget) -> Void
    let openDebug: () -> Void
    let promptOpenRouterKey: () -> Void

    init(
        updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void,
        updateTranslationSettings: @escaping (@escaping (TranslationSettings) -> TranslationSettings) -> Void,
        openTab: @escaping (TelewhiteModsTab) -> Void = { _ in },
        promptCustomColor: @escaping (TelewhiteCustomColorTarget) -> Void = { _ in },
        openDebug: @escaping () -> Void = {},
        promptOpenRouterKey: @escaping () -> Void = {}
    ) {
        self.updateSettings = updateSettings
        self.updateTranslationSettings = updateTranslationSettings
        self.openTab = openTab
        self.promptCustomColor = promptCustomColor
        self.openDebug = openDebug
        self.promptOpenRouterKey = promptOpenRouterKey
    }
}

private enum TelewhiteModsSection: Int32 {
    case menu
    case messenger
    case translator
    case privacy
    case stealth
    case channels
    case media
    case appearance
    case accentColor
    case bubbleColor
    case backgroundColor
    case cornerRadius
    case developer
}

private enum TelewhiteModsTab: Int32, Equatable {
    case messenger
    case privacy
    case stealth
    case channels
    case media
    case appearance
    case developer
    // Telewhite: the translation cluster was six of the fourteen rows on the Messages
    // screen; it is one row now, opening here.
    case translator
    // Telewhite: sub-screens of the appearance tab. Every colour used to be one row
    // on a single 31-row screen, which meant scrolling past three palettes to reach
    // the radius options.
    case accentColor
    case bubbleColor
    case background
    case shape
}

private enum TelewhiteModsMenuIcon: Int32, Equatable {
    case privacy
    case ghost
    case messages
    case groups
    case media
    case appearance
    case developer
}

private enum TelewhiteModsEntry: ItemListNodeEntry, Equatable {
    case menuItem(Int32, TelewhiteModsMenuIcon, String, String, TelewhiteModsTab)

    case messengerHeader(String)
    case preserveDeletedMessages(String, Bool)
    case forwardHideNamesByDefault(String, Bool)
    case showPreviousEditedText(String, Bool)
    // Telewhite: one row for both halves of the view-once feature — opening without a
    // limit and saving were two switches for what users think of as one thing.
    case oneTimeMedia(String, Bool)
    case hdPhotos(String, Bool)
    case quickForwardToSaved(String, Bool)
    case translatorLink(String)
    case messengerInfo(String)

    case translatorHeader(String)
    case translateMessages(String, Bool)
    case autoTranslateEnglish(String, Bool)
    case translationTargetLanguage(String, String)
    case outgoingTranslateButtonEnabled(String, Bool)
    case translateVoiceMessages(String, Bool)
    case openRouterApiKey(String, String)
    case translatorInfo(String)

    case privacyHeader(String)
    // Telewhite: screenshot blocking and copy/forward/save blocking are the same
    // restriction to a user, so they are lifted by the same switch.
    case protectionBypass(String, Bool)
    case hidePhoneInSettings(String, Bool)
    case showProfileIds(String, Bool)
    case privacyInfo(String)

    case stealthHeader(String)
    // Telewhite: one switch for being invisible, covering messages and stories alike.
    // It also writes the ghostMode master flag, which had lost its row and so could be
    // left stuck on with nothing in the UI able to clear it.
    case ghost(String, Bool)
    case ghostChatButtonEnabled(String, Bool)
    case stealthInfo(String)

    case channelsHeader(String)
    case channelsDeclutter(String, Bool)
    case channelsInfo(String)

    case mediaHeader(String)
    case downloadStories(String, Bool)
    case hideStories(String, Bool)
    case autoCacheCleanup(String, Bool)
    case cacheLimit(Int32, String, Int32, Bool)
    case mediaInfo(String)

    case appearanceHeader(String)
    case accentColorLink(String, Int64?)
    case bubbleColorLink(String, Int64?)
    case backgroundColorLink(String, Int64?, [Int64]?)
    case shapeLink(String)
    case compactChatList(String, Bool)
    case chatSplitLandscape(String, Bool)
    case amoledMode(String, Bool)
    case darkMonoPreset(String)
    case accentColorHeader(String)
    case accentColorOption(Int32, String, Int64?, Bool)
    case accentColorCustom(String, Int64?, Bool)
    case bubbleColorHeader(String)
    case bubbleColorOption(Int32, String, Int64?, Bool)
    case bubbleColorCustom(String, Int64?, Bool)
    case backgroundColorHeader(String)
    case backgroundColorOption(Int32, String, Int64?, Bool)
    case backgroundColorCustom(String, Int64?, Bool)
    case cornerRadiusHeader(String)
    case cornerRadiusOption(Int32, String, Int32?, Bool)
    case chatFontSizeOption(Int32, String, Int32, Bool)
    case appearanceInfo(String)
    
    case developerHeader(String)
    case pushStatus(String, String)
    case pushToken(String, String)
    case debugMenu(String)
    case developerInfo(String)
    
    var section: ItemListSectionId {
        switch self {
        case .menuItem:
            return TelewhiteModsSection.menu.rawValue
        case .messengerHeader, .preserveDeletedMessages, .forwardHideNamesByDefault, .showPreviousEditedText, .oneTimeMedia, .hdPhotos, .quickForwardToSaved, .translatorLink, .messengerInfo:
            return TelewhiteModsSection.messenger.rawValue
        case .translatorHeader, .translateMessages, .autoTranslateEnglish, .translationTargetLanguage, .outgoingTranslateButtonEnabled, .translateVoiceMessages, .openRouterApiKey, .translatorInfo:
            return TelewhiteModsSection.translator.rawValue
        case .privacyHeader, .protectionBypass, .hidePhoneInSettings, .showProfileIds, .privacyInfo:
            return TelewhiteModsSection.privacy.rawValue
        case .stealthHeader, .ghost, .ghostChatButtonEnabled, .stealthInfo:
            return TelewhiteModsSection.stealth.rawValue
        case .channelsHeader, .channelsDeclutter, .channelsInfo:
            return TelewhiteModsSection.channels.rawValue
        case .mediaHeader, .downloadStories, .hideStories, .autoCacheCleanup, .cacheLimit, .mediaInfo:
            return TelewhiteModsSection.media.rawValue
        case .appearanceHeader, .compactChatList, .chatSplitLandscape, .amoledMode, .darkMonoPreset, .accentColorLink, .bubbleColorLink, .backgroundColorLink, .shapeLink:
            return TelewhiteModsSection.appearance.rawValue
        case .accentColorHeader, .accentColorOption, .accentColorCustom:
            return TelewhiteModsSection.accentColor.rawValue
        case .bubbleColorHeader, .bubbleColorOption, .bubbleColorCustom:
            return TelewhiteModsSection.bubbleColor.rawValue
        case .backgroundColorHeader, .backgroundColorOption, .backgroundColorCustom:
            return TelewhiteModsSection.backgroundColor.rawValue
        case .cornerRadiusHeader, .cornerRadiusOption, .chatFontSizeOption, .appearanceInfo:
            return TelewhiteModsSection.cornerRadius.rawValue
        case .developerHeader, .pushStatus, .pushToken, .debugMenu, .developerInfo:
            return TelewhiteModsSection.developer.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .menuItem(index, _, _, _, _):
            return -1000 + index
        case .messengerHeader:
            return 0
        case .preserveDeletedMessages:
            return 1
        case .showPreviousEditedText:
            return 2
        case .forwardHideNamesByDefault:
            return 3
        case .oneTimeMedia:
            return 4
        case .hdPhotos:
            return 5
        case .quickForwardToSaved:
            return 6
        case .translatorLink:
            return 7
        case .messengerInfo:
            return 8
        case .translatorHeader:
            return 50
        case .autoTranslateEnglish:
            return 51
        case .translationTargetLanguage:
            return 52
        case .translateMessages:
            return 53
        case .outgoingTranslateButtonEnabled:
            return 54
        case .translateVoiceMessages:
            return 55
        case .openRouterApiKey:
            return 56
        case .translatorInfo:
            return 57
        case .privacyHeader:
            return 100
        case .protectionBypass:
            return 101
        case .hidePhoneInSettings:
            return 102
        case .showProfileIds:
            return 103
        case .privacyInfo:
            return 104
        case .stealthHeader:
            return 300
        case .ghost:
            return 301
        case .ghostChatButtonEnabled:
            return 302
        case .stealthInfo:
            return 303
        case .channelsHeader:
            return 400
        case .channelsDeclutter:
            return 401
        case .channelsInfo:
            return 402
        case .mediaHeader:
            return 500
        case .downloadStories:
            return 501
        case .mediaInfo:
            return 502
        case .autoCacheCleanup:
            return 503
        case let .cacheLimit(index, _, _, _):
            return 504 + index
        case .appearanceHeader:
            return 700
        case .hideStories:
            return 701
        case .compactChatList:
            return 702
        case .amoledMode:
            return 703
        case .chatSplitLandscape:
            return 704
        case .darkMonoPreset:
            return 705
        case .accentColorLink:
            return 706
        case .bubbleColorLink:
            return 707
        case .backgroundColorLink:
            return 708
        case .shapeLink:
            return 709
        case .accentColorHeader:
            return 710
        case let .accentColorOption(index, _, _, _):
            return 711 + index
        case .accentColorCustom:
            return 729
        case .bubbleColorHeader:
            return 730
        case let .bubbleColorOption(index, _, _, _):
            return 731 + index
        case .bubbleColorCustom:
            return 749
        case .backgroundColorHeader:
            return 750
        case let .backgroundColorOption(index, _, _, _):
            return 751 + index
        case .backgroundColorCustom:
            return 769
        case .cornerRadiusHeader:
            return 770
        case let .cornerRadiusOption(index, _, _, _):
            return 771 + index
        case let .chatFontSizeOption(index, _, _, _):
            return 781 + index
        case .appearanceInfo:
            return 790
        case .developerHeader:
            return 800
        case .pushStatus:
            return 804
        case .pushToken:
            return 805
        case .debugMenu:
            return 806
        case .developerInfo:
            return 807
        }
    }
    
    static func <(lhs: TelewhiteModsEntry, rhs: TelewhiteModsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    private func switchItem(presentationData: ItemListPresentationData, arguments: TelewhiteModsControllerArguments, text: String, value: Bool, apply: @escaping (inout TelewhiteModsSettings, Bool) -> Void) -> ListViewItem {
        return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, text: telewhiteEntryDescription(self, presentationData: presentationData), value: value, maximumNumberOfLines: 3, sectionId: self.section, style: .blocks, updated: { newValue in
            arguments.updateSettings { current in
                var updated = current
                apply(&updated, newValue)
                return updated
            }
        })
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TelewhiteModsControllerArguments
        switch self {
        case let .menuItem(_, icon, title, subtitle, tab):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteMenuIcon(icon, color: presentationData.theme.list.itemAccentColor), title: title, titleFont: .bold, label: subtitle, labelStyle: .multilineDetailText, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(tab)
            })
        case let .messengerHeader(text), let .translatorHeader(text), let .privacyHeader(text), let .stealthHeader(text), let .channelsHeader(text), let .mediaHeader(text), let .appearanceHeader(text), let .developerHeader(text), let .accentColorHeader(text), let .bubbleColorHeader(text), let .backgroundColorHeader(text), let .cornerRadiusHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .accentColorOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.accentColorOverride = value
                    return updated
                }
            })
        case let .bubbleColorOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.bubbleColorOverride = value
                    return updated
                }
            })
        case let .backgroundColorOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.chatBackgroundColorOverride = value
                    updated.chatBackgroundGradientOverride = nil
                    return updated
                }
            })
        case let .accentColorCustom(title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(selected ? value : nil), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.promptCustomColor(.accent)
            })
        case let .bubbleColorCustom(title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(selected ? value : nil), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.promptCustomColor(.bubble)
            })
        case let .backgroundColorCustom(title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(selected ? value : nil), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.promptCustomColor(.background)
            })
        case let .cornerRadiusOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.bubbleCornerRadiusOverride = value
                    return updated
                }
            })
        case let .chatFontSizeOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.chatFontSizeOverride = value
                    return updated
                }
            })
        case let .oneTimeMedia(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                // Telewhite: opening without a limit and saving are one idea to a user.
                settings.oneTimeMediaUnlimited = value
                settings.downloadOneTimeMedia = value
            }
        case let .protectionBypass(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.screenshotProtectionBypass = value
                settings.contentRestrictionBypass = value
            }
        case let .ghost(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                // Telewhite: ghostMode is the master flag the engine checks alongside each
                // granular one. Its own row is gone, so this switch owns it — otherwise a
                // user who once enabled it would have no way left to turn it off.
                settings.ghostMode = value
                settings.hideOnlineStatus = value
                settings.hideTypingStatus = value
                settings.hideReadReceipts = value
                settings.ghostStories = value
            }
        case let .ghostChatButtonEnabled(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.ghostChatButtonEnabled = value
            }
        case let .channelsDeclutter(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.channelHideReactions = value
                settings.channelHideComments = value
                settings.channelHideShareButton = value
            }
        case let .translatorLink(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.translator)
            })
        case let .preserveDeletedMessages(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.preserveDeletedMessages = value
            }
        case let .forwardHideNamesByDefault(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.forwardHideNamesByDefault = value
            }
        case let .showPreviousEditedText(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showPreviousEditedText = value
            }
        case let .translateMessages(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, text: telewhiteEntryDescription(self, presentationData: presentationData), value: value, maximumNumberOfLines: 3, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateTranslationSettings { current in
                    var updated = current.withUpdatedShowTranslate(value)
                    if !updated.showTranslate && !updated.translateChats {
                        updated = updated.withUpdatedIgnoredLanguages(nil)
                    }
                    return updated
                }
            })
        case let .autoTranslateEnglish(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, text: telewhiteEntryDescription(self, presentationData: presentationData), value: value, maximumNumberOfLines: 3, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.autoTranslateEnglish = value
                    return updated
                }
                // Telewhite: "translate whole chats" was a separate switch for the same
                // outcome, so this one drives Telegram's setting as well.
                arguments.updateTranslationSettings { current in
                    var updated = current.withUpdatedTranslateChats(value)
                    if !updated.showTranslate && !updated.translateChats {
                        updated = updated.withUpdatedIgnoredLanguages(nil)
                    }
                    return updated
                }
            })
        case let .translationTargetLanguage(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value.uppercased(), labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case let .outgoingTranslateButtonEnabled(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.outgoingTranslateButtonEnabled = value
            }
        case let .openRouterApiKey(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value.isEmpty ? "" : "•••" + String(value.suffix(4)), labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.promptOpenRouterKey()
            })
        case let .hdPhotos(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hdPhotos = value
            }
        case let .translateVoiceMessages(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.translateVoiceMessages = value
            }
        case let .quickForwardToSaved(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.quickForwardToSaved = value
            }
        case let .debugMenu(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openDebug()
            })
        case let .messengerInfo(text), let .translatorInfo(text), let .privacyInfo(text), let .stealthInfo(text), let .channelsInfo(text), let .mediaInfo(text), let .developerInfo(text), let .appearanceInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .hidePhoneInSettings(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hidePhoneInSettings = value
            }
        case let .showProfileIds(text, value):
            // Telewhite: one switch controls all technical IDs (users, chats, messages).
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showUserIds = value
                settings.showChatIds = value
                settings.showMessageIds = value
            }
        case let .accentColorLink(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.accentColor)
            })
        case let .bubbleColorLink(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.bubbleColor)
            })
        case let .backgroundColorLink(text, value, gradient):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: gradient.flatMap(telewhiteGradientSwatchImage) ?? telewhiteColorSwatchImage(value), title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.background)
            })
        case let .shapeLink(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.shape)
            })
        case let .darkMonoPreset(text):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                // Telewhite: one-tap dark monochrome theme (matches the reference look):
                // true-black background, graphite outgoing bubbles, neutral-grey accent,
                // large rounded corners, AMOLED on.
                arguments.updateSettings { current in
                    var updated = current
                    updated.chatBackgroundGradientOverride = nil
                    updated.chatBackgroundColorOverride = 0x000000
                    updated.bubbleColorOverride = 0x1c1c1e
                    updated.accentColorOverride = 0x8e8e93
                    updated.bubbleCornerRadiusOverride = 17
                    updated.amoledMode = true
                    return updated
                }
            })
        case let .downloadStories(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.downloadStories = value
            }
        case let .autoCacheCleanup(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.autoCacheCleanup = value
            }
        case let .cacheLimit(_, text, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: text, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.cacheLimitGigabytes = value
                    updated.autoCacheCleanup = true
                    return updated
                }
            })
        case let .hideStories(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideStories = value
            }
        case let .compactChatList(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.compactChatList = value
            }
        case let .chatSplitLandscape(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.chatSplitLandscape = value
            }
        case let .amoledMode(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.amoledMode = value
            }
        case let .pushStatus(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case let .pushToken(text, value):
            let fullToken = UserDefaults.standard.string(forKey: "telewhite.push.token") ?? ""
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: fullToken.isEmpty ? .none : .arrow, action: fullToken.isEmpty ? nil : {
                UIPasteboard.general.string = fullToken
            })
        }
    }
}

private struct TelewhiteModsStrings {
    let isRussian: Bool

    init(presentationData: PresentationData) {
        self.isRussian = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
    }

    func text(_ en: String, _ ru: String) -> String {
        return self.isRussian ? ru : en
    }
}

private func telewhiteCustomColorTitle(strings: TelewhiteModsStrings, value: Int64?) -> String {
    let base = strings.text("Custom Color (HEX)", "Свой цвет (HEX)")
    if let value = value {
        return base + String(format: " — #%06X", UInt32(truncatingIfNeeded: value) & 0xffffff)
    }
    return base
}

func telewhiteParseHexColor(_ input: String) -> Int64? {
    var cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleaned.hasPrefix("#") {
        cleaned = String(cleaned.dropFirst())
    }
    if cleaned.hasPrefix("0x") || cleaned.hasPrefix("0X") {
        cleaned = String(cleaned.dropFirst(2))
    }
    if cleaned.count == 3 {
        cleaned = cleaned.map { "\($0)\($0)" }.joined()
    }
    guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
        return nil
    }
    return Int64(value)
}

private func telewhiteGradientSwatchImage(_ colors: [Int64]) -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(ovalIn: rect.insetBy(dx: 1.0, dy: 1.0))
        path.addClip()
        let cgColors = colors.map { UIColor(rgb: UInt32(truncatingIfNeeded: $0)).cgColor }
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors as CFArray, locations: nil) {
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: size.height), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        path.lineWidth = 1.0
        UIColor(white: 0.5, alpha: 0.35).setStroke()
        path.stroke()
    }
}

private func telewhiteColorSwatchImage(_ value: Int64?) -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(ovalIn: rect.insetBy(dx: 1.0, dy: 1.0))
        if let value = value {
            UIColor(rgb: UInt32(truncatingIfNeeded: value)).setFill()
            path.fill()
            path.lineWidth = 1.0
            UIColor(white: 0.5, alpha: 0.35).setStroke()
            path.stroke()
        } else {
            path.lineWidth = 1.5
            UIColor(white: 0.5, alpha: 0.35).setStroke()
            path.stroke()
            let line = UIBezierPath()
            line.move(to: CGPoint(x: 5.0, y: 17.0))
            line.addLine(to: CGPoint(x: 17.0, y: 5.0))
            line.lineWidth = 1.5
            UIColor(white: 0.5, alpha: 0.5).setStroke()
            line.stroke()
        }
    }
}

private var telewhiteMenuIconCache: [String: UIImage] = [:]

// Telewhite: glyphs for the Mods menu rows. These were hand-drawn bezier paths that
// read as approximations — a lock that looked like a bag, a "wave" for media — and
// several did not match their section at all. SF Symbols keep the same monochrome
// line-art style at a consistent weight while actually depicting each section. Every
// entry lists a fallback: all primaries ship in iOS 13, the app's minimum, and the
// fallback covers a symbol being renamed out from under us.
private func telewhiteMenuIconSymbolNames(_ icon: TelewhiteModsMenuIcon) -> [String] {
    switch icon {
    case .privacy:
        return ["lock.shield", "lock"]
    case .ghost:
        return ["eye.slash", "eye"]
    case .messages:
        return ["bubble.left.and.bubble.right", "bubble.left"]
    case .groups:
        return ["person.2", "person"]
    case .media:
        return ["photo.on.rectangle", "photo"]
    case .appearance:
        return ["paintbrush", "circle.lefthalf.fill"]
    case .developer:
        return ["hammer", "wrench"]
    }
}

private func telewhiteMenuIcon(_ icon: TelewhiteModsMenuIcon, color: UIColor) -> UIImage? {
    let cacheKey = "\(icon.rawValue)-\(color.argb)"
    if let cached = telewhiteMenuIconCache[cacheKey] {
        return cached
    }

    let configuration = UIImage.SymbolConfiguration(pointSize: 19.0, weight: .regular)
    var symbol: UIImage?
    for name in telewhiteMenuIconSymbolNames(icon) {
        if let candidate = UIImage(systemName: name, withConfiguration: configuration) {
            symbol = candidate
            break
        }
    }
    guard let symbol else {
        return nil
    }

    // Centre the glyph on a fixed canvas: symbol widths differ, and the rows must
    // still line up with each other.
    let size = CGSize(width: 29.0, height: 29.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
        let tinted = symbol.withTintColor(color, renderingMode: .alwaysOriginal)
        tinted.draw(in: CGRect(
            x: floor((size.width - tinted.size.width) * 0.5),
            y: floor((size.height - tinted.size.height) * 0.5),
            width: tinted.size.width,
            height: tinted.size.height
        ))
    }
    telewhiteMenuIconCache[cacheKey] = image
    return image
}

private func telewhiteTabTitle(_ tab: TelewhiteModsTab, strings: TelewhiteModsStrings) -> String {
    switch tab {
    case .messenger:
        return strings.text("Messages", "\u{0421}\u{043e}\u{043e}\u{0431}\u{0449}\u{0435}\u{043d}\u{0438}\u{044f}")
    case .privacy:
        return strings.text("Privacy", "\u{041a}\u{043e}\u{043d}\u{0444}\u{0438}\u{0434}\u{0435}\u{043d}\u{0446}\u{0438}\u{0430}\u{043b}\u{044c}\u{043d}\u{043e}\u{0441}\u{0442}\u{044c}")
    case .stealth:
        return strings.text("Ghost Mode", "\u{0420}\u{0435}\u{0436}\u{0438}\u{043c} \u{043d}\u{0435}\u{0432}\u{0438}\u{0434}\u{0438}\u{043c}\u{043a}\u{0438}")
    case .channels:
        return strings.text("Channels and Groups", "\u{041a}\u{0430}\u{043d}\u{0430}\u{043b}\u{044b} \u{0438} \u{0433}\u{0440}\u{0443}\u{043f}\u{043f}\u{044b}")
    case .media:
        return strings.text("Media and Stories", "\u{041c}\u{0435}\u{0434}\u{0438}\u{0430} \u{0438} \u{0438}\u{0441}\u{0442}\u{043e}\u{0440}\u{0438}\u{0438}")
    case .appearance:
        return strings.text("Look", "\u{0412}\u{043d}\u{0435}\u{0448}\u{043d}\u{0438}\u{0439} \u{0432}\u{0438}\u{0434}")
    case .developer:
        return strings.text("Developer", "\u{0420}\u{0430}\u{0437}\u{0440}\u{0430}\u{0431}\u{043e}\u{0442}\u{0447}\u{0438}\u{043a}")
    case .translator:
        return strings.text("Translator", "Переводчик")
    case .accentColor:
        return strings.text("Accent Color", "Акцентный цвет")
    case .bubbleColor:
        return strings.text("Outgoing Bubble Color", "Цвет исходящих")
    case .background:
        return strings.text("Chat Background", "Фон чата")
    case .shape:
        return strings.text("Bubbles and Text", "Пузыри и текст")
    }
}

private func telewhiteMenuEntries(strings: TelewhiteModsStrings) -> [TelewhiteModsEntry] {
    return [
        .menuItem(0, .privacy, telewhiteTabTitle(.privacy, strings: strings), strings.text("Saving restrictions, your number, numeric IDs.", "Запреты на сохранение, ваш номер, числовые ID."), .privacy),
        .menuItem(1, .ghost, telewhiteTabTitle(.stealth, strings: strings), strings.text("Read messages and watch stories without being seen.", "Читать сообщения и смотреть истории незаметно."), .stealth),
        .menuItem(2, .messages, telewhiteTabTitle(.messenger, strings: strings), strings.text("Deleted messages, view-once media, forwarding, translation.", "Удалённые сообщения, одноразовые медиа, пересылка, перевод."), .messenger),
        .menuItem(3, .groups, telewhiteTabTitle(.channels, strings: strings), strings.text("What is shown under channel posts.", "Что показывать под постами каналов."), .channels),
        .menuItem(4, .media, telewhiteTabTitle(.media, strings: strings), strings.text("Stories and space taken up on the phone.", "Истории и место, занятое на телефоне."), .media),
        .menuItem(5, .appearance, telewhiteTabTitle(.appearance, strings: strings), strings.text("Colours, chat list, landscape mode.", "Цвета, список чатов, горизонтальный режим."), .appearance),
        .menuItem(6, .developer, telewhiteTabTitle(.developer, strings: strings), strings.text("Notification diagnostics and debug tools.", "Диагностика уведомлений и отладка."), .developer)
    ]
}

private func telewhiteEntryDescription(_ entry: TelewhiteModsEntry, presentationData: ItemListPresentationData) -> String? {
    let isRussian = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
    func text(_ en: String, _ ru: String) -> String {
        return isRussian ? ru : en
    }
    // Telewhite: every line here is read by someone who just installed the app and has
    // no idea what the switch does. Say what they will see, not how it is implemented.
    switch entry {
    case .preserveDeletedMessages:
        return text("If someone deletes a message, it stays in the chat for you, marked \"Deleted\". Only on this phone — nothing is sent anywhere.", "Если собеседник удалит сообщение, у вас оно останется в чате с пометкой «Удалено». Только на этом телефоне — никуда ничего не отправляется.")
    case .showPreviousEditedText:
        return text("When someone edits a message, the old version stays visible in small text underneath.", "Когда сообщение изменят, под ним мелким шрифтом останется прошлый вариант.")
    case .forwardHideNamesByDefault:
        return text("Forwarded messages go out without the \"Forwarded from\" line. You can still turn it back on for a single forward.", "Пересланные сообщения уходят без строки «Переслано от». Для конкретной пересылки имя можно вернуть вручную.")
    case .oneTimeMedia:
        return text("Photos and videos sent as view-once can be opened as many times as you like, and saved.", "Фото и видео, отправленные с самоудалением после просмотра, можно открывать сколько угодно раз и сохранять себе.")
    case .hdPhotos:
        return text("Your photos are sent with much less compression. They look better and use more data.", "Ваши фото отправляются почти без сжатия — выглядят лучше, весят больше.")
    case .quickForwardToSaved:
        return text("Adds \"Forward to Saved Messages\" to the message menu — one tap, no chat picker.", "Добавляет в меню сообщения пункт «Переслать в Избранное» — одно нажатие, без выбора чата.")
    case .translatorLink:
        return text("Automatic translation of incoming messages, your own messages and voice messages.", "Автоперевод входящих, перевод ваших сообщений и голосовых.")
    case .autoTranslateEnglish:
        return text("Messages in other languages are shown to you already translated. Messages in your own language are left alone.", "Сообщения на других языках сразу показываются переведёнными. Сообщения на вашем языке не трогаются.")
    case .translationTargetLanguage:
        return text("The language everything is translated into.", "Язык, на который всё переводится.")
    case .translateMessages:
        return text("Adds \"Translate\" to the menu that appears when you hold a message.", "Добавляет пункт «Перевести» в меню, которое открывается долгим нажатием на сообщение.")
    case .outgoingTranslateButtonEnabled:
        return text("Puts a translator button at the top of private chats: tap it and your messages are sent translated, hold it to pick the language.", "Ставит кнопку переводчика в шапку личных чатов: нажатие — ваши сообщения уходят переведёнными, долгое нажатие — выбор языка.")
    case .translateVoiceMessages:
        return text("Voice messages in other languages get a translation under the transcript.", "Под расшифровкой голосового на чужом языке появляется перевод.")
    case .openRouterApiKey:
        return text("Optional. A free key from openrouter.ai gives better translation and voice transcription. Without it the regular translator is used.", "Необязательно. Бесплатный ключ с openrouter.ai даёт более точный перевод и расшифровку голосовых. Без него работает обычный переводчик.")
    case .protectionBypass:
        return text("In chats and channels that block saving, you can take screenshots, copy text, forward and save media again.", "В чатах и каналах, где запрещено сохранять, снова работают скриншоты, копирование, пересылка и сохранение медиа.")
    case .hidePhoneInSettings:
        return text("Your phone number and @username stop being shown in Settings and on your own profile, so nobody sees them over your shoulder. Other people still see them as usual.", "Ваш номер и @имя перестают показываться в настройках и в вашем профиле — их не увидят, заглянув в ваш экран. Для других людей ничего не меняется.")
    case .showProfileIds:
        return text("Shows the numeric ID in profiles and chats. Tap it to copy. Useful for bots; safe to leave off.", "Показывает числовой ID в профилях и чатах. Нажмите, чтобы скопировать. Нужно для ботов, обычно можно не включать.")
    case .ghost:
        return text("Nobody can tell you are there: no read receipts, no \"played\" marks on voice messages, no \"typing\", no online status, and stories are viewed anonymously.", "Никто не видит, что вы здесь: нет галочек о прочтении, отметок о прослушивании голосовых, статусов «печатает» и «в сети», а истории вы смотрите анонимно.")
    case .ghostChatButtonEnabled:
        return text("Adds a ghost icon to the top of every chat. It turns invisibility on for that one person, without affecting the rest.", "Добавляет значок-призрак в шапку каждого чата. Он включает невидимку только для этого собеседника, остальных не затрагивает.")
    case .channelsDeclutter:
        return text("Hides reactions, the comments bar and the share button under channel posts, leaving just the post.", "Убирает под постами каналов реакции, панель комментариев и кнопку «Поделиться» — остаётся только сам пост.")
    case .downloadStories:
        return text("Adds a save button to other people's stories.", "Добавляет кнопку сохранения в чужих историях.")
    case .hideStories:
        return text("Removes the row of stories above the chat list.", "Убирает ленту историй над списком чатов.")
    case .autoCacheCleanup:
        return text("When downloaded photos and videos take up more than the limit, the oldest ones are deleted. Nothing is lost — anything you open again is downloaded from Telegram.", "Когда скачанные фото и видео займут больше лимита, самые старые удаляются. Ничего не теряется — при открытии всё снова скачается из Telegram.")
    case .compactChatList:
        return text("Chat rows become shorter, so more chats fit on the screen.", "Строки чатов становятся ниже — на экране помещается больше чатов.")
    case .chatSplitLandscape:
        return text("Turn the phone sideways and the chat list stays next to the open chat, like on a computer.", "Поверните телефон горизонтально — список чатов останется рядом с открытым чатом, как на компьютере.")
    case .amoledMode:
        return text("Makes the dark theme pure black. On OLED screens black pixels are switched off, so it also saves battery.", "Делает тёмную тему полностью чёрной. На OLED-экранах чёрные пиксели не светятся, поэтому расходуется меньше заряда.")
    default:
        return nil
    }
}

private func telewhiteModsEntries(tab: TelewhiteModsTab, settings: TelewhiteModsSettings, translationSettings: TranslationSettings, strings: TelewhiteModsStrings) -> [TelewhiteModsEntry] {
    var entries: [TelewhiteModsEntry] = []

    switch tab {
    case .messenger:
        entries.append(.messengerHeader(telewhiteTabTitle(.messenger, strings: strings)))
        entries.append(.preserveDeletedMessages(strings.text("Keep Deleted Messages", "Не терять удалённые сообщения"), settings.preserveDeletedMessages))
        entries.append(.showPreviousEditedText(strings.text("Show the Text Before an Edit", "Показывать текст до правки"), settings.showPreviousEditedText))
        entries.append(.forwardHideNamesByDefault(strings.text("Forward Without the Author", "Пересылать без автора"), settings.forwardHideNamesByDefault))
        entries.append(.oneTimeMedia(strings.text("View-Once Photos and Videos", "Одноразовые фото и видео"), settings.oneTimeMediaUnlimited && settings.downloadOneTimeMedia))
        entries.append(.hdPhotos(strings.text("Send Photos in High Quality", "Отправлять фото в высоком качестве"), settings.hdPhotos))
        entries.append(.quickForwardToSaved(strings.text("\"To Saved Messages\" Button", "Кнопка «В Избранное»"), settings.quickForwardToSaved))
        entries.append(.translatorLink(telewhiteTabTitle(.translator, strings: strings)))
        entries.append(.messengerInfo(strings.text("Everything here works on this phone only.", "Всё перечисленное работает только на этом телефоне.")))

    case .translator:
        entries.append(.translatorHeader(telewhiteTabTitle(.translator, strings: strings)))
        entries.append(.autoTranslateEnglish(strings.text("Translate Incoming Messages", "Переводить входящие"), settings.autoTranslateEnglish))
        entries.append(.translationTargetLanguage(strings.text("Translate Into", "Переводить на"), settings.translationTargetLanguage))
        entries.append(.translateMessages(strings.text("\"Translate\" in the Message Menu", "«Перевести» в меню сообщения"), translationSettings.showTranslate))
        entries.append(.outgoingTranslateButtonEnabled(strings.text("Translate What You Send", "Переводить то, что вы пишете"), settings.outgoingTranslateButtonEnabled))
        entries.append(.translateVoiceMessages(strings.text("Translate Voice Messages", "Переводить голосовые"), settings.translateVoiceMessages))
        entries.append(.openRouterApiKey(strings.text("OpenRouter Key", "Ключ OpenRouter"), settings.openRouterApiKey))
        entries.append(.translatorInfo(strings.text("Translation is free and needs no account. Messages already in your language are never translated.", "Перевод бесплатный и не требует аккаунта. Сообщения, уже написанные на вашем языке, не переводятся.")))

    case .privacy:
        entries.append(.privacyHeader(telewhiteTabTitle(.privacy, strings: strings)))
        entries.append(.protectionBypass(strings.text("Allow Saving Everywhere", "Разрешить сохранять везде"), settings.screenshotProtectionBypass && settings.contentRestrictionBypass))
        entries.append(.hidePhoneInSettings(strings.text("Hide My Number and Username", "Скрыть свой номер и юзернейм"), settings.hidePhoneInSettings))
        entries.append(.showProfileIds(strings.text("Show Numeric IDs", "Показывать числовые ID"), settings.showUserIds && settings.showChatIds))
        entries.append(.privacyInfo(strings.text("These switches change what this phone shows and allows. They do not change your Telegram privacy settings.", "Эти переключатели меняют то, что показывает и разрешает этот телефон. Настройки приватности в самом Telegram они не трогают.")))

    case .stealth:
        entries.append(.stealthHeader(telewhiteTabTitle(.stealth, strings: strings)))
        entries.append(.ghost(strings.text("Invisible Mode", "Невидимка"), settings.hideReadReceipts && settings.ghostStories))
        entries.append(.ghostChatButtonEnabled(strings.text("Ghost Button in Chats", "Кнопка невидимки в чате"), settings.ghostChatButtonEnabled))
        entries.append(.stealthInfo(strings.text("While you are invisible, Telegram will not show other people's read receipts to you either.", "Пока вы невидимы, Telegram и вам не показывает чужие отметки о прочтении.")))

    case .channels:
        entries.append(.channelsHeader(telewhiteTabTitle(.channels, strings: strings)))
        entries.append(.channelsDeclutter(strings.text("Clean Up Posts", "Убрать лишнее под постами"), settings.channelHideReactions && settings.channelHideComments && settings.channelHideShareButton))
        entries.append(.channelsInfo(strings.text("Only changes how posts look on this phone. Nobody else is affected.", "Меняет только то, как посты выглядят на этом телефоне. Для остальных ничего не меняется.")))

    case .media:
        entries.append(.mediaHeader(telewhiteTabTitle(.media, strings: strings)))
        entries.append(.downloadStories(strings.text("Save Other People's Stories", "Сохранять чужие истории"), settings.downloadStories))
        entries.append(.hideStories(strings.text("Hide the Stories Row", "Скрыть ленту историй"), settings.hideStories))
        entries.append(.autoCacheCleanup(strings.text("Clear Space Automatically", "Освобождать место автоматически"), settings.autoCacheCleanup))
        if settings.autoCacheCleanup {
            for (index, limit) in [Int32(1), 2, 5, 10].enumerated() {
                entries.append(.cacheLimit(Int32(index), strings.text("Keep up to \(limit) GB", "Хранить до \(limit) ГБ"), limit, settings.cacheLimitGigabytes == limit))
            }
        }
        entries.append(.mediaInfo(strings.text("Your messages and files in the cloud are never deleted — only the copies downloaded to this phone.", "Ваши сообщения и файлы в облаке не удаляются — стираются только копии, скачанные на этот телефон.")))

    case .appearance:
        entries.append(.appearanceHeader(telewhiteTabTitle(.appearance, strings: strings)))
        entries.append(.compactChatList(strings.text("Compact Chat List", "Компактный список чатов"), settings.compactChatList))
        entries.append(.chatSplitLandscape(strings.text("Split View in Landscape", "Сплит чатов (альбомная)"), settings.chatSplitLandscape))
        entries.append(.amoledMode(strings.text("AMOLED Mode", "AMOLED режим"), settings.amoledMode))
        entries.append(.darkMonoPreset(strings.text("Dark Mono Theme", "Тёмная моно-тема")))
        // Telewhite: the three palettes and the shape options live on their own
        // screens. Each row shows the colour currently in effect as its swatch, so the
        // overview still answers "what is set?" without opening anything.
        entries.append(.accentColorLink(strings.text("Accent Color", "Акцентный цвет"), settings.accentColorOverride))
        entries.append(.bubbleColorLink(strings.text("Outgoing Bubble Color", "Цвет исходящих сообщений"), settings.bubbleColorOverride))
        entries.append(.backgroundColorLink(strings.text("Chat Background", "Фон чата"), settings.chatBackgroundColorOverride, settings.chatBackgroundGradientOverride))
        entries.append(.shapeLink(strings.text("Bubbles and Text", "Пузыри и текст")))

    case .accentColor:
        let accentPresets: [(String, Int64?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Blue", "Синий"), 0x007aff),
            (strings.text("Green", "Зелёный"), 0x34c759),
            (strings.text("Red", "Красный"), 0xff3b30),
            (strings.text("Pink", "Розовый"), 0xff2d55),
            (strings.text("Indigo", "Индиго"), 0x5856d6)
        ]
        entries.append(.accentColorHeader(strings.text("Accent Color", "Акцентный цвет")))
        for (index, preset) in accentPresets.enumerated() {
            entries.append(.accentColorOption(Int32(index), preset.0, preset.1, settings.accentColorOverride == preset.1))
        }
        let accentIsCustom = settings.accentColorOverride != nil && !accentPresets.contains(where: { $0.1 == settings.accentColorOverride })
        entries.append(.accentColorCustom(telewhiteCustomColorTitle(strings: strings, value: accentIsCustom ? settings.accentColorOverride : nil), settings.accentColorOverride, accentIsCustom))

    case .bubbleColor:
        let bubblePresets: [(String, Int64?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Blue", "Синий"), 0x007aff),
            (strings.text("Indigo", "Индиго"), 0x5856d6),
            (strings.text("Graphite", "Графит"), 0x3a3a3c),
            (strings.text("Dark Green", "Тёмно-зелёный"), 0x1f3d2b)
        ]
        entries.append(.bubbleColorHeader(strings.text("Outgoing Bubble Color", "Цвет исходящих сообщений")))
        for (index, preset) in bubblePresets.enumerated() {
            entries.append(.bubbleColorOption(Int32(index), preset.0, preset.1, settings.bubbleColorOverride == preset.1))
        }
        let bubbleIsCustom = settings.bubbleColorOverride != nil && !bubblePresets.contains(where: { $0.1 == settings.bubbleColorOverride })
        entries.append(.bubbleColorCustom(telewhiteCustomColorTitle(strings: strings, value: bubbleIsCustom ? settings.bubbleColorOverride : nil), settings.bubbleColorOverride, bubbleIsCustom))

    case .background:
        let backgroundPresets: [(String, Int64?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Black", "Чёрный"), 0x000000),
            (strings.text("Graphite", "Графит"), 0x1c1c1e),
            (strings.text("Deep Green", "Тёмно-зелёный"), 0x0e1f16),
            (strings.text("Light", "Светлый"), 0xf2f2f7)
        ]
        entries.append(.backgroundColorHeader(strings.text("Chat Background", "Фон чата")))
        for (index, preset) in backgroundPresets.enumerated() {
            let selected = settings.chatBackgroundGradientOverride == nil && settings.chatBackgroundColorOverride == preset.1
            entries.append(.backgroundColorOption(Int32(index), preset.0, preset.1, selected))
        }
        let backgroundIsCustom = settings.chatBackgroundGradientOverride == nil && settings.chatBackgroundColorOverride != nil && !backgroundPresets.contains(where: { $0.1 == settings.chatBackgroundColorOverride })
        entries.append(.backgroundColorCustom(telewhiteCustomColorTitle(strings: strings, value: backgroundIsCustom ? settings.chatBackgroundColorOverride : nil), settings.chatBackgroundColorOverride, backgroundIsCustom))

    case .shape:
        let radiusPresets: [(String, Int32?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Small", "Маленькое"), 8),
            (strings.text("Medium", "Среднее"), 12),
            (strings.text("Large", "Большое"), 17)
        ]
        entries.append(.cornerRadiusHeader(strings.text("Bubble Corner Radius", "Скругление сообщений")))
        for (index, preset) in radiusPresets.enumerated() {
            entries.append(.cornerRadiusOption(Int32(index), preset.0, preset.1, settings.bubbleCornerRadiusOverride == preset.1))
        }
        entries.append(.chatFontSizeOption(0, strings.text("Chat Text: Default", "Текст чата: по умолчанию"), 0, settings.chatFontSizeOverride == 0))
        entries.append(.chatFontSizeOption(1, strings.text("Chat Text: Small", "Текст чата: меньше"), PresentationFontSize.small.rawValue, settings.chatFontSizeOverride == PresentationFontSize.small.rawValue))
        entries.append(.chatFontSizeOption(2, strings.text("Chat Text: Large", "Текст чата: больше"), PresentationFontSize.large.rawValue, settings.chatFontSizeOverride == PresentationFontSize.large.rawValue))
        entries.append(.appearanceInfo(strings.text("Color, radius and chat text overrides apply on top of the selected Telegram theme and update instantly.", "Настройки цвета, скругления и текста чата применяются поверх выбранной темы Telegram и обновляются мгновенно.")))

    case .developer:
        entries.append(.developerHeader(telewhiteTabTitle(.developer, strings: strings)))

        let defaults = UserDefaults.standard
        let pushStatus = defaults.string(forKey: "telewhite.push.status") ?? strings.text("Not requested yet", "Ещё не запрошено")
        entries.append(.pushStatus(strings.text("Push status", "Статус пушей"), pushStatus))
        let pushToken = defaults.string(forKey: "telewhite.push.token") ?? ""
        let shortToken: String
        if pushToken.isEmpty {
            shortToken = strings.text("None", "Нет")
        } else if pushToken.count > 16 {
            shortToken = "\(pushToken.prefix(8))…\(pushToken.suffix(8))"
        } else {
            shortToken = pushToken
        }
        entries.append(.pushToken(strings.text("APNs token", "APNs токен"), pushToken.isEmpty ? shortToken : "\(shortToken) — \(strings.text("tap to copy", "нажмите чтобы скопировать"))"))
        entries.append(.debugMenu(strings.text("Debug Menu", "Меню отладки")))
        entries.append(.developerInfo(strings.text("Diagnostics for push registration and technical debugging tools.", "Диагностика регистрации push-уведомлений и технические инструменты отладки.")))
    }

    return entries
}

public func telewhiteModsController(context: AccountContext) -> ViewController {
    let initialSettings = TelewhiteModsSettings.current
    let stateValue = Atomic(value: initialSettings)
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)

    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void = { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        // Telewhite: one global Ghost Mode switch is the only presence control.
        context.account.shouldKeepOnlinePresence.set(.single(!updated.ghostMode))
        let cacheLimit = updated.autoCacheCleanup ? updated.cacheLimitGigabytes : Int32.max
        let _ = updateCacheStorageSettingsInteractively(accountManager: context.sharedContext.accountManager, { current in
            var current = current
            current.defaultCacheStorageLimitGigabytes = cacheLimit
            return current
        }).start()
        let _ = (context.sharedContext.accountManager.sharedData(keys: [SharedDataKeys.cacheStorageSettings])
        |> take(1)).start(next: { sharedData in
            let cacheSettings = sharedData.entries[SharedDataKeys.cacheStorageSettings]?.get(CacheStorageSettings.self) ?? CacheStorageSettings.defaultSettings
            context.account.postbox.mediaBox.setMaxStoreTimes(general: cacheSettings.defaultCacheStorageTimeout, shortLived: 60 * 60, gigabytesLimit: cacheLimit)
        })
        statePromise.set(updated)
    }

    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = TelewhiteModsControllerArguments(updateSettings: updateSettings, updateTranslationSettings: { _ in
    }, openTab: { tab in
        pushControllerImpl?(telewhiteModsSectionController(context: context, tab: tab, statePromise: statePromise, stateValue: stateValue, updateSettings: updateSettings))
    })

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let title = strings.text("Telewhite Settings", "\u{041d}\u{0430}\u{0441}\u{0442}\u{0440}\u{043e}\u{0439}\u{043a}\u{0438} Telewhite")
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteMenuEntries(strings: strings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments as Any))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}

private func telewhiteModsSectionController(context: AccountContext, tab: TelewhiteModsTab, statePromise: ValuePromise<TelewhiteModsSettings>, stateValue: Atomic<TelewhiteModsSettings>, updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void) -> ViewController {
    var presentControllerImpl: ((ViewController) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = TelewhiteModsControllerArguments(updateSettings: updateSettings, updateTranslationSettings: { f in
        let _ = updateTranslationSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }, openTab: { tab in
        // Telewhite: appearance sub-screens are pushed from this screen, so a section
        // controller has to be able to open another section controller.
        pushControllerImpl?(telewhiteModsSectionController(context: context, tab: tab, statePromise: statePromise, stateValue: stateValue, updateSettings: updateSettings))
    }, promptCustomColor: { target in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let settings = stateValue.with { $0 }
        let currentValue: Int64?
        switch target {
        case .accent:
            currentValue = settings.accentColorOverride
        case .bubble:
            currentValue = settings.bubbleColorOverride
        case .background:
            currentValue = settings.chatBackgroundColorOverride
        }
        let initialText = currentValue.flatMap { String(format: "#%06X", UInt32(truncatingIfNeeded: $0) & 0xffffff) } ?? ""
        let prompt = promptController(
            context: context,
            text: strings.text("Custom Color", "Свой цвет"),
            subtitle: strings.text("Enter a HEX code, e.g. #1E90FF", "Введите HEX-код, например #1E90FF"),
            value: initialText,
            placeholder: "#RRGGBB",
            characterLimit: 9,
            apply: { value in
                guard let value = value, let parsed = telewhiteParseHexColor(value) else {
                    return
                }
                updateSettings { current in
                    var updated = current
                    switch target {
                    case .accent:
                        updated.accentColorOverride = parsed
                    case .bubble:
                        updated.bubbleColorOverride = parsed
                    case .background:
                        updated.chatBackgroundColorOverride = parsed
                        updated.chatBackgroundGradientOverride = nil
                    }
                    return updated
                }
            }
        )
        presentControllerImpl?(prompt)
    }, openDebug: {
        if let debugController = context.sharedContext.makeDebugSettingsController(context: context) {
            pushControllerImpl?(debugController)
        }
    }, promptOpenRouterKey: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let settings = stateValue.with { $0 }
        let prompt = promptController(
            context: context,
            text: strings.text("OpenRouter API Key", "Ключ OpenRouter API"),
            subtitle: strings.text("Paste your key from openrouter.ai (starts with sk-or-). Leave empty to use the standard translator.", "Вставьте ключ с openrouter.ai (начинается с sk-or-). Оставьте пустым для стандартного переводчика."),
            value: settings.openRouterApiKey,
            placeholder: "sk-or-v1-...",
            characterLimit: 256,
            apply: { value in
                guard let value = value else {
                    return
                }
                updateSettings { current in
                    var updated = current
                    updated.openRouterApiKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    return updated
                }
            }
        )
        presentControllerImpl?(prompt)
    })

    let translationSettings = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.translationSettings])
    |> map { sharedData -> TranslationSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.translationSettings]?.get(TranslationSettings.self) ?? TranslationSettings.defaultSettings
    }

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), translationSettings)
    |> deliverOnMainQueue
    |> map { presentationData, settings, translationSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(telewhiteTabTitle(tab, strings: strings)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteModsEntries(tab: tab, settings: settings, translationSettings: translationSettings, strings: strings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments as Any))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}
