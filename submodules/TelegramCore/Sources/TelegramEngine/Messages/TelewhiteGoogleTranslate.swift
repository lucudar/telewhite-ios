import Foundation
import SwiftSignalKit
import Postbox
import TelegramApi

// Telewhite: translation through the free Google endpoint instead of Telegram's own
// messages.translateText.
//
// Telegram's translation is rate limited per account and is really meant for Premium: with
// translation enabled for a non-Premium account the server answers FLOOD_WAIT_180 after a
// handful of messages, so a scrolled chat translated three bubbles and then went quiet for
// three minutes. The free endpoint has no account tied to it, no key and no Premium check,
// which is why both directions now go through here and Telegram's API is kept only as a
// fallback for when this is unreachable.
//
// Privacy note, deliberately explicit: this sends message text to a third party. Callers must
// never route secret-chat content here.
public enum TelewhiteGoogleTranslate {
    // Shared by the incoming and outgoing paths so a phrase typed and received repeatedly is
    // translated once. NSCache is thread-safe and evicts itself under memory pressure.
    private static let cache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        // Telewhite: 600 was one long chat. Scrolling back through a second one evicted the
        // first, so returning to it re-translated everything already seen. These are short
        // strings; 3000 of them is a rounding error next to the media cache.
        cache.countLimit = 3000
        return cache
    }()
    
    // A batch of freshly scrolled messages can be dozens of texts, and firing them all at once
    // is what gets this endpoint to answer 429. Capping connections per host keeps a batch
    // polite without needing a queue of our own; the rest of the requests simply wait.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()
    
    private static func cacheKey(text: String, toLang: String) -> NSString {
        return "\(toLang)\u{1}\(text)" as NSString
    }
    
    public static func cachedTranslation(text: String, toLang: String) -> String? {
        return self.cache.object(forKey: self.cacheKey(text: text, toLang: toLang)) as String?
    }
    
    /// Translates a single text. Completes with nil when the endpoint is unreachable, throttled
    /// or answers something unparseable, so the caller can fall back rather than show nothing.
    public static func translate(text: String, toLang: String, fromLang: String? = nil, timeout: Double = 8.0) -> Signal<String?, NoError> {
        let attempt = self.performTranslate(text: text, toLang: toLang, fromLang: fromLang, timeout: timeout)
        guard let fromLang, !fromLang.isEmpty else {
            return attempt
        }
        // A source language the endpoint does not recognise makes it reject every request, which
        // would silently disable translation for whole languages instead of just costing quality.
        // One retry with auto-detection turns that from a permanent failure into a mild one.
        return attempt
        |> mapToSignal { result -> Signal<String?, NoError> in
            if result != nil {
                return .single(result)
            }
            return self.performTranslate(text: text, toLang: toLang, fromLang: nil, timeout: timeout)
        }
    }
    
    private static func performTranslate(text: String, toLang: String, fromLang: String?, timeout: Double) -> Signal<String?, NoError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .single(nil)
        }
        let key = self.cacheKey(text: text, toLang: toLang)
        if let cached = self.cache.object(forKey: key) {
            return .single(cached as String)
        }
        
        return Signal { subscriber in
            // Slang is normalised only on the way in: the request carries plain wording, while
            // the cache key stays the user's original text.
            let sourceText = TelewhiteSlangGlossary.normalize(trimmed)
            
            // A known source language measurably improves quality on short texts, where
            // auto-detection often guesses wrong; "auto" only when we genuinely don't know.
            let sourceLanguage: String
            if let fromLang, !fromLang.isEmpty {
                sourceLanguage = fromLang
            } else {
                sourceLanguage = "auto"
            }
            
            var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
            components?.queryItems = [
                URLQueryItem(name: "client", value: "gtx"),
                URLQueryItem(name: "sl", value: sourceLanguage),
                URLQueryItem(name: "tl", value: toLang),
                URLQueryItem(name: "dt", value: "t"),
                URLQueryItem(name: "ie", value: "UTF-8"),
                URLQueryItem(name: "oe", value: "UTF-8"),
                URLQueryItem(name: "q", value: sourceText)
            ]
            
            guard let url = components?.url else {
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = timeout
            
            let task = self.session.dataTask(with: request) { data, response, error in
                // Anything other than 200 (429 in particular) means "fall back", not "no text".
                if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                    subscriber.putNext(nil)
                    subscriber.putCompletion()
                    return
                }
                // The response is a nested JSON array: [[["translated","original",...],...],...]
                guard error == nil, let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
                      let segments = json.first as? [Any] else {
                    subscriber.putNext(nil)
                    subscriber.putCompletion()
                    return
                }
                // Segments are sentence-sized and already carry their own line breaks, so they
                // are concatenated verbatim rather than joined with a separator.
                var translated = ""
                for segment in segments {
                    if let parts = segment as? [Any], let piece = parts.first as? String {
                        translated += piece
                    }
                }
                translated = translated.trimmingCharacters(in: .whitespacesAndNewlines)
                if translated.isEmpty {
                    subscriber.putNext(nil)
                } else {
                    self.cache.setObject(translated as NSString, forKey: key)
                    subscriber.putNext(translated)
                }
                subscriber.putCompletion()
            }
            task.resume()
            
            return ActionDisposable {
                task.cancel()
            }
        }
    }
    
    /// Translates a batch, preserving order. Entries that fail come back as nil so the caller can
    /// decide per text whether to fall back or leave the original alone.
    public static func translate(texts: [String], toLang: String, fromLang: String? = nil, timeout: Double = 8.0) -> Signal<[String?], NoError> {
        if texts.isEmpty {
            return .single([])
        }
        let signals = texts.map { text -> Signal<String?, NoError> in
            return self.translate(text: text, toLang: toLang, fromLang: fromLang, timeout: timeout)
        }
        return combineLatest(signals)
    }
}

