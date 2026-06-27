import MegrumCore
import MegrumDesign
import SwiftUI

struct AccountSetupWelcomeStep: View {
    var body: some View {
        VStack(spacing: 26) {
            AccountSetupFeatureRow(
                systemImage: "arrow.left.arrow.right.circle",
                title: "グッズ交換",
                highlights: [
                    .init(text: "AIでグッズ登録"),
                    .init(text: "交換相手を自動で見つける"),
                    .init(text: "「探す」から「めぐりあう」へ", style: .accent)
                ]
            )

            Divider()
                .padding(.leading, 86)

            AccountSetupFeatureRow(
                systemImage: "heart.circle",
                title: "めぐり",
                highlights: [
                    .init(text: "近くの人とゆるくつながれる"),
                    .init(text: "気軽な交流から、深いつながりまで", style: .accent)
                ]
            )
        }
        .padding(.top, 22)
    }
}

struct AccountSetupAreaStep: View {
    @Binding var selectedPrefecture: String
    @Binding var searchText: String
    var errorMessage: String?
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var onClearError: () -> Void

    private var filteredPrefectures: [String] {
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return JapanesePrefectureCatalog.all
        }
        return JapanesePrefectureCatalog.all.filter { $0.localizedCaseInsensitiveContains(normalized) }
    }

    var body: some View {
        VStack(spacing: 18) {
            AccountSetupSearchField(
                placeholder: "都道府県を検索",
                text: $searchText,
                focusedField: $focusedField,
                focusCase: .areaSearch
            )

            VStack(spacing: 0) {
                ForEach(filteredPrefectures, id: \.self) { prefecture in
                    AccountSetupListChoiceRow(
                        title: prefecture,
                        isSelected: selectedPrefecture == prefecture
                    ) {
                        selectedPrefecture = prefecture
                        onClearError()
                    }

                    if prefecture != filteredPrefectures.last {
                        Divider()
                    }
                }
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }

            AccountSetupErrorText(message: errorMessage)
        }
    }
}

struct AccountSetupTextInputStep: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var focusCase: AccountSetupFocusedField
    var leadingText: String?
    var isHandleField = false
    var footnote: String
    var errorMessage: String?
    var onClearError: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 6) {
                if let leadingText {
                    Text(leadingText)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                TextField(placeholder, text: $text)
                    .focused($focusedField, equals: focusCase)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .textContentType(isHandleField ? .username : .name)
                    .keyboardType(isHandleField ? .asciiCapable : .default)
                    .textInputAutocapitalization(isHandleField ? .never : .words)
                    .autocorrectionDisabled()
                    #endif
                    .submitLabel(.next)
                    .onChange(of: text) { _, newValue in
                        if isHandleField {
                            let lowercased = newValue.lowercased()
                            if lowercased != newValue {
                                text = lowercased
                            }
                        }
                        onClearError()
                    }

                if !text.isEmpty {
                    Button {
                        text = ""
                        onClearError()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.36))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 64)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.55), lineWidth: 1.2)
            }

            Text(footnote)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(4)

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 28)
    }
}

struct AccountSetupBirthDateStep: View {
    @Binding var birthDate: Date
    var errorMessage: String?
    var onClearError: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            AccountSetupBirthDateCalendar(
                selection: $birthDate,
                onSelectionChange: onClearError
            )

            Text("生年月日は相手にそのまま公開されません。プロフィールでは年齢表示に使います。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(4)

            AccountSetupErrorText(message: errorMessage)
        }
    }
}

struct AccountSetupGenderStep: View {
    @Binding var gender: UserGender?
    var errorMessage: String?
    var onClearError: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(AccountSetupGenderOptions.all) { option in
                AccountSetupListChoiceRow(
                    title: option.displayName,
                    isSelected: gender == option
                ) {
                    gender = option
                    onClearError()
                }
            }

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 22)
    }
}

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

struct AccountSetupCompletionStep: View {
    var displayName: String
    var handle: String
    var prefecture: String
    var birthDate: Date
    var gender: UserGender?
    var selectedOshiDrafts: [OnboardingOshiDraft]
    var isSaving: Bool
    var errorMessage: String?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                AccountSetupSummaryRow(title: "推し", value: selectedOshiDrafts.map(\.displayName).joined(separator: "、"))
                Divider()
                AccountSetupSummaryRow(title: "活動エリア", value: prefecture)
                Divider()
                AccountSetupSummaryRow(title: "名前", value: displayName)
                Divider()
                AccountSetupSummaryRow(title: "ユーザーID", value: "@\(MegrumAppStateInputNormalizer.profileHandle(handle) ?? handle)")
                Divider()
                AccountSetupSummaryRow(title: "生年月日", value: ProfileBirthDateCodec.string(from: birthDate) ?? "")
                Divider()
                AccountSetupSummaryRow(title: "性別", value: gender?.displayName ?? "")
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }

            if isSaving {
                ProgressView("保存しています")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tint(MegrumTheme.lavender)
            }

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 22)
    }
}

private struct AccountSetupFeatureRow: View {
    var systemImage: String
    var title: String
    var highlights: [AccountSetupFeatureHighlight]

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 68, height: 68)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(highlights) { highlight in
                        AccountSetupFeatureHighlightLabel(highlight: highlight)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AccountSetupFeatureHighlight: Identifiable, Equatable {
    enum Style: Equatable {
        case primary
        case accent
    }

    let id = UUID()
    var text: String
    var style: Style = .primary
}

private struct AccountSetupFeatureHighlightLabel: View {
    var highlight: AccountSetupFeatureHighlight

    var body: some View {
        Text(highlight.text)
            .font(.system(size: highlight.style == .accent ? 15 : 14, weight: .black, design: .rounded))
            .foregroundStyle(highlight.style == .accent ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.86))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
    }

    private var backgroundColor: Color {
        switch highlight.style {
        case .primary:
            Color.white.opacity(0.78)
        case .accent:
            MegrumTheme.lavender.opacity(0.11)
        }
    }

    private var borderColor: Color {
        switch highlight.style {
        case .primary:
            Color.black.opacity(0.05)
        case .accent:
            MegrumTheme.lavender.opacity(0.22)
        }
    }
}

private struct AccountSetupSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 82, alignment: .leading)
            Text(value.isEmpty ? "未設定" : value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
