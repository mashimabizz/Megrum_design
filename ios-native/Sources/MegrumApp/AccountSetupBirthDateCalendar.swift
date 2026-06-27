import Foundation
import MegrumDesign
import SwiftUI

struct AccountSetupBirthDateCalendar: View {
    @Binding private var selection: Date
    private let maxDate: Date
    private let onSelectionChange: () -> Void
    @State private var visibleMonth: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    init(
        selection: Binding<Date>,
        maxDate: Date = Date(),
        onSelectionChange: @escaping () -> Void
    ) {
        _selection = selection
        self.maxDate = maxDate
        self.onSelectionChange = onSelectionChange
        _visibleMonth = State(initialValue: AccountSetupBirthDateCalendarLogic.startOfMonth(selection.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            weekdayHeader
            dayGrid
        }
        .padding(18)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .onChange(of: selection) { _, newValue in
            let selectedMonth = AccountSetupBirthDateCalendarLogic.startOfMonth(newValue)
            if selectedMonth != visibleMonth {
                visibleMonth = selectedMonth
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(AccountSetupBirthDateCalendarLogic.monthTitle(for: visibleMonth))
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            HStack(spacing: 0) {
                calendarNavigationButton(
                    title: "前年",
                    systemImage: "chevron.left.2",
                    isEnabled: canShowPreviousYear,
                    action: showPreviousYear
                )

                calendarNavigationButton(
                    title: "前月",
                    systemImage: "chevron.left",
                    action: showPreviousMonth
                )

                calendarNavigationButton(
                    title: "翌月",
                    systemImage: "chevron.right",
                    isEnabled: canShowNextMonth,
                    action: showNextMonth
                )

                calendarNavigationButton(
                    title: "翌年",
                    systemImage: "chevron.right.2",
                    isEnabled: canShowNextYear,
                    action: showNextYear
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(AccountSetupBirthDateCalendarLogic.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(AccountSetupBirthDateCalendarLogic.days(for: visibleMonth)) { day in
                if let date = day.date {
                    let isSelected = AccountSetupBirthDateCalendarLogic.isSameDay(date, selection)
                    let isDisabled = AccountSetupBirthDateCalendarLogic.isAfter(date, maxDate)
                    Button {
                        selection = date
                        onSelectionChange()
                    } label: {
                        Text("\(AccountSetupBirthDateCalendarLogic.dayNumber(for: date))")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(dayTextColor(isSelected: isSelected, isDisabled: isDisabled))
                            .frame(width: 38, height: 38)
                            .background {
                                if isSelected {
                                    Circle()
                                        .fill(MegrumTheme.lavender.opacity(0.18))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled)
                    .accessibilityLabel(AccountSetupBirthDateCalendarLogic.accessibilityLabel(for: date))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                } else {
                    Color.clear
                        .frame(width: 38, height: 38)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var canShowNextMonth: Bool {
        guard let nextMonth = AccountSetupBirthDateCalendarLogic.addMonths(1, to: visibleMonth) else {
            return false
        }
        return !AccountSetupBirthDateCalendarLogic.isAfterMonth(nextMonth, maxDate)
    }

    private var canShowPreviousYear: Bool {
        AccountSetupBirthDateCalendarLogic.addYears(-1, to: visibleMonth, maxDate: maxDate) != nil
    }

    private var canShowNextYear: Bool {
        AccountSetupBirthDateCalendarLogic.addYears(1, to: visibleMonth, maxDate: maxDate) != nil
    }

    private func calendarNavigationButton(
        title: String,
        systemImage: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundStyle(isEnabled ? MegrumTheme.lavender : Color.black.opacity(0.18))
            .frame(width: 34, height: 38)
            .contentShape(Rectangle())
            .disabled(!isEnabled)
    }

    private func showPreviousMonth() {
        guard let previousMonth = AccountSetupBirthDateCalendarLogic.addMonths(-1, to: visibleMonth) else {
            return
        }
        visibleMonth = previousMonth
    }

    private func showNextMonth() {
        guard canShowNextMonth,
              let nextMonth = AccountSetupBirthDateCalendarLogic.addMonths(1, to: visibleMonth)
        else {
            return
        }
        visibleMonth = nextMonth
    }

    private func showPreviousYear() {
        guard let previousYear = AccountSetupBirthDateCalendarLogic.addYears(-1, to: visibleMonth, maxDate: maxDate) else {
            return
        }
        visibleMonth = previousYear
    }

    private func showNextYear() {
        guard let nextYear = AccountSetupBirthDateCalendarLogic.addYears(1, to: visibleMonth, maxDate: maxDate) else {
            return
        }
        visibleMonth = nextYear
    }

    private func dayTextColor(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled {
            return Color.black.opacity(0.20)
        }
        return isSelected ? MegrumTheme.lavender : MegrumTheme.ink
    }
}

struct AccountSetupBirthDateCalendarDay: Identifiable, Equatable {
    var id: String
    var date: Date?
}

enum AccountSetupBirthDateCalendarLogic {
    static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    static func startOfMonth(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    static func days(for month: Date) -> [AccountSetupBirthDateCalendarDay] {
        let start = startOfMonth(month)
        guard let range = calendar.range(of: .day, in: .month, for: start) else {
            return []
        }

        let leadingBlankCount = max(0, calendar.component(.weekday, from: start) - 1)
        var days = (0..<leadingBlankCount).map { index in
            AccountSetupBirthDateCalendarDay(id: "blank-leading-\(index)", date: nil)
        }

        for day in range {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            guard let date = calendar.date(from: components) else {
                continue
            }
            days.append(AccountSetupBirthDateCalendarDay(id: isoDateString(from: date), date: date))
        }

        let trailingBlankCount = (7 - (days.count % 7)) % 7
        days.append(contentsOf: (0..<trailingBlankCount).map { index in
            AccountSetupBirthDateCalendarDay(id: "blank-trailing-\(index)", date: nil)
        })
        return days
    }

    static func addMonths(_ value: Int, to month: Date) -> Date? {
        calendar.date(byAdding: .month, value: value, to: startOfMonth(month))
    }

    static func addYears(_ value: Int, to month: Date, maxDate: Date, minimumYear: Int = 1900) -> Date? {
        let start = startOfMonth(month)
        let components = calendar.dateComponents([.year, .month], from: start)
        guard
            let currentYear = components.year,
            let currentMonth = components.month
        else {
            return nil
        }

        let targetYear = currentYear + value
        guard targetYear >= minimumYear else {
            return nil
        }

        guard let targetMonth = calendar.date(from: DateComponents(year: targetYear, month: currentMonth, day: 1)) else {
            return nil
        }

        return isAfterMonth(targetMonth, maxDate) ? nil : targetMonth
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func isAfter(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.startOfDay(for: lhs) > calendar.startOfDay(for: rhs)
    }

    static func isAfterMonth(_ month: Date, _ maxDate: Date) -> Bool {
        startOfMonth(month) > startOfMonth(maxDate)
    }

    static func dayNumber(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    static func monthTitle(for date: Date) -> String {
        monthFormatter.string(from: date)
    }

    static func accessibilityLabel(for date: Date) -> String {
        accessibilityFormatter.string(from: date)
    }

    private static func isoDateString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .long
        return formatter
    }()

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
