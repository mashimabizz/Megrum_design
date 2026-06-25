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
    @State private var dragPreviewKeys: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weekdayHeader
            calendarGrid
            legend
        }
        .padding(12)
        .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.10), radius: 22, y: 12)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(monthTitle)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(minWidth: 34, alignment: .leading)

            Button("前の月", systemImage: "chevron.left", action: previousMonth)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            Button("次の月", systemImage: "chevron.right", action: nextMonth)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            Spacer(minLength: 4)

            HomeExchangePrefectureMenu(selection: $selectedPrefecture)
                .frame(width: 118)
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(HomeExchangeCalendarMonthBuilder.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(weekdayColor(symbol: symbol, isCurrentMonth: true))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }

    private var calendarGrid: some View {
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
                                selectionColor: color(for: day),
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
            .simultaneousGesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .local)
                    .onChanged { value in
                        let finalDays = selectedDays(in: value, size: proxy.size)
                        let resolvedKeys = HomeExchangeCalendarDragSelectionResolver.resolvedKeys(
                            accumulatedKeys: dragPreviewKeys,
                            finalKeys: finalDays.map(\.key),
                            visibleKeys: flattenedDays.map(\.key)
                        )
                        let nextPreviewKeys = Set(resolvedKeys)
                        guard !nextPreviewKeys.isEmpty,
                              nextPreviewKeys != dragPreviewKeys else {
                            return
                        }
                        dragPreviewKeys = nextPreviewKeys
                    }
                    .onEnded { value in
                        let finalDays = selectedDays(in: value, size: proxy.size)
                        let resolvedKeys = HomeExchangeCalendarDragSelectionResolver.resolvedKeys(
                            accumulatedKeys: dragPreviewKeys,
                            finalKeys: finalDays.map(\.key),
                            visibleKeys: flattenedDays.map(\.key)
                        )
                        let dayByKey = Dictionary(uniqueKeysWithValues: flattenedDays.map { ($0.key, $0) })
                        let days = resolvedKeys.compactMap { dayByKey[$0] }
                        onFinishDragSelection(days)
                        dragPreviewKeys = []
                    }
            )
        }
        .frame(height: 272)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var legend: some View {
        if !legendEntries.isEmpty {
            HStack(spacing: 14) {
                ForEach(legendEntries) { entry in
                    Label {
                        Text(entry.title)
                    } icon: {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 10, height: 10)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 0)
            }
        }
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

    private var activeSelectedDateKeys: Set<String> {
        selectedDateKeys.union(dragPreviewKeys)
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
enum HomeExchangeCalendarDragSelectionPolicy {
    static func allowsSelection(
        startIndex: Int,
        endIndex: Int,
        translation: CGSize,
        columnCount: Int = 7
    ) -> Bool {
        guard columnCount > 0,
              abs(translation.width) > abs(translation.height) else {
            return false
        }
        return startIndex / columnCount == endIndex / columnCount
    }
}

enum HomeExchangeCalendarDragSelectionResolver {
    static func resolvedKeys(
        accumulatedKeys: Set<String>,
        finalKeys: [String],
        visibleKeys: [String]
    ) -> [String] {
        let selectedKeys = accumulatedKeys.union(finalKeys)
        guard !selectedKeys.isEmpty else {
            return []
        }
        return visibleKeys.filter { selectedKeys.contains($0) }
    }
}

private struct HomeExchangePrefectureMenu: View {
    @Binding var selection: String

    var body: some View {
        Menu {
            Button("未設定") {
                selection = ""
            }
            ForEach(JapanesePrefectureCatalog.all, id: \.self) { prefecture in
                Button(prefecture) {
                    selection = prefecture
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text("既定")
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(displayPrefecture)
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .layoutPriority(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
                    .fixedSize()
            }
            .font(.caption.weight(.black))
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(Color.white.opacity(0.82), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MegrumTheme.lavender.opacity(0.34), lineWidth: 1.2)
            }
        }
        .accessibilityLabel("デフォルトの都道府県、\(selection.nilIfBlank ?? "未設定")")
    }

    private var displayPrefecture: String {
        guard let selection = selection.nilIfBlank else {
            return "未設定"
        }
        return HomeExchangePrefecturePresentation.shortName(selection)
    }
}
