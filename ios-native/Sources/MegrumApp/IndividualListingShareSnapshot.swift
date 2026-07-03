import Foundation
import MegrumCore

struct IndividualListingShareSnapshot: Identifiable {
    let id = UUID()
    var listingID: UUID
    var displayName: String
    var wantedRows: [IndividualListingShareRow]
    var offeredRows: [IndividualListingShareRow]
    var exchangeConditionLines: [String]
    var paymentMethodsText: String
    var hashtagValues: [String]

    var previewItems: [GoodsItem] {
        (offeredRows + wantedRows).compactMap(\.previewItem)
    }
}

struct IndividualListingShareRow: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String?
    var badge: String?
    var imageURL: URL?
    var hashtagValues: [String]
    var previewItem: GoodsItem?
}

enum IndividualListingShareSnapshotFactory {
    static func make(
        listing: IndividualListing,
        displayName: String,
        inventory: [GoodsItem],
        wishes: [WishItem],
        groups: [OshiGroup],
        goodsTypes: [GoodsType],
        paymentMethodsText: String
    ) -> IndividualListingShareSnapshot {
        let inventoryByID = Dictionary(uniqueKeysWithValues: inventory.map { ($0.id, $0) })
        let wishByID = Dictionary(uniqueKeysWithValues: wishes.map { ($0.id, $0) })
        let offeredRows = offeredRows(
            listing: listing,
            inventoryByID: inventoryByID,
            goodsTypes: goodsTypes
        )
        let wantedRows = wantedRows(
            listing: listing,
            wishByID: wishByID,
            groups: groups,
            goodsTypes: goodsTypes
        )
        let exchangeLines = exchangeConditionLines(from: listing.note)
        let hashtags = GoodsSharePostTextBuilder.uniqueHashtagValues(
            offeredRows.flatMap(\.hashtagValues)
                + wantedRows.flatMap(\.hashtagValues)
                + ["個別募集", "グッズ交換"]
        )

        return IndividualListingShareSnapshot(
            listingID: listing.id,
            displayName: displayName,
            wantedRows: wantedRows,
            offeredRows: offeredRows,
            exchangeConditionLines: exchangeLines,
            paymentMethodsText: paymentMethodsText,
            hashtagValues: hashtags
        )
    }

    private static func offeredRows(
        listing: IndividualListing,
        inventoryByID: [UUID: GoodsItem],
        goodsTypes: [GoodsType]
    ) -> [IndividualListingShareRow] {
        if listing.haves.isEmpty,
           let cashSummary = IndividualListingHaveCashSummary.extract(from: listing.note).summary {
            return [
                IndividualListingShareRow(
                    title: cashSummary.title,
                    detail: listing.haveLogic.displayName(minimumCount: listing.haveMinimumCount),
                    badge: "譲る",
                    imageURL: nil,
                    hashtagValues: ["定価"],
                    previewItem: nil
                )
            ]
        }

        let rows = listing.haves.compactMap { quantity -> IndividualListingShareRow? in
            guard let item = inventoryByID[quantity.itemID] else {
                return nil
            }
            return IndividualListingShareRow(
                title: item.title,
                detail: quantity.quantity > 1 ? "\(quantity.quantity)点" : nil,
                badge: listing.haveLogic.displayName(minimumCount: listing.haveMinimumCount),
                imageURL: item.imageURL,
                hashtagValues: hashtagValues(for: item),
                previewItem: item
            )
        }
        guard !rows.isEmpty else {
            return [
                IndividualListingShareRow(
                    title: "譲るもの",
                    detail: listing.haveLogic.displayName(minimumCount: listing.haveMinimumCount),
                    badge: "条件指定",
                    imageURL: nil,
                    hashtagValues: ["譲るもの"],
                    previewItem: nil
                )
            ]
        }
        return rows
    }

    private static func wantedRows(
        listing: IndividualListing,
        wishByID: [UUID: WishItem],
        groups: [OshiGroup],
        goodsTypes: [GoodsType]
    ) -> [IndividualListingShareRow] {
        let options = listing.options.sorted { $0.position < $1.position }
        let optionRows = options.enumerated().flatMap { index, option -> [IndividualListingShareRow] in
            shareRows(
                for: option,
                index: index + 1,
                wishByID: wishByID,
                groups: groups,
                goodsTypes: goodsTypes
            )
        }
        return optionRows.isEmpty ? [
            IndividualListingShareRow(
                title: "求めるもの",
                detail: "条件指定",
                badge: nil,
                imageURL: nil,
                hashtagValues: ["求めるもの"],
                previewItem: nil
            )
        ] : optionRows
    }

