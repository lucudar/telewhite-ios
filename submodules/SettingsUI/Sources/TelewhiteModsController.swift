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
import TranslateUI

public struct TelewhiteModsSettings: Equatable {
    public static let didChangeNotification = Notification.Name("TelewhiteModsSettingsDidChange")

    public var ghostMode: Bool
    public var ghostChatButtonEnabled: Bool
    public var preserveDeletedMessages: Bool
    public var backgroundMessageRefresh: Bool
    public var hideOnlineStatus: Bool
    public var hideTypingStatus: Bool
    public var hideReadReceipts: Bool
    public var screenshotProtectionBypass: Bool
    public var contentRestrictionBypass: Bool
    public var hidePhoneInSettings: Bool
    public var hideStories: Bool
    public var ghostStories: Bool
    public var chatListDensity: Int32
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
    public var chatFontSizeOverride: Int32
    public var outgoingTranslateButtonEnabled: Bool
    public var outgoingTranslateInPrivate: Bool
    public var outgoingTranslateInGroups: Bool
    public var outgoingTranslateInBots: Bool
    public var outgoingTranslationPeerIds: Set<Int64>
    public var outgoingTranslationLanguages: [Int64: String]
    public var forwardHideNamesByDefault: Bool
    public var showPreviousEditedText: Bool
    public var autoCacheCleanup: Bool
    public var cacheLimitGigabytes: Int32
    public var speedBoost: Int32
    public var longRoundVideos: Bool
    public var confirmVoiceSend: Bool
    public var settingsIconVariant: Int32
    public var chatListRows: Int32
    public var translateButtonInChat: Bool
    public var channelHideReactions: Bool
    public var channelHideComments: Bool
    public var channelHideShareButton: Bool
    public var hdPhotos: Bool
    public var translateVoiceMessages: Bool
    public var quickForwardToSaved: Bool
    public var showReadDateOnTap: Bool
    public var localTranscription: Bool
    public var hideSponsoredContent: Bool
    public var keepTimedMessages: Bool

    private enum Key {
        static let ghostMode = "telewhite.mods.ghostMode"
        static let ghostChatButtonEnabled = "telewhite.mods.ghostChatButtonEnabled"
        static let preserveDeletedMessages = "telewhite.mods.preserveDeletedMessages"
        static let backgroundMessageRefresh = "telewhite.mods.backgroundMessageRefresh"
        static let hideOnlineStatus = "telewhite.mods.hideOnlineStatus"
        static let hideTypingStatus = "telewhite.mods.hideTypingStatus"
        static let hideReadReceipts = "telewhite.mods.hideReadReceipts"
        static let screenshotProtectionBypass = "telewhite.mods.screenshotProtectionBypass"
        static let contentRestrictionBypass = "telewhite.mods.contentRestrictionBypass"
        static let hidePhoneInSettings = "telewhite.mods.hidePhoneInSettings"
        static let hideStories = "telewhite.mods.hideStories"
        static let ghostStories = "telewhite.mods.ghostStories"
        static let chatListDensity = "telewhite.mods.chatListDensity"
        // Retired in favour of chatListDensity; still read once to carry the old value over.
        static let legacyCompactChatList = "telewhite.mods.compactChatList"
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
        static let chatFontSizeOverride = "telewhite.mods.chatFontSizeOverride"
        static let outgoingTranslateButtonEnabled = "telewhite.mods.outgoingTranslateButtonEnabled"
        static let outgoingTranslateInPrivate = "telewhite.mods.outgoingTranslateInPrivate"
        static let outgoingTranslateInGroups = "telewhite.mods.outgoingTranslateInGroups"
        static let outgoingTranslateInBots = "telewhite.mods.outgoingTranslateInBots"
        static let outgoingTranslationPeerIds = "telewhite.mods.outgoingTranslationPeerIds"
        static let outgoingTranslationLanguages = "telewhite.mods.outgoingTranslationLanguages"
        static let forwardHideNamesByDefault = "telewhite.mods.forwardHideNamesByDefault"
        static let showPreviousEditedText = "telewhite.mods.showPreviousEditedText"
        static let autoCacheCleanup = "telewhite.mods.autoCacheCleanup"
        static let cacheLimitGigabytes = "telewhite.mods.cacheLimitGigabytes"
        static let speedBoost = "telewhite.mods.speedBoost"
        static let longRoundVideos = "telewhite.mods.longRoundVideos"
        static let confirmVoiceSend = "telewhite.mods.confirmVoiceSend"
        static let settingsIconVariant = "telewhite.mods.settingsIconVariant"
        static let chatListRows = "telewhite.mods.chatListRows"
        static let translateButtonInChat = "telewhite.mods.translateButtonInChat"
        static let channelHideReactions = "telewhite.mods.channelHideReactions"
        static let channelHideComments = "telewhite.mods.channelHideComments"
        static let channelHideShareButton = "telewhite.mods.channelHideShareButton"
        static let hdPhotos = "telewhite.mods.hdPhotos"
        static let translateVoiceMessages = "telewhite.mods.translateVoiceMessages"
        static let quickForwardToSaved = "telewhite.mods.quickForwardToSaved"
        static let showReadDateOnTap = "telewhite.mods.showReadDateOnTap"
        static let localTranscription = "telewhite.mods.localTranscription"
        static let hideSponsoredContent = "telewhite.mods.hideSponsoredContent"
        static let keepTimedMessages = "telewhite.mods.keepTimedMessages"
    }

    // The language the phone is set to, which is the only sensible guess for "translate
    // into" before the user has said otherwise. Falls back to Russian, the audience this
    // fork is built for, when the system language is not one the translator supports.
    private static func telewhiteDefaultTranslationTargetLanguage() -> String {
        for language in Locale.preferredLanguages {
            let code = normalizeTranslationLanguage(language.components(separatedBy: "-").first?.lowercased() ?? language)
            if supportedTranslationLanguages.contains(code) {
                return code
            }
        }
        return "ru"
    }

