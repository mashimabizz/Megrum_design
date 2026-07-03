import Foundation

struct AccountSetupBirthDateCalendarPresentationState: Equatable {
    var visibleMonth: Date

    init(selection: Date) {
        self.visibleMonth = AccountSetupBirthDateCalendarLogic.startOfMonth(selection)
    }

    var monthTitle: String {
        AccountSetupBirthDateCalendarLogic.monthTitle(for: visibleMonth)
    }

    mutating func syncSelection(_ selection: Date) {
        let selectedMonth = AccountSetupBirthDateCalendarLogic.startOfMonth(selection)
        if selectedMonth != visibleMonth {
            visibleMonth = selectedMonth
        }
    }

    func canShowNextMonth(maxDate: Date) -> Bool {
        guard let nextMonth = AccountSetupBirthDateCalendarLogic.addMonths(1, to: visibleMonth) else {
            return false
        }
        return !AccountSetupBirthDateCalendarLogic.isAfterMonth(nextMonth, maxDate)
    }

    func canShowPreviousYear(maxDate: Date) -> Bool {
        AccountSetupBirthDateCalendarLogic.addYears(-1, to: visibleMonth, maxDate: maxDate) != nil
    }

    func canShowNextYear(maxDate: Date) -> Bool {
        AccountSetupBirthDateCalendarLogic.addYears(1, to: visibleMonth, maxDate: maxDate) != nil
    }

    mutating func showPreviousMonth() {
        guard let previousMonth = AccountSetupBirthDateCalendarLogic.addMonths(-1, to: visibleMonth) else {
            return
        }
        visibleMonth = previousMonth
    }

    mutating func showNextMonth(maxDate: Date) {
        guard canShowNextMonth(maxDate: maxDate),
              let nextMonth = AccountSetupBirthDateCalendarLogic.addMonths(1, to: visibleMonth)
        else {
            return
        }
        visibleMonth = nextMonth
    }

    mutating func showPreviousYear(maxDate: Date) {
        guard let previousYear = AccountSetupBirthDateCalendarLogic.addYears(-1, to: visibleMonth, maxDate: maxDate) else {
            return
        }
        visibleMonth = previousYear
    }

    mutating func showNextYear(maxDate: Date) {
        guard let nextYear = AccountSetupBirthDateCalendarLogic.addYears(1, to: visibleMonth, maxDate: maxDate) else {
            return
        }
        visibleMonth = nextYear
    }
}