    private static func shareRows(
        for option: IndividualListingWishOption,
        index: Int,
        wishByID: [UUID: WishItem],
        groups: [OshiGroup],
        goodsTypes: [GoodsType]
    ) -> [IndividualListingShareRow] {
        let optionBadge = "選択肢\(index)・\(option.logic.displayName(minimumCount: option.minimumCount))"
        if option.isCashOffer {
            return [
                IndividualListingShareRow(
                    title: TradeAmountFormatter.fixedPrice(amount: option.cashAmount),
                    detail: option.exchangeType.displayName,
                    badge: optionBadge,
                    imageURL: nil,
                    hashtagValues: ["定価"],
                    previewItem: nil
                )
            ]
        }

        let wishRows = option.wishes.compactMap { quantity -> IndividualListingShareRow? in
            guard let wish = wishByID[quantity.itemID] else {
                return nil
            }
            return IndividualListingShareRow(
                title: wish.title,
                detail: quantity.quantity > 1 ? "\(quantity.quantity)点" : option.exchangeType.displayName,
                badge: optionBadge,
                imageURL: wish.imageURL,
                hashtagValues: hashtagValues(for: wish, groups: groups, goodsTypes: goodsTypes),
                previewItem: goodsItem(from: wish, groups: groups, goodsTypes: goodsTypes)
            )
        }
        if !wishRows.isEmpty {
            return wishRows
        }

        let conditionTitle = [
            groupName(for: option.wishGroupID, groups: groups),
            goodsTypeName(for: option.wishGoodsTypeID, goodsTypes: goodsTypes)
        ]
        .compactMap(\.self)
        .joined(separator: " / ")
        let title = conditionTitle.isEmpty ? "条件から選ぶ" : conditionTitle

        return [
            IndividualListingShareRow(
                title: title,
                detail: option.exchangeType.displayName,
                badge: optionBadge,
                imageURL: nil,
                hashtagValues: [title],
                previewItem: nil
            )
        ]
    }

    private static func exchangeConditionLines(from note: String?) -> [String] {
        let extracted = IndividualListingExchangeSummary.extract(from: note).summary
        guard let summary = extracted else {
            return ["交換条件: 相談して決める"]
        }
        var lines = ["交換手段: \(summary.handoffMethod.title)"]
        if let local = summary.localDetailTextForProposalDisplay {
            lines.append("現地: \(local)")
        }
        if let mail = summary.mailDetailText {
            lines.append("郵送: \(mail)")
        }
        lines.append("条件外打診: \(summary.acceptsOutsideCondition ? "可" : "不可")")
        return lines
    }

    private static func hashtagValues(for item: GoodsItem) -> [String] {
        [
            item.groupName,
            item.memberName,
            item.goodsTypeName
        ]
        .compactMap(\.self)
        + item.tags.map(\.name)
    }

    private static func hashtagValues(for wish: WishItem, groups: [OshiGroup], goodsTypes: [GoodsType]) -> [String] {
        [
            groupName(for: wish.groupID, groups: groups),
            goodsTypeName(for: wish.goodsTypeID, goodsTypes: goodsTypes)
        ]
        .compactMap(\.self)
        + wish.tags.map(\.name)
    }

    private static func goodsItem(from wish: WishItem, groups: [OshiGroup], goodsTypes: [GoodsType]) -> GoodsItem {
        GoodsItem(
            id: wish.id,
            ownerID: wish.ownerID,
            kind: .wish,
            status: .active,
            groupID: wish.groupID,
            memberID: wish.memberID,
            goodsTypeID: wish.goodsTypeID,
            groupName: groupName(for: wish.groupID, groups: groups),
            goodsTypeName: goodsTypeName(for: wish.goodsTypeID, goodsTypes: goodsTypes),
            title: wish.title,
            imageURL: wish.imageURL,
            tags: wish.tags,
            quantity: wish.quantity
        )
    }

    private static func groupName(for id: UUID?, groups: [OshiGroup]) -> String? {
        guard let id else {
            return nil
        }
        return groups.first { $0.id == id }?.name
    }

    private static func goodsTypeName(for id: UUID?, goodsTypes: [GoodsType]) -> String? {
        guard let id else {
            return nil
        }
        return goodsTypes.first { $0.id == id }?.name
    }
}

private extension IndividualListingHaveCashSummary {
    var title: String {
        switch pricingMode {
        case .listPrice:
            "定価"
        case .specifiedAmount:
            TradeAmountFormatter.fixedPrice(amount: amount)
        }
    }
}
