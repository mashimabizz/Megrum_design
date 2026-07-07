import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingWantedOptionFactory {
    static func wantedOption(
        from option: SupabaseHomeListingWishOptionRow,
        viewerInventory: [SupabaseHomeGoodsRow],
        previewInventory: [SupabaseHomeGoodsRow] = [],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        includesCash: Bool
    ) -> HomeIndividualListingWantedOption? {
        let logic = ListingLogic(rawValue: option.logic ?? "") ?? .one
        if option.isCashOffer == true {
            guard includesCash else {
                return nil
            }
            return cashWantedOption(option: option, logic: logic)
        }

        let rowsByID = Self.rowsByID(previewInventory)
        let matchingItems = HomeCandidateListingWantedOptionMatchPolicy.matchingItems(
            for: option,
            in: viewerInventory,
            wantedRowsByID: rowsByID,
            tagsByInventoryID: tagsByInventoryID
        )
        guard HomeCandidateListingWantedOptionMatchPolicy.isSelectable(
            option: option,
            logic: logic,
            matchingItems: matchingItems
        ) else {
            return nil
        }

        return goodsWantedOption(
            option: option,
            logic: logic,
            matchingItems: matchingItems,
            tentativeGoodsIDs: Self.tentativeGoodsIDs(
                option: option,
                matchingItems: matchingItems,
                rowsByID: rowsByID,
                tagsByInventoryID: tagsByInventoryID
            ),
            titlePreviewItems: [],
            previewItems: HomeCandidateListingWantedOptionPreviewBuilder.previewItems(
                for: option,
                matchingItems: matchingItems,
                previewInventory: previewInventory,
                tagsByInventoryID: tagsByInventoryID
            ),
            wantedRowsByID: rowsByID,
            tagsByInventoryID: tagsByInventoryID
        )
    }

    static func detailWantedOption(
        from option: SupabaseHomeListingWishOptionRow,
        viewerInventory: [SupabaseHomeGoodsRow],
        previewInventory: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        includesCash: Bool
    ) -> HomeIndividualListingWantedOption? {
        let logic = ListingLogic(rawValue: option.logic ?? "") ?? .one
        if option.isCashOffer == true {
            guard includesCash else {
                return nil
            }
            return cashWantedOption(option: option, logic: logic)
        }

        let rowsByID = Self.rowsByID(previewInventory)
        let matchingItems = HomeCandidateListingWantedOptionMatchPolicy.matchingItems(
            for: option,
            in: viewerInventory,
            wantedRowsByID: rowsByID,
            tagsByInventoryID: tagsByInventoryID
        )
        let previews = HomeCandidateListingWantedOptionPreviewBuilder.previewItems(
            for: option,
            matchingItems: matchingItems,
            previewInventory: previewInventory,
            tagsByInventoryID: tagsByInventoryID
        )
        let hasConfiguredCondition = HomeCandidateListingWantedOptionMatchPolicy.hasConfiguredGoodsCondition(option)
        guard hasConfiguredCondition || !previews.isEmpty else {
            return nil
        }
        return goodsWantedOption(
            option: option,
            logic: logic,
            matchingItems: matchingItems,
            tentativeGoodsIDs: Self.tentativeGoodsIDs(
                option: option,
                matchingItems: matchingItems,
                rowsByID: rowsByID,
                tagsByInventoryID: tagsByInventoryID
            ),
            titlePreviewItems: previews,
            previewItems: previews,
            subtitleMatchingCount: max(matchingItems.count, previews.count),
            wantedRowsByID: rowsByID,
            tagsByInventoryID: tagsByInventoryID
        )
    }

    /// matchingItems のうち、確度が不確定（メンバー・種別・シリーズが無記載）な分のID。iter1226.363。
    private static func tentativeGoodsIDs(
        option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow],
        rowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> [UUID] {
        matchingItems
            .filter { item in
                HomeMutualMatchListingEvaluator.mutualOptionMatchConfidence(
                    option,
                    counterpartItem: item,
                    rowsByID: rowsByID,
                    tagsByInventoryID: tagsByInventoryID
                ) == .tentative
            }
            .map(\.id)
    }

    private static func rowsByID(_ rows: [SupabaseHomeGoodsRow]) -> [UUID: SupabaseHomeGoodsRow] {
        Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func cashWantedOption(
        option: SupabaseHomeListingWishOptionRow,
        logic: ListingLogic
    ) -> HomeIndividualListingWantedOption {
        HomeIndividualListingWantedOption(
            id: option.id,
            listingID: option.listingId,
            position: option.position,
            title: TradeAmountFormatter.fixedPrice(amount: option.cashAmount),
            subtitle: "金額で受け取る条件",
            logic: logic,
            kind: .cash,
            cashAmount: option.cashAmount
        )
    }

    private static func goodsWantedOption(
        option: SupabaseHomeListingWishOptionRow,
        logic: ListingLogic,
        matchingItems: [SupabaseHomeGoodsRow],
        tentativeGoodsIDs: [UUID] = [],
        titlePreviewItems: [HomeIndividualListingWantedPreviewItem],
        previewItems: [HomeIndividualListingWantedPreviewItem],
        subtitleMatchingCount: Int? = nil,
        wantedRowsByID: [UUID: SupabaseHomeGoodsRow] = [:],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:]
    ) -> HomeIndividualListingWantedOption {
        let kind: HomeIndividualListingWantedOption.Kind = option.wishIds.isEmpty ? .condition : .goods
        return HomeIndividualListingWantedOption(
            id: option.id,
            listingID: option.listingId,
            position: option.position,
            title: HomeCandidateListingWantedOptionTextPolicy.title(
                option: option,
                matchingItems: matchingItems,
                previewItems: titlePreviewItems
            ),
            subtitle: HomeCandidateListingWantedOptionTextPolicy.subtitle(
                option: option,
                matchingCount: subtitleMatchingCount ?? matchingItems.count
            ),
            logic: logic,
            minimumCount: option.minCount ?? 1,
            kind: kind,
            goodsIDs: option.wishIds,
            matchingGoodsIDs: matchingItems.map(\.id),
            tentativeGoodsIDs: tentativeGoodsIDs,
            previewItems: previewItems,
            groupID: option.wishGroupId,
            goodsTypeID: option.wishGoodsTypeId,
            conditionSummary: kind == .condition
                ? Self.conditionSummary(option: option, matchingItems: matchingItems)
                : nil,
            namedPairings: kind == .goods
                ? Self.namedPairings(
                    option: option,
                    matchingItems: matchingItems,
                    wantedRowsByID: wantedRowsByID,
                    tagsByInventoryID: tagsByInventoryID
                )
                : []
        )
    }

    /// 指名オプションの「相手のほしいもの1件 → 充てられる自分の候補」対応。iter1226.373。
    /// 相手のほしいもの画像（相手自身のほしいもの行）と、それを満たせる自分のマッチ済みグッズをメンバー等で紐づける。
    private static func namedPairings(
        option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow],
        wantedRowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> [HomeWantedNamedPairing] {
        option.wishIds.compactMap { wishID -> HomeWantedNamedPairing? in
            guard let wanted = wantedRowsByID[wishID] else {
                return nil
            }
            let candidateIDs = matchingItems
                .filter { item in
                    HomeMutualMatchListingEvaluator.wishGoodsConfidence(
                        wish: wanted,
                        item: item,
                        tagsByInventoryID: tagsByInventoryID
                    ) != nil
                }
                .map(\.id)
            return HomeWantedNamedPairing(
                id: wanted.id,
                title: wanted.title,
                imageURL: GoodsPhotoURLResolver.displayURL(from: wanted.photoUrls),
                characterID: wanted.characterId,
                candidateGoodsIDs: candidateIDs
            )
        }
    }

    /// 条件指定型の選択肢を「TWICE / トレカ / メンバー / #シリーズ」の1文字列にする。
    /// グループ・種別名はマッチしたグッズ（同属性）から取り、シリーズは選択肢に保存された文字列を使う。iter1226.371。
    private static func conditionSummary(
        option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow]
    ) -> String? {
        var parts: [String] = []
        if let groupID = option.wishGroupId,
           let name = (matchingItems.first { $0.groupId == groupID }?.groupName
            ?? matchingItems.first?.groupName)?.nilIfBlank {
            parts.append(name)
        }
        if let goodsTypeID = option.wishGoodsTypeId,
           let name = (matchingItems.first { $0.goodsTypeId == goodsTypeID }?.goodsTypeName
            ?? matchingItems.first?.goodsTypeName)?.nilIfBlank {
            parts.append(name)
        }
        if !option.wishMemberIds.isEmpty {
            let names = option.wishMemberIds.compactMap { memberID in
                matchingItems.first { $0.characterId == memberID }?.characterName?.nilIfBlank
            }
            if !names.isEmpty {
                parts.append((option.excludesWishMembers ? "以外: " : "") + names.joined(separator: "・"))
            } else if option.excludesWishMembers {
                parts.append("一部メンバー除く")
            }
        }
        if !option.wishSeriesNames.isEmpty {
            let series = option.wishSeriesNames
                .map { $0.hasPrefix("#") ? String($0.dropFirst()) : $0 }
                .filter { !$0.isEmpty }
                .map { "#\($0)" }
            parts.append(contentsOf: series)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

}
