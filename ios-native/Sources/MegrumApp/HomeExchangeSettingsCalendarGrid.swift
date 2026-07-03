import MegrumDesign
import SwiftUI

struct HomeExchangeSettingsCalendarWeekdayHeader: View {
    var weekdayColor: (String, Bool) -> Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeExchangeCalendarMonthBuilder.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(weekdayColor(symbol, true))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
}

struct HomeExchangeSettingsCalendarGrid: View {
    var calendarWeeks: [[HomeExchangeCalendarDay]]
    var dateDetails: [String: HomeExchangeLocalDateDetail]
    var selectedDateKeys: Set<String>
    var dayColor: (HomeExchangeCalendarDay) -> Color
    var selectionColor: (HomeExchangeCalendarDay) -> Color
    var onTapDay: (HomeExchangeCalendarDay) -> Void
    var onFinishDragSelection: ([HomeExchangeCalendarDay]) -> Void

    @State private var dragPreviewState = HomeExchangeCalendarDragPreviewState()

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(Array(calendarWeeks.enumerated()), id: \.offset) { rowIndex, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.element.id) { columnIndex, day in
                            HomeExchangeCalendarDayCell(
                                day: day,
                                detail: dateDetails[day.key],
                                isSelected: activeSelectedDateKeys.contains(day.key),
                                color: dayColor(day),
                                selectionColor: selectionColor(day),
                                selectionConnection: selectionConnection(in: week, at: columnIndex),
                                showsTrailingDivider: showsTrailingDivider(in: week, at: columnIndex),
                                action: { onTapDay(day) }
                            )
                            .frame(height: proxy.size.height / 6)
                        }
                    }

                    if rowIndex < calendarWeeks.count - 1 {
                        Divider().overlay(MegrumTheme.ink.opacity(0.08))
                    }
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(dragSelectionGesture(in: proxy.size))
        }
        .frame(height: 272)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var flattenedDays: [HomeExchangeCalendarDay] {
        calendarWeeks.flatMap(\.self)
    }

    private var activeSelectedDateKeys: Set<String> {
        dragPreviewState.activeSelectedDateKeys(selectedDateKeys: selectedDateKeys)
    }

    private func dragSelectionGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                let finalDays = selectedDays(in: value, size: size)
                dragPreviewState.updatePreview(
                    finalDays: finalDays,
                    visibleDays: flattenedDays
                )
            }
            .onEnded { value in
                let finalDays = selectedDays(in: value, size: size)
                let days = dragPreviewState.finishDragSelection(
                    finalDays: finalDays,
                    visibleDays: flattenedDays
                )
                onFinishDragSelection(days)
            }
    }

    private func selectionConnection(
        in week: [HomeExchangeCalendarDay],
        at index: Int
    ) -> HomeExchangeCalendarSelectionConnection {
        guard week.indices.contains(index),
              activeSelectedDateKeys.contains(week[index].key)
        else {
            return .isolated
        }
        return HomeExchangeCalendarSelectionConnection(
            connectsFromPrevious: index > 0 && activeSelectedDateKeys.contains(week[index - 1].key),
            connectsToNext: index < week.count - 1 && activeSelectedDateKeys.contains(week[index + 1].key)
        )
    }

    private func showsTrailingDivider(in week: [HomeExchangeCalendarDay], at index: Int) -> Bool {
        guard index < week.count - 1 else {
            return false
        }
        return !selectionConnection(in: week, at: index).connectsToNext
    }

    private func dayIndex(at location: CGPoint, in size: CGSize) -> Int? {
        guard size.width > 0, size.height > 0 else {
            return nil
        }
        let column = min(max(Int(location.x / (size.width / 7)), 0), 6)
        let row = min(max(Int(location.y / (size.height / 6)), 0), 5)
        return row * 7 + column
    }

    private func selectedDays(in value: DragGesture.Value, size: CGSize) -> [HomeExchangeCalendarDay] {
        guard let startIndex = dayIndex(at: value.startLocation, in: size),
              let endIndex = dayIndex(at: value.location, in: size),
              HomeExchangeCalendarDragSelectionPolicy.allowsSelection(
                  startIndex: startIndex,
                  endIndex: endIndex,
                  translation: value.translation
              ) else {
            return []
        }
        let lowerBound = min(startIndex, endIndex)
        let upperBound = max(startIndex, endIndex)
        return (lowerBound...upperBound).compactMap { index in
            flattenedDays.indices.contains(index) ? flattenedDays[index] : nil
        }
    }
}