    public static var current: TelewhiteModsSettings {
        let defaults = UserDefaults.standard
        var settings = TelewhiteModsSettings(
            // Telewhite: global Ghost Mode is an optional master switch; the granular
            // stealth toggles below are independent and persist on their own keys.
            ghostMode: defaults.bool(forKey: Key.ghostMode),
            ghostChatButtonEnabled: defaults.object(forKey: Key.ghostChatButtonEnabled) as? Bool ?? true,
            preserveDeletedMessages: defaults.bool(forKey: Key.preserveDeletedMessages),
            // On by default, but it only ever schedules anything while Keep Deleted Messages
            // is on, so a user who never touched that feature pays nothing for this.
            backgroundMessageRefresh: defaults.object(forKey: Key.backgroundMessageRefresh) as? Bool ?? true,
            hideOnlineStatus: defaults.bool(forKey: Key.hideOnlineStatus),
            hideTypingStatus: defaults.bool(forKey: Key.hideTypingStatus),
            hideReadReceipts: defaults.bool(forKey: Key.hideReadReceipts),
            screenshotProtectionBypass: defaults.bool(forKey: Key.screenshotProtectionBypass),
            contentRestrictionBypass: defaults.bool(forKey: Key.contentRestrictionBypass),
            hidePhoneInSettings: defaults.bool(forKey: Key.hidePhoneInSettings),
            hideStories: defaults.bool(forKey: Key.hideStories),
            ghostStories: defaults.bool(forKey: Key.ghostStories),
            chatListDensity: {
                if let stored = (defaults.object(forKey: Key.chatListDensity) as? NSNumber)?.int32Value {
                    return min(3, max(0, stored))
                }
                // First run after the switch became a scale: "Compact Chat List" was
                // roughly the first step, so land there instead of silently resetting.
                return defaults.bool(forKey: Key.legacyCompactChatList) ? 1 : 0
            }(),
            chatSplitLandscape: defaults.bool(forKey: Key.chatSplitLandscape),
            amoledMode: defaults.bool(forKey: Key.amoledMode),
            showUserIds: defaults.bool(forKey: Key.showUserIds),
            showChatIds: defaults.bool(forKey: Key.showChatIds),
            showMessageIds: defaults.bool(forKey: Key.showMessageIds),
            ghostPeerIds: Set((defaults.array(forKey: Key.ghostPeerIds) as? [NSNumber] ?? []).map { $0.int64Value }),
            autoTranslateEnglish: defaults.object(forKey: Key.autoTranslateEnglish) as? Bool ?? true,
            // Not hardcoded "ru": the first save writes this value out for good, so an
            // English-interface user who merely flipped some other switch would have had
            // every foreign chat translated into Russian from then on.
            translationTargetLanguage: defaults.string(forKey: Key.translationTargetLanguage) ?? telewhiteDefaultTranslationTargetLanguage(),
            oneTimeMediaUnlimited: defaults.bool(forKey: Key.oneTimeMediaUnlimited),
            downloadOneTimeMedia: defaults.bool(forKey: Key.downloadOneTimeMedia),
            downloadStories: defaults.bool(forKey: Key.downloadStories),
            chatFontSizeOverride: (defaults.object(forKey: Key.chatFontSizeOverride) as? NSNumber)?.int32Value ?? 0,
            outgoingTranslateButtonEnabled: defaults.object(forKey: Key.outgoingTranslateButtonEnabled) as? Bool ?? true,
            outgoingTranslateInPrivate: defaults.object(forKey: Key.outgoingTranslateInPrivate) as? Bool ?? true,
            outgoingTranslateInGroups: defaults.object(forKey: Key.outgoingTranslateInGroups) as? Bool ?? true,
            outgoingTranslateInBots: defaults.object(forKey: Key.outgoingTranslateInBots) as? Bool ?? true,
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
            forwardHideNamesByDefault: defaults.bool(forKey: Key.forwardHideNamesByDefault),
            showPreviousEditedText: defaults.object(forKey: Key.showPreviousEditedText) as? Bool ?? true,
            autoCacheCleanup: defaults.bool(forKey: Key.autoCacheCleanup),
            cacheLimitGigabytes: max(1, (defaults.object(forKey: Key.cacheLimitGigabytes) as? NSNumber)?.int32Value ?? 5),
            speedBoost: min(2, max(0, (defaults.object(forKey: Key.speedBoost) as? NSNumber)?.int32Value ?? 0)),
            longRoundVideos: defaults.bool(forKey: Key.longRoundVideos),
            confirmVoiceSend: defaults.bool(forKey: Key.confirmVoiceSend),
            settingsIconVariant: min(3, max(0, (defaults.object(forKey: Key.settingsIconVariant) as? NSNumber)?.int32Value ?? 0)),
            chatListRows: min(3, max(1, (defaults.object(forKey: Key.chatListRows) as? NSNumber)?.int32Value ?? 2)),
            translateButtonInChat: defaults.object(forKey: Key.translateButtonInChat) as? Bool ?? true,
            channelHideReactions: defaults.bool(forKey: Key.channelHideReactions),
            channelHideComments: defaults.bool(forKey: Key.channelHideComments),
            channelHideShareButton: defaults.bool(forKey: Key.channelHideShareButton),
            hdPhotos: defaults.object(forKey: Key.hdPhotos) as? Bool ?? false,
            translateVoiceMessages: defaults.bool(forKey: Key.translateVoiceMessages),
            quickForwardToSaved: defaults.bool(forKey: Key.quickForwardToSaved),
            // Defaults on: it only reacts to a deliberate tap on your own checkmarks.
            showReadDateOnTap: defaults.object(forKey: Key.showReadDateOnTap) as? Bool ?? true,
            // Defaults off: the first transcript asks for the speech recognition permission,
            // and a permission sheet nobody asked for on first launch reads as a bug.
            localTranscription: defaults.bool(forKey: Key.localTranscription),
            // Defaults on: nobody installs a fork to keep the ads.
            hideSponsoredContent: defaults.object(forKey: Key.hideSponsoredContent) as? Bool ?? true,
            // Defaults off: it deliberately ignores what the sender asked for, so it has to be
            // an explicit choice rather than something the fork does behind the user's back.
            keepTimedMessages: defaults.bool(forKey: Key.keepTimedMessages)
        )

        // Telewhite: the five stealth flags are one switch now, but older builds wrote
        // them separately, so half-on states exist on real devices. Every engine consumer
        // gates on `ghostMode || <its own flag>`, so half-on means "partly invisible" —
        // and a single row cannot honestly display that. Normalise it once, upward: the
        // user asked to be hidden, so finish hiding them rather than silently exposing
        // what they had already turned on. Idempotent — after this the branch is dead.
        let anyStealth = settings.ghostMode || settings.hideOnlineStatus || settings.hideTypingStatus || settings.hideReadReceipts || settings.ghostStories
        let allStealth = settings.ghostMode && settings.hideOnlineStatus && settings.hideTypingStatus && settings.hideReadReceipts && settings.ghostStories
        if anyStealth && !allStealth {
            settings.ghostMode = true
            settings.hideOnlineStatus = true
            settings.hideTypingStatus = true
            settings.hideReadReceipts = true
            settings.ghostStories = true
            settings.save()
        }

        return settings
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
        defaults.set(self.backgroundMessageRefresh, forKey: Key.backgroundMessageRefresh)
        defaults.set(self.hideOnlineStatus, forKey: Key.hideOnlineStatus)
        defaults.set(self.hideTypingStatus, forKey: Key.hideTypingStatus)
        defaults.set(self.hideReadReceipts, forKey: Key.hideReadReceipts)
        defaults.set(self.screenshotProtectionBypass, forKey: Key.screenshotProtectionBypass)
        defaults.set(self.contentRestrictionBypass, forKey: Key.contentRestrictionBypass)
        defaults.set(self.hidePhoneInSettings, forKey: Key.hidePhoneInSettings)
        defaults.set(self.hideStories, forKey: Key.hideStories)
        defaults.set(self.ghostStories, forKey: Key.ghostStories)
        defaults.set(self.chatListDensity, forKey: Key.chatListDensity)
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
        defaults.set(self.chatFontSizeOverride, forKey: Key.chatFontSizeOverride)
        defaults.set(self.outgoingTranslateButtonEnabled, forKey: Key.outgoingTranslateButtonEnabled)
        defaults.set(self.outgoingTranslateInPrivate, forKey: Key.outgoingTranslateInPrivate)
        defaults.set(self.outgoingTranslateInGroups, forKey: Key.outgoingTranslateInGroups)
        defaults.set(self.outgoingTranslateInBots, forKey: Key.outgoingTranslateInBots)
        defaults.set(self.outgoingTranslationPeerIds.map { NSNumber(value: $0) }, forKey: Key.outgoingTranslationPeerIds)
        defaults.set(Dictionary(uniqueKeysWithValues: self.outgoingTranslationLanguages.map { (String($0.key), $0.value) }), forKey: Key.outgoingTranslationLanguages)
        defaults.set(self.forwardHideNamesByDefault, forKey: Key.forwardHideNamesByDefault)
        defaults.set(self.showPreviousEditedText, forKey: Key.showPreviousEditedText)
        defaults.set(self.autoCacheCleanup, forKey: Key.autoCacheCleanup)
        defaults.set(self.cacheLimitGigabytes, forKey: Key.cacheLimitGigabytes)
        defaults.set(self.speedBoost, forKey: Key.speedBoost)
        defaults.set(self.longRoundVideos, forKey: Key.longRoundVideos)
        defaults.set(self.confirmVoiceSend, forKey: Key.confirmVoiceSend)
        defaults.set(self.settingsIconVariant, forKey: Key.settingsIconVariant)
        defaults.set(self.chatListRows, forKey: Key.chatListRows)
        defaults.set(self.translateButtonInChat, forKey: Key.translateButtonInChat)
        defaults.set(self.channelHideReactions, forKey: Key.channelHideReactions)
        defaults.set(self.channelHideComments, forKey: Key.channelHideComments)
        defaults.set(self.channelHideShareButton, forKey: Key.channelHideShareButton)
        defaults.set(self.hdPhotos, forKey: Key.hdPhotos)
        defaults.set(self.translateVoiceMessages, forKey: Key.translateVoiceMessages)
        defaults.set(self.quickForwardToSaved, forKey: Key.quickForwardToSaved)
        defaults.set(self.showReadDateOnTap, forKey: Key.showReadDateOnTap)
        defaults.set(self.localTranscription, forKey: Key.localTranscription)
        defaults.set(self.hideSponsoredContent, forKey: Key.hideSponsoredContent)
        defaults.set(self.keepTimedMessages, forKey: Key.keepTimedMessages)
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

private final class TelewhiteModsControllerArguments {
    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void
    let updateTranslationSettings: (@escaping (TranslationSettings) -> TranslationSettings) -> Void
    let openTab: (TelewhiteModsTab) -> Void
    let openDebug: () -> Void
    // Telewhite: reopens the stock accent color picker (palette + hue slider) that
    // ThemeSettingsController already ships, instead of writing a second one.
    let openAccentColorPicker: () -> Void
    // Telewhite: same stock picker, opened on its Messages section, which is what
    // actually edits the outgoing bubble color.
    let openBubbleColorPicker: () -> Void

    init(
        updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void,
        updateTranslationSettings: @escaping (@escaping (TranslationSettings) -> TranslationSettings) -> Void,
        openTab: @escaping (TelewhiteModsTab) -> Void = { _ in },
        openDebug: @escaping () -> Void = {},
        openAccentColorPicker: @escaping () -> Void = {},
        openBubbleColorPicker: @escaping () -> Void = {}
    ) {
        self.updateSettings = updateSettings
        self.updateTranslationSettings = updateTranslationSettings
        self.openTab = openTab
        self.openDebug = openDebug
        self.openAccentColorPicker = openAccentColorPicker
        self.openBubbleColorPicker = openBubbleColorPicker
    }
}

private enum TelewhiteModsSection: Int32 {
    case menu
    case messenger
    case translator
    case translationLanguage
    case privacy
    case stealth
    case channels
    case media
    case appearance
    case chatText
    case chatListLook
    case settingsIcons
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
    // Telewhite: "Translate Into" used to be a row that displayed a language code and
    // did nothing when tapped, so the target could never be changed from ru.
    case translationLanguage
    // Telewhite: chat text sizing. Colours and bubble shape used to live here too, but
    // they duplicated the stock Appearance screen, so they were dropped.
    case chatText
    // Telewhite: density and line count share a screen because both answer the same
    // question — how much of the chat list fits — and are judged together.
    case chatListLook
    case settingsIcons
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
    case backgroundMessageRefresh(String, Bool)
    case keepTimedMessages(String, Bool)
    case forwardHideNamesByDefault(String, Bool)
    case showPreviousEditedText(String, Bool)
    // Telewhite: one row for both halves of the view-once feature — opening without a
    // limit and saving were two switches for what users think of as one thing.
    case oneTimeMedia(String, Bool)
    case hdPhotos(String, Bool)
    case quickForwardToSaved(String, Bool)
    case localTranscription(String, Bool)
    case hideSponsoredContent(String, Bool)
    case showReadDateOnTap(String, Bool)
    case translatorLink(String)
    case messengerInfo(String)

    case translatorHeader(String)
    case translateMessages(String, Bool)
    case autoTranslateEnglish(String, Bool)
    case translationTargetLanguage(String, String)
    case outgoingTranslateButtonEnabled(String, Bool)
    case outgoingTranslateInPrivate(String, Bool)
    case outgoingTranslateInGroups(String, Bool)
    case outgoingTranslateInBots(String, Bool)
    case translateVoiceMessages(String, Bool)
    case translateButtonInChat(String, Bool)
    case translatorInfo(String)

    case translationLanguageHeader(String)
    case translationLanguageOption(Int32, String, String, Bool)

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
    case speedBoostEnabled(String, Bool)
    case speedBoostLevel(Int32, String, Int32, Bool)
    case longRoundVideos(String, Bool)
    case confirmVoiceSend(String, Bool)
    case mediaInfo(String)

    case appearanceHeader(String)
    case accentColorLink(String, UIColor)
    case bubbleColorLink(String, UIColor)
    // Telewhite: one row each, showing the current value on the right and stepping to the
    // next on tap. A checkbox per value was eleven rows for three settings and buried
    // everything else on the screen; a sub-screen per setting would have hidden them a tap
    // deep instead. Payload is (title, current value label).
    case chatListLookLink(String, String)
    case settingsIconsLink(String, String)
    case chatTextLink(String)

    // Rows of the two screens those links open.
    case chatListDensityHeader(String)
    case chatListDensity(Int32, String, Int32, Bool)
    case chatListDensityInfo(String)
    case chatListRowsHeader(String)
    case chatListRows(Int32, String, Int32, Bool)
    case chatListRowsInfo(String)
    case settingsIconsHeader(String)
    case settingsIconVariant(Int32, String, Int32, Bool)
    case settingsIconsInfo(String)
    case chatSplitLandscape(String, Bool)
    case amoledMode(String, Bool)
    case chatTextHeader(String)
    case chatFontSizeOption(Int32, String, Int32, Bool)
    case chatTextInfo(String)
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
        case .messengerHeader, .preserveDeletedMessages, .backgroundMessageRefresh, .keepTimedMessages, .forwardHideNamesByDefault, .showPreviousEditedText, .oneTimeMedia, .hdPhotos, .quickForwardToSaved, .showReadDateOnTap, .translatorLink, .messengerInfo:
            return TelewhiteModsSection.messenger.rawValue
        case .translatorHeader, .translateMessages, .autoTranslateEnglish, .translationTargetLanguage, .outgoingTranslateButtonEnabled, .outgoingTranslateInPrivate, .outgoingTranslateInGroups, .outgoingTranslateInBots, .localTranscription, .translateVoiceMessages, .translateButtonInChat, .translatorInfo:
            return TelewhiteModsSection.translator.rawValue
        case .translationLanguageHeader, .translationLanguageOption:
            return TelewhiteModsSection.translationLanguage.rawValue
        case .privacyHeader, .protectionBypass, .hidePhoneInSettings, .showProfileIds, .privacyInfo:
            return TelewhiteModsSection.privacy.rawValue
        case .stealthHeader, .ghost, .ghostChatButtonEnabled, .stealthInfo:
            return TelewhiteModsSection.stealth.rawValue
        case .channelsHeader, .channelsDeclutter, .hideSponsoredContent, .channelsInfo:
            return TelewhiteModsSection.channels.rawValue
        case .mediaHeader, .downloadStories, .hideStories, .autoCacheCleanup, .cacheLimit, .speedBoostEnabled, .speedBoostLevel, .longRoundVideos, .confirmVoiceSend, .mediaInfo:
            return TelewhiteModsSection.media.rawValue
        case .appearanceHeader, .accentColorLink, .bubbleColorLink, .chatListLookLink, .chatSplitLandscape, .amoledMode, .settingsIconsLink, .chatTextLink, .appearanceInfo:
            return TelewhiteModsSection.appearance.rawValue
        case .chatTextHeader, .chatFontSizeOption, .chatTextInfo:
            return TelewhiteModsSection.chatText.rawValue
        case .chatListDensityHeader, .chatListDensity, .chatListDensityInfo, .chatListRowsHeader, .chatListRows, .chatListRowsInfo:
            return TelewhiteModsSection.chatListLook.rawValue
        case .settingsIconsHeader, .settingsIconVariant, .settingsIconsInfo:
            return TelewhiteModsSection.settingsIcons.rawValue
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
        case .backgroundMessageRefresh:
            return 2
        case .keepTimedMessages:
            return 3
        case .showPreviousEditedText:
            return 4
        case .forwardHideNamesByDefault:
            return 5
        case .oneTimeMedia:
            return 6
        case .hdPhotos:
            return 7
        case .quickForwardToSaved:
            return 8
        case .showReadDateOnTap:
            return 9
        case .translatorLink:
            return 10
        case .messengerInfo:
            return 11
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
        case .outgoingTranslateInPrivate:
            return 55
        case .outgoingTranslateInGroups:
            return 56
        case .outgoingTranslateInBots:
            return 57
        case .localTranscription:
            return 70
        case .translateVoiceMessages:
            return 71
        case .translateButtonInChat:
            return 72
        case .translatorInfo:
            return 80
        case .translationLanguageHeader:
            return 60
        case let .translationLanguageOption(index, _, _, _):
            return 61 + index
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
        case .hideSponsoredContent:
            return 402
        case .channelsInfo:
            return 403
        case .mediaHeader:
            return 500
        case .downloadStories:
            return 501
        case .hideStories:
            return 502
        case .autoCacheCleanup:
            return 503
        case let .cacheLimit(index, _, _, _):
            return 504 + index
        case .speedBoostEnabled:
            return 510
        case let .speedBoostLevel(index, _, _, _):
            return 511 + index
        case .longRoundVideos:
            return 520
        case .confirmVoiceSend:
            return 521
        // Telewhite: stableId must rise in the order rows are appended — ItemListUI
        // asserts it (ItemListControllerNode.swift:449) and its row diff assumes it.
        // The trailing info row therefore sits at the end of the media block, not at 502.
        case .mediaInfo:
            return 599
        case .appearanceHeader:
            return 700
        case .accentColorLink:
            return 701
        case .bubbleColorLink:
            return 702
        case .chatListLookLink:
            return 703
        case .chatSplitLandscape:
            return 710
        case .amoledMode:
            return 711
        case .settingsIconsLink:
            return 712
        case .chatTextLink:
            return 720
        case .appearanceInfo:
            return 790
        // The chat text screen is its own section, so its ids only have to rise among
        // themselves — they sit above the appearance block to keep the ranges readable.
        case .chatTextHeader:
            return 900
        case let .chatFontSizeOption(index, _, _, _):
            return 901 + index
        case .chatTextInfo:
            return 950
        // The two look screens are their own sections, so their ids only have to rise
        // among themselves.
        case .chatListDensityHeader:
            return 1000
        case let .chatListDensity(index, _, _, _):
            return 1001 + index
        case .chatListDensityInfo:
            return 1009
        case .chatListRowsHeader:
            return 1010
        case let .chatListRows(index, _, _, _):
            return 1011 + index
        case .chatListRowsInfo:
            return 1019
        case .settingsIconsHeader:
            return 1100
        case let .settingsIconVariant(index, _, _, _):
            return 1101 + index
        case .settingsIconsInfo:
            return 1109
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
        case let .messengerHeader(text), let .translatorHeader(text), let .translationLanguageHeader(text), let .privacyHeader(text), let .stealthHeader(text), let .channelsHeader(text), let .mediaHeader(text), let .appearanceHeader(text), let .developerHeader(text), let .chatTextHeader(text), let .chatListDensityHeader(text), let .chatListRowsHeader(text), let .settingsIconsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .translationLanguageOption(_, title, code, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.translationTargetLanguage = code
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
            // The disclosure item never asks for telewhiteEntryDescription the way
            // switchItem does, so the explanation has to be handed to it as the label —
            // same shape as .menuItem above.
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: telewhiteEntryDescription(self, presentationData: presentationData) ?? "", labelStyle: .multilineDetailText, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.translator)
            })
        case let .preserveDeletedMessages(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.preserveDeletedMessages = value
            }
        case let .keepTimedMessages(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.keepTimedMessages = value
            }
        case let .backgroundMessageRefresh(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.backgroundMessageRefresh = value
            }
        case let .forwardHideNamesByDefault(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.forwardHideNamesByDefault = value
            }
        case let .showPreviousEditedText(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showPreviousEditedText = value
            }
        case let .showReadDateOnTap(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showReadDateOnTap = value
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
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: telewhiteLanguageDisplayName(value), labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.translationLanguage)
            })
        case let .outgoingTranslateInPrivate(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.outgoingTranslateInPrivate = value
            }
        case let .outgoingTranslateInGroups(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.outgoingTranslateInGroups = value
            }
        case let .outgoingTranslateInBots(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.outgoingTranslateInBots = value
            }
        case let .outgoingTranslateButtonEnabled(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.outgoingTranslateButtonEnabled = value
            }
        case let .hdPhotos(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hdPhotos = value
            }
        case let .translateButtonInChat(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.translateButtonInChat = value
            }
        case let .translateVoiceMessages(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.translateVoiceMessages = value
            }
        case let .quickForwardToSaved(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.quickForwardToSaved = value
            }
        case let .localTranscription(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.localTranscription = value
            }
        case let .hideSponsoredContent(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideSponsoredContent = value
            }
        case let .debugMenu(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openDebug()
            })
        case let .messengerInfo(text), let .translatorInfo(text), let .privacyInfo(text), let .stealthInfo(text), let .channelsInfo(text), let .mediaInfo(text), let .developerInfo(text), let .appearanceInfo(text), let .chatTextInfo(text), let .chatListDensityInfo(text), let .chatListRowsInfo(text), let .settingsIconsInfo(text):
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
        case let .accentColorLink(text, color):
            // Telewhite: the swatch shows the color that is actually applied, not a
            // static placeholder, so this row can be read at a glance.
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", labelStyle: .color(color), sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openAccentColorPicker()
            })
        case let .bubbleColorLink(text, color):
            // Telewhite: the swatch mirrors the outgoing bubble currently in use, so the
            // row reads as "this is your color" rather than a generic link.
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", labelStyle: .color(color), sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openBubbleColorPicker()
            })
        case let .chatTextLink(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.chatText)
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
        case let .confirmVoiceSend(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.confirmVoiceSend = value
            }
        case let .longRoundVideos(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.longRoundVideos = value
            }
        case let .speedBoostEnabled(text, value):
            // Switching back on lands on the moderate level rather than whichever one was
            // last picked: the higher level is the one worth choosing deliberately.
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.speedBoost = value ? 1 : 0
            }
        case let .speedBoostLevel(_, text, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: text, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.speedBoost = value
                    return updated
                }
            })
        case let .hideStories(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideStories = value
            }
        case let .chatListLookLink(text, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: label, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.chatListLook)
            })
        case let .settingsIconsLink(text, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: label, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(.settingsIcons)
            })
        case let .chatListDensity(_, text, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: text, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.chatListDensity = value
                    return updated
                }
            })
        case let .chatSplitLandscape(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.chatSplitLandscape = value
            }
        case let .amoledMode(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.amoledMode = value
            }
        case let .chatListRows(_, text, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: text, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.chatListRows = value
                    return updated
                }
            })
        case let .settingsIconVariant(_, text, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: text, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.settingsIconVariant = value
                    return updated
                }
            })
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

