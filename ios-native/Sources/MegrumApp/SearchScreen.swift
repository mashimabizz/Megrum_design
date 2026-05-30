import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchScreen: View {
    @ObservedObject var appState: MegrumAppState

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedGroupID: UUID?
    @State private var selectedGoodsTypeID: UUID?
    @State private var searchTask: Task<Void, Never>?

    private var resultCount: Int {
        appState.searchResults.count
    }

    private func results(in bucket: SearchMatchBucket) -> [SearchResultItem] {
        appState.searchResults.filter { $0.bucket == bucket }
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

                    SearchFilterBar(
                        appState: appState,
                        selectedGroupID: $selectedGroupID,
                        selectedGoodsTypeID: $selectedGoodsTypeID
                    )

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
                    } else if appState.searchResults.isEmpty {
                        SearchEmptyMessage()
                    } else {
                        SearchResultSection(results: results(in: .matched), bucket: .matched)
                        SearchResultSection(results: results(in: .possible), bucket: .possible)
                        SearchResultSection(results: results(in: .none), bucket: .none)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 132)
            }

            SearchInputBar(query: $query) {
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
            scheduleSearch(delayNanoseconds: 0)
        }
        .onChange(of: selectedGoodsTypeID) { _, _ in
            scheduleSearch(delayNanoseconds: 0)
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func loadFiltersAndSearch() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        await appState.searchGoods(query: query, groupID: selectedGroupID, goodsTypeID: selectedGoodsTypeID)
    }

    private func scheduleSearch(delayNanoseconds: UInt64 = 260_000_000) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else {
                return
            }
            await appState.searchGoods(query: query, groupID: selectedGroupID, goodsTypeID: selectedGoodsTypeID)
        }
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
        .frame(height: 62)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}

private struct SearchFilterBar: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchFilterRow(title: "グループ", isLoading: appState.isLoadingOshiGroups) {
                SearchFilterChip(title: "すべて", isSelected: selectedGroupID == nil) {
                    selectedGroupID = nil
                }
                ForEach(appState.oshiGroups) { group in
                    SearchFilterChip(title: group.name, isSelected: selectedGroupID == group.id) {
                        selectedGroupID = group.id
                    }
                }
            }

            SearchFilterRow(title: "グッズ種別", isLoading: appState.isLoadingGoodsTypes) {
                SearchFilterChip(title: "すべて", isSelected: selectedGoodsTypeID == nil) {
                    selectedGoodsTypeID = nil
                }
                ForEach(appState.goodsTypes) { goodsType in
                    SearchFilterChip(title: goodsType.name, isSelected: selectedGoodsTypeID == goodsType.id) {
                        selectedGoodsTypeID = goodsType.id
                    }
                }
            }
        }
    }
}

private struct SearchFilterRow<Content: View>: View {
    var title: String
    var isLoading: Bool
    var content: Content

    init(title: String, isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isLoading = isLoading
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    content
                }
                .padding(.vertical, 2)
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
                .padding(.horizontal, 16)
                .frame(height: 42)
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

                GoodsGrid(items: results.map(\.item))
            }
        }
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
