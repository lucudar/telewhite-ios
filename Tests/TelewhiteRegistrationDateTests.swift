import Foundation

@main
struct TelewhiteRegistrationDateTests {
    static func main() {
        let now = ISO8601DateFormatter().date(from: "2026-09-06T21:00:00Z")!
        var passed = 0
        func check(_ condition: @autoclosure () -> Bool, _ description: String) {
            guard condition() else { fatalError(description) }
            passed += 1
        }
        func bot(_ date: String, _ flag: String = "INTERPOLATED") -> TelewhiteRegistrationDateValue? {
            return TelewhiteRegistrationDateValue.ayuResponse("{\"date\":\"\(date)\",\"flag\":\"\(flag)\"}", now: now)
        }
        let month = TelewhiteRegistrationDateValue.telegramMonth("04.2022", now: now)
        check(month?.kind == .telegramMonth, "Telegram month is recognized")
        check(month == TelewhiteRegistrationDateValue.telegramMonth("4.2022", now: now), "Single-digit month is supported")
        check(month?.formatted(languageCode: "en_US").contains("2022") == true, "Telegram year is preserved")
        check(month?.formatted(languageCode: "en_US").contains("April") == true, "Telegram month is localized")
        check(month?.formatted(languageCode: "ru").contains("≈") == false, "Server month is not an ID estimate")
        for raw in [nil, "", "0.2022", "13.2022", "04.22", "04.2012", "10.2026", "01.2027", "01.9999", "04.2022.01", "-1.2022", "+1.2022", " 4.2022", "٠٤.2022", "4..2022"] as [String?] {
            check(TelewhiteRegistrationDateValue.telegramMonth(raw, now: now) == nil, "Reject invalid month: \(raw ?? "nil")")
        }
        check(TelewhiteRegistrationDateValue.telegramMonth("04.2022", now: Date(timeIntervalSince1970: 0)) == nil, "Old clock cannot construct an invalid closed range")
        for flag in ["EXACT", "INTERPOLATED"] {
            let value = bot("24.04.2022", flag)
            check(value?.kind == .approximate, "Bot flag \(flag) is still a third-party estimate")
            check(value?.formatted(languageCode: "ru").hasPrefix("≈ ") == true, "Approximate prefix is retained")
        }
        check(bot("24.04.2022", "LT")?.kind == .earlier, "LT means earlier")
        check(bot("24.04.2022", "ET")?.kind == .later, "ET means later")
        check(bot("24.04.2022", "LT")?.formatted(languageCode: "ru").hasPrefix("Раньше ") == true, "Earlier is localized")
        check(bot("24.04.2022", "ET")?.formatted(languageCode: "en").hasPrefix("After ") == true, "Later is localized")
        check(bot("29.02.2024") != nil, "Leap day is valid")
        for date in ["29.02.2023", "31.04.2022", "00.04.2022", "24.00.2022", "24.13.2022", "24.04.1970", "07.09.2026", "01.01.2027", "1.01.2022", "2022-04-24", "٢٤.٠٤.2022", "+1.04.2022"] {
            check(bot(date) == nil, "Reject invalid bot date: \(date)")
        }
        for raw in ["failed", "", "[]", "null", "{}", "{\"date\":42,\"flag\":\"EXACT\"}", "{\"date\":\"24.04.2022\",\"flag\":null}", "{\"date\":\"24.04.2022\",\"flag\":\"UNKNOWN\"}", "{\"date\":\"24.04.2022\",\"flag\":\"exact\"}", String(repeating: "x", count: 4097)] {
            check(TelewhiteRegistrationDateValue.ayuResponse(raw, now: now) == nil, "Reject malformed/untrusted payload")
        }
        let decorated = TelewhiteRegistrationDateValue.ayuResponse("{\"date\":\"24.04.2022\",\"flag\":\"EXACT\",\"text\":\"https://example.invalid\"}", now: now)
        check(decorated == bot("24.04.2022", "EXACT"), "Untrusted extra fields are ignored")
        let estimate = bot("24.04.2024")
        check(TelewhiteRegistrationDateValue.preferred(telegramMonth: "04.2022", botValue: estimate, now: now) == month, "Telegram 2022 wins over bot 2024")
        check(TelewhiteRegistrationDateValue.preferred(telegramMonth: nil, botValue: bot("24.04.2022"), now: now) == bot("24.04.2022"), "Bot 2022 is preserved without ID interpolation")
        check(TelewhiteRegistrationDateValue.preferred(telegramMonth: "invalid", botValue: estimate, now: now) == estimate, "Invalid server data does not hide valid bot data")
        check(TelewhiteRegistrationDateValue.preferred(telegramMonth: nil, botValue: nil, now: now) == nil, "Missing data stays missing")
        let oldZone = NSTimeZone.default
        for identifier in ["Pacific/Honolulu", "Pacific/Kiritimati"] {
            NSTimeZone.default = TimeZone(identifier: identifier)!
            check(bot("01.01.2022")?.formatted(languageCode: "en_US").contains("January 1, 2022") == true, "No date shift in \(identifier)")
        }
        NSTimeZone.default = oldZone
        print("PASS: \(passed) registration-date assertions")
    }
}
