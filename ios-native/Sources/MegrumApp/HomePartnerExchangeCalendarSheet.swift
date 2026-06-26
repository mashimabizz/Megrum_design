import Foundation
import MegrumDesign
import SwiftUI

struct HomePartnerExchangeCalendarContext: Identifiable, Equatable, Sendable {
    var ownerName: String?
    var methodTitle: String
    var dateDetails: [String: HomeExchangeLocalDateDetail]
    var fallbackPrefecture: String?
    var fallbackMemo: String?

    var id: String {
        [
            ownerName ?? "",
            methodTitle,
            dateDetails.keys.sorted().joined(separator: ","),
            fallbackPrefecture ?? "",
            fallbackMemo ?? ""
        ].joined(separator: "|")
    }

    var dateKeys: Set<String> {
        Set(dateDetails.keys)
    }

    var initialDateKey: String? {
        sortedDateKeys(onlyFuture: true).first ?? sortedDateKeys(onlyFuture: false).first
    }

    var initialVisibleMonth: Date {
        guard let initialDateKey,
              let date = HomeExchangeDateKey.date(from: initialDateKey, calendar: Self.calendar)
        else {
            return HomePartnerExchangeCalendarMonthBuilder.monthStart(containing: Date(), calendar: Self.calendar)
        }
        return HomePartnerExchangeCalendarMonthBuilder.monthStart(containing: date, calendar: Self.calendar)
    }

    static func from(
        signals: HomeCandidateConditionSignals,
        ownerName: String?
    ) -> HomePartnerExchangeCalendarContext? {
        let exchange = signals.exchange
        let methodTitle = HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(signals)?.methodTitle
            ?? exchange.partnerExchangeMethodTitle
            ?? "交換条件"
        let parsed = HomePartnerExchangeCalendarTextParser.parse(exchange.partnerLocalConditionText)
        let dateKeys = Set(exchange.partnerLocalDateKeys)
            .union(HomePartnerExchangeCalendarTextParser.dateKeys(in: exchange.partnerLocalConditionText))
        let fallbackPrefecture = parsed.prefecture
            ?? exchange.partnerLocalPrefectures.sorted().first
        let fallbackMemo = parsed.memo

        guard exchange.localExchangeSelected
            || methodTitle.contains("現地")
            || !dateKeys.isEmpty
            || fallbackPrefecture?.nilIfBlank != nil
            || fallbackMemo?.nilIfBlank != nil
        else {
            return nil
        }

        return HomePartnerExchangeCalendarContext(
            ownerName: ownerName?.nilIfBlank,
            methodTitle: methodTitle,
            dateDetails: Dictionary(uniqueKeysWithValues: dateKeys.sorted().map { key in
                (
                    key,
                    HomeExchangeLocalDateDetail(
                        prefecture: fallbackPrefecture ?? "",
                        memo: fallbackMemo ?? ""
                    )
                )
            }),
            fallbackPrefecture: fallbackPrefecture?.nilIfBlank,
            fallbackMemo: fallbackMemo?.nilIfBlank
        )
    }

    func sortedDateKeys(onlyFuture: Bool) -> [String] {
        dateKeys
            .filter { !onlyFuture || HomeExchangeDateKey.isOnOrAfterToday($0, calendar: Self.calendar) }
            .compactMap { key -> (String, Date)? in
                guard let date = HomeExchangeDateKey.date(from: key, calendar: Self.calendar) else {
                    return nil
                }
                return (key, date)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    private static var calendar: Calendar {
        HomePartnerExchangeCalendarMonthBuilder.calendar
    }
}

struct HomePartnerExchangeCalendarSheet: View {
    var context: HomePartnerExchangeCalendarContext

    @State private var visibleMonth: Date
    @State private var selectedDateKey: String?

    init(context: HomePartnerExchangeCalendarContext) {
        self.context = context
        _visibleMonth = State(initialValue: context.initialVisibleMonth)
        _selectedDateKey = State(initialValue: context.initialDateKey)
    }

    var body: some View {
        HomeSheetScaffold(bottomButton: nil) {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("相手の交換条件")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.trailing, 58)

                HomePartnerExchangeCalendarCard(
                    visibleMonth: $visibleMonth,
                    selectedDateKey: $selectedDateKey,
                    context: context
                )

                HomePartnerExchangeDateMemoCard(
                    dateKey: selectedDateKey,
                    detail: selectedDetail,
                    fallbackPrefecture: context.fallbackPrefecture,
                    fallbackMemo: context.fallbackMemo
                )
            }
        }
    }

