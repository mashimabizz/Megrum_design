import Foundation
import MegrumDesign
import SwiftUI

struct HomeExchangeSettingsCalendarCard: View {
    @Binding var visibleMonth: Date
    @Binding var selectedPrefecture: String
    var selectedDateKeys: Set<String>
    var dateDetails: [String: HomeExchangeLocalDateDetail]
    var onTapDay: (HomeExchangeCalendarDay) -> Void
    var onFinishDragSelection: ([HomeExchangeCalendarDay]) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeExchangeCalendarHeader(
                monthTitle: monthTitle,
                selectedPrefecture: $selectedPrefecture,
                onPreviousMonth: previousMonth,
                onNextMonth: nextMonth
            )
            weekdayHeader
            calendarGrid
            HomeExchangeCalendarLegend(entries: legendEntries)
        }
        .padding(12)
        .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.10), radius: 22, y: 12)
    }

    private var weekdayHeader: some View {
        HomeExchangeSettingsCalendarWeekdayHeader { symbol, isCurrentMonth in
            weekdayColor(symbol: symbol, isCurrentMonth: isCurrentMonth)
        }
    }

    private var calendarGrid: some View {
        HomeExchangeSettingsCalendarGrid(
            calendarWeeks: calendarWeeks,
            dateDetails: dateDetails,
            selectedDateKeys: selectedDateKeys,
            dayColor: dayColor,
            selectionColor: { day in color(for: day) },
            onTapDay: onTapDay,
            onFinishDragSelection: onFinishDragSelection
        )
    }

    private var calendarWeeks: [[HomeExchangeCalendarDay]] {
        HomeExchangeCalendarMonthBuilder.weeks(containing: visibleMonth, calendar: calendar)
    }

    private var monthTitle: String {
        let month = calendar.component(.month, from: visibleMonth)
        return "\(month)月"
    }

    private var unsetSelectionColor: Color {
        MegrumTheme.muted.opacity(0.46)
    }

    private var legendEntries: [HomeExchangeCalendarLegendEntry] {
        let visibleMonthKeys = Set(
            flattenedDays
                .filter(\.isInDisplayedMonth)
                .map(\.key)
        )
        let visibleSelectedKeys = selectedDateKeys.filter { visibleMonthKeys.contains($0) }
        var registeredPrefectures: Set<String> = []

        for key in visibleSelectedKeys {
            if let prefecture = dateDetails[key]?.prefecture.nilIfBlank {
                registeredPrefectures.insert(prefecture)
            }
        }

        return JapanesePrefectureCatalog.all.compactMap { prefecture -> HomeExchangeCalendarLegendEntry? in
            guard registeredPrefectures.contains(prefecture) else {
                return nil
            }
            return HomeExchangeCalendarLegendEntry(
                title: prefecture,
                color: HomeExchangePrefecturePresentation.color(for: prefecture)
            )
        }
    }

    private var flattenedDays: [HomeExchangeCalendarDay] {
        calendarWeeks.flatMap(\.self)
    }

    private func previousMonth() {
        moveMonth(by: -1)
    }

    private func nextMonth() {
        moveMonth(by: 1)
    }

    private func moveMonth(by offset: Int) {
        guard let next = calendar.date(byAdding: .month, value: offset, to: visibleMonth) else {
            return
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            visibleMonth = HomeExchangeCalendarMonthBuilder.monthStart(containing: next, calendar: calendar)
        }
    }

    private func dayColor(_ day: HomeExchangeCalendarDay) -> Color {
        weekdayColor(symbol: day.weekdaySymbol, isCurrentMonth: day.isInDisplayedMonth)
    }

    private func color(for day: HomeExchangeCalendarDay) -> Color {
        guard let prefecture = dateDetails[day.key]?.prefecture.nilIfBlank else {
            return unsetSelectionColor
        }
        return HomeExchangePrefecturePresentation.color(for: prefecture)
    }

    private func weekdayColor(symbol: String, isCurrentMonth: Bool) -> Color {
        let baseColor: Color
        switch symbol {
        case "土":
            baseColor = Color.blue.opacity(0.72)
        case "日":
            baseColor = MegrumTheme.conditionExact
        default:
            baseColor = MegrumTheme.ink
        }
        return isCurrentMonth ? baseColor : MegrumTheme.muted.opacity(0.58)
    }
}
