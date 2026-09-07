import Foundation

@main
struct TelewhiteRegistrationDateTests {
    static func main() {
        let now = ISO8601DateFormatter().date(from: "2026-09-07T09:00:00Z")!
        var passed = 0
        func check(_ condition: @autoclosure () -> Bool, _ description: String) {
            guard condition() else { fatalError(description) }
            passed += 1
        }
        let month = TelewhiteRegistrationDateValue.telegramMonth("04.2022", now: now)
        check(month != nil, "Telegram month is recognized")
        check(month == TelewhiteRegistrationDateValue.telegramMonth("4.2022", now: now), "Single-digit month is supported")
        check(month?.formatted(languageCode: "en_US") == "April 2022", "Only the month/year are shown, not a fabricated day")
        for raw in [nil, "", "0.2022", "13.2022", "04.22", "04.2012", "10.2026", "01.2027", "01.9999", "04.2022.01", "-1.2022", "+1.2022", " 4.2022", "٠٤.2022", "4..2022", "failed", "{\"date\":\"24.04.2022\",\"flag\":\"EXACT\"}"] as [String?] {
            check(TelewhiteRegistrationDateValue.telegramMonth(raw, now: now) == nil, "Reject invalid or third-party data: \(raw ?? "nil")")
        }
        check(TelewhiteRegistrationDateValue.telegramMonth("04.2022", now: Date(timeIntervalSince1970: 0)) == nil, "Old clock cannot form an invalid range")
        check(TelewhiteRegistrationDateValue.telegramMonth(String(repeating: "9", count: 100000), now: now) == nil, "Oversized input is rejected")
        for year in [0, 1970, 2012, 2013, 2022, 2026, 2027, 9999] {
            for value in 0...99 {
                let raw = String(format: "%02d.%04d", value, year)
                let expected = (2013...2026).contains(year) && (1...12).contains(value) && (year < 2026 || value <= 9)
                check((TelewhiteRegistrationDateValue.telegramMonth(raw, now: now) != nil) == expected, "Month/year boundary \(raw)")
            }
        }
        for language in ["ru", "en_US", "de", "ar", "ja", "", "invalid-language"] {
            let text = month?.formatted(languageCode: language) ?? ""
            check(!text.isEmpty && !text.contains("≈"), "Formatting cannot invent an estimate for \(language)")
        }
        let oldZone = NSTimeZone.default
        for identifier in ["Pacific/Honolulu", "Pacific/Kiritimati"] {
            NSTimeZone.default = TimeZone(identifier: identifier)!
            check(TelewhiteRegistrationDateValue.telegramMonth("01.2022", now: now)?.formatted(languageCode: "en_US") == "January 2022", "No month shift in \(identifier)")
        }
        NSTimeZone.default = oldZone
        print("PASS: \(passed) Telegram-only registration-date assertions")
    }
}
