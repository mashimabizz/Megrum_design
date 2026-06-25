import Foundation
import MegrumDesign
import SwiftUI

struct HomeOtherExchangeEmptyPanel: View {
    var body: some View {
        Text(HomeOtherExchangeCopy.noOtherExchangeCandidates)
            .font(.system(size: 13.5, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

enum HomeOtherExchangeCopy {
    static let noOtherExchangeCandidates = "他に交換できそうなものはありません"
}

enum HomeOtherExchangePolicy {
    static func visibleGoods(_ goods: [HomeMockGoods], excluding excludedGoodsIDs: Set<UUID>) -> [HomeMockGoods] {
        guard !excludedGoodsIDs.isEmpty else {
            return goods
        }
        return goods.filter { !excludedGoodsIDs.contains($0.id) }
    }

    static func visiblePayloads(
        _ payloads: [HomeExtraHitPayload],
        excluding excludedGoodsIDs: Set<UUID>
    ) -> [HomeExtraHitPayload] {
        guard !excludedGoodsIDs.isEmpty else {
            return payloads
        }
        return payloads.filter { !excludedGoodsIDs.contains($0.goods.id) }
    }

    static func visibleWishGoods(
        _ goods: [HomeMockGoods],
        excluding excludedGoodsIDs: Set<UUID>,
        listingHitGoods: [HomeMockGoods]
    ) -> [HomeMockGoods] {
        visibleGoods(
            goods,
            excluding: excludedGoodsIDs.union(listingHitGoods.map(\.id))
        )
    }

    static func visibleWishPayloads(
        _ payloads: [HomeExtraHitPayload],
        excluding excludedGoodsIDs: Set<UUID>,
        listingHitPayloads: [HomeExtraHitPayload]
    ) -> [HomeExtraHitPayload] {
        visiblePayloads(
            payloads,
            excluding: excludedGoodsIDs.union(listingHitPayloads.map(\.goods.id))
        )
    }
}

struct HomeOtherExchangeThumbnailButton: View {
    var goods: HomeMockGoods
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                HomeTinyGoodsThumbnail(goods: goods)
                    .frame(width: 58, height: 58)
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(
                                selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                                lineWidth: selected ? 3 : 1
                            )
                    }

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(MegrumTheme.lavender, in: Circle())
                        .offset(x: -5, y: -5)
                        .shadow(color: .black.opacity(0.10), radius: 5, y: 2)
                }
            }
            .padding(3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(goods.title)を交換候補として確認")
    }
}