    private var subtitle: String {
        if let ownerName = context.ownerName {
            return "\(ownerName)さんの\(context.methodTitle)"
        }
        return context.methodTitle
    }

    private var selectedDetail: HomeExchangeLocalDateDetail? {
        selectedDateKey.flatMap { context.dateDetails[$0] }
    }
}

private struct HomePartnerExchangeCalendarCard: View {
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

private struct HomePartnerExchangeCalendarDayCell: View {
    var day: HomePartnerExchangeCalendarDay
    var detail: HomeExchangeLocalDateDetail?
    var isMarked: Bool
    var isFocused: Bool
    var color: Color
    var selectionColor: Color
    var connection: HomeExchangeCalendarSelectionConnection
    var showsTrailingDivider: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(day.dayNumber)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isMarked ? Color.white : color)

                if isMarked {
                    Text(prefectureLabel)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(selectionColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(isFocused ? 0.96 : 0.86), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(selectionBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isMarked)
        .overlay(alignment: .trailing) {
            if showsTrailingDivider {
                Rectangle()
                    .fill(MegrumTheme.ink.opacity(0.06))
                    .frame(width: 1)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isMarked ? [.isButton, .isSelected] : [])
    }

    private var selectionBackground: some View {
        Group {
            if isMarked {
                HomePartnerExchangeCalendarSelectionBackgroundShape(connection: connection)
                    .fill(selectionColor.opacity(day.isInDisplayedMonth ? (isFocused ? 0.98 : 0.72) : 0.24))
                    .overlay {
                        if isFocused {
                            HomePartnerExchangeCalendarSelectionBackgroundShape(connection: connection)
                                .stroke(Color.white.opacity(0.94), lineWidth: 2)
                        }
                    }
                    .padding(.leading, connection.connectsFromPrevious ? 0 : 5)
                    .padding(.trailing, connection.connectsToNext ? 0 : 5)
                    .padding(.vertical, 4)
            }
        }
    }

    private var accessibilityLabel: String {
        "\(day.monthNumber)月\(day.dayNumber)日、\(isMarked ? "現地交換可能" : "予定なし")、\(prefectureLabel)"
    }

    private var prefectureLabel: String {
        detail?.prefecture.nilIfBlank.map(HomePartnerExchangePrefecturePresentation.shortName) ?? "場所"
    }
}

private struct HomePartnerExchangeDateMemoCard: View {
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

private enum HomePartnerExchangeCalendarTextParser {
    static func parse(_ text: String?) -> (prefecture: String?, memo: String?) {
        let parts = detailParts(from: text)
        let prefecture = parts.first(where: isPrefecture)
        let memo = parts.first { part in
            !isPrefecture(part) && !containsDate(part) && !isScheduleConsultation(part)
        }
        return (prefecture, memo)
    }

    static func dateKeys(in text: String?) -> Set<String> {
        guard let text else {
            return []
        }
        let calendar = HomePartnerExchangeCalendarMonthBuilder.calendar
        let currentYear = calendar.component(.year, from: Date())
        let patterns = [
            #"(?<year>\d{4})-(?<month>\d{1,2})-(?<day>\d{1,2})"#,
            #"(?<month>\d{1,2})月(?<day>\d{1,2})日"#,
            #"(?<month>\d{1,2})/(?<day>\d{1,2})"#,
            #"(?<month>\d{1,2})\.(?<day>\d{1,2})"#
        ]
        let keys = patterns.flatMap { pattern in
            matchedDateKeys(in: text, pattern: pattern, fallbackYear: currentYear, calendar: calendar)
        }
        return Set(HomeExchangeDateKey.normalizedKeys(from: HomeExchangeDateKey.rawValue(from: keys)))
    }

    private static func detailParts(from text: String?) -> [String] {
        guard let text else {
            return []
        }
        return text
            .replacingOccurrences(of: "現地交換：", with: "")
            .components(separatedBy: " / ")
            .flatMap { $0.components(separatedBy: "、") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func matchedDateKeys(
        in text: String,
        pattern: String,
        fallbackYear: Int,
        calendar: Calendar
    ) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            let year = intValue(named: "year", in: text, match: match) ?? fallbackYear
            guard let month = intValue(named: "month", in: text, match: match),
                  let day = intValue(named: "day", in: text, match: match),
                  let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
            else {
                return nil
            }
            return HomeExchangeDateKey.key(for: date, calendar: calendar)
        }
    }

    private static func intValue(named name: String, in text: String, match: NSTextCheckingResult) -> Int? {
        let range = match.range(withName: name)
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: text)
        else {
            return nil
        }
        return Int(text[swiftRange])
    }

    private static func isPrefecture(_ value: String) -> Bool {
        JapanesePrefectureCatalog.all.contains(value)
    }

    private static func containsDate(_ value: String) -> Bool {
        !dateKeys(in: value).isEmpty || value.contains("他")
    }

    private static func isScheduleConsultation(_ value: String) -> Bool {
        ["相談", "相談して決める", "日程は相談", "日程相談", "場所相談"].contains(value)
    }
}

private enum HomePartnerExchangeCalendarMonthBuilder {
    static let weekdaySymbols = ["月", "火", "水", "木", "金", "土", "日"]

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar
    }

    static func monthStart(containing date: Date, calendar: Calendar = Self.calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func weeks(containing visibleMonth: Date, calendar: Calendar = Self.calendar) -> [[HomePartnerExchangeCalendarDay]] {
        let monthStart = monthStart(containing: visibleMonth, calendar: calendar)
        let leadingDays = mondayFirstWeekdayIndex(for: monthStart, calendar: calendar)
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart
        let displayedMonth = calendar.component(.month, from: monthStart)

        let days = (0..<42).compactMap { offset -> HomePartnerExchangeCalendarDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            let weekdayIndex = mondayFirstWeekdayIndex(for: date, calendar: calendar)
            return HomePartnerExchangeCalendarDay(
                date: date,
                key: HomeExchangeDateKey.key(for: date, calendar: calendar),
                isInDisplayedMonth: calendar.component(.month, from: date) == displayedMonth,
                weekdaySymbol: weekdaySymbols[weekdayIndex],
                dayNumber: calendar.component(.day, from: date),
                monthNumber: calendar.component(.month, from: date)
            )
        }

        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    private static func mondayFirstWeekdayIndex(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}

private struct HomePartnerExchangeCalendarDay: Equatable, Identifiable {
    var date: Date
    var key: String
    var isInDisplayedMonth: Bool
    var weekdaySymbol: String
    var dayNumber: Int
    var monthNumber: Int

    var id: String { key }
}

private struct HomePartnerExchangeCalendarSelectionBackgroundShape: Shape {
    var connection: HomeExchangeCalendarSelectionConnection

    func path(in rect: CGRect) -> Path {
        let radius = min(11, rect.width / 2, rect.height / 2)
        let topLeft = connection.connectsFromPrevious ? 0 : radius
        let bottomLeft = connection.connectsFromPrevious ? 0 : radius
        let topRight = connection.connectsToNext ? 0 : radius
        let bottomRight = connection.connectsToNext ? 0 : radius

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        if topRight > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + topRight),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        if bottomRight > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        }
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        if bottomLeft > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        if topLeft > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + topLeft, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }
        path.closeSubpath()
        return path
    }
}

private enum HomePartnerExchangePrefecturePresentation {
    static func shortName(_ prefecture: String) -> String {
        let trimmed = prefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "北海道" {
            return trimmed
        }
        return trimmed
            .replacingOccurrences(of: "都", with: "")
            .replacingOccurrences(of: "府", with: "")
            .replacingOccurrences(of: "県", with: "")
    }

    static func color(for prefecture: String) -> Color {
        let trimmed = prefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = JapanesePrefectureCatalog.all.firstIndex(of: trimmed) else {
            return MegrumTheme.lavender
        }
        let hue = Double((index * 7) % JapanesePrefectureCatalog.all.count) / Double(JapanesePrefectureCatalog.all.count)
        return Color(hue: hue, saturation: 0.44, brightness: 0.86)
    }
}

private struct HomePartnerExchangeCalendarLegendEntry: Identifiable {
    var title: String
    var color: Color

    var id: String { title }
}