// Accepts what someone would actually type: with or without "#" or "0x", and the
// three-digit shorthand. Returns nil rather than a fallback colour so a typo leaves the
// current colour alone instead of silently repainting the app.
private func telewhiteParseHexColor(_ input: String) -> Int64? {
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

// Telewhite: one entry point for both colour rows. iOS 15 and up get the system picker
// (wheel, sliders, HEX field, eyedropper); 13 and 14 have no such picker, so they fall
// back to typing a HEX code rather than the row doing nothing at all.
private func telewhitePickColor(context: AccountContext, title: String, initialColor: Int64?, present: (ViewController) -> Void, apply: @escaping (Int64) -> Void) {
    if #available(iOS 15.0, *) {
        TelewhiteColorPickerPresenter.present(context: context, title: title, initialColor: initialColor, apply: apply)
        return
    }
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let strings = TelewhiteModsStrings(presentationData: presentationData)
    let initialText = initialColor.flatMap { String(format: "#%06X", UInt32(truncatingIfNeeded: $0) & 0xffffff) } ?? ""
    let prompt = promptController(context: context, text: title,
        subtitle: strings.text("Enter a HEX code, e.g. #1E90FF", "Введите HEX-код, например #1E90FF"),
        value: initialText, placeholder: "#RRGGBB", characterLimit: 9,
        apply: { value in
            guard let value = value, let parsed = telewhiteParseHexColor(value) else {
                return
            }
            apply(parsed)
        }
    )
    present(prompt)
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
    case .translationLanguage:
        return strings.text("Translate Into", "Переводить на")
    case .chatText:
        return strings.text("Chat Text", "Текст в чате")
    case .chatListLook:
        return strings.text("Chat List", "Список чатов")
    case .settingsIcons:
        return strings.text("Settings Icons", "Иконки настроек")
    }
}

