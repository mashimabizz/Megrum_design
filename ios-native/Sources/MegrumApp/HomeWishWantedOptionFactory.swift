import Foundation
import MegrumCore
import MegrumData

/// 「求めてる？」（wishベースの不確定マッチ）を超求めてる？と同じ3列取引ブロックで
/// 見せるために、相手のほしいもの行を条件型の選択肢へ合成する（iter1226.417 / FB項目3）。
/// 個別募集の選択肢とは別フィールド（signals.wishWantedOptions）に載せ、
/// 需要判定（超求＝個別募集）には影響させない。
enum HomeWishWantedOptionFactory {
    static func wantedOptions(
        partnerWishes: [SupabaseHomeGoodsRow],
        viewerInventory: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> [HomeIndividualListingWantedOption] {
        partnerWishes.enumerated().compactMap { position, wish in
            wantedOption(
                wish: wish,
                position: position,
                viewerInventory: viewerInventory,
                tagsByInventoryID: tagsByInventoryID
            )
        }
    }

    private static func wantedOption(
        wish: SupabaseHomeGoodsRow,
        position: Int,
        viewerInventory: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> HomeIndividualListingWantedOption? {
        // このほしいものに当たる自分のグッズ（確定/不確定を分けて保持）。
        var matchingGoodsIDs: [UUID] = []
        var tentativeGoodsIDs: [UUID] = []
        for item in viewerInventory {
            guard let confidence = HomeMutualMatchListingEvaluator.wishGoodsConfidence(
                wish: wish,
                item: item,
                tagsByInventoryID: tagsByInventoryID
            ) else {
                continue
            }
            matchingGoodsIDs.append(item.id)
            if confidence == .tentative {
                tentativeGoodsIDs.append(item.id)
            }
        }
        guard !matchingGoodsIDs.isEmpty else {
            return nil
        }

        let tagNames = tagsByInventoryID[wish.id, default: []]
            .compactMap { $0.label?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank }

        return HomeIndividualListingWantedOption(
            id: wish.id,
            listingID: wish.id,
            position: position,
            title: shortTitle(for: wish),
            kind: .condition,
            matchingGoodsIDs: matchingGoodsIDs,
            tentativeGoodsIDs: tentativeGoodsIDs,
            previewItems: previewItems(for: wish, tagNames: tagNames),
            groupID: wish.groupId,
            goodsTypeID: wish.goodsTypeId,
            conditionSummary: conditionSummary(for: wish, tagNames: tagNames),
            quantity: max(wish.quantity ?? 1, 1)
        )
    }

    /// ピル・列見出しに出す短文（「サナのトレカ」式）。
    private static func shortTitle(for wish: SupabaseHomeGoodsRow) -> String {
        let member = wish.characterName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        let goodsType = wish.goodsTypeName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        switch (member, goodsType) {
        case let (member?, goodsType?):
            return "\(member)の\(goodsType)"
        case let (member?, nil):
            return "\(member)のグッズ"
        case let (nil, goodsType?):
            return goodsType
        case (nil, nil):
            return wish.title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "相手のほしいもの"
        }
    }

    /// 条件カード表示用「TWICE / サナ / トレカ / #シリーズ」。
    private static func conditionSummary(for wish: SupabaseHomeGoodsRow, tagNames: [String]) -> String? {
        var parts: [String] = []
        if let group = wish.groupName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank {
            parts.append(group)
        }
        if let member = wish.characterName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank {
            parts.append(member)
        }
        if let goodsType = wish.goodsTypeName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank {
            parts.append(goodsType)
        }
        parts.append(contentsOf: tagNames.map { "#\($0)" })
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    /// 相手のほしいもの写真は「自分の手持ちではない」ため、条件のグッズ確認の参考画像として使える。
    private static func previewItems(
        for wish: SupabaseHomeGoodsRow,
        tagNames: [String]
    ) -> [HomeIndividualListingWantedPreviewItem] {
        guard let urlString = wish.photoUrls.first?.nilIfBlank,
              let url = URL(string: urlString)
        else {
            return []
        }
        return [
            HomeIndividualListingWantedPreviewItem(
                id: wish.id,
                title: shortTitle(for: wish),
                imageURL: url,
                rawTagNames: tagNames
            )
        ]
    }
}
