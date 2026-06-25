import SwiftUI

#if DEBUG
struct ListingConditionSplitContent: View {
    var scenario: ListingConditionScenario

    var body: some View {
        GeometryReader { proxy in
            let leftWidth = floor((proxy.size.width - ListingConditionDesignMetrics.splitSpacing) * ListingConditionDesignMetrics.leftColumnRatio)
            let rightWidth = proxy.size.width - leftWidth - ListingConditionDesignMetrics.splitSpacing

            HStack(spacing: ListingConditionDesignMetrics.splitSpacing) {
                ListingConditionReceivePanel(scenario: scenario)
                    .frame(width: leftWidth)

                Group {
                    switch scenario {
                    case .cashOffer:
                        ListingConditionOfferPricePanel()
                    case .multipleGoodsAndConditions:
                        ListingConditionOfferGoodsPanel()
                    }
                }
                    .frame(width: rightWidth)
            }
        }
        .frame(height: ListingConditionDesignMetrics.splitHeight)
    }
}
#endif
