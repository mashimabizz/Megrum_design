import Foundation

public enum ProfileBirthDateCodec {
    private static let calendar = Calendar(identifier: .gregorian)

    public static func date(from rawValue: String?) -> Date? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty
        else {
            return nil
        }
        return formatter.date(from: rawValue)
    }

    public static func string(from date: Date?) -> String? {
        guard let date else {
            return nil
        }
        return formatter.string(from: date)
    }

    public static func age(on date: Date = .now, from birthDate: Date?) -> Int? {
        guard let birthDate else {
            return nil
        }
        let startOfToday = calendar.startOfDay(for: date)
        let startOfBirthDate = calendar.startOfDay(for: birthDate)
        let components = calendar.dateComponents([.year], from: startOfBirthDate, to: startOfToday)
        guard let years = components.year, years >= 0 else {
            return nil
        }
        return years
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