// One name per value, used both for the option row on the screen and for the summary on
// the row that opens it, so the two can never drift apart.
private func telewhiteDensityName(_ value: Int32, strings: TelewhiteModsStrings) -> String {
    switch value {
    case 1:
        return strings.text("Snug", "плотнее")
    case 2:
        return strings.text("Tight", "плотно")
    case 3:
        return strings.text("Tightest", "очень плотно")
    default:
        return strings.text("Roomy", "просторно")
    }
}

private func telewhiteRowsName(_ value: Int32, strings: TelewhiteModsStrings) -> String {
    switch value {
    case 1:
        return strings.text("One Line", "одна строка")
    case 3:
        return strings.text("Three Lines", "три строки")
    default:
        return strings.text("Two Lines", "две строки")
    }
}

private func telewhiteIconVariantName(_ value: Int32, strings: TelewhiteModsStrings) -> String {
    switch value {
    case 1:
        return strings.text("Outlined", "контурные")
    case 2:
        return strings.text("Thin, Gray", "тонкие серые")
    case 3:
        return strings.text("In a Ring", "в кольце")
    default:
        return strings.text("Solid", "заливкой")
    }
}

// The language's own name for itself ("Русский", "Deutsch") — a language list that
// names languages in a language the reader may not know is no use to them.
private func telewhiteLanguageDisplayName(_ code: String) -> String {
    // Look the name up by the base code: "pt-BR" has no localized name of its own,
    // "pt" does.
    let base = normalizeTranslationLanguage(code)
    let locale = Locale(identifier: base)
    if let name = locale.localizedString(forLanguageCode: base), !name.isEmpty {
        return name.capitalized
    }
    return code.uppercased()
}

