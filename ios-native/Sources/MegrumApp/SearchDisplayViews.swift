import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

private func searchFilterDateText(_ date: Date) -> String {
    date.formatted(
        .dateTime
            .locale(Locale(identifier: "ja_JP"))
            .month()
            .day()
            .weekday(.abbreviated)
    )
}

private let searchFilterJapanesePrefectures = [
    "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
    "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
    "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
    "岐阜県", "静岡県", "愛知県", "三重県",
    "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
    "鳥取県", "島根県", "岡山県", "広島県", "山口県",
    "徳島県", "香川県", "愛媛県", "高知県",
    "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
]

private struct SearchInputBar: View {
    @Binding var query: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink)

            TextField("グッズ・推し・タグを検索", text: $query)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .disableAutocorrection(true)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        .megrumLiquidGlass(.capsule, tint: MegrumTheme.sky.opacity(0.10), interactive: true)
    }
}

struct SearchFooterBar: View {
    @Binding var query: String
    var activeFilterCount: Int
    var onFilterTap: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        MegrumGlassGroup(spacing: SearchLayoutMetrics.footerGlassGroupSpacing) {
            HStack(spacing: SearchLayoutMetrics.footerGlassGroupSpacing) {
                Button(action: onFilterTap) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 29, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(width: 62, height: 62)
                            .background(.regularMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))
                            .megrumLiquidGlass(.circle, tint: MegrumTheme.lavender.opacity(0.14), interactive: true)

                        if activeFilterCount > 0 {
                            Text("\(activeFilterCount)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(MegrumTheme.lavender, in: Circle())
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("検索フィルター")

                SearchInputBar(query: $query, onSubmit: onSubmit)
            }
        }
    }
}

