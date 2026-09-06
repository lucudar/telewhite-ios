import Foundation

// Telegram supplies MM.yyyy for some peers. AyuGram's on-demand inline bot
// supplies JSON {"date":"dd.MM.yyyy","flag":"EXACT|INTERPOLATED|LT|ET"}.
// Reference: AyuGram/AyuGramDesktop, telegram_helpers.cpp at db3b9891cb0b.
// This is an independent Swift implementation; no ID-to-date guessing is used.
struct TelewhiteRegistrationDateValue: Equatable {
    enum Kind: Equatable {
        case telegramMonth
        case approximate
        case earlier
        case later
    }

    let kind: Kind
    let date: Date

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func decimal(_ text: Substring) -> Int? {
        guard !text.isEmpty, text.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) else {
            return nil
        }
        return Int(text)
    }

    private static func validatedDate(year: Int, month: Int, day: Int, now: Date) -> Date? {
        let calendar = self.utcCalendar
        let currentYear = calendar.component(.year, from: now)
        guard currentYear >= 2013, (2013...currentYear).contains(year), (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else {
            return nil
        }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day,
              date <= calendar.startOfDay(for: now) else {
            return nil
        }
        return date
    }

    static func telegramMonth(_ raw: String?, now: Date = Date()) -> TelewhiteRegistrationDateValue? {
        guard let raw = raw, raw.utf8.count <= 7 else {
            return nil
        }
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2, (1...2).contains(parts[0].count), parts[1].count == 4,
              let month = self.decimal(parts[0]), let year = self.decimal(parts[1]),
              let date = self.validatedDate(year: year, month: month, day: 1, now: now) else {
            return nil
        }
        return TelewhiteRegistrationDateValue(kind: .telegramMonth, date: date)
    }

    static func ayuResponse(_ raw: String, now: Date = Date()) -> TelewhiteRegistrationDateValue? {
        // Treat bot output as untrusted data: accept only the documented date
        // and flags, never arbitrary text, links, markup or instructions.
        guard raw.utf8.count <= 4096,
              let data = raw.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let flag = object["flag"] as? String,
              let dateText = object["date"] as? String, dateText.utf8.count == 10 else {
            return nil
        }
        let kind: Kind
        switch flag {
        case "EXACT", "INTERPOLATED":
            // AyuGram itself presents both flags as approximate. EXACT is a
            // third-party database claim, not confirmation from Telegram.
            kind = .approximate
        case "LT":
            kind = .earlier
        case "ET":
            kind = .later
        default:
            return nil
        }
        let parts = dateText.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 2, parts[1].count == 2, parts[2].count == 4,
              let day = self.decimal(parts[0]), let month = self.decimal(parts[1]), let year = self.decimal(parts[2]),
              let date = self.validatedDate(year: year, month: month, day: day, now: now) else {
            return nil
        }
        return TelewhiteRegistrationDateValue(kind: kind, date: date)
    }

    static func preferred(telegramMonth: String?, botValue: TelewhiteRegistrationDateValue?, now: Date = Date()) -> TelewhiteRegistrationDateValue? {
        return self.telegramMonth(telegramMonth, now: now) ?? botValue
    }

    func formatted(languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.calendar = Self.utcCalendar
        formatter.timeZone = Self.utcCalendar.timeZone
        // A server-provided month must not be misrepresented as its first day.
        formatter.setLocalizedDateFormatFromTemplate(self.kind == .telegramMonth ? "MMMM yyyy" : "d MMMM yyyy")
        let text = formatter.string(from: self.date)
        let isRussian = languageCode.lowercased().hasPrefix("ru")
        switch self.kind {
        case .telegramMonth:
            return text
        case .approximate:
            return "≈ \(text)"
        case .earlier:
            return (isRussian ? "Раньше " : "Before ") + text
        case .later:
            return (isRussian ? "Позже " : "After ") + text
        }
    }
}