private func telewhiteMenuEntries(strings: TelewhiteModsStrings) -> [TelewhiteModsEntry] {
    return [
        .menuItem(0, .privacy, telewhiteTabTitle(.privacy, strings: strings), strings.text("Saving restrictions, your number, numeric IDs.", "Запреты на сохранение, ваш номер, числовые ID."), .privacy),
        .menuItem(1, .ghost, telewhiteTabTitle(.stealth, strings: strings), strings.text("Read messages and watch stories without being seen.", "Читать сообщения и смотреть истории незаметно."), .stealth),
        .menuItem(2, .messages, telewhiteTabTitle(.messenger, strings: strings), strings.text("Deleted messages, view-once media, forwarding, translation.", "Удалённые сообщения, одноразовые медиа, пересылка, перевод."), .messenger),
        .menuItem(3, .groups, telewhiteTabTitle(.channels, strings: strings), strings.text("What is shown under channel posts.", "Что показывать под постами каналов."), .channels),
        .menuItem(4, .media, telewhiteTabTitle(.media, strings: strings), strings.text("Stories and space taken up on the phone.", "Истории и место, занятое на телефоне."), .media),
        .menuItem(5, .appearance, telewhiteTabTitle(.appearance, strings: strings), strings.text("Chat text, chat list, landscape mode.", "Текст в чате, список чатов, горизонтальный режим."), .appearance),
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
    case .backgroundMessageRefresh:
        return text("While the app is closed, the phone quietly picks up new messages on its own, so a message that arrives and is deleted before you ever look at it is still kept. iOS decides how often this happens — there is no fixed schedule and no guarantee, and only the account you are currently using is refreshed.", "Пока приложение закрыто, телефон сам время от времени забирает новые сообщения — тогда удалённое сохранится, даже если вы не успели его увидеть. Как часто это происходит, решает iOS: расписания нет и полной гарантии тоже. Обновляется только тот аккаунт, в котором вы сейчас находитесь.")
    case .keepTimedMessages:
        return text("In chats with a self-destruct timer, messages stay instead of disappearing when the time runs out. Only on this phone — for everyone else they still disappear. Secret chats are not affected.", "В чатах с таймером удаления сообщения останутся, а не исчезнут по истечении времени. Только на этом телефоне — у остальных они всё равно исчезнут. На секретные чаты не влияет.")
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
    case .showReadDateOnTap:
        return text("Tap the checkmarks under your message to see when it was read. Works in private chats. Nothing is shown if the other person hides their read times, or if you hide yours.", "Нажмите на галочки под своим сообщением, чтобы увидеть, когда его прочитали. Работает в личных чатах. Время не покажется, если собеседник скрыл время прочтения или если вы скрыли своё.")
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
    case .localTranscription:
        return text("Turns voice messages into text without Premium. The phone does the recognition itself, so the audio is not sent anywhere and it works offline. The first time, iOS asks for permission.", "Превращает голосовые в текст без Premium. Распознаёт сам телефон, поэтому звук никуда не отправляется и работает без интернета. При первом включении iOS спросит разрешение.")
    case .translateButtonInChat:
        return text("Puts a small round button beside every incoming message. Tap it and the translation appears inside the bubble; tap again for the original. The stored message is not changed, so copying and forwarding still give the original text.", "Ставит маленькую круглую кнопку рядом с каждым входящим сообщением. Нажали — перевод появляется прямо в пузыре, нажали снова — вернулся оригинал. Само сообщение не меняется, поэтому копирование и пересылка по-прежнему дают исходный текст.")
    case .translateVoiceMessages:
        return text("Voice messages in other languages get a translation under the transcript.", "Под расшифровкой голосового на чужом языке появляется перевод.")
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
    case .hideSponsoredContent:
        return text("Removes sponsored posts inside channels and promoted chats from search results. They are never requested, so they do not load at all.", "Убирает рекламные посты внутри каналов и продвигаемые чаты из результатов поиска. Реклама не запрашивается вообще, поэтому и не загружается.")
    case .downloadStories:
        return text("Adds a save button to other people's stories.", "Добавляет кнопку сохранения в чужих историях.")
    case .hideStories:
        return text("Removes the row of stories above the chat list.", "Убирает ленту историй над списком чатов.")
    case .confirmVoiceSend:
        return text("Asks before a recorded voice message or round video is sent. Recording is press-and-hold, so letting go in the wrong place sends it — this puts a question in the way.", "Спрашивает перед отправкой записанного голосового или кружка. Запись идёт удержанием пальца, поэтому отпустил не там — уже улетело; здесь на пути встаёт вопрос.")
    case .longRoundVideos:
        return text("Round videos stop at a minute in stock Telegram. This raises the recorder limit to five. That minute is the app's own, not the server's, so a longer one may still be refused on upload — if that happens, switch this back off.", "В обычном Telegram кружок останавливается на минуте. Здесь предел записи поднимается до пяти. Эта минута — ограничение приложения, а не сервера, поэтому длинный кружок всё же может не приняться при отправке. Если так — просто выключите обратно.")
    case .autoCacheCleanup:
        return text("When downloaded photos and videos take up more than the limit, the oldest ones are deleted. Nothing is lost — anything you open again is downloaded from Telegram.", "Когда скачанные фото и видео займут больше лимита, самые старые удаляются. Ничего не теряется — при открытии всё снова скачается из Telegram.")
    case .speedBoostEnabled:
        return text("Downloads and uploads media in more pieces at a time. Helps most on a fast connection; on a weak one it can make things slower.", "Качает и отправляет медиа большим числом кусков сразу. Сильнее всего помогает на быстром соединении; на слабом может, наоборот, замедлить.")
    case .chatSplitLandscape:
        return text("Turn the phone sideways and the chat list stays next to the open chat, like on a computer.", "Поверните телефон горизонтально — список чатов останется рядом с открытым чатом, как на компьютере.")
    case .amoledMode:
        return text("Makes the dark theme pure black. On OLED screens black pixels are switched off, so it also saves battery.", "Делает тёмную тему полностью чёрной. На OLED-экранах чёрные пиксели не светятся, поэтому расходуется меньше заряда.")
    default:
        return nil
    }
}

