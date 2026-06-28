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
