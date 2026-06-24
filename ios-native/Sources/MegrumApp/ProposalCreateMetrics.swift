import MegrumCore
import SwiftUI

enum ProposalFlowContentMetrics {
    static let defaultHorizontalPadding: CGFloat = 18
    static let confirmHorizontalPadding: CGFloat = 18
    static let defaultContentSpacing: CGFloat = 12
    static let confirmContentSpacing: CGFloat = 13
}

enum ProposalFlowBottomBarMetrics {
    static let horizontalPadding: CGFloat = 18
    static let topPadding: CGFloat = 10
    static let bottomPadding: CGFloat = 6
    static let inlineTopPadding: CGFloat = 4
    static let inlineBottomPadding: CGFloat = 4
    static let buttonMinHeight: CGFloat = 56
    static let buttonCornerRadius: CGFloat = 18
}

struct ProposalCandidateListMetrics {
    static let spacing: CGFloat = 10
    static let paneSpacing: CGFloat = 10

    static func estimatedColumnCount(containerWidth: CGFloat) -> Int {
        1
    }
}

enum ProposalSelectableGoodsRowMetrics {
    static let rowSpacing: CGFloat = 12
    static let rowPadding: CGFloat = 10
    static let rowCornerRadius: CGFloat = 18
    static let selectedBackgroundOpacity: CGFloat = 0.08
    static let selectedBorderOpacity: CGFloat = 0.48
    static let defaultBorderOpacity: CGFloat = 0.08
    static let thumbnailWidth: CGFloat = 66
    static let thumbnailHeight: CGFloat = 82
    static let thumbnailCornerRadius: CGFloat = 15
    static let thumbnailShineSize: CGFloat = 56
    static let thumbnailShineOffsetX: CGFloat = 16
    static let thumbnailShineOffsetY: CGFloat = -18
    static let glyphFontSize: CGFloat = 27
    static let checkCircleSize: CGFloat = 26
}

enum ProposalExchangePreviewMetrics {
    static let thumbSize: CGFloat = 44
    static let thumbSpacing: CGFloat = 6

    static var thumbGridColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: thumbSize, maximum: thumbSize),
                spacing: thumbSpacing,
                alignment: .top
            )
        ]
    }
}

enum ProposalFlowHeaderMetrics {
    static let backButtonSize: CGFloat = 42
    static let backChevronSize: CGFloat = 18
    static let horizontalSpacing: CGFloat = 12
    static let kickerFontSize: CGFloat = 10
    static let kickerTracking: CGFloat = 0.7
    static let titleFontSize: CGFloat = 23
}

enum ProposalSectionTabsMetrics {
    static let containerPadding: CGFloat = 3
    static let tabGap: CGFloat = 4
    static let tabHorizontalPadding: CGFloat = 5
    static let tabVerticalPadding: CGFloat = 5
    static let minTabHeight: CGFloat = 30
    static let labelFontSize: CGFloat = 11.5
    static let countFontSize: CGFloat = 10
}

enum ProposalGoodsFilterMetrics {
    static let rowSpacing: CGFloat = 6
    static let labelWidth: CGFloat = 30
    static let labelFontSize: CGFloat = 9.5
    static let labelTracking: CGFloat = 0.4
    static let chipSpacing: CGFloat = 6
    static let chipHorizontalPadding: CGFloat = 10
    static let chipVerticalPadding: CGFloat = 5
    static let chipFontSize: CGFloat = 11
}

struct ProposalGoodsFilterCatalog {
    static func groupChoices(items: [GoodsItem], groups: [OshiGroup]) -> [ProposalFilterChoice] {
        let presentIDs = Set(items.compactMap(\.groupID))
        return groups
            .filter { presentIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .map { ProposalFilterChoice(id: $0.id, title: $0.name) }
    }

    static func goodsTypeChoices(items: [GoodsItem], goodsTypes: [GoodsType]) -> [ProposalFilterChoice] {
        let presentIDs = Set(items.compactMap(\.goodsTypeID))
        return goodsTypes
            .filter { presentIDs.contains($0.id) }
            .sorted { lhs, rhs in
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .map { ProposalFilterChoice(id: $0.id, title: $0.name) }
    }
}
