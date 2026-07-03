import Foundation

struct OwnProfileEditProfileFieldsPresentationState: Equatable {
    var isBirthDatePickerExpanded = false

    var birthDateChevronDegrees: Double {
        isBirthDatePickerExpanded ? 90 : 0
    }

    var birthDateSelectionFallback: Date {
        Self.defaultBirthDate
    }

    mutating func toggleBirthDatePicker() {
        isBirthDatePickerExpanded.toggle()
    }

    func birthDateText(for birthDate: Date?) -> String {
        guard let birthDate else {
            return "未設定"
        }
        return Self.birthDateFormatter.string(from: birthDate)
    }

    private static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static var defaultBirthDate: Date {
        Calendar(identifier: .gregorian)
            .date(byAdding: .year, value: -20, to: .now)
            ?? .now
    }
}
