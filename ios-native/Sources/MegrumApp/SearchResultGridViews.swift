import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchResultGrid: View {
    var results: [SearchResultItem]
    var appState: MegrumAppState?
    var viewerID: UUID?
    var onStartProposal: (GoodsItem) -> Void
    var onOpenOwnerProfile: (UUID) -> Void
    var onReportItem: (GoodsItem, GoodsReportReason, String) -> Void

    @State private var selectedSheet: HomeDiscoverySheet?
    @State private var pendingProfileUserID: UUID?
    @State private var reportTargetItem: GoodsItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                SearchResultGridCard(
                    item: result.item,
                    goods: homeGoods(for: result.item, index: index),
                    conditionTags: conditionTags(for: result, index: index),
                    viewerID: viewerID,
                    onOpen: {
                        selectedSheet = SearchResultHomePresentation.sheet(
                            for: result,
                            index: index,
                            goodsTypes: appState?.goodsTypes ?? [],
                            explicitSignals: appState?.homeCandidateConditionSignals ?? [:]
                        )
                    },
                    onReport: {
                        reportTargetItem = result.item
                    }
                )
            }
        }
        .sheet(
            item: $selectedSheet,
            onDismiss: presentPendingProfileIfNeeded
        ) { sheet in
            HomeDiscoverySheetView(
                sheet: sheet,
                appState: appState,
                viewerOfferGoods: viewerOfferGoods,
                onOpenOwnerProfile: requestProfilePresentation,
                onStartProposal: requestProposalPresentation
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $reportTargetItem) { item in
            NavigationStack {
                GoodsReportSheet(item: item) { reason, note in
                    onReportItem(item, reason, note)
                    reportTargetItem = nil
                }
            }
        }
    }

    private var viewerOfferGoods: [HomeMockGoods] {
        guard let viewerID else {
            return []
        }
        return (appState?.inventory ?? [])
            .filter { item in
                item.ownerID == viewerID && item.marketAvailableQuantity > 0
            }
            .enumerated()
            .map { index, item in
                HomeMockGoods.from(item: item, index: index, goodsTypes: appState?.goodsTypes ?? [])
            }
    }

    private func homeGoods(for item: GoodsItem, index: Int) -> HomeMockGoods {
        HomeMockGoods.from(item: item, index: index, goodsTypes: appState?.goodsTypes ?? [])
    }

    private func conditionTags(for result: SearchResultItem, index: Int) -> HomeConditionTagSet {
        HomeConditionTagSet(
            signals: SearchResultHomePresentation.signals(
                for: result,
                index: index,
                explicitSignals: appState?.homeCandidateConditionSignals ?? [:]
            )
        )
    }

    private func requestProposalPresentation(_ selection: HomeDiscoveryProposalSelection) {
        selectedSheet = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            if let item = proposalTargetItem(for: selection) {
                onStartProposal(item)
            }
        }
    }

    private func requestProfilePresentation(_ userID: UUID) {
        pendingProfileUserID = userID
        selectedSheet = nil
    }

    private func presentPendingProfileIfNeeded() {
        guard let pendingProfileUserID else {
            return
        }
        self.pendingProfileUserID = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onOpenOwnerProfile(pendingProfileUserID)
        }
    }

    private func proposalTargetItem(for selection: HomeDiscoveryProposalSelection) -> GoodsItem? {
        results.first { result in
            result.item.id == selection.receiverGoodsID && result.item.ownerID != viewerID
        }?.item
        ?? results.first { result in
            result.item.ownerID != viewerID
        }?.item
    }
}

private struct SearchResultGridCard: View {
    var item: GoodsItem
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet
    var viewerID: UUID?
    var onOpen: () -> Void
    var onReport: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 7) {
                HomeGoodsArtwork(goods: goods)
                    .aspectRatio(0.82, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: MegrumTheme.ink.opacity(0.11), radius: 11, y: 7)

                SearchResultConditionTags(tags: conditionTags)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if item.ownerID != viewerID {
                Button(role: .destructive) {
                    onReport()
                } label: {
                    Label("通報する", systemImage: "exclamationmark.bubble")
                }
            }
        }
        .accessibilityLabel(item.title)
        .accessibilityHint("詳細を開きます")
    }
}

private struct SearchResultConditionTags: View {
    var tags: HomeConditionTagSet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                SearchResultMiniConditionPill(title: tags.goods.floatingTagTitle, color: tags.goods.accent)
                if tags.homeCandidateShowsExchangeTag {
                    SearchResultMiniConditionPill(title: tags.exchange.floatingTagTitle, color: tags.exchange.accent)
                }
            }
            SearchResultMiniConditionPill(title: tags.payment.floatingTagTitle, color: tags.payment.accent)
        }
        .accessibilityLabel(tags.homeCandidateAccessibilityText)
    }
}

private struct SearchResultMiniConditionPill: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 9.5, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.white.opacity(0.86), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.24), lineWidth: 1)
            }
    }
}

enum SearchResultHomePresentation {
    static func signals(
        for result: SearchResultItem,
        index: Int,
        explicitSignals: [UUID: HomeCandidateConditionSignals]
    ) -> HomeCandidateConditionSignals {
        explicitSignals[result.item.id] ?? fallbackSignals(for: result.bucket, index: index)
    }

    static func sheet(
        for result: SearchResultItem,
        index: Int,
        goodsTypes: [GoodsType],
        explicitSignals: [UUID: HomeCandidateConditionSignals]
    ) -> HomeDiscoverySheet {
        let signals = signals(for: result, index: index, explicitSignals: explicitSignals)
        let payload = HomeDiscoverySheetPayload(
            goods: HomeMockGoods.from(item: result.item, index: index, goodsTypes: goodsTypes),
            signals: signals
        )
        switch HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) {
        case .direct:
            return .goodsHit(payload)
        case .wish, .none:
            return .wishHit(payload)
        }
    }

    private static func fallbackSignals(for bucket: SearchMatchBucket, index: Int) -> HomeCandidateConditionSignals {
        switch bucket {
        case .matched:
            HomeCandidateConditionSignalDefaults.matched(index: index)
        case .possible:
            HomeCandidateConditionSignalDefaults.possible(index: index)
        case .none:
            HomeCandidateConditionSignalDefaults.noEvidence
        }
    }
}
