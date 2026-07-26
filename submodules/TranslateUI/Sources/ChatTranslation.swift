import Foundation
import NaturalLanguage
import SwiftSignalKit
import TelegramCore
import AccountContext
import TelegramUIPreferences

public struct ChatTranslationState: Codable {
    enum CodingKeys: String, CodingKey {
        case baseLang
        case fromLang
        case timestamp
        case toLang
        case isEnabled
        case userDisabledFromLang
    }

    public let baseLang: String
    public let fromLang: String
    public let timestamp: Int32?
    public let toLang: String?
    public let isEnabled: Bool
    // Telewhite: the language the user explicitly tapped "Show Original" for. `isEnabled
    // == false` alone cannot carry this — it also means "auto never turned it on" — so
    // re-detection used to switch auto-translation straight back on and the user's choice
    // expired with the cache, once an hour, forever. Absent in states written by older
    // builds, which is exactly right: nothing was recorded then.
    public let userDisabledFromLang: String?

    public init(
        baseLang: String,
        fromLang: String,
        timestamp: Int32?,
        toLang: String?,
        isEnabled: Bool,
        userDisabledFromLang: String? = nil
    ) {
        self.baseLang = baseLang
        self.fromLang = fromLang
        self.timestamp = timestamp
        self.toLang = toLang
        self.isEnabled = isEnabled
        self.userDisabledFromLang = userDisabledFromLang
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.baseLang = try container.decode(String.self, forKey: .baseLang)
        self.fromLang = try container.decode(String.self, forKey: .fromLang)
        self.timestamp = try container.decodeIfPresent(Int32.self, forKey: .timestamp)
        self.toLang = try container.decodeIfPresent(String.self, forKey: .toLang)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.userDisabledFromLang = try container.decodeIfPresent(String.self, forKey: .userDisabledFromLang)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.baseLang, forKey: .baseLang)
        try container.encode(self.fromLang, forKey: .fromLang)
        try container.encodeIfPresent(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.toLang, forKey: .toLang)
        try container.encode(self.isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(self.userDisabledFromLang, forKey: .userDisabledFromLang)
    }

    public func withToLang(_ toLang: String?) -> ChatTranslationState {
        return ChatTranslationState(
            baseLang: self.baseLang,
            fromLang: self.fromLang,
            timestamp: self.timestamp,
            toLang: toLang,
            isEnabled: self.isEnabled,
            userDisabledFromLang: self.userDisabledFromLang
        )
    }

    public func withIsEnabled(_ isEnabled: Bool) -> ChatTranslationState {
        // Telewhite mod: refresh the timestamp when the user toggles translation,
        // otherwise a stale (>1h) cached state makes the panel disappear right
        // after tapping "Show Original".
        return ChatTranslationState(
            baseLang: self.baseLang,
            fromLang: self.fromLang,
            timestamp: Int32(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970),
            toLang: self.toLang,
            isEnabled: isEnabled,
            // Turning it off is a decision about the language currently detected; turning
            // it on clears the decision.
            userDisabledFromLang: isEnabled ? nil : self.fromLang
        )
    }
}

private func cachedChatTranslationState(engine: TelegramEngine, peerId: EnginePeer.Id, threadId: Int64?) -> Signal<ChatTranslationState?, NoError> {
    let key: EngineDataBuffer
    if let threadId {
        key = EngineDataBuffer(length: 16)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
        key.setInt64(8, value: threadId)
    } else {
        key = EngineDataBuffer(length: 8)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
    }
    
    return engine.data.subscribe(TelegramEngine.EngineData.Item.ItemCache.Item(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key))
    |> map { entry -> ChatTranslationState? in
        return entry?.get(ChatTranslationState.self)
    }
}

private func updateChatTranslationState(engine: TelegramEngine, peerId: EnginePeer.Id, threadId: Int64?, state: ChatTranslationState?) -> Signal<Never, NoError> {
    let key: EngineDataBuffer
    if let threadId {
        key = EngineDataBuffer(length: 16)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
        key.setInt64(8, value: threadId)
    } else {
        key = EngineDataBuffer(length: 8)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
    }
    
    if let state {
        return engine.itemCache.put(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key, item: state)
    } else {
        return engine.itemCache.remove(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key)
    }
}

