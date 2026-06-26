import Foundation
import MegrumCore
import SwiftUI

struct IndividualListingHavesStep: View {
    enum Tab: String {
        case goods
        case cash
    }

    var inventory: [GoodsItem]
    var selectedIDs: Set<UUID>
    @Binding var filter: IndividualListingSelectionFilter
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    @Binding var selectedTab: Tab
    @Binding var cashPricingMode: IndividualListingCashPricingMode
    @Binding var cashAmount: Int
    var onToggle: (GoodsItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IndividualListingStepTitle(step: .haves)

            IndividualListingHaveTabs(selection: $selectedTab)

            switch selectedTab {
            case .goods:
                goodsSelection
            case .cash:
                IndividualListingCashTab(
                    pricingMode: $cashPricingMode,
                    amount: $cashAmount
                )
            }
        }
    }

    private var goodsSelection: some View {
        IndividualListingHavesGoodsSelection(
            inventory: inventory,
            selectedIDs: selectedIDs,
            filter: $filter,
            groups: groups,
            goodsTypes: goodsTypes,
            onToggle: onToggle
        )
    }
}