private func telewhiteModsEntries(tab: TelewhiteModsTab, settings: TelewhiteModsSettings, translationSettings: TranslationSettings, strings: TelewhiteModsStrings, accentColor: UIColor, bubbleColor: UIColor) -> [TelewhiteModsEntry] {
    var entries: [TelewhiteModsEntry] = []

    switch tab {
    case .messenger:
        entries.append(.messengerHeader(telewhiteTabTitle(.messenger, strings: strings)))
        entries.append(.preserveDeletedMessages(strings.text("Keep Deleted Messages", "Не терять удалённые сообщения"), settings.preserveDeletedMessages))
        // Only shown under Keep Deleted Messages, because on its own it does nothing a user
        // would notice — and it is the answer to "why did it not save that one?".
        if settings.preserveDeletedMessages {
            entries.append(.backgroundMessageRefresh(strings.text("Fetch Messages in the Background", "Забирать сообщения в фоне"), settings.backgroundMessageRefresh))
        }
        entries.append(.keepTimedMessages(strings.text("Timed Messages Do Not Disappear", "Сообщения с таймером не исчезают"), settings.keepTimedMessages))
        entries.append(.showPreviousEditedText(strings.text("Show the Text Before an Edit", "Показывать текст до правки"), settings.showPreviousEditedText))
        entries.append(.forwardHideNamesByDefault(strings.text("Forward Without the Author", "Пересылать без автора"), settings.forwardHideNamesByDefault))
        // Rows that write several fields at once read them with OR. Each of these was two
        // or three separate switches in an older build, so a half-on state is something
        // users actually have — and with AND the row showed OFF while the behaviour was
        // still on, which is both a lie and impossible to undo in one tap.
        entries.append(.oneTimeMedia(strings.text("View-Once Photos and Videos", "Одноразовые фото и видео"), settings.oneTimeMediaUnlimited || settings.downloadOneTimeMedia))
        entries.append(.hdPhotos(strings.text("Send Photos in Original Quality", "Отправлять фото в оригинальном качестве"), settings.hdPhotos))
        entries.append(.quickForwardToSaved(strings.text("\"To Saved Messages\" Button", "Кнопка «В Избранное»"), settings.quickForwardToSaved))
        entries.append(.showReadDateOnTap(strings.text("Read Time on the Checkmarks", "Время прочтения по галочкам"), settings.showReadDateOnTap))
        entries.append(.translatorLink(telewhiteTabTitle(.translator, strings: strings)))
        entries.append(.messengerInfo(strings.text("Everything here works on this phone only.", "Всё перечисленное работает только на этом телефоне.")))

    case .translator:
        entries.append(.translatorHeader(telewhiteTabTitle(.translator, strings: strings)))
        // Also OR: this row absorbed the stock "Translate Entire Chats" switch, whose
        // setting defaults to true and is still written from Settings → Language. Reading
        // only our own flag showed OFF while the translation panel kept appearing.
        entries.append(.autoTranslateEnglish(strings.text("Translate Incoming Messages", "Переводить входящие"), settings.autoTranslateEnglish || translationSettings.translateChats))
        entries.append(.translationTargetLanguage(strings.text("Translate Into", "Переводить на"), settings.translationTargetLanguage))
        entries.append(.translateMessages(strings.text("\"Translate\" in the Message Menu", "«Перевести» в меню сообщения"), translationSettings.showTranslate))
        entries.append(.outgoingTranslateButtonEnabled(strings.text("Translate What You Send", "Переводить то, что вы пишете"), settings.outgoingTranslateButtonEnabled))
        if settings.outgoingTranslateButtonEnabled {
            entries.append(.outgoingTranslateInPrivate(strings.text("    In Private Chats", "    В личных чатах"), settings.outgoingTranslateInPrivate))
            entries.append(.outgoingTranslateInGroups(strings.text("    In Groups and Channels", "    В группах и каналах"), settings.outgoingTranslateInGroups))
            entries.append(.outgoingTranslateInBots(strings.text("    In Bots", "    В ботах"), settings.outgoingTranslateInBots))
        }
        entries.append(.localTranscription(strings.text("Voice to Text Without Premium", "Расшифровка голосовых без Premium"), settings.localTranscription))
        entries.append(.translateVoiceMessages(strings.text("Translate Voice Messages", "Переводить голосовые"), settings.translateVoiceMessages))
        entries.append(.translateButtonInChat(strings.text("Translate Button on Messages", "Кнопка перевода у сообщений"), settings.translateButtonInChat))
        entries.append(.translatorInfo(strings.text("Translation is free and needs no account. Messages already in your language are never translated.", "Перевод бесплатный и не требует аккаунта. Сообщения, уже написанные на вашем языке, не переводятся.")))

    case .translationLanguage:
        entries.append(.translationLanguageHeader(telewhiteTabTitle(.translationLanguage, strings: strings)))
        // Only the popular set (12 codes), not every supported language: the whole
        // point of this screen is one tap, and stableId 61 + index has to stay clear
        // of the privacy block at 100.
        let current = normalizeTranslationLanguage(settings.translationTargetLanguage)
        for (index, code) in popularTranslationLanguages.enumerated() {
            entries.append(.translationLanguageOption(Int32(index), telewhiteLanguageDisplayName(code), code, normalizeTranslationLanguage(code) == current))
        }

    case .privacy:
        entries.append(.privacyHeader(telewhiteTabTitle(.privacy, strings: strings)))
        entries.append(.protectionBypass(strings.text("Allow Saving Everywhere", "Разрешить сохранять везде"), settings.screenshotProtectionBypass || settings.contentRestrictionBypass))
        entries.append(.hidePhoneInSettings(strings.text("Hide My Number and Username", "Скрыть свой номер и юзернейм"), settings.hidePhoneInSettings))
        entries.append(.showProfileIds(strings.text("Show Numeric IDs", "Показывать числовые ID"), settings.showUserIds || settings.showChatIds || settings.showMessageIds))
        entries.append(.privacyInfo(strings.text("These switches change what this phone shows and allows. They do not change your Telegram privacy settings.", "Эти переключатели меняют то, что показывает и разрешает этот телефон. Настройки приватности в самом Telegram они не трогают.")))

    case .stealth:
        entries.append(.stealthHeader(telewhiteTabTitle(.stealth, strings: strings)))
        // Read with OR, not AND: the row writes all five flags at once, so a half-on
        // state can only come from an older build. Showing OFF while the engine still
        // treats the user as invisible is exactly the trap this row exists to undo —
        // ghostMode alone already suppresses the online presence.
        entries.append(.ghost(strings.text("Invisible Mode", "Невидимка"), settings.ghostMode || settings.hideOnlineStatus || settings.hideTypingStatus || settings.hideReadReceipts || settings.ghostStories))
        entries.append(.ghostChatButtonEnabled(strings.text("Ghost Button in Chats", "Кнопка невидимки в чате"), settings.ghostChatButtonEnabled))
        entries.append(.stealthInfo(strings.text("While you are invisible, Telegram will not show other people's read receipts to you either.", "Пока вы невидимы, Telegram и вам не показывает чужие отметки о прочтении.")))

    case .channels:
        entries.append(.channelsHeader(telewhiteTabTitle(.channels, strings: strings)))
        entries.append(.channelsDeclutter(strings.text("Clean Up Posts", "Убрать лишнее под постами"), settings.channelHideReactions || settings.channelHideComments || settings.channelHideShareButton))
        entries.append(.hideSponsoredContent(strings.text("Hide Ads", "Скрыть рекламу"), settings.hideSponsoredContent))
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
        entries.append(.speedBoostEnabled(strings.text("Speed Boost", "Ускорить загрузку"), settings.speedBoost > 0))
        if settings.speedBoost > 0 {
            for (index, level) in [Int32(1), 2].enumerated() {
                let title = level == 1
                    ? strings.text("Moderate", "Умеренно")
                    : strings.text("Maximum", "Максимально")
                entries.append(.speedBoostLevel(Int32(index), title, level, settings.speedBoost == level))
            }
        }
        entries.append(.longRoundVideos(strings.text("Longer Round Videos", "Длинные кружки"), settings.longRoundVideos))
        entries.append(.confirmVoiceSend(strings.text("Confirm Voice and Round Videos", "Спрашивать перед голосовым и кружком"), settings.confirmVoiceSend))
        entries.append(.mediaInfo(strings.text("Your messages and files in the cloud are never deleted — only the copies downloaded to this phone. Speed Boost asks the server for more pieces at once; on a weak network that can backfire, so lower it if transfers get worse.", "Ваши сообщения и файлы в облаке не удаляются — стираются только копии, скачанные на этот телефон. Ускорение запрашивает у сервера больше кусков сразу; на слабой сети это может выйти боком — тогда снизьте уровень или выключите.")))

    case .appearance:
        entries.append(.appearanceHeader(telewhiteTabTitle(.appearance, strings: strings)))
        // Telewhite: opens the iOS colour picker — wheel, sliders, HEX field, eyedropper —
        // so the accent is mixed by hand rather than chosen from a fixed set.
        entries.append(.accentColorLink(strings.text("Accent Color", "Акцентный цвет"), accentColor))
        // Telewhite: no preset swatches — tapping opens the same picker and you mix your
        // own outgoing bubble colour there.
        entries.append(.bubbleColorLink(strings.text("Outgoing Bubble Color", "Цвет исходящих сообщений"), bubbleColor))
        // Telewhite: density and line count share one screen; the row summarises both, so
        // the current look is readable without opening it.
        entries.append(.chatListLookLink(strings.text("Chat List", "Список чатов"), "\(telewhiteDensityName(settings.chatListDensity, strings: strings)), \(telewhiteRowsName(settings.chatListRows, strings: strings))"))
        entries.append(.chatSplitLandscape(strings.text("Split View in Landscape", "Сплит чатов (альбомная)"), settings.chatSplitLandscape))
        entries.append(.amoledMode(strings.text("AMOLED Mode", "AMOLED режим"), settings.amoledMode))
        entries.append(.settingsIconsLink(strings.text("Settings Icons", "Иконки настроек"), telewhiteIconVariantName(settings.settingsIconVariant, strings: strings)))
        entries.append(.chatTextLink(strings.text("Chat Text", "Текст в чате")))
        entries.append(.appearanceInfo(strings.text("Tap a colour row to mix your own shade — colour wheel, sliders, HEX or the eyedropper. AMOLED mode deepens the background to true black.", "Нажмите на строку цвета и подберите свой оттенок — колесо, ползунки, HEX или пипетка. AMOLED-режим делает фон полностью чёрным.")))

    case .chatListLook:
        entries.append(.chatListDensityHeader(strings.text("Density", "Плотность")))
        for (index, density) in [Int32(0), 1, 2, 3].enumerated() {
            entries.append(.chatListDensity(Int32(index), telewhiteDensityName(density, strings: strings), density, settings.chatListDensity == density))
        }
        entries.append(.chatListDensityInfo(strings.text("Shrinks the avatar and tightens the row, so more chats fit on the screen. The text column follows the avatar, so the row gets narrower as well as shorter. \"Roomy\" is stock Telegram.", "Уменьшает аватарку и поджимает строку — на экране помещается больше чатов. Текст сдвигается вслед за аватаркой, поэтому строка становится не только ниже, но и уже. «Просторно» — как в обычном Telegram.")))
        entries.append(.chatListRowsHeader(strings.text("Lines Under the Name", "Строк под именем")))
        for (index, rows) in [Int32(1), 2, 3].enumerated() {
            entries.append(.chatListRows(Int32(index), telewhiteRowsName(rows, strings: strings), rows, settings.chatListRows == rows))
        }
        entries.append(.chatListRowsInfo(strings.text("How much of the last message you see. In groups one line goes to the sender's name, so those rows show one line of text fewer. Two lines is stock Telegram.", "Сколько видно от последнего сообщения. В группах одна строка уходит под имя отправителя, поэтому там текста на строку меньше. Две строки — как в обычном Telegram.")))

    case .settingsIcons:
        entries.append(.settingsIconsHeader(strings.text("Style", "Стиль")))
        for (index, variant) in [Int32(0), 1, 2, 3].enumerated() {
            entries.append(.settingsIconVariant(Int32(index), telewhiteIconVariantName(variant, strings: strings), variant, settings.settingsIconVariant == variant))
        }
        entries.append(.settingsIconsInfo(strings.text("Changes every icon in Settings at once. \"Solid\" and \"Outlined\" follow the accent colour; \"Thin, Gray\" is the quietest and drops the colour; \"In a Ring\" draws a hairline circle around a smaller glyph. The change shows up straight away, no restart.", "Меняет сразу все значки в настройках. «Заливкой» и «Контурные» следуют акцентному цвету, «Тонкие серые» — самый спокойный вариант без цвета, «В кольце» рисует тонкую окружность вокруг уменьшенного значка. Результат виден сразу, перезапуск не нужен.")))

    case .chatText:
        entries.append(.chatTextHeader(strings.text("Chat Text", "Текст в чате")))
        entries.append(.chatFontSizeOption(0, strings.text("Default", "По умолчанию"), 0, settings.chatFontSizeOverride == 0))
        entries.append(.chatFontSizeOption(1, strings.text("Small", "Меньше"), PresentationFontSize.small.rawValue, settings.chatFontSizeOverride == PresentationFontSize.small.rawValue))
        entries.append(.chatFontSizeOption(2, strings.text("Large", "Больше"), PresentationFontSize.large.rawValue, settings.chatFontSizeOverride == PresentationFontSize.large.rawValue))
        entries.append(.chatTextInfo(strings.text("Applies to message text in chats and updates instantly.", "Применяется к тексту сообщений в чатах и обновляется мгновенно.")))

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
        let updated = stateValue.modify { _ in
            // Mutate the LIVE settings, not this screen's snapshot. The screen stays alive
            // on the Settings tab while chats write the same struct (the per-chat ghost
            // button writes ghostPeerIds, the chat translator writes
            // outgoingTranslationPeerIds/Languages), so flipping any switch here used to
            // save a stale copy over them and silently wipe the per-chat state.
            let updated = f(TelewhiteModsSettings.current)
            updated.save()
            return updated
        }
        // Telewhite: presence is suppressed by the master flag, by the granular online
        // switch, or by a single per-chat ghost — computed the same way the chat header
        // computes it, so saving an unrelated setting cannot put the account back online.
        let keepOnline = !(updated.ghostMode || updated.hideOnlineStatus || !updated.ghostPeerIds.isEmpty)
        context.account.shouldKeepOnlinePresence.set(.single(keepOnline))
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

    let arguments = TelewhiteModsControllerArguments(updateSettings: updateSettings, updateTranslationSettings: { f in
        // The root screen is menu rows only today, so nothing here needs it — but a
        // silent no-op would make any translation row moved to the root stop working
        // without a trace. It costs one line to keep it honest.
        let _ = updateTranslationSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
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
    }, openDebug: {
        if let debugController = context.sharedContext.makeDebugSettingsController(context: context) {
            pushControllerImpl?(debugController)
        }
    }, openAccentColorPicker: {
        // Telewhite: the system picker instead of the stock palette screen, and the value
        // written straight into the theme settings. Routing this through
        // ThemeAccentColorController(.colors(create: false)) looked right but silently did
        // nothing on a builtin theme, which is the default.
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let _ = (context.sharedContext.accountManager.transaction { transaction -> (PresentationThemeReference, PresentationThemeAccentColor?) in
            let settings = transaction.getSharedData(ApplicationSpecificSharedDataKeys.presentationThemeSettings)?.get(PresentationThemeSettings.self) ?? PresentationThemeSettings.defaultSettings
            let autoNightModeTriggered = context.sharedContext.currentPresentationData.with { $0 }.autoNightModeTriggered
            let reference = autoNightModeTriggered ? settings.automaticThemeSwitchSetting.theme : settings.theme
            return (reference, settings.themeSpecificAccentColors[reference.index])
        }
        |> deliverOnMainQueue).start(next: { themeReference, currentColors in
            let initialColor = currentColors?.accentColor.flatMap { Int64($0) } ?? Int64(presentationData.theme.list.itemAccentColor.rgb)
            telewhitePickColor(context: context, title: strings.text("Accent Color", "Акцентный цвет"), initialColor: initialColor, present: { controller in
                presentControllerImpl?(controller)
            }, apply: { value in
                let _ = updatePresentationThemeSettingsInteractively(accountManager: context.sharedContext.accountManager, { current in
                    var themeSpecificAccentColors = current.themeSpecificAccentColors
                    let existing = themeSpecificAccentColors[themeReference.index]
                    // Preserve the bubble colour the other row may have set; only the accent
                    // changes here.
                    themeSpecificAccentColors[themeReference.index] = PresentationThemeAccentColor(index: existing?.index ?? -1, baseColor: existing?.baseColor ?? .custom, accentColor: UInt32(truncatingIfNeeded: value), bubbleColors: existing?.bubbleColors ?? [], wallpaper: existing?.wallpaper)
                    return current.withUpdatedThemeSpecificAccentColors(themeSpecificAccentColors)
                }).start()
            })
        })
    }, openBubbleColorPicker: {
        // Telewhite: the system picker, not the stock Telegram screen. The stock one leads
        // with a palette of ready-made circles, which is exactly what this row is meant to
        // replace: tap, pick your own colour, done.
        //
        // The colour is stored as the theme's own bubbleColors rather than as a separate
        // Telewhite setting. That is the field the theme pipeline already reads
        // (PresentationData.swift: themeSpecificAccentColors -> customBubbleColors ->
        // makePresentationTheme), so the bubble repaints through the normal path with no
        // extra plumbing. Note this cannot go through ThemeAccentColorController's
        // .colors(create: false) mode: for a builtin theme that path ends in
        // `apply = .complete()` and silently saves nothing.
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let _ = (context.sharedContext.accountManager.transaction { transaction -> (PresentationThemeReference, PresentationThemeAccentColor?) in
            let settings = transaction.getSharedData(ApplicationSpecificSharedDataKeys.presentationThemeSettings)?.get(PresentationThemeSettings.self) ?? PresentationThemeSettings.defaultSettings
            let autoNightModeTriggered = context.sharedContext.currentPresentationData.with { $0 }.autoNightModeTriggered
            let reference = autoNightModeTriggered ? settings.automaticThemeSwitchSetting.theme : settings.theme
            return (reference, settings.themeSpecificAccentColors[reference.index])
        }
        |> deliverOnMainQueue).start(next: { themeReference, currentColors in
            // Seed the picker with the bubble currently on screen, so opening it does not
            // jump to an unrelated colour before anything is chosen.
            let initialColor = currentColors?.customBubbleColors.first.flatMap { Int64($0) }
                ?? Int64(presentationData.theme.chat.message.outgoing.bubble.withWallpaper.fill.first?.rgb ?? presentationData.theme.list.itemAccentColor.rgb)
            telewhitePickColor(context: context, title: strings.text("Outgoing Bubble Color", "Цвет исходящих сообщений"), initialColor: initialColor, present: { controller in
                presentControllerImpl?(controller)
            }, apply: { value in
                let _ = updatePresentationThemeSettingsInteractively(accountManager: context.sharedContext.accountManager, { current in
                    var themeSpecificAccentColors = current.themeSpecificAccentColors
                    let existing = themeSpecificAccentColors[themeReference.index]
                    // Keep whatever accent the theme already carries; only the bubble is
                    // being changed here. `index: -1` and `.custom` are what the stock code
                    // uses for a hand-picked colour that belongs to no preset slot.
                    themeSpecificAccentColors[themeReference.index] = PresentationThemeAccentColor(index: existing?.index ?? -1, baseColor: existing?.baseColor ?? .custom, accentColor: existing?.accentColor, bubbleColors: [UInt32(truncatingIfNeeded: value)], wallpaper: existing?.wallpaper)
                    return current.withUpdatedThemeSpecificAccentColors(themeSpecificAccentColors)
                }).start()
            })
        })
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
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteModsEntries(tab: tab, settings: settings, translationSettings: translationSettings, strings: strings, accentColor: presentationData.theme.list.itemAccentColor, bubbleColor: presentationData.theme.chat.message.outgoing.bubble.withWallpaper.fill.first ?? presentationData.theme.list.itemAccentColor), style: .blocks, animateChanges: false)
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