public func updateChatTranslationStateInteractively(engine: TelegramEngine, peerId: EnginePeer.Id, threadId: Int64?, _ f: @escaping (ChatTranslationState?) -> ChatTranslationState?) -> Signal<Never, NoError> {
    let key: EngineDataBuffer
    if let threadId {
        key = EngineDataBuffer(length: 16)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
        key.setInt64(8, value: threadId)
    } else {
        key = EngineDataBuffer(length: 8)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
    }
    
    return engine.data.get(TelegramEngine.EngineData.Item.ItemCache.Item(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key))
    |> map { entry -> ChatTranslationState? in
        return entry?.get(ChatTranslationState.self)
    }
    |> mapToSignal { current -> Signal<Never, NoError> in
        if let current {
            return updateChatTranslationState(engine: engine, peerId: peerId, threadId: threadId, state: f(current))
        } else {
            return .never()
        }
    }
}


// Telewhite: single source of truth for the incoming-translation mod settings.
// Always read them through these helpers — reading UserDefaults.standard.bool(...)
// directly returns `false` for users who never opened the mods settings screen,
// while TelewhiteModsSettings defaults to `true`, which made translation behave
// differently for different users.
public func telewhiteAutoTranslateEnabled() -> Bool {
    return (UserDefaults.standard.object(forKey: "telewhite.mods.autoTranslateEnglish") as? Bool) ?? true
}

// Telewhite: the target language for incoming translation comes from the "Translation
// Language" setting, never from the app interface language — but only once the user has
// actually chosen one. Defaulting an unset value to "ru" meant an English-interface user
// who never opened the screen had their German chats translated into Russian.
public func telewhiteTranslationTargetLanguage(fallback baseLang: String) -> String {
    if let stored = UserDefaults.standard.string(forKey: "telewhite.mods.translationTargetLanguage"), !stored.isEmpty {
        // Region forms matter to the backend ("pt-BR" is not "pt"), so a stored code that
        // is supported verbatim is returned as it is; only unsupported ones get folded.
        if supportedTranslationLanguages.contains(stored) {
            return stored
        }
        let normalized = normalizeTranslationLanguage(stored.lowercased())
        if supportedTranslationLanguages.contains(normalized) {
            return normalized
        }
    }
    let base = normalizeTranslationLanguage(baseLang)
    if supportedTranslationLanguages.contains(base) {
        return base
    }
    return "ru"
}

// Telewhite: there is deliberately no shared NLLanguageRecognizer in this file any more.
// Chat detection and message detection both run per subscription, several of them at once
// for the same chat and on different queues, and the class accumulates state per instance —
// one shared instance mixed two chats' text together. Each site owns its own.

// Telewhite: a hypothesis for the target language at or above this probability means
// the text may well already be in a language the user reads, so it is left alone.
// Deliberately low: between two Cyrillic languages the recognizer is often confident
// and wrong, and wrongly translating Russian into Russian is far more annoying than
// occasionally leaving a Ukrainian message untranslated.
private let telewhiteTargetLanguageHypothesisFloor: Double = 0.15

// Telewhite: below this probability a detection is treated as no detection at all
// rather than as evidence of a foreign language.
private let telewhiteLanguageConfidenceFloor: Double = 0.45

// Telewhite: and the target hypothesis has to hold at least this share of the top one.
// The absolute floor above says "present"; without this it also said "plausible", which
// made every near neighbour of the target untranslatable — Portuguese text puts "es"
// over 0.15 for a Spanish target, Japanese puts "zh" there for a Chinese one.
private let telewhiteTargetLanguageRelativeFloor: Double = 0.5

// Telewhite: the recognizer cannot reliably tell Russian from Ukrainian, but the two
// alphabets can: these letters exist in one and not the other. This is only ever used
// as a tie-break INSIDE the family below, never as a language detector of its own —
// "ъ" is an everyday Bulgarian letter and "ы"/"э" are everyday Mongolian, Kyrgyz and
// Tatar ones, so letting the alphabet speak first would label those chats Russian and
// (with a Russian target) remove their translation panel entirely.
private let telewhiteRussianOnlyLetters: Set<Character> = ["ы", "ъ", "э"]
private let telewhiteUkrainianOnlyLetters: Set<Character> = ["і", "ї", "є", "ґ"]
private let telewhiteEastSlavicLanguages: Set<String> = ["ru", "uk", "be"]

