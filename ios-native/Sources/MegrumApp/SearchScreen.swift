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

struct SearchScreen: View {
    @ObservedObject var appState: MegrumAppState

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedGroupID: UUID?
    @State private var selectedMemberID: UUID?
    @State private var selectedGoodsTypeID: UUID?
    @State private var selectedGoodsTagNames: Set<String> = []
    @State private var selectedMeetupDates: [Date] = []
    @State private var meetupDateDraft = Date()
    @State private var selectedMeetupPrefecture = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var proposalTargetItem: GoodsItem?
    @State private var profileRoute: PublicProfileRoute?
    @State private var isShowingFilters = false

    private var resultCount: Int {
        filteredSearchResults.count
    }

    private func results(in bucket: SearchMatchBucket) -> [SearchResultItem] {
        filteredSearchResults.filter { $0.bucket == bucket }
    }

    private var filteredSearchResults: [SearchResultItem] {
        appState.searchResults.filter { result in
            if let selectedMemberID, result.item.memberID != selectedMemberID {
                return false
            }
            if !selectedGoodsTagNames.isEmpty {
                let itemTagNames = Set(result.item.tags.map(\.name))
                if !selectedGoodsTagNames.isSubset(of: itemTagNames) {
                    return false
                }
            }
            return true
        }
    }

