import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeHavesLookupSheet: View {
    var payload: HomeHavesLookupPayload
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        HomeSheetScaffold(bottomButton: nil) {
            HomeHavesSelectedGoodsPanel(
                goods: payload.offeredGoods,
                conditionTags: payload.offeredConditionTags
            )

            if payload.shouldShowTagMatches {
                HomeDiscoverySection(
                    title: "メンバー×シリーズでマッチ",
                    candidates: payload.tagMatchedCandidates,
                    layout: .grid,
                    showsGridHeaderTitle: true,
                    showsSeeAllButton: false,
                    onSelect: onOpenNestedSheet
                )
            }

            if !payload.memberMatchedCandidates.isEmpty {
                HomeDiscoverySection(
                    title: "メンバーでマッチ",
                    candidates: payload.memberMatchedCandidates,
                    layout: .grid,
                    showsGridHeaderTitle: true,
                    showsSeeAllButton: false,
                    onSelect: onOpenNestedSheet
                )
            }

            if !payload.hasAnyMatches {
                HomeHavesEmptyMatchPanel()
            }
        }
    }
}

private struct HomeHavesSelectedGoodsPanel: View {
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選んだグッズ")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack {
                HomeSelectedGoodsSingleCard(goods: goods, conditionTags: conditionTags)
                    .frame(width: 118, height: 142)

                Spacer()
            }
        }
        .padding(.bottom, 2)
    }
}

private struct HomeHavesEmptyMatchPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
            Text("一致する候補はまだありません")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("このグッズを欲しがっている相手が見つかったらここに表示されます。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

struct HomeExtraHitDetailSheet: View {
    var payload: HomeExtraHitPayload
    var viewerOfferGoods: [HomeMockGoods]
    var onClose: (() -> Void)?
    var onOpenOwnerProfile: (UUID) -> Void

    var body: some View {
        HomeSheetScaffold(
            bottomButton: nil,
            dismissAction: onClose
        ) {
            HomeSelectedGoodsHeader(
                title: "他にも交換できそうなグッズ",
                goods: payload.goods,
                conditionTags: payload.conditionTags,
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(payload.signals),
                listingNote: payload.individualListingSelection.listingNote,
                listingDetail: payload.individualListingSelection.detail,
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "line.3.horizontal.decrease.circle",
                title: "交換条件",
                trailing: selectionRequirementLabel
            )
            wantedSelectionRail
        }
    }

    private var wantedGoods: [HomeMockGoods] {
        HomeDiscoveryFixtures.wantedGoods
    }

    private var wantedOptions: [HomeIndividualListingWantedOption] {
        payload.individualListingSelection.wantedOptions
    }

    private var usesListingWantedOptions: Bool {
        !wantedOptions.isEmpty
    }

    private var allOfferGoods: [HomeMockGoods] {
        viewerOfferGoods.isEmpty ? HomeDiscoveryFixtures.offerGoods : viewerOfferGoods
    }

    private var wantedLogic: ListingLogic {
        payload.individualListingSelection.wantedLogic
    }

    private var selectionRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: wantedLogic)
    }

    @ViewBuilder
    private var wantedSelectionRail: some View {
        if usesListingWantedOptions {
            HomeListingWantedOptionRail(
                options: wantedOptions,
                selectedIndices: [],
                previewGoodsByOptionID: previewGoodsByWantedOptionID,
                isSelectionEnabled: false,
                onSelect: { _ in }
            )
        } else {
            HomeGoodsImagePanelRail(
                goods: wantedGoods,
                selectedIndices: [],
                onSelect: { _ in }
            )
        }
    }

    private var previewGoodsByWantedOptionID: [UUID: HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.previewGoodsByOptionID(
            options: wantedOptions,
            goodsPool: wantedOptionPreviewGoodsPool
        )
    }

    private var wantedOptionPreviewGoodsPool: [HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.uniqueGoodsPool([
            allOfferGoods,
            wantedGoods,
            HomeDiscoveryFixtures.offerGoods,
            HomeDiscoveryFixtures.wantedGoods,
            [payload.goods]
        ])
    }
}