// Returns "ru" or "uk" when the alphabet settles which one it is, nil when it does not.
// Two letters of one kind and none of the other is the bar: a single "і" in a Russian
// message is a quoted word, a name or a brand — «Слава Україні» inside Russian text
// must not turn the message Ukrainian, or it gets translated into its own language.
private func telewhiteCyrillicAlphabetVerdict(_ text: String) -> String? {
    var russianOnlyCount = 0
    var ukrainianOnlyCount = 0
    for character in text.lowercased() {
        if telewhiteRussianOnlyLetters.contains(character) {
            russianOnlyCount += 1
        } else if telewhiteUkrainianOnlyLetters.contains(character) {
            ukrainianOnlyCount += 1
        }
    }
    if russianOnlyCount >= 2 && ukrainianOnlyCount == 0 {
        return "ru"
    }
    if ukrainianOnlyCount >= 2 && russianOnlyCount == 0 {
        return "uk"
    }
    return nil
}

// Telewhite: decide whether a message should be left untranslated. Translation must
// only trigger on text that is confidently NOT in the target language; anything else
// — target-language text, an unconfident guess, a text too short to judge — is left
// as it is. The previous rule was the opposite way round: it only skipped a message
// when the top hypothesis was the target with >= 0.6 confidence, so Russian text
// mis-read as Ukrainian (or judged with low confidence) was translated into Russian.
private func telewhiteShouldSkipTranslation(_ text: String, toLang: String, recognizer: NLLanguageRecognizer) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 3 else {
        return true
    }
    // normalizeTranslationLanguage, not a hand-rolled split: NLLanguage.norwegian is
    // "nb" while the translator's code is "no", so a raw comparison translates
    // Norwegian into Norwegian.
    let target = normalizeTranslationLanguage(toLang.lowercased())
    // One sample for both signals: the alphabet must not judge text the recognizer
    // never saw, or a stray letter 5000 characters in decides the whole message.
    let sample = String(trimmed.prefix(200))

    // The recognizer is owned by the caller so a batch does not allocate one per
    // message; it accumulates per-instance state, hence the reset before each use.
    recognizer.reset()
    recognizer.processString(sample)
    let hypotheses = recognizer.languageHypotheses(withMaximum: 6)
    let best = hypotheses.max(by: { $0.value < $1.value })

    // Inside East Slavic the recognizer is a coin flip, so the alphabet decides. Outside
    // it — Bulgarian, Serbian, Mongolian, Kazakh — the recognizer is reliable and the
    // alphabet would only mislabel, so it is not consulted at all.
    if let best {
        let bestCode = normalizeTranslationLanguage(best.key.rawValue.lowercased())
        if telewhiteEastSlavicLanguages.contains(bestCode), let alphabetVerdict = telewhiteCyrillicAlphabetVerdict(sample) {
            return alphabetVerdict == target
        }
    }

    var targetProbability: Double = 0.0
    for (language, probability) in hypotheses {
        if normalizeTranslationLanguage(language.rawValue.lowercased()) == target {
            targetProbability = max(targetProbability, probability)
        }
    }
    // The target hypothesis has to be a contender, not merely present. Without the
    // relative test any near neighbour of the target became untranslatable: with a
    // Spanish target, Portuguese text puts "es" above 0.15 every time.
    if targetProbability >= telewhiteTargetLanguageHypothesisFloor, targetProbability >= (best?.value ?? 0.0) * telewhiteTargetLanguageRelativeFloor {
        return true
    }
    guard let best, best.value >= telewhiteLanguageConfidenceFloor else {
        return true
    }
    let detected = normalizeTranslationLanguage(best.key.rawValue.lowercased())
    return detected == target
}

