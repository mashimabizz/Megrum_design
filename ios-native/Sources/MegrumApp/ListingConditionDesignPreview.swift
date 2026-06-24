import MegrumDesign
import SwiftUI

#if DEBUG
struct ListingConditionDesignPreview: View {
    var scenario: ListingConditionScenario = .cashOffer

    var body: some View {
        ZStack {
            ListingConditionDesignColors.background
                .ignoresSafeArea()

            VStack(spacing: ListingConditionDesignMetrics.verticalGap) {
                ListingConditionDesignHeader()
                    .padding(.horizontal, ListingConditionDesignMetrics.screenPadding)

                ListingConditionSwitcher(scenario: scenario)
                    .padding(.top, 2)

                ListingConditionSplitContent(scenario: scenario)
                    .padding(.horizontal, ListingConditionDesignMetrics.screenPadding)
                    .padding(.top, 4)

                ListingConditionBottomPanel()
                    .padding(.horizontal, ListingConditionDesignMetrics.screenPadding)
                    .padding(.top, 2)
            }
            .padding(.top, ListingConditionDesignMetrics.topPadding)
            .padding(.bottom, ListingConditionDesignMetrics.bottomPadding)
        }
    }
}

enum ListingConditionScenario {
    case cashOffer
    case multipleGoodsAndConditions
}

enum ListingConditionDesignMetrics {
    static let previewWidth: CGFloat = 368
    static let previewHeight: CGFloat = 800
    static let screenPadding: CGFloat = 10
    static let topPadding: CGFloat = 50
    static let bottomPadding: CGFloat = 8
    static let verticalGap: CGFloat = 10

    static let headerButtonSize: CGFloat = 44
    static let headerTitleSize: CGFloat = 25
    static let headerSubtitleSize: CGFloat = 14

    static let conditionCardWidth: CGFloat = 184
    static let conditionCardHeight: CGFloat = 86
    static let sideConditionCardWidth: CGFloat = 56
    static let conditionCardRadius: CGFloat = 18
    static let conditionTitleSize: CGFloat = 21
    static let conditionCounterSize: CGFloat = 19
    static let conditionEditButtonSize: CGFloat = 44

    static let splitHeight: CGFloat = 400
    static let splitSpacing: CGFloat = 8
    static let leftColumnRatio: CGFloat = 0.52
    static let panelRadius: CGFloat = 24
    static let panelPadding: CGFloat = 14

    static let optionRowHeight: CGFloat = 92
    static let optionLabelHeight: CGFloat = 28
    static let optionThumbnailSize: CGFloat = 58
    static let optionThumbnailGap: CGFloat = 8
    static let optionRowGap: CGFloat = 9
    static let priceRowHeight: CGFloat = 64

    static let offerCardWidth: CGFloat = 136
    static let offerCardHeight: CGFloat = 126
    static let offerIconSize: CGFloat = 40
    static let offerPriceSize: CGFloat = 22
    static let offerLabelSize: CGFloat = 13

    static let bottomPanelHeight: CGFloat = 116
    static let addButtonSize: CGFloat = 52
    static let addLabelSize: CGFloat = 21
    static let toggleLabelSize: CGFloat = 15
}

enum ListingConditionDesignColors {
    static let background = Color(red: 0.986, green: 0.980, blue: 0.990)
    static let panel = Color.white.opacity(0.86)
    static let faintPanel = Color.white.opacity(0.62)
    static let priceFill = MegrumTheme.lavender.opacity(0.11)
    static let divider = MegrumTheme.ink.opacity(0.08)
}

#Preview("個別募集 条件切替 定価") {
    ListingConditionDesignPreview()
        .frame(
            width: ListingConditionDesignMetrics.previewWidth,
            height: ListingConditionDesignMetrics.previewHeight
        )
}

#Preview("個別募集 複数グッズ 条件指定") {
    ListingConditionDesignPreview(scenario: .multipleGoodsAndConditions)
        .frame(
            width: ListingConditionDesignMetrics.previewWidth,
            height: ListingConditionDesignMetrics.previewHeight
        )
}
#endif
