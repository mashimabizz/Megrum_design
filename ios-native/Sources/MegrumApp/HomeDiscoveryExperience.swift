import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryExperience: View {
    var viewer: UserProfile?
    var inventoryItems: [GoodsItem] = []
    var matchedItems: [GoodsItem] = []
    var possibleItems: [GoodsItem] = []
    var goodsTypes: [GoodsType] = []
    var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]
    var isLoading: Bool
    var opensInitialHavesLookup: Bool = false
    var onOpenSettings: () -> Void
    var onOpenSearch: () -> Void
    var onRefresh: () async -> Void

    @State private var selectedSheet: HomeDiscoverySheet?
    @State private var didOpenInitialSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                HomeDiscoverySection(
                    title: "ユーザー×タグでマッチ",
                    candidates: userTagCandidates,
                    layout: .grid,
                    onSelect: { selectedSheet = $0 }
                )

                HomeDiscoverySection(
                    title: "ユーザーでマッチ",
                    candidates: userCandidates,
                    layout: .grid,
                    onSelect: { selectedSheet = $0 }
                )

                HomeDiscoverySection(
                    title: "譲るものから見る",
                    candidates: havesCandidates,
                    layout: .rail,
                    onSelect: { selectedSheet = $0 }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 34)
        }
        .refreshable {
            await onRefresh()
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .tint(MegrumTheme.lavender)
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .sheet(item: $selectedSheet) { sheet in
            HomeDiscoverySheetView(
                sheet: sheet,
                onOpenNestedSheet: { selectedSheet = $0 }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            openInitialSheetIfNeeded()
        }
    }

    private var userTagCandidates: [HomeDiscoveryCandidate] {
        let items = partnerItems(from: matchedItems + possibleItems)
            .filter { $0.memberID != nil && !$0.tags.isEmpty }
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: Array(items.prefix(4)),
            source: .userTag,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: conditionSignalsByItemID
        )
        return candidates.isEmpty ? HomeDiscoveryFixtures.userTagCandidates : candidates
    }

    private var userCandidates: [HomeDiscoveryCandidate] {
        let usedIDs = Set(userTagCandidates.map(\.id))
        let items = partnerItems(from: matchedItems + possibleItems)
            .filter { !usedIDs.contains($0.id) }
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: Array(items.prefix(4)),
            source: .user,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: conditionSignalsByItemID
        )
        return candidates.isEmpty ? HomeDiscoveryFixtures.userCandidates : candidates
    }

    private var havesCandidates: [HomeDiscoveryCandidate] {
        let inventoryViewerItems = ownItems(from: inventoryItems)
        let viewerItems = inventoryViewerItems.isEmpty ? ownItems(from: matchedItems + possibleItems) : inventoryViewerItems
        let sourceItems = viewerItems.isEmpty ? possibleItems : viewerItems
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: Array(sourceItems.prefix(8)),
            source: .haves,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: conditionSignalsByItemID
        )
        return candidates.isEmpty ? HomeDiscoveryFixtures.havesCandidates : candidates
    }

    private func partnerItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return deduplicated(items)
        }
        return deduplicated(items.filter { $0.ownerID != viewerID })
    }

    private func ownItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return []
        }
        return deduplicated(items.filter { $0.ownerID == viewerID })
    }

    private func openInitialSheetIfNeeded() {
        guard opensInitialHavesLookup, !didOpenInitialSheet else {
            return
        }
        didOpenInitialSheet = true
        selectedSheet = .havesLookup
    }

    private func deduplicated(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }

    private var header: some View {
        HStack {
            Button(action: onOpenSettings) {
                HomeDiscoveryViewerAvatar(viewer: viewer)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("メニューを開く")

            Spacer()

            Text("Megurum")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.vertical, 2)
    }
}