public func translateMessageIds(context: AccountContext, messageIds: [EngineMessage.Id], fromLang: String?, toLang: String) -> Signal<Never, NoError> {
    return context.account.postbox.transaction { transaction -> Signal<Never, NoError> in
        var messageIdsToTranslate: [EngineMessage.Id] = []
        var messageIdsSet = Set<EngineMessage.Id>()
        // One recognizer for the whole batch. This loop runs inside a postbox
        // transaction, so allocating one per message would hold up database access
        // for nothing — and it must not be shared with chat-level detection, which
        // runs on other queues.
        let batchLanguageRecognizer = NLLanguageRecognizer()
        for messageId in messageIds {
            if let message = transaction.getMessage(messageId) {
                if let replyAttribute = message.attributes.first(where: { $0 is ReplyMessageAttribute }) as? ReplyMessageAttribute, let replyMessage = message.associatedMessages[replyAttribute.messageId] {
                    // Telewhite: the quoted message needs the same language check as any
                    // other. Without it a Russian reply inside a Ukrainian chat was pulled
                    // in and "translated" into Russian, which is what the check exists for.
                    if !replyMessage.text.isEmpty, !telewhiteShouldSkipTranslation(replyMessage.text, toLang: toLang, recognizer: batchLanguageRecognizer) {
                        if let translation = replyMessage.attributes.first(where: { $0 is TranslationMessageAttribute }) as? TranslationMessageAttribute, translation.toLang == toLang {
                        } else {
                            if !messageIdsSet.contains(replyMessage.id) {
                                messageIdsToTranslate.append(replyMessage.id)
                                messageIdsSet.insert(replyMessage.id)
                            }
                        }
                    }
                }
                guard message.author?.id != context.account.peerId else {
                    continue
                }
                if let translation = message.attributes.first(where: { $0 is TranslationMessageAttribute }) as? TranslationMessageAttribute, translation.toLang == toLang {
                    continue
                }
                
                if !message.text.isEmpty {
                    // Telewhite: only translate text that is confidently foreign.
                    if telewhiteShouldSkipTranslation(message.text, toLang: toLang, recognizer: batchLanguageRecognizer) {
                        continue
                    }
                    if !messageIdsSet.contains(messageId) {
                        messageIdsToTranslate.append(messageId)
                        messageIdsSet.insert(messageId)
                    }
                } else if let _ = message.media.first(where: { $0 is TelegramMediaPoll }) {
                    if !messageIdsSet.contains(messageId) {
                        messageIdsToTranslate.append(messageId)
                        messageIdsSet.insert(messageId)
                    }
                } else if let audioTranscription = message.attributes.first(where: { $0 is AudioTranscriptionMessageAttribute }) as? AudioTranscriptionMessageAttribute, !audioTranscription.text.isEmpty && !audioTranscription.isPending {
                    // Telewhite: a transcript is text like any other — check it, or a
                    // Russian voice message gets a Russian "translation" underneath it.
                    if telewhiteShouldSkipTranslation(audioTranscription.text, toLang: toLang, recognizer: batchLanguageRecognizer) {
                        continue
                    }
                    if !messageIdsSet.contains(messageId) {
                        messageIdsToTranslate.append(messageId)
                        messageIdsSet.insert(messageId)
                    }
                }
            } else {
                if !messageIdsSet.contains(messageId) {
                    messageIdsToTranslate.append(messageId)
                    messageIdsSet.insert(messageId)
                }
            }
        }
        
        let translationConfiguration = TranslationConfiguration.with(appConfiguration: context.currentAppConfiguration.with { $0 })
        var enableLocalIfPossible = false
        switch translationConfiguration.auto {
        case .system:
            if #available(iOS 18.0, *) {
                enableLocalIfPossible = true
            }
        default:
            break
        }
        return context.engine.messages.translateMessages(messageIds: messageIdsToTranslate, fromLang: fromLang, toLang: toLang, enableLocalIfPossible: enableLocalIfPossible)
        |> `catch` { _ -> Signal<Never, NoError> in
            return .complete()
        }
    } |> switchToLatest
}

