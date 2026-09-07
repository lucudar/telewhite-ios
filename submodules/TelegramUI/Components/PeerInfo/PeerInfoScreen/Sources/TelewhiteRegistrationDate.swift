import Foundation

// Only the optional registration month already supplied by Telegram is used.
// An absent/invalid month stays absent. There is no ID-to-date inference.
struct TelewhiteRegistrationDateValue: Equatable {
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

    static func telegramMonth(_ raw: String?, now: Date = Date()) -> TelewhiteRegistrationDateValue? {
        guard let raw = raw, raw.utf8.prefix(8).count <= 7 else {
            return nil
        }
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2, (1...2).contains(parts[0].count), parts[1].count == 4,
              let month = self.decimal(parts[0]), let year = self.decimal(parts[1]),
              (1...12).contains(month) else {
            return nil
        }
        let calendar = self.utcCalendar
        let currentYear = calendar.component(.year, from: now)
        guard currentYear >= 2013, (2013...currentYear).contains(year),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              date <= now else {
            return nil
        }
        return TelewhiteRegistrationDateValue(date: date)
    }

    func formatted(languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.calendar = Self.utcCalendar
        formatter.timeZone = Self.utcCalendar.timeZone
        // Never misrepresent a registration month as an exact registration day.
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: self.date)
    }
}
