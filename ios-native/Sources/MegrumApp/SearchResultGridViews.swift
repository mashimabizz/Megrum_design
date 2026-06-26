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
        .megrumSlideItemPresentation(item: $selectedSheet) { sheet, _ in
            HomeDiscoverySheetView(
                sheet: sheet,
                appState: appState,
                viewerOfferGoods: viewerOfferGoods,
                onOpenOwnerProfile: requestProfilePresentation,
                onStartProposal: requestProposalPresentation
            )
            .megrumInteractiveBackSwipe {
                selectedSheet = nil
            }
        }
        .onChange(of: selectedSheet?.id) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                presentPendingProfileIfNeeded()
            }
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
