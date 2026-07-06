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

    var sort: SearchResultSort = .demand
    @State private var presentationState = SearchResultGridPresentationState()
    /// 20件ずつの追い読み。
    @State private var visibleRowLimit = 20

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(listEntries) { entry in
                listEntryView(entry)
            }

            if hasMoreRows {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        visibleRowLimit += 20
                    }
            }
        }
        .sheet(
            item: $presentationState.selectedSheet,
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
        .sheet(item: $presentationState.reportTargetItem) { item in
            NavigationStack {
                GoodsReportSheet(item: item) { reason, note in
                    onReportItem(item, reason, note)
                    presentationState.clearReport()
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

    private var demandSections: [SearchDemandSection] {
        SearchResultDemandListBuilder.sections(
            results: results,
            signals: appState?.homeCandidateConditionSignals ?? [:],
            sort: sort
        )
    }

    /// 追い読み分だけ行を残したセクション。
    private var visibleSections: [SearchDemandSection] {
        var remaining = visibleRowLimit
        var sections: [SearchDemandSection] = []
        for section in demandSections {
            guard remaining > 0 else {
                break
            }
            let rows = Array(section.rows.prefix(remaining))
            remaining -= rows.count
            sections.append(SearchDemandSection(groupTitle: section.groupTitle, rows: rows))
        }
        return sections
    }

    private var hasMoreRows: Bool {
        results.count > visibleRowLimit
    }

    private var listEntries: [SearchDemandListEntry] {
        SearchResultDemandListBuilder.entries(
            sections: visibleSections,
            includesAds: nativeAdDecision.isAllowed
        )
    }

    private var viewerGoodsImageURLByID: [UUID: URL] {
        guard let viewerID else {
            return [:]
        }
        return Dictionary(
            (appState?.inventory ?? [])
                .filter { $0.ownerID == viewerID }
                .compactMap { item in
                    item.imageURL.map { (item.id, $0) }
                },
            uniquingKeysWith: { first, _ in first }
        )
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
        presentationState.requestProposalPresentation()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            if let item = proposalTargetItem(for: selection) {
                onStartProposal(item)
            }
        }
    }

    private func requestProfilePresentation(_ userID: UUID) {
        presentationState.requestProfilePresentation(userID: userID)
    }

    private func presentPendingProfileIfNeeded() {
        guard let pendingProfileUserID = presentationState.consumePendingProfileUserID() else {
            return
        }
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
    private func listEntryView(_ entry: SearchDemandListEntry) -> some View {
        switch entry {
        case .groupHeader(let title):
            Text(title)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.top, 6)
        case .row(let row):
            VStack(alignment: .leading, spacing: 5) {
                if let subheading = row.subheading {
                    Text(subheading)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                        .lineLimit(1)
                }
                SearchResultDemandRow(
                    goods: homeGoods(for: row.result.item, index: row.index),
                    signals: SearchResultHomePresentation.signals(
                        for: row.result,
                        index: row.index,
                        explicitSignals: appState?.homeCandidateConditionSignals ?? [:]
                    ),
                    viewerGoodsImageURLByID: viewerGoodsImageURLByID,
                    onOpen: {
                        presentationState.showSheet(
                            SearchResultHomePresentation.sheet(
                                for: row.result,
                                index: row.index,
                                goodsTypes: appState?.goodsTypes ?? [],
                                explicitSignals: appState?.homeCandidateConditionSignals ?? [:]
                            )
                        )
                    }
                )
                .contextMenu {
                    Button(role: .destructive) {
                        presentationState.showReport(item: row.result.item)
                    } label: {
                        Label("通報する", systemImage: "exclamationmark.bubble")
                    }
                }
            }
        case .ad:
            AdNativeSlot(
                placement: .searchResultsNative,
                displayContext: adDisplayContext,
                configuration: adConfiguration,
                presentation: .searchResultsGrid
            )
        }
    }
}