    private var selectedGroup: OshiGroup? {
        guard let selectedGroupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == selectedGroupID }
    }

    private var selectedMember: OshiCharacter? {
        guard let selectedMemberID else {
            return nil
        }
        return appState.oshiCharacters.first { $0.id == selectedMemberID }
    }

    private var selectedGoodsType: GoodsType? {
        guard let selectedGoodsTypeID else {
            return nil
        }
        return appState.goodsTypes.first { $0.id == selectedGoodsTypeID }
    }

    private var availableGoodsTagNames: [String] {
        let tags = appState.searchResults
            .filter { result in
                selectedGroupID == nil || result.item.groupID == selectedGroupID
            }
            .flatMap { $0.item.tags.map(\.name) }
        return Array(Set(tags))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .prefix(20)
            .map { $0 }
    }

    private var activeFilterCount: Int {
        var count = 0
        if selectedGroupID != nil { count += 1 }
        if selectedMemberID != nil { count += 1 }
        if selectedGoodsTypeID != nil { count += 1 }
        count += selectedGoodsTagNames.count
        if !selectedMeetupDates.isEmpty { count += 1 }
        if !selectedMeetupPrefecture.isEmpty { count += 1 }
        return count
    }

    private var filterSummaryTitles: [String] {
        var titles: [String] = []
        if let selectedGroup {
            titles.append(selectedGroup.name)
        }
        if let selectedMember {
            titles.append(selectedMember.name)
        }
        if let selectedGoodsType {
            titles.append(selectedGoodsType.name)
        }
        titles.append(contentsOf: selectedGoodsTagNames.sorted())
        if !selectedMeetupDates.isEmpty {
            titles.append("日付\(selectedMeetupDates.count)件")
        }
        if !selectedMeetupPrefecture.isEmpty {
            titles.append(selectedMeetupPrefecture)
        }
        return titles
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
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

                    Text("検索")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)

                    SearchFilterSummaryBar(
                        activeFilterCount: activeFilterCount,
                        summaryTitles: filterSummaryTitles
                    ) {
                        isShowingFilters = true
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(resultCount)件")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        if appState.isSearchingGoods {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    if appState.isSearchingGoods && appState.searchResults.isEmpty {
                        SearchResultSkeleton()
                    } else if filteredSearchResults.isEmpty {
                        SearchEmptyMessage()
                    } else {
                        SearchResultSection(results: results(in: .matched), bucket: .matched, viewerID: appState.viewer?.id) { item in
                            proposalTargetItem = item
                        } onOpenOwnerProfile: { userID in
                            profileRoute = PublicProfileRoute(userID: userID)
                        } onReportItem: { item, reason, note in
                            reportItem(item, reason: reason, note: note)
                        }
                        SearchResultSection(results: results(in: .possible), bucket: .possible, viewerID: appState.viewer?.id) { item in
                            proposalTargetItem = item
                        } onOpenOwnerProfile: { userID in
                            profileRoute = PublicProfileRoute(userID: userID)
                        } onReportItem: { item, reason, note in
                            reportItem(item, reason: reason, note: note)
                        }
                        SearchResultSection(results: results(in: .none), bucket: .none, viewerID: appState.viewer?.id) { item in
                            proposalTargetItem = item
                        } onOpenOwnerProfile: { userID in
                            profileRoute = PublicProfileRoute(userID: userID)
                        } onReportItem: { item, reason, note in
                            reportItem(item, reason: reason, note: note)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 132)
            }

            SearchFooterBar(
                query: $query,
                activeFilterCount: activeFilterCount,
                onFilterTap: {
                    isShowingFilters = true
                }
            ) {
                scheduleSearch(delayNanoseconds: 0)
            }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .task {
            await loadFiltersAndSearch()
        }
        .onChange(of: query) { _, _ in
            scheduleSearch()
        }
        .onChange(of: selectedGroupID) { _, _ in
            selectedMemberID = nil
            selectedGoodsTypeID = nil
            selectedGoodsTagNames = []
            Task {
                await appState.loadOshiCharacters(group: selectedGroup)
            }
            scheduleSearch(delayNanoseconds: 0)
        }
        .onChange(of: selectedGoodsTypeID) { _, _ in
            scheduleSearch(delayNanoseconds: 0)
        }
        .onChange(of: selectedMemberID) { _, _ in
            scheduleSearch(delayNanoseconds: 0)
        }
        .onDisappear {
            searchTask?.cancel()
        }
        .sheet(item: $proposalTargetItem) { item in
            NavigationStack {
                ProposalCreateSheet(appState: appState, targetItem: item)
            }
        }
        .sheet(item: $profileRoute) { route in
            NavigationStack {
                PublicUserProfileScreen(appState: appState, userID: route.userID)
            }
        }
        .sheet(isPresented: $isShowingFilters) {
            NavigationStack {
                SearchFilterSheet(
                    appState: appState,
                    selectedGroupID: $selectedGroupID,
                    selectedMemberID: $selectedMemberID,
                    selectedGoodsTypeID: $selectedGoodsTypeID,
                    selectedGoodsTagNames: $selectedGoodsTagNames,
                    selectedMeetupDates: $selectedMeetupDates,
                    meetupDateDraft: $meetupDateDraft,
                    selectedMeetupPrefecture: $selectedMeetupPrefecture,
                    availableGoodsTagNames: availableGoodsTagNames,
                    onReset: resetFilters
                )
            }
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
    }

    private func loadFiltersAndSearch() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        await appState.searchGoods(
            query: query,
            groupID: selectedGroupID,
            memberID: selectedMemberID,
            goodsTypeID: selectedGoodsTypeID
        )
    }

    private func reportItem(_ item: GoodsItem, reason: GoodsReportReason, note: String) {
        Task {
            _ = await appState.reportGoods(
                itemID: item.id,
                reportedUserID: item.ownerID,
                reason: reason,
                note: note
            )
        }
    }

    private func scheduleSearch(delayNanoseconds: UInt64 = 260_000_000) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else {
                return
            }
            await appState.searchGoods(
                query: query,
                groupID: selectedGroupID,
                memberID: selectedMemberID,
                goodsTypeID: selectedGoodsTypeID
            )
        }
    }

    private func resetFilters() {
        selectedGroupID = nil
        selectedMemberID = nil
        selectedGoodsTypeID = nil
        selectedGoodsTagNames = []
        selectedMeetupDates = []
        selectedMeetupPrefecture = ""
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
        scheduleSearch(delayNanoseconds: 0)
    }
}

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
    }
}

private struct SearchFooterBar: View {
    @Binding var query: String
    var activeFilterCount: Int
    var onFilterTap: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onFilterTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 62, height: 62)
                        .background(.regularMaterial, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))

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