struct SearchFilterSummaryBar: View {
    var activeFilterCount: Int
    var summaryTitles: [String]
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)

                    Text("絞り込み")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Spacer()

                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)件")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(MegrumTheme.lavender, in: Capsule())
                    }

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(MegrumTheme.muted)
                }

                if summaryTitles.isEmpty {
                    Text("グループを選ぶと、メンバーとグッズタグを選択できます")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(summaryTitles, id: \.self) { title in
                                Text(title)
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(.white.opacity(0.76), in: Capsule())
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SearchContent: View {
    var activeFilterCount: Int
    var summaryTitles: [String]
    var hasSearchCriteria: Bool
    var resultCount: Int
    var isSearching: Bool
    var isSearchResultsEmpty: Bool
    var matchedResults: [SearchResultItem]
    var possibleResults: [SearchResultItem]
    var unmatchedResults: [SearchResultItem]
    var viewerID: UUID?
    var onBack: () -> Void
    var onFilterTap: () -> Void
    var onStartProposal: (GoodsItem) -> Void
    var onOpenOwnerProfile: (UUID) -> Void
    var onReportItem: (GoodsItem, GoodsReportReason, String) -> Void

    private var hasFilteredResults: Bool {
        !matchedResults.isEmpty || !possibleResults.isEmpty || !unmatchedResults.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SearchBackButton(action: onBack)

                Text("検索")
                    .font(.system(size: SearchLayoutMetrics.titleFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)

                SearchFilterSummaryBar(
                    activeFilterCount: activeFilterCount,
                    summaryTitles: summaryTitles,
                    onTap: onFilterTap
                )

                if hasSearchCriteria {
                    SearchResultCountHeader(resultCount: resultCount, isSearching: isSearching)

                    if isSearching && isSearchResultsEmpty {
                        SearchResultSkeleton()
                    } else if !hasFilteredResults {
                        SearchEmptyMessage()
                    } else {
                        SearchResultSection(
                            results: matchedResults,
                            bucket: .matched,
                            viewerID: viewerID,
                            onStartProposal: onStartProposal,
                            onOpenOwnerProfile: onOpenOwnerProfile,
                            onReportItem: onReportItem
                        )
                        SearchResultSection(
                            results: possibleResults,
                            bucket: .possible,
                            viewerID: viewerID,
                            onStartProposal: onStartProposal,
                            onOpenOwnerProfile: onOpenOwnerProfile,
                            onReportItem: onReportItem
                        )
                        SearchResultSection(
                            results: unmatchedResults,
                            bucket: .none,
                            viewerID: viewerID,
                            onStartProposal: onStartProposal,
                            onOpenOwnerProfile: onOpenOwnerProfile,
                            onReportItem: onReportItem
                        )
                    }
                } else {
                    SearchIdleMessage()
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 132)
        }
    }
}

private struct SearchBackButton: View {
    var action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.86), in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}

private struct SearchResultCountHeader: View {
    var resultCount: Int
    var isSearching: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(resultCount)件")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            if isSearching {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
}

struct SearchFilterSheet: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedGroupID: UUID?
    @Binding var selectedMemberID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    @Binding var selectedGoodsTagNames: Set<String>
    @Binding var selectedMeetupDates: [Date]
    @Binding var meetupDateDraft: Date
    @Binding var selectedMeetupPrefecture: String
    var availableGoodsTagNames: [String]
    var onReset: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isMeetupDatePickerExpanded = false
    @State private var isMeetupPrefecturePickerExpanded = false

    private var hasSelectedGroup: Bool {
        selectedGroupID != nil
    }

    var body: some View {
        Form {
            SearchOshiGroupFilterSection(
                groups: appState.oshiGroups,
                selectedGroupID: $selectedGroupID,
                isLoading: appState.isLoadingOshiGroups
            )

            if hasSelectedGroup {
                SearchOshiMemberFilterSection(
                    characters: appState.oshiCharacters,
                    selectedMemberID: $selectedMemberID,
                    isLoading: appState.isLoadingOshiCharacters
                )
            }

            SearchGoodsTypeFilterSection(
                goodsTypes: appState.goodsTypes,
                selectedGoodsTypeID: $selectedGoodsTypeID,
                isLoading: appState.isLoadingGoodsTypes
            )

            if hasSelectedGroup {
                SearchGoodsTagFilterSection(
                    tagNames: availableGoodsTagNames,
                    selectedTags: $selectedGoodsTagNames
                )
            }

            SearchMeetupDateFilterSection(
                selectedDates: $selectedMeetupDates,
                draft: $meetupDateDraft,
                isExpanded: $isMeetupDatePickerExpanded,
                onAddDate: addMeetupDate,
                onRemoveDate: removeMeetupDate
            )

            SearchMeetupPrefectureFilterSection(
                selectedPrefecture: $selectedMeetupPrefecture,
                isExpanded: $isMeetupPrefecturePickerExpanded
            )

            SearchFilterResetSection(onReset: onReset)
        }
        .navigationTitle("検索フィルター")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完了") {
                    dismiss()
                }
            }
        }
    }

    private func addMeetupDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard !selectedMeetupDates.contains(normalizedDate) else {
            return
        }
        selectedMeetupDates.append(normalizedDate)
        selectedMeetupDates.sort()
    }

    private func removeMeetupDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        selectedMeetupDates.removeAll { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
    }
}

private struct SearchOshiGroupFilterSection: View {
    var groups: [OshiGroup]
    @Binding var selectedGroupID: UUID?
    var isLoading: Bool

    var body: some View {
        Section {
            Picker("グループ", selection: $selectedGroupID) {
                Text("すべて").tag(Optional<UUID>.none)
                ForEach(groups) { group in
                    Text(group.name).tag(Optional(group.id))
                }
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            if isLoading {
                ProgressView("グループを読み込み中")
            }
        } header: {
            Text("グループ")
        }
    }
}

private struct SearchOshiMemberFilterSection: View {
    var characters: [OshiCharacter]
    @Binding var selectedMemberID: UUID?
    var isLoading: Bool

    var body: some View {
        Section {
            Picker("メンバー", selection: $selectedMemberID) {
                Text("グループ全体").tag(Optional<UUID>.none)
                ForEach(characters) { character in
                    Text(character.name).tag(Optional(character.id))
                }
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            if isLoading {
                ProgressView("メンバーを読み込み中")
            }
        } header: {
            Text("メンバー")
        }
    }
}

private struct SearchGoodsTypeFilterSection: View {
    var goodsTypes: [GoodsType]
    @Binding var selectedGoodsTypeID: UUID?
    var isLoading: Bool