public func chatTranslationState(context: AccountContext, peerId: EnginePeer.Id, threadId: Int64?) -> Signal<ChatTranslationState?, NoError> {
    if peerId.id == EnginePeer.Id.Id._internalFromInt64Value(777000) {
        return .single(nil)
    }
    
    guard canTranslateChats(context: context) else {
        return .single(nil)
    }
    
    let loggingEnabled = context.sharedContext.immediateExperimentalUISettings.logLanguageRecognition
    
    if #available(iOS 12.0, *) {
        var baseLang = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode
        let rawSuffix = "-raw"
        if baseLang.hasSuffix(rawSuffix) {
            baseLang = String(baseLang.dropLast(rawSuffix.count))
        }

        return combineLatest(
            context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.translationSettings])
            |> map { sharedData -> TranslationSettings in
                return sharedData.entries[ApplicationSpecificSharedDataKeys.translationSettings]?.get(TranslationSettings.self) ?? TranslationSettings.defaultSettings
            },
            context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.AutoTranslateEnabled(id: peerId))
        )
        |> mapToSignal { settings, autoTranslateEnabled in
            let telewhiteIncomingTranslationEnabled = telewhiteAutoTranslateEnabled()
            if !settings.translateChats && !autoTranslateEnabled && !telewhiteIncomingTranslationEnabled {
                return .single(nil)
            }
            
            var dontTranslateLanguages = Set<String>()
            if let ignoredLanguages = settings.ignoredLanguages {
                dontTranslateLanguages = Set(ignoredLanguages)
            } else {
                dontTranslateLanguages.insert(baseLang)
                for language in systemLanguageCodes() {
                    dontTranslateLanguages.insert(language)
                }
            }
            
            return cachedChatTranslationState(engine: context.engine, peerId: peerId, threadId: threadId)
            |> mapToSignal { cached in
                let currentTime = Int32(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970)
                // Telewhite: unified rule for when a chat is translatable.
                // A chat whose detected language equals the target language
                // (e.g. a Russian chat with a Russian target) must NEVER be
                // translated or show the translation panel — translation only
                // makes sense between two different languages.
                let isDisplayable: (ChatTranslationState) -> Bool = { state in
                    guard !state.fromLang.isEmpty else {
                        return false
                    }
                    if let toLang = state.toLang, state.fromLang == toLang {
                        return false
                    }
                    // Telewhite: never auto-translate a message that is already in
                    // the target language (e.g. Russian when the target is Russian).
                    let targetLanguage = telewhiteTranslationTargetLanguage(fallback: baseLang)
                    if normalizeTranslationLanguage(state.fromLang) == normalizeTranslationLanguage(targetLanguage) {
                        return false
                    }
                    // Telewhite: also respect the ignored-language list even in
                    // auto mode — languages the user reads (Russian, the app
                    // language, system languages) are left untouched.
                    if dontTranslateLanguages.contains(state.fromLang) {
                        return false
                    }
                    if state.isEnabled {
                        return true
                    }
                    if telewhiteIncomingTranslationEnabled {
                        return true
                    }
                    return !dontTranslateLanguages.contains(state.fromLang)
                }
                // Telewhite: a cached entry whose target is not the one currently set is
                // stale no matter how fresh it is. Without this, changing "Translate Into"
                // left every already-visited chat translating into the previous language
                // for up to an hour, with no way to force it. The cost is that a per-chat
                // "Translate to X" override does not survive a change of the global
                // target — the global setting is the authority here by design.
                let cachedTargetIsCurrent: Bool
                if let cachedToLang = cached?.toLang {
                    cachedTargetIsCurrent = normalizeTranslationLanguage(cachedToLang) == normalizeTranslationLanguage(telewhiteTranslationTargetLanguage(fallback: baseLang))
                } else {
                    cachedTargetIsCurrent = false
                }
                if let cached, let timestamp = cached.timestamp, cachedTargetIsCurrent, cached.baseLang == baseLang && currentTime - timestamp < 60 * 60 {
                    if isDisplayable(cached) {
                        return .single(cached)
                    } else {
                        return .single(nil)
                    }
                } else {
                    // Keep showing the last known state while language re-detection
                    // runs, instead of blinking the panel out with nil.
                    var initialState: ChatTranslationState?
                    if let cached, cached.baseLang == baseLang, !cached.fromLang.isEmpty {
                        if isDisplayable(cached) {
                            initialState = cached
                        }
                    }
                    return .single(initialState)
                    |> then(
                        context.account.viewTracker.aroundMessageHistoryViewForLocation(.peer(peerId: peerId, threadId: threadId), index: .upperBound, anchorIndex: .upperBound, count: 32, fixedCombinedReadStates: nil)
                        |> filter { messageHistoryView -> Bool in
                            return messageHistoryView.0.entries.count > 1
                        }
                        |> take(1)
                        |> map { messageHistoryView, _, _ -> ChatTranslationState? in
                            let messages = messageHistoryView.entries.map(\.message)
                            
                            if loggingEnabled {
                                Logger.shared.log("ChatTranslation", "Start language recognizing for \(peerId)")
                            }
                            // Telewhite: always derive the target from the global
                            // "Translation Language" setting instead of the interface
                            // language. On re-detection we intentionally do NOT reuse
                            // cached.toLang: old caches were populated with the
                            // interface language and would keep the wrong target
                            // forever. A manual per-chat "Translate to" choice still
                            // wins while its cache entry is fresh (< 1h, refreshed on
                            // every toggle). Read once — it cannot change mid-loop, and
                            // the sampling loop below asks per hypothesis per message.
                            let targetLanguage = telewhiteTranslationTargetLanguage(fallback: baseLang)
                            let normalizedTargetLanguage = normalizeTranslationLanguage(targetLanguage)
                            // A recognizer of our own: this closure runs once per
                            // subscription and several subscriptions (history list, content
                            // data, profile, gallery) detect the same chat concurrently.
                            // NLLanguageRecognizer accumulates state per instance, so
                            // sharing one across queues mixes two chats' text together.
                            let localRecognizer = NLLanguageRecognizer()
                            var fromLangs: [String: Int] = [:]
                            var count = 0
                            for message in messages {
                                if message.effectivelyIncoming(context.account.peerId), message.text.count >= 10 {
                                    if let summaryAttribute = message.attributes.first(where: { $0 is SummarizationMessageAttribute }) as? SummarizationMessageAttribute, !summaryAttribute.fromLang.isEmpty {
                                        let fromLang = normalizeTranslationLanguage(summaryAttribute.fromLang)
                                        if supportedTranslationLanguages.contains(fromLang) {
                                            // Capped like the detected path below: without this a
                                            // single long summarised message (up to 4096) outweighed
                                            // everything the capped path can ever accumulate.
                                            fromLangs[fromLang] = (fromLangs[fromLang] ?? 0) + min(message.text.count, 100)
                                            count += 1
                                        }
                                    } else {
                                        var text = String(message.text.prefix(256))
                                        if var entities = message.textEntitiesAttribute?.entities.filter({ entity in
                                            switch entity.type {
                                            case .Pre, .Code, .Url, .Email, .Mention, .Hashtag, .BotCommand:
                                                return true
                                            default:
                                                return false
                                            }
                                        }) {
                                            entities = entities.sorted(by: { $0.range.lowerBound > $1.range.lowerBound })
                                            var ranges: [Range<String.Index>] = []
                                            for entity in entities {
                                                if entity.range.lowerBound > text.count || entity.range.upperBound > text.count {
                                                    continue
                                                }
                                                ranges.append(text.index(text.startIndex, offsetBy: entity.range.lowerBound) ..< text.index(text.startIndex, offsetBy: entity.range.upperBound))
                                            }
                                            for range in ranges {
                                                if range.upperBound < text.endIndex {
                                                    text.removeSubrange(range)
                                                }
                                            }
                                        }
                                        
                                        if message.text.count < 10 {
                                            continue
                                        }
                                        
                                        localRecognizer.reset()
                                        localRecognizer.processString(text)
                                        let hypotheses = localRecognizer.languageHypotheses(withMaximum: 6)

                                        let filteredLanguages = hypotheses.filter { supportedTranslationLanguages.contains(normalizeTranslationLanguage($0.key.rawValue)) }.sorted(by: { $0.value > $1.value })
                                        // Telewhite: Russian text is regularly mis-read as another Cyrillic
                                        // language with high confidence, so taking the top hypothesis
                                        // unconditionally made a Russian chat detect as foreign and
                                        // auto-translate Russian into Russian. Two guards against that, in
                                        // order of strength: inside East Slavic the alphabet decides (see
                                        // telewhiteCyrillicAlphabetVerdict), and otherwise a target hypothesis
                                        // that is both present and a genuine contender wins over the top one.
                                        // Neither may fire for a language the recognizer CAN tell apart —
                                        // Bulgarian, Serbian, Kazakh — or that chat stops being translatable.
                                        let messageLanguage: String?
                                        let topLanguage = filteredLanguages.first.map { normalizeTranslationLanguage($0.key.rawValue) }
                                        if let topLanguage, telewhiteEastSlavicLanguages.contains(topLanguage), let alphabetVerdict = telewhiteCyrillicAlphabetVerdict(text) {
                                            messageLanguage = alphabetVerdict
                                        } else if let targetHypothesis = filteredLanguages.first(where: { normalizeTranslationLanguage($0.key.rawValue) == normalizedTargetLanguage }), targetHypothesis.value >= telewhiteTargetLanguageHypothesisFloor, targetHypothesis.value >= (filteredLanguages.first?.value ?? 0.0) * telewhiteTargetLanguageRelativeFloor {
                                            messageLanguage = normalizeTranslationLanguage(targetHypothesis.key.rawValue)
                                        } else if let language = filteredLanguages.first, language.value >= telewhiteLanguageConfidenceFloor {
                                            // Telewhite: an unconfident guess is no evidence at all — skip the
                                            // message instead of letting it vote.
                                            messageLanguage = normalizeTranslationLanguage(language.key.rawValue)
                                        } else {
                                            messageLanguage = nil
                                        }
                                        if let fromLang = messageLanguage {
                                            if loggingEnabled && !["en", "ru"].contains(fromLang) && !dontTranslateLanguages.contains(fromLang) {
                                                Logger.shared.log("ChatTranslation", "\(text)")
                                                Logger.shared.log("ChatTranslation", "Recognized as: \(fromLang), other hypotheses: \(hypotheses.map { $0.key.rawValue }.joined(separator: ",")) ")
                                            }
                                            // Telewhite: cap the per-message weight. Weighting purely by text
                                            // length let a single long mis-detected message outvote several
                                            // correctly detected ones.
                                            fromLangs[fromLang] = (fromLangs[fromLang] ?? 0) + min(message.text.count, 100)
                                            count += 1
                                        }
                                    }
                                }
                                if count >= 16 {
                                    break
                                }
                            }
                                                        
                            // Telewhite: the weight cap above quantises long messages to
                            // exactly 100, so exact ties are routine rather than freak.
                            // Iterating a Dictionary with `>` resolved them in hash order,
                            // which Swift randomises per launch — the same chat translated
                            // on one launch and not the next. Sort by weight, then by code,
                            // so the winner is a property of the messages alone.
                            let mostFrequent: (String, Int)? = fromLangs
                                .sorted(by: { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key })
                                .first
                                .map { ($0.key, $0.value) }
                            let fromLang = mostFrequent?.0 ?? ""
                            if loggingEnabled {
                                Logger.shared.log("ChatTranslation", "Ended with: \(fromLang)")
                            }

                            if telewhiteIncomingTranslationEnabled && !settings.showTranslate && fromLang.isEmpty {
                                return nil
                            }

                            // Telewhite: with auto incoming translation on, non-target
                            // languages are translated automatically (no manual tap);
                            // otherwise the bar is shown but nothing is translated until
                            // the user turns it on for this chat.
                            // Telewhite: auto-translation needs solid evidence. A winning
                            // language that holds less than half of the counted weight, or
                            // a verdict drawn from a single sampled message, is a coin
                            // flip — leave auto off and let the panel offer a manual
                            // translation instead.
                            let totalDetectionWeight = fromLangs.values.reduce(0, +)
                            var hasDecisiveDetection = false
                            if let mostFrequent, count >= 2, totalDetectionWeight > 0 {
                                // Strictly more than half: with `>=` an even split between two
                                // languages counted as decisive for whichever won the sort.
                                hasDecisiveDetection = Double(mostFrequent.1) > Double(totalDetectionWeight) * 0.5
                            }
                            // Telewhite: respect a recorded "Show Original" for as long as the
                            // chat is still in the language it was recorded for. A different
                            // language is a different question, so the decision lapses then.
                            let userTurnedItOff: Bool
                            if let userDisabledFromLang = cached?.userDisabledFromLang, !fromLang.isEmpty, normalizeTranslationLanguage(userDisabledFromLang) == normalizeTranslationLanguage(fromLang) {
                                userTurnedItOff = true
                            } else {
                                userTurnedItOff = false
                            }
                            var isEnabled = cached?.isEnabled ?? false
                            if telewhiteIncomingTranslationEnabled, !userTurnedItOff, !fromLang.isEmpty, hasDecisiveDetection, normalizeTranslationLanguage(fromLang) != normalizedTargetLanguage {
                                isEnabled = true
                            }
                            // Never translate a chat that is already in the target
                            // language (e.g. Russian chats with a Russian target),
                            // and never auto-enable when detection failed.
                            if fromLang.isEmpty || normalizeTranslationLanguage(fromLang) == normalizedTargetLanguage {
                                isEnabled = false
                            }
                            let state = ChatTranslationState(
                                baseLang: baseLang,
                                fromLang: fromLang,
                                timestamp: currentTime,
                                toLang: targetLanguage,
                                isEnabled: isEnabled,
                                // Carry the decision only while it still applies to this language.
                                userDisabledFromLang: userTurnedItOff ? cached?.userDisabledFromLang : nil
                            )
                            let _ = updateChatTranslationState(engine: context.engine, peerId: peerId, threadId: threadId, state: state).start()
                            if isDisplayable(state) {
                                return state
                            } else {
                                return nil
                            }
                        }
                    )
                }
            }
        }
    } else {
        return .single(nil)
    }
}