private struct SearchFilterSummaryBar: View {
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

private struct SearchFilterSheet: View {
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
            Section {
                Picker("グループ", selection: $selectedGroupID) {
                    Text("すべて").tag(Optional<UUID>.none)
                    ForEach(appState.oshiGroups) { group in
                        Text(group.name).tag(Optional(group.id))
                    }
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif

                if appState.isLoadingOshiGroups {
                    ProgressView("グループを読み込み中")
                }
            } header: {
                Text("グループ")
            }

            if hasSelectedGroup {
                Section {
                    Picker("メンバー", selection: $selectedMemberID) {
                        Text("グループ全体").tag(Optional<UUID>.none)
                        ForEach(appState.oshiCharacters) { character in
                            Text(character.name).tag(Optional(character.id))
                        }
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    #if os(iOS)
                    .pickerStyle(.navigationLink)
                    #endif

                    if appState.isLoadingOshiCharacters {
                        ProgressView("メンバーを読み込み中")
                    }
                } header: {
                    Text("メンバー")
                }
            }

            Section {
                Picker("グッズ種別", selection: $selectedGoodsTypeID) {
                    Text("すべて").tag(Optional<UUID>.none)
                    ForEach(appState.goodsTypes) { goodsType in
                        Text(goodsType.name).tag(Optional(goodsType.id))
                    }
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif

                if appState.isLoadingGoodsTypes {
                    ProgressView("グッズ種別を読み込み中")
                }
            } header: {
                Text("グッズ種別")
            }

            if hasSelectedGroup {
                Section {
                    if availableGoodsTagNames.isEmpty {
                        Text("このグループに紐づくタグ候補はまだありません。")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    } else {
                        SearchWrappingTagPicker(
                            tags: availableGoodsTagNames,
                            selectedTags: $selectedGoodsTagNames
                        )
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("グッズタグ")
                } footer: {
                    Text("最大20件まで表示します。")
                }
            }

            Section {
                DisclosureGroup(isExpanded: $isMeetupDatePickerExpanded) {
                    DatePicker("日付を追加", selection: $meetupDateDraft, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    Button {
                        addMeetupDate(meetupDateDraft)
                    } label: {
                        Label("この日付を追加", systemImage: "calendar.badge.plus")
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                } label: {
                    HStack {
                        Text("現地交換日付")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                        Spacer()
                        Text(selectedMeetupDates.isEmpty ? "選択" : "\(selectedMeetupDates.count)件")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                if selectedMeetupDates.isEmpty {
                    Text("指定なし")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                } else {
                    ForEach(selectedMeetupDates, id: \.self) { date in
                        HStack {
                            Text(searchFilterDateText(date))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Spacer()
                            Button {
                                removeMeetupDate(date)
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

            Section {
                DisclosureGroup(isExpanded: $isMeetupPrefecturePickerExpanded) {
                    Picker("都道府県", selection: $selectedMeetupPrefecture) {
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
                        Text(selectedMeetupPrefecture.isEmpty ? "選択" : selectedMeetupPrefecture)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
            } header: {
                Text("現地交換場所")
            }

            Section {
                Button("すべてリセット", role: .destructive) {
                    onReset()
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
            }
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

private struct SearchResultSection: View {
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

struct ProposalCreateSheet: View {
    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSenderGoodsID: UUID?
    @State private var exchangeMethod: ExchangeMethod = .mail
    @State private var selectedConditionTags: Set<String> = []
    @State private var message = ""
    @State private var meetupStartAt = Date()
    @State private var meetupEndAt = Date().addingTimeInterval(30 * 60)
    @State private var meetupPlaceName = ""
    @State private var meetupLatitudeText = ""
    @State private var meetupLongitudeText = ""
    @StateObject private var locationState = MegrumLocationState()

    private var selectedSenderID: UUID? {
        selectedSenderGoodsID ?? appState.inventory.first?.id
    }

    private var resolvedReceiverGoodsIDs: [UUID] {
        var uniqueIDs: [UUID] = []
        let candidateIDs = receiverGoodsIDs ?? [targetItem.id]
        for id in candidateIDs where !uniqueIDs.contains(id) {
            uniqueIDs.append(id)
        }
        return uniqueIDs.isEmpty ? [targetItem.id] : uniqueIDs
    }

    private var configuration: ProposalCreateConfiguration {
        ProposalCreateConfiguration(
            exchangeMethod: exchangeMethod,
            hasSelectedSenderGoods: selectedSenderID != nil,
            isCreatingProposal: appState.isCreatingProposal,
            hasReadyMailingAddress: appState.mailingAddress?.isReady == true,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            hasValidMeetup: meetupInput?.isValid == true,
            receiverGoodsCount: resolvedReceiverGoodsIDs.count,
            isListingSource: listingID != nil
        )
    }

    private var conditionTagOptions: [String] {
        configuration.conditionTagOptions
    }

    private var orderedConditionTags: [String] {
        conditionTagOptions.filter { selectedConditionTags.contains($0) }
    }

    private var meetupInput: ProposalMeetupInput? {
        guard
            let latitude = Self.coordinateValue(from: meetupLatitudeText),
            let longitude = Self.coordinateValue(from: meetupLongitudeText)
        else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupPlaceName,
            latitude: latitude,
            longitude: longitude
        )
        return input.isValid ? input : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROPOSAL")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text("打診を作成")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                }

                proposalTargetCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("私が出す")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    if appState.inventory.isEmpty {
                        Text("在庫を登録すると選択できます")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(appState.inventory) { item in
                                    proposalGoodsChoice(item)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("交換手段")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Picker("交換手段", selection: $exchangeMethod) {
                        ForEach(ExchangeMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let methodNotice = configuration.methodNotice {
                        Text(methodNotice)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if configuration.requiresMeetupBeforeSubmit {
                    ProposalMeetupForm(
                        startAt: $meetupStartAt,
                        endAt: $meetupEndAt,
                        placeName: $meetupPlaceName,
                        latitudeText: $meetupLatitudeText,
                        longitudeText: $meetupLongitudeText,
                        isRequestingLocation: locationState.isRequestingLocation,
                        locationErrorMessage: locationState.locationErrorMessage
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("交換条件タグ")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                        ForEach(conditionTagOptions, id: \.self) { tag in
                            Button {
                                if selectedConditionTags.contains(tag) {
                                    selectedConditionTags.remove(tag)
                                } else {
                                    selectedConditionTags.insert(tag)
                                }
                            } label: {
                                Text(tag)
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundStyle(selectedConditionTags.contains(tag) ? .white : MegrumTheme.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(
                                        selectedConditionTags.contains(tag)
                                            ? AnyShapeStyle(MegrumTheme.lavender)
                                            : AnyShapeStyle(.regularMaterial),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("メッセージ")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    TextField("よろしくお願いします", text: $message, axis: .vertical)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(3...6)
                        .padding(16)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                Button {
                    Task {
                        await createProposal()
                    }
                } label: {
                    HStack {
                        if appState.isCreatingProposal {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(configuration.submitTitle)
                    }
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!configuration.canSubmit)
                .opacity(configuration.canSubmit ? 1 : 0.48)
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("打診作成")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .onAppear {
            selectedSenderGoodsID = selectedSenderID
            if meetupEndAt <= meetupStartAt {
                meetupEndAt = meetupStartAt.addingTimeInterval(30 * 60)
            }
            requestLocationIfNeeded()
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
        }
        .onChange(of: exchangeMethod) { _, _ in
            selectedConditionTags = selectedConditionTags.intersection(Set(conditionTagOptions))
            requestLocationIfNeeded()
        }
        .onChange(of: meetupStartAt) { _, newValue in
            if meetupEndAt <= newValue {
                meetupEndAt = newValue.addingTimeInterval(30 * 60)
            }
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            guard let coordinate, configuration.requiresMeetupBeforeSubmit else {
                return
            }
            if meetupPlaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                meetupPlaceName = "現在地"
            }
            if meetupLatitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                meetupLatitudeText = Self.coordinateText(coordinate.latitude)
            }
            if meetupLongitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                meetupLongitudeText = Self.coordinateText(coordinate.longitude)
            }
        }
    }

    private var proposalTargetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("受け取る")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MegrumTheme.sky.opacity(0.24))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(targetItem.title)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(2)
                    Text(configuration.targetSubtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    if let targetSupplement = configuration.targetSupplement {
                        Text(targetSupplement)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.72), lineWidth: 1))
        }
    }

    private func proposalGoodsChoice(_ item: GoodsItem) -> some View {
        Button {
            selectedSenderGoodsID = item.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.2))
                    .frame(width: 98, height: 116)
                    .overlay {
                        Image(systemName: selectedSenderGoodsID == item.id ? "checkmark.circle.fill" : "photo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(selectedSenderGoodsID == item.id ? MegrumTheme.lavender : .white)
                    }

                Text(item.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .frame(width: 98, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func createProposal() async {
        guard let selectedSenderID, let targetStatus = configuration.targetStatus else {
            return
        }
        let meetup = configuration.requiresMeetupBeforeSubmit ? meetupInput : nil
        guard !configuration.requiresMeetupBeforeSubmit || meetup != nil else {
            return
        }
        let created = await appState.createProposal(
            ProposalCreateInput(
                receiverID: targetItem.ownerID,
                senderGoodsIDs: [selectedSenderID],
                receiverGoodsIDs: resolvedReceiverGoodsIDs,
                exchangeMethod: exchangeMethod,
                conditionTags: orderedConditionTags,
                message: message,
                status: targetStatus,
                meetup: meetup,
                listingID: listingID
            )
        )
        if created {
            dismiss()
        }
    }

    private static func coordinateValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func coordinateText(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private func requestLocationIfNeeded() {
        guard configuration.requiresMeetupBeforeSubmit else {
            return
        }
        locationState.requestCurrentLocation()
    }
}

private struct ProposalMeetupForm: View {
    @Binding var startAt: Date
    @Binding var endAt: Date
    @Binding var placeName: String
    @Binding var latitudeText: String
    @Binding var longitudeText: String
    var isRequestingLocation: Bool
    var locationErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("待ち合わせ候補")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                if isRequestingLocation {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            VStack(spacing: 0) {
                DatePicker("開始日時", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    .proposalMeetupRow()
                Divider()
                DatePicker("終了日時", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    .proposalMeetupRow()
                Divider()
                TextField("場所名", text: $placeName)
                    .proposalMeetupRow()
                Divider()
                HStack(spacing: 12) {
                    TextField("緯度", text: $latitudeText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("経度", text: $longitudeText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .proposalMeetupRow()
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.68), lineWidth: 1)
            }

            if let locationErrorMessage {
                Text(locationErrorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

private extension View {
    func proposalMeetupRow() -> some View {
        self
            .frame(minHeight: 48)
            .padding(.vertical, 6)
    }
}

struct ProposalCreateConfiguration: Equatable {
    var exchangeMethod: ExchangeMethod
    var hasSelectedSenderGoods: Bool
    var isCreatingProposal: Bool
    var hasReadyMailingAddress: Bool
    var isLoadingMailingAddress: Bool
    var hasValidMeetup: Bool = false
    var receiverGoodsCount: Int
    var isListingSource: Bool

    private static let mailConditionTags = ["即日発送", "同日発送"]
    private static let handConditionTags = ["終演後OK", "グッズ販売中OK"]

    var conditionTagOptions: [String] {
        switch exchangeMethod {
        case .hand:
            Self.handConditionTags
        case .mail:
            Self.mailConditionTags
        case .both:
            Self.handConditionTags + Self.mailConditionTags
        }
    }

    var requiresMeetupBeforeSubmit: Bool {
        exchangeMethod == .hand || exchangeMethod == .both
    }

    var requiresMailingAddressBeforeSubmit: Bool {
        exchangeMethod == .mail || exchangeMethod == .both
    }

    var canSubmit: Bool {
        hasSelectedSenderGoods && !isCreatingProposal && !isLoadingMailingAddress && targetStatus != nil
    }

    var targetStatus: ProposalStatus? {
        if requiresMailingAddressBeforeSubmit && !hasReadyMailingAddress {
            return nil
        }
        if requiresMeetupBeforeSubmit && !hasValidMeetup {
            return nil
        }
        return .sent
    }

    var submitTitle: String {
        if requiresMailingAddressBeforeSubmit && !hasReadyMailingAddress {
            return "住所登録が必要"
        }
        if requiresMeetupBeforeSubmit && !hasValidMeetup {
            return "待ち合わせ入力が必要"
        }
        return "この内容で打診を送る"
    }

    var methodNotice: String? {
        if requiresMailingAddressBeforeSubmit && isLoadingMailingAddress {
            return "住所登録を確認しています。"
        }
        if requiresMailingAddressBeforeSubmit && !hasReadyMailingAddress {
            return "郵送交換は住所登録が必要です。設定から住所を登録してください。"
        }
        if requiresMeetupBeforeSubmit && !hasValidMeetup {
            return "現地交換は待ち合わせ候補を入力すると送信できます。"
        }
        return nil
    }

    var targetSubtitle: String {
        isListingSource ? "個別募集から選択" : "相手の在庫から選択"
    }

    var targetSupplement: String? {
        guard isListingSource, receiverGoodsCount > 1 else {
            return nil
        }
        return "ほか\(receiverGoodsCount - 1)件も受け取る条件です"
    }
}

private struct SearchEmptyMessage: View {
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

private struct SearchResultSkeleton: View {
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
