import Foundation
import MegrumDesign
import SwiftUI

struct IndividualListingLocalScheduleField: View {
    @Binding var localSchedule: String
    @State private var mode: IndividualListingLocalScheduleMode
    @State private var selectedDate: Date

    init(localSchedule: Binding<String>) {
        _localSchedule = localSchedule
        _mode = State(initialValue: Self.mode(for: localSchedule.wrappedValue))
        _selectedDate = State(initialValue: Self.date(from: localSchedule.wrappedValue) ?? .now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("日程")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
            }

            Picker("日程", selection: $mode) {
                ForEach(IndividualListingLocalScheduleMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .dates {
                DatePicker(
                    "日程を選択",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(MegrumTheme.lavender)
                .onAppear {
                    localSchedule = Self.scheduleText(from: selectedDate)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .onChange(of: mode) { _, newValue in
            switch newValue {
            case .consult:
                localSchedule = IndividualListingExchangeSummary.defaultLocalSchedule
            case .dates:
                selectedDate = Self.date(from: localSchedule) ?? selectedDate
                localSchedule = Self.scheduleText(from: selectedDate)
            }
        }
        .onChange(of: selectedDate) { _, newValue in
            guard mode == .dates else {
                return
            }
            localSchedule = Self.scheduleText(from: newValue)
        }
        .onChange(of: localSchedule) { _, newValue in
            let derivedMode = Self.mode(for: newValue)
            if derivedMode != mode {
                mode = derivedMode
            }
            if let date = Self.date(from: newValue), !Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                selectedDate = date
            }
        }
    }

    private static func mode(for value: String) -> IndividualListingLocalScheduleMode {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == IndividualListingExchangeSummary.defaultLocalSchedule ? .consult : .dates
    }

    private static func scheduleText(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return IndividualListingExchangeSummary.defaultLocalSchedule
        }
        return "\(month)/\(day)"
    }

    private static func date(from value: String) -> Date? {
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

private enum IndividualListingLocalScheduleMode: String, CaseIterable, Identifiable {
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