    var body: some View {
        Section {
            Picker("グッズ種別", selection: $selectedGoodsTypeID) {
                Text("すべて").tag(Optional<UUID>.none)
                ForEach(goodsTypes) { goodsType in
                    Text(goodsType.name).tag(Optional(goodsType.id))
                }
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            if isLoading {
                ProgressView("グッズ種別を読み込み中")
            }
        } header: {
            Text("グッズ種別")
        }
    }
}

private struct SearchGoodsTagFilterSection: View {
    var tagNames: [String]
    @Binding var selectedTags: Set<String>

    var body: some View {
        Section {
            if tagNames.isEmpty {
                Text("このグループに紐づくタグ候補はまだありません。")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            } else {
                SearchWrappingTagPicker(
                    tags: tagNames,
                    selectedTags: $selectedTags
                )
                .padding(.vertical, 4)
            }
        } header: {
            Text("グッズタグ")
        } footer: {
            Text("最大20件まで表示します。")
        }
    }
}

private struct SearchMeetupDateFilterSection: View {
    @Binding var selectedDates: [Date]
    @Binding var draft: Date
    @Binding var isExpanded: Bool
    var onAddDate: (Date) -> Void
    var onRemoveDate: (Date) -> Void

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                DatePicker("日付を追加", selection: $draft, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                Button {
                    onAddDate(draft)
                } label: {
                    Label("この日付を追加", systemImage: "calendar.badge.plus")
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
            } label: {
                HStack {
                    Text("現地交換日付")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                    Spacer()
                    Text(selectedDates.isEmpty ? "選択" : "\(selectedDates.count)件")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }

            if selectedDates.isEmpty {
                Text("指定なし")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            } else {
                ForEach(selectedDates, id: \.self) { date in
                    HStack {
                        Text(searchFilterDateText(date))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Spacer()
                        Button {
                            onRemoveDate(date)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(MegrumTheme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            Text("現地交換日付")
        }
    }
}

private struct SearchMeetupPrefectureFilterSection: View {
    @Binding var selectedPrefecture: String
    @Binding var isExpanded: Bool

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                Picker("都道府県", selection: $selectedPrefecture) {
                    Text("指定なし").tag("")
                    ForEach(searchFilterJapanesePrefectures, id: \.self) { prefecture in
                        Text(prefecture).tag(prefecture)
                    }
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif
            } label: {
                HStack {
                    Text("現地交換場所")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                    Spacer()
                    Text(selectedPrefecture.isEmpty ? "選択" : selectedPrefecture)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
        } header: {
            Text("現地交換場所")
        }
    }
}

private struct SearchFilterResetSection: View {
    var onReset: () -> Void

    var body: some View {
        Section {
            Button("すべてリセット", role: .destructive) {
                onReset()
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
        }
    }
}

private struct SearchWrappingTagPicker: View {
    var tags: [String]
    @Binding var selectedTags: Set<String>

    private let columns = [GridItem(.adaptive(minimum: 118), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                SearchFilterChip(title: tag, isSelected: selectedTags.contains(tag)) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
    }
}

private struct SearchFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 18)
                .frame(minHeight: 46)
                .background(isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.regularMaterial), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(isSelected ? 0.7 : 0.45), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct SearchResultSection: View {
    var results: [SearchResultItem]
    var bucket: SearchMatchBucket
    var viewerID: UUID?
    var onStartProposal: (GoodsItem) -> Void
    var onOpenOwnerProfile: (UUID) -> Void
    var onReportItem: (GoodsItem, GoodsReportReason, String) -> Void

    var body: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(bucket.displayName)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Text("\(results.count)件")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                GoodsGrid(
                    items: results.map(\.item),
                    viewerID: viewerID,
                    onOpenOwnerProfile: onOpenOwnerProfile,
                    onAddToExchangeList: onStartProposal,
                    onReportItem: onReportItem
                )
            }
        }
    }
}

struct SearchEmptyMessage: View {
    var body: some View {
        Text("検索に合うグッズがありません")
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 1)
            }
    }
}

struct SearchIdleMessage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("条件を入れて検索")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            } icon: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            Text("キーワードを入力するか、絞り込みでグループやグッズ種別を選ぶと結果を表示します。")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        }
    }
}

struct SearchResultSkeleton: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.76), lineWidth: 1)
                    )
                    .aspectRatio(0.78, contentMode: .fit)
                    .redacted(reason: .placeholder)
            }
        }
    }
}
