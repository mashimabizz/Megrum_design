import Foundation

struct IndividualListingLocalScheduleState: Equatable {
    var mode: IndividualListingLocalScheduleMode
    var selectedDate: Date

    init(localSchedule: String, now: Date = .now) {
        mode = Self.mode(for: localSchedule)
        selectedDate = Self.date(from: localSchedule) ?? now
    }

    func onDatePickerAppearText() -> String? {
        guard mode == .dates else {
            return nil
        }
        return Self.scheduleText(from: selectedDate)
    }

    mutating func localScheduleTextAfterModeChange(currentLocalSchedule: String) -> String {
        switch mode {
        case .consult:
            return IndividualListingExchangeSummary.defaultLocalSchedule
        case .dates:
            selectedDate = Self.date(from: currentLocalSchedule) ?? selectedDate
            return Self.scheduleText(from: selectedDate)
        }
    }

    mutating func localScheduleTextAfterDateChange(_ date: Date) -> String? {
        selectedDate = date
        guard mode == .dates else {
            return nil
        }
        return Self.scheduleText(from: selectedDate)
    }

    mutating func applyExternalLocalSchedule(_ value: String) {
        let derivedMode = Self.mode(for: value)
        if derivedMode != mode {
            mode = derivedMode
        }
        if let date = Self.date(from: value), !Calendar.current.isDate(date, inSameDayAs: selectedDate) {
            selectedDate = date
        }
    }

    static func mode(for value: String) -> IndividualListingLocalScheduleMode {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == IndividualListingExchangeSummary.defaultLocalSchedule ? .consult : .dates
    }

    static func scheduleText(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return IndividualListingExchangeSummary.defaultLocalSchedule
        }
        return "\(month)/\(day)"
    }

    static func date(from value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed != IndividualListingExchangeSummary.defaultLocalSchedule
        else {
            return nil
        }

        let currentYear = Calendar.current.component(.year, from: .now)
        let normalized = trimmed.replacingOccurrences(of: "月", with: "/")
            .replacingOccurrences(of: "日", with: "")
        let firstToken = normalized
            .components(separatedBy: CharacterSet(charactersIn: "、,\n "))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstToken, !firstToken.isEmpty else {
            return nil
        }

        let parts = firstToken.split(separator: "/").compactMap { Int($0) }
        if parts.count >= 3 {
            return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        }
        if parts.count >= 2 {
            return Calendar.current.date(from: DateComponents(year: currentYear, month: parts[0], day: parts[1]))
        }
        return nil
    }
}

enum IndividualListingLocalScheduleMode: String, CaseIterable, Identifiable {
    case consult
    case dates

    var id: String { rawValue }

    var title: String {
        switch self {
        case .consult:
            "相談して決める"
        case .dates:
            "日程を指定"
        }
    }
}
