import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchResultGrid: View {
    var results: [SearchResultItem]
    var appState: MegrumAppState?
    var viewerID: UUID?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var adConfiguration: AdRuntimeConfiguration = .current()
    var onStartProposal: (GoodsItem) -> Void
    var onOpenOwnerProfile: (UUID) -> Void
    var onReportItem: (GoodsItem, GoodsReportReason, String) -> Void

    @State private var selectedSheet: HomeDiscoverySheet?
    @State private var pendingProfileUserID: UUID?
    @State private var reportTargetItem: GoodsItem?

    var body: some View {
        Grid(horizontalSpacing: SearchResultGridMetrics.columnSpacing, verticalSpacing: SearchResultGridMetrics.rowSpacing) {
            ForEach(displayRows) { row in
                GridRow(alignment: .top) {
                    ForEach(row.cells) { cell in
                        gridCell(for: cell.entry)
                            .gridCellColumns(cell.columnSpan)
                    }
                }
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

    private var displayEntries: [SearchResultGridEntry] {
        SearchResultAdInsertion.entries(
            for: results,
            includesNativeAds: nativeAdDecision.isAllowed
        )
    }

    private var displayRows: [SearchResultGridRow] {
        SearchResultGridLayout.rows(for: displayEntries)
    }

    private var nativeAdDecision: AdDisplayDecision {
        AdDisplayPolicy.decision(
            for: .searchResultsNative,
            context: adDisplayContext,
            configuration: adConfiguration
        )
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

    @ViewBuilder
    private func gridCell(for entry: SearchResultGridEntry) -> some View {
        switch entry {
        case let .goods(index, result):
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
        case .nativeAd:
            AdNativeSlot(
                placement: .searchResultsNative,
                displayContext: adDisplayContext,
                configuration: adConfiguration,
                presentation: .searchResultsGrid
            )
        }
    }
}
