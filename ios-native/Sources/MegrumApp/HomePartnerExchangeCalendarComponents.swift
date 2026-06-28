import Foundation
import MegrumDesign
import SwiftUI

struct HomePartnerExchangeCalendarCard: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDateKey: String?
    var context: HomePartnerExchangeCalendarContext

    private let calendar = HomePartnerExchangeCalendarMonthBuilder.calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weekdayHeader
            calendarGrid
            legend
        }
        .padding(12)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.10), radius: 22, y: 12)
    }

    private var monthTitle: String {
        let year = calendar.component(.year, from: visibleMonth)
        let month = calendar.component(.month, from: visibleMonth)
        return "\(year)年\(month)月"
    }

    private var calendarWeeks: [[HomePartnerExchangeCalendarDay]] {
        HomePartnerExchangeCalendarMonthBuilder.weeks(containing: visibleMonth, calendar: calendar)
    }

    private var legendEntries: [HomePartnerExchangeCalendarLegendEntry] {
        var prefectures = Set<String>()
        let visibleKeys = Set(calendarWeeks.flatMap(\.self).filter(\.isInDisplayedMonth).map(\.key))
        for key in context.dateKeys where visibleKeys.contains(key) {
            if let prefecture = context.dateDetails[key]?.prefecture.nilIfBlank {
                prefectures.insert(prefecture)
            }
        }
        if prefectures.isEmpty, let fallback = context.fallbackPrefecture {
            prefectures.insert(fallback)
        }

        return JapanesePrefectureCatalog.all.compactMap { prefecture in
            guard prefectures.contains(prefecture) else {
                return nil
            }
            return HomePartnerExchangeCalendarLegendEntry(
                title: prefecture,
                color: HomePartnerExchangePrefecturePresentation.color(for: prefecture)
            )
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("現地交換可能な場所と日程")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.muted)

                Text(monthTitle)
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("前の月", systemImage: "chevron.left", action: previousMonth)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 34, height: 34)
                .background(MegrumTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            Button("次の月", systemImage: "chevron.right", action: nextMonth)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(width: 34, height: 34)
                .background(MegrumTheme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(HomePartnerExchangeCalendarMonthBuilder.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(weekdayColor(symbol: symbol, isCurrentMonth: true))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 2)
    }

    private var calendarGrid: some View {
        VStack(spacing: 0) {
            ForEach(Array(calendarWeeks.enumerated()), id: \.offset) { rowIndex, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.element.id) { columnIndex, day in
                        HomePartnerExchangeCalendarDayCell(
                            day: day,
                            detail: context.dateDetails[day.key],
                            isMarked: context.dateKeys.contains(day.key),
                            isFocused: selectedDateKey == day.key,
                            color: weekdayColor(symbol: day.weekdaySymbol, isCurrentMonth: day.isInDisplayedMonth),
                            selectionColor: selectionColor(for: day),
                            connection: selectionConnection(in: week, at: columnIndex),
                            showsTrailingDivider: showsTrailingDivider(in: week, at: columnIndex),
                            action: { select(day) }
                        )
                        .frame(height: 45)
                    }
                }

                if rowIndex < calendarWeeks.count - 1 {
                    Divider().overlay(MegrumTheme.ink.opacity(0.08))
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var legend: some View {
        if legendEntries.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                Text("現地交換の日程はまだ登録されていません")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(MegrumTheme.muted)
        } else {
            HStack(spacing: 12) {
                ForEach(legendEntries) { entry in
                    Label {
                        Text(entry.title)
                    } icon: {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 9, height: 9)
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func select(_ day: HomePartnerExchangeCalendarDay) {
        guard context.dateKeys.contains(day.key) else {
            return
        }
        selectedDateKey = day.key
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
            visibleMonth = HomePartnerExchangeCalendarMonthBuilder.monthStart(containing: next, calendar: calendar)
        }
    }

    private func selectionColor(for day: HomePartnerExchangeCalendarDay) -> Color {
        guard let prefecture = context.dateDetails[day.key]?.prefecture.nilIfBlank
            ?? context.fallbackPrefecture
        else {
            return MegrumTheme.muted.opacity(0.46)
        }
        return HomePartnerExchangePrefecturePresentation.color(for: prefecture)
    }

    private func selectionConnection(
        in week: [HomePartnerExchangeCalendarDay],
        at index: Int
    ) -> HomeExchangeCalendarSelectionConnection {
        guard week.indices.contains(index),
              context.dateKeys.contains(week[index].key)
        else {
            return .isolated
        }
        return HomeExchangeCalendarSelectionConnection(
            connectsFromPrevious: index > 0 && context.dateKeys.contains(week[index - 1].key),
            connectsToNext: index < week.count - 1 && context.dateKeys.contains(week[index + 1].key)
        )
    }

    private func showsTrailingDivider(in week: [HomePartnerExchangeCalendarDay], at index: Int) -> Bool {
        guard index < week.count - 1 else {
            return false
        }
        return !selectionConnection(in: week, at: index).connectsToNext
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

struct HomePartnerExchangeDateMemoCard: View {
    var dateKey: String?
    var detail: HomeExchangeLocalDateDetail?
    var fallbackPrefecture: String?
    var fallbackMemo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "text.bubble")
                Text(title)
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)

            Text(memoText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var title: String {
        guard let dateKey else {
            return "メモ"
        }
        return "\(HomeExchangeDateKey.displayText(for: dateKey, calendar: HomePartnerExchangeCalendarMonthBuilder.calendar))のメモ"
    }

    private var memoText: String {
        let prefecture = detail?.prefecture.nilIfBlank ?? fallbackPrefecture
        let memo = detail?.memo.nilIfBlank ?? fallbackMemo
        let parts = [
            prefecture.map { "場所：\($0)" },
            memo.map { "メモ：\($0)" }
        ].compactMap(\.self)
        return parts.isEmpty ? "この日程のメモはまだ登録されていません。" : parts.joined(separator: "\n")
    }
}