// Translates a batch of stored messages and hands the result back in the shape the engine already
// knows how to persist, so the storage path stays untouched. Completes with nil whenever the batch
// cannot be fully translated, which the caller treats as "use Telegram's API instead" — a partial
// result would otherwise leave some bubbles showing their original text as a "translation".
func telewhiteGoogleTranslateMessages(account: Account, messageIds: [MessageId], fromLang: String?, toLang: String) -> Signal<Api.messages.TranslatedText?, NoError> {
    if messageIds.isEmpty {
        return .single(nil)
    }
    return account.postbox.transaction { transaction -> [MessageId: String] in
        var texts: [MessageId: String] = [:]
        for messageId in messageIds {
            if let message = transaction.getMessage(messageId), !message.text.isEmpty {
                texts[messageId] = message.text
            }
        }
        return texts
    }
    |> mapToSignal { texts -> Signal<Api.messages.TranslatedText?, NoError> in
        if texts.isEmpty {
            return .single(nil)
        }
        // Order matters: the engine pairs results with messageIds by position.
        let orderedTexts = messageIds.map { texts[$0] ?? "" }
        return TelewhiteGoogleTranslate.translate(texts: orderedTexts, toLang: toLang, fromLang: fromLang)
        |> map { results -> Api.messages.TranslatedText? in
            var apiResults: [Api.TextWithEntities] = []
            for (index, messageId) in messageIds.enumerated() {
                let original = texts[messageId]
                if let translated = results[index], !translated.isEmpty {
                    // Entities are dropped on purpose: the free endpoint returns plain text, and
                    // reusing the original offsets against a different string would misplace
                    // links and formatting.
                    apiResults.append(.textWithEntities(.init(text: translated, entities: [])))
                } else if original == nil {
                    // Nothing translatable here (media without a caption); an empty entry keeps
                    // the positional pairing intact.
                    apiResults.append(.textWithEntities(.init(text: "", entities: [])))
                } else {
                    return nil
                }
            }
            return .translateResult(.init(result: apiResults))
        }
    }
}

