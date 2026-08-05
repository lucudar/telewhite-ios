import Foundation
import NaturalLanguage

// Telewhite: language detection for translation lives here rather than in TranslateUI
// because two very different callers need the same verdict: the batch translator in
// TranslateUI, and the per-message translate button drawn by ChatMessageBubbleItemNode.
// Neither of those modules can see the other, and both already see TelegramCore. Keeping
// one copy matters more than where it sits: the rules below are the accumulated answer to
// "why was my Russian message translated into Russian", and a second copy would drift.

// Telewhite: the folding TranslateUI's normalizeTranslationLanguage does, minus the part
// that needs the supported-language list. Kept here so the detector does not depend on a
// UI module; normalizeTranslationLanguage now forwards to this, so there is still one
// implementation.
public func telewhiteNormalizeLanguageCode(_ code: String) -> String {
    var code = code
    if code.contains("-") {
        code = code.components(separatedBy: "-").first ?? code
    }
    if code == "nb" {
        code = "no"
    }
    return code
}

// Telewhite: a hypothesis for the target language at or above this probability means
// the text may well already be in a language the user reads, so it is left alone.
// Deliberately low: between two Cyrillic languages the recognizer is often confident
// and wrong, and wrongly translating Russian into Russian is far more annoying than
// occasionally leaving a Ukrainian message untranslated.
private let telewhiteTargetLanguageHypothesisFloor: Double = 0.15

// Telewhite: below this probability a detection is treated as no detection at all
// rather than as evidence of a foreign language.
public let telewhiteLanguageConfidenceFloor: Double = 0.45

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
public let telewhiteEastSlavicLanguages: Set<String> = ["ru", "uk", "be"]

// Returns "ru" or "uk" when the alphabet settles which one it is, nil when it does not.
//
// The evidence is asymmetric, because the two alphabets are. Ukrainian reaches for
// і/ї/є/ґ constantly — roughly one letter in ten — so their RATE is the signal, not their
// presence: «Слава Україні» quoted inside a long Russian post is three such letters in
// two hundred, which is a quoted name, not the language of the message. Russian, on the
// other hand, is identified by their ABSENCE: requiring ы/ъ/э to be present instead left
// ordinary short messages ("Привет, как дела?") with no verdict at all, and the
// recognizer then read them as Ukrainian at 0.55 against 0.20 for Russian and translated
// Russian into Russian — the complaint this whole guard exists to answer.
//
// Only consulted when the recognizer's top hypothesis is already East Slavic, so text
// that is confidently Bulgarian, Serbian or Kazakh never reaches this function.
private let telewhiteUkrainianLetterRateDenominator = 25

private func telewhiteIsCyrillic(_ character: Character) -> Bool {
    guard let scalar = character.unicodeScalars.first else {
        return false
    }
    return scalar.value >= 0x0400 && scalar.value <= 0x04FF
}

public func telewhiteCyrillicAlphabetVerdict(_ text: String) -> String? {
    var russianOnlyCount = 0
    var ukrainianOnlyCount = 0
    var cyrillicCount = 0
    for character in text.lowercased() {
        if telewhiteRussianOnlyLetters.contains(character) {
            russianOnlyCount += 1
        } else if telewhiteUkrainianOnlyLetters.contains(character) {
            ukrainianOnlyCount += 1
        }
        if telewhiteIsCyrillic(character) {
            cyrillicCount += 1
        }
    }
    // Too little Cyrillic to be judging Cyrillic languages.
    guard cyrillicCount >= 6 else {
        return nil
    }
    let atUkrainianRate = ukrainianOnlyCount * telewhiteUkrainianLetterRateDenominator >= cyrillicCount
    if ukrainianOnlyCount > 0, atUkrainianRate {
        if russianOnlyCount > 0 {
            // Both alphabets at their own rate — a genuinely mixed message. No verdict;
            // let the recognizer and the probability floors decide.
            return nil
        }
        return "uk"
    }
    // Ukrainian letters absent, or present only at a quoted-word rate: Russian.
    return "ru"
}

// Telewhite: decide whether a message should be left untranslated. Translation must
// only trigger on text that is confidently NOT in the target language; anything else
// — target-language text, an unconfident guess, a text too short to judge — is left
// as it is. The previous rule was the opposite way round: it only skipped a message
// when the top hypothesis was the target with >= 0.6 confidence, so Russian text
// mis-read as Ukrainian (or judged with low confidence) was translated into Russian.
public func telewhiteShouldSkipTranslation(_ text: String, toLang: String, recognizer: NLLanguageRecognizer) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 3 else {
        return true
    }
    // telewhiteNormalizeLanguageCode, not a hand-rolled split: NLLanguage.norwegian is
    // "nb" while the translator's code is "no", so a raw comparison translates
    // Norwegian into Norwegian.
    let target = telewhiteNormalizeLanguageCode(toLang.lowercased())
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
        let bestCode = telewhiteNormalizeLanguageCode(best.key.rawValue.lowercased())
        if telewhiteEastSlavicLanguages.contains(bestCode), let alphabetVerdict = telewhiteCyrillicAlphabetVerdict(sample) {
            return alphabetVerdict == target
        }
    }

    var targetProbability: Double = 0.0
    for (language, probability) in hypotheses {
        if telewhiteNormalizeLanguageCode(language.rawValue.lowercased()) == target {
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
    let detected = telewhiteNormalizeLanguageCode(best.key.rawValue.lowercased())
    return detected == target
}

// Telewhite: the same question, asked from message layout instead of from the translation
// pipeline. Layout runs off the main thread, once per bubble and again on every relayout,
// so this wrapper adds the two things the batch path does not need: a cache, and a lock
// around the shared recognizer — the class accumulates state per instance, and two chats
// detecting at once through one instance is the bug the comment above warns about.
private let telewhiteDetectionLock = NSLock()
private let telewhiteDetectionRecognizer = NLLanguageRecognizer()
private let telewhiteDetectionCache: NSCache<NSString, NSNumber> = {
    let cache = NSCache<NSString, NSNumber>()
    cache.countLimit = 512
    return cache
}()

public func telewhiteTextIsAlreadyInLanguage(_ text: String, toLang: String) -> Bool {
    // The detector only ever looks at the first 200 characters, so the key may too — and a
    // long message then costs one short key instead of one the size of the message.
    let sample = String(text.prefix(200))
    let key = "\(telewhiteNormalizeLanguageCode(toLang.lowercased()))|\(sample)" as NSString
    if let cached = telewhiteDetectionCache.object(forKey: key) {
        return cached.boolValue
    }
    telewhiteDetectionLock.lock()
    let result = telewhiteShouldSkipTranslation(text, toLang: toLang, recognizer: telewhiteDetectionRecognizer)
    telewhiteDetectionLock.unlock()
    telewhiteDetectionCache.setObject(NSNumber(value: result), forKey: key)
    return result
}
