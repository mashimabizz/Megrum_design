import Foundation
import MegrumDesign
import SwiftUI

struct HomeGoodsHitWantedSelectionRail: View {
    var usesListingWantedOptions: Bool
    var wantedOptionPreviewGoods: [HomeMockGoods]
    var selectedWantedOptionPreviewIndices: Set<Int>
    var topTrailingBadgeTextByGoodsID: [UUID: String]
    var wantedGoods: [HomeMockGoods]
    var selectedWantedIndices: Set<Int>
    var cardSize: HomeGoodsImagePanelCardSize
    var onSelectWantedOptionPreviewGoods: (Int) -> Void
    var onSelectWantedGoods: (Int) -> Void

    var body: some View {
        if usesListingWantedOptions, !wantedOptionPreviewGoods.isEmpty {
            HomeGoodsImagePanelRail(
                goods: wantedOptionPreviewGoods,
                selectedIndices: selectedWantedOptionPreviewIndices,
                topTrailingBadgeTextByGoodsID: topTrailingBadgeTextByGoodsID,
                cardSize: cardSize,
                onSelect: onSelectWantedOptionPreviewGoods
            )
        } else {
            HomeGoodsImagePanelRail(
                goods: wantedGoods,
                selectedIndices: selectedWantedIndices,
                cardSize: cardSize,
                onSelect: onSelectWantedGoods
            )
        }
    }
}

struct HomeWantedSelectionSectionHeader: View {
    var systemName: String
    var title: String
    var trailing: String?
    var showsOtherOptionsButton: Bool
    var onOpenOtherOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 24, height: 24)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    if let trailing {
                        Text(trailing)
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsOtherOptionsButton {
                    Button("他の選択肢", systemImage: "list.bullet.rectangle", action: onOpenOtherOptions)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .padding(.horizontal, 9)
                        .frame(height: 30)
                        .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
                        }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}