// Telewhite: a small, hand-written glossary of internet slang and chat shorthand.
//
// Being honest about what this is: it is a substitution list, not a model that learns. Machine
// translation handles ordinary prose well but mangles slang, and there is no way to "teach" the
// free endpoint from the app. Rewriting the handful of words that actually break translation
// into their plain equivalents before sending is the part that can be done reliably, and it is
// what makes "спс, го" come out as something sensible instead of nonsense.
//
// Only whole words are replaced, case-insensitively, so ordinary text is never touched.
enum TelewhiteSlangGlossary {
    private static let entries: [String: String] = [
        // Russian chat shorthand
        "спс": "спасибо",
        "пжл": "пожалуйста",
        "плз": "пожалуйста",
        "прив": "привет",
        "здарова": "привет",
        "го": "давай начнём",
        "норм": "нормально",
        "оч": "очень",
        "щас": "сейчас",
        "сек": "секунду",
        "мб": "может быть",
        "хз": "не знаю",
        "имхо": "по моему мнению",
        "кмк": "как мне кажется",
        "нзч": "не за что",
        "спокойн": "спокойно",
        "збс": "отлично",
        "кек": "смешно",
        "лол": "смешно",
        "ору": "это очень смешно",
        "зашло": "понравилось",
        "агонь": "отлично",
        "топ": "отличный",
        "кринж": "неловко",
        "краш": "любимый человек",
        "рофл": "шутка",
        "рофлить": "шутить",
        "жиза": "это правда жизни",
        "пруф": "доказательство",
        "пруфы": "доказательства",
        "бро": "друг",
        "чел": "человек",
        "тян": "девушка",
        "движ": "движение",
        "туса": "вечеринка",
        "шара": "лёгкая возможность",
        "бабки": "деньги",
        "лавэ": "деньги",
        "работка": "работа",
        // English chat shorthand
        "thx": "thanks",
        "pls": "please",
        "plz": "please",
        // Single letters like "u" and "r" are deliberately absent: with non-letter boundaries
        // they also match things like the "R" in "R&B" and corrupt ordinary text.
        "ur": "your",
        "idk": "I do not know",
        "imo": "in my opinion",
        "imho": "in my opinion",
        "btw": "by the way",
        "afaik": "as far as I know",
        "asap": "as soon as possible",
        "brb": "I will be right back",
        "np": "no problem",
        "nvm": "never mind",
        "tbh": "to be honest",
        "rn": "right now",
        "ikr": "I know, right",
        "lmk": "let me know",
        "wdym": "what do you mean",
        "wtf": "what the hell",
        "omg": "oh my god",
        "lol": "that is funny",
        "lmao": "that is very funny",
        "cringe": "awkward",
        "sus": "suspicious",
        "legit": "genuine",
        "gonna": "going to",
        "wanna": "want to",
        "gotta": "have got to",
        "kinda": "kind of",
        "dunno": "do not know",
        "cya": "see you",
        "ty": "thank you",
        "yw": "you are welcome"
    ]
    
    // Built once: constructing the alternation per translated message would cost more than the
    // substitution itself.
    private static let regex: NSRegularExpression? = {
        let alternation = entries.keys
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        // Unicode-aware boundaries: \b does not behave for Cyrillic here, so the neighbours are
        // asserted to be non-letters instead.
        let pattern = "(?<![\\p{L}\\p{N}])(\(alternation))(?![\\p{L}\\p{N}])"
        return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()
    
    static func normalize(_ text: String) -> String {
        guard let regex = self.regex else {
            return text
        }
        // Long texts are prose, not shorthand, and running substitutions over them is a waste.
        guard text.count <= 1000 else {
            return text
        }
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        if matches.isEmpty {
            return text
        }
        var result = text
        // Applied back to front so earlier ranges stay valid.
        for match in matches.reversed() {
            let matched = nsText.substring(with: match.range)
            guard let replacement = entries[matched.lowercased()] else {
                continue
            }
            guard let range = Range(match.range, in: result) else {
                continue
            }
            result.replaceSubrange(range, with: replacement)
        }
        return result
    }
}
