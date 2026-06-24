import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum HomeMockGoodsShape: Sendable {
    case portrait
    case badge
    case stand
    case keychain
    case plush
}

struct HomeMockGoods: Identifiable, Equatable, Sendable {
    var id: UUID
    var ownerID: UUID?
    var ownerDisplayName: String?
    var ownerHandle: String?
    var ownerAvatarURL: URL?
    var ownerGender: UserGender?
    var ownerAge: Int?
    var ownerAverageStars: Double?
    var ownerEvaluationCount: Int?
    var ownerCompletedTradeCount: Int?
    var ownerPrefecture: String?
    var groupID: UUID?
    var memberID: UUID?
    var goodsTypeID: UUID?
    var groupName: String?
    var memberName: String?
    var goodsTypeName: String?
    var title: String
    var subtitle: String
    var displayTags: [String]
    var rawTagNames: [String]
    var ownerPaymentMethods: [UserPaymentMethod]
    var ownerPaymentNote: String?
    var shape: HomeMockGoodsShape
    var palette: [Color]
    var symbol: String
    var imageURL: URL?

    static func make(
        _ uuidTail: String,
        title: String,
        subtitle: String,
        ownerID: UUID? = nil,
        ownerDisplayName: String? = nil,
        ownerHandle: String? = nil,
        ownerAvatarURL: URL? = nil,
        ownerGender: UserGender? = nil,
        ownerAge: Int? = nil,
        ownerAverageStars: Double? = nil,
        ownerEvaluationCount: Int? = nil,
        ownerCompletedTradeCount: Int? = nil,
        ownerPrefecture: String? = nil,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        groupName: String? = nil,
        memberName: String? = nil,
        goodsTypeName: String? = nil,
        displayTags: [String] = [],
        rawTagNames: [String] = [],
        ownerPaymentMethods: [UserPaymentMethod] = [.paypay, .other],
        ownerPaymentNote: String? = "差額相談可",
        shape: HomeMockGoodsShape,
        palette: [Color],
        symbol: String,
        imageURL: URL? = nil
    ) -> HomeMockGoods {
        guard let id = UUID(uuidString: "00000000-0000-0000-0000-\(uuidTail)") else {
            preconditionFailure("Invalid home mock goods UUID tail: \(uuidTail)")
        }

        return HomeMockGoods(
            id: id,
            ownerID: ownerID,
            ownerDisplayName: ownerDisplayName,
            ownerHandle: ownerHandle,
            ownerAvatarURL: ownerAvatarURL,
            ownerGender: ownerGender,
            ownerAge: ownerAge,
            ownerAverageStars: ownerAverageStars,
            ownerEvaluationCount: ownerEvaluationCount,
            ownerCompletedTradeCount: ownerCompletedTradeCount,
            ownerPrefecture: ownerPrefecture,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            groupName: groupName,
            memberName: memberName,
            goodsTypeName: goodsTypeName,
            title: title,
            subtitle: subtitle,
            displayTags: displayTags,
            rawTagNames: rawTagNames,
            ownerPaymentMethods: ownerPaymentMethods,
            ownerPaymentNote: ownerPaymentNote,
            shape: shape,
            palette: palette,
            symbol: symbol,
            imageURL: imageURL
        )
    }

    static func from(item: GoodsItem, index: Int, goodsTypes: [GoodsType]) -> HomeMockGoods {
        let displayTags = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes)
        let displayTitle = item.masterGoodsTitle ?? item.title
        let shape = HomeMockGoodsShape.bestGuess(for: displayTitle)
        let palette = HomeMockGoodsPalette.palette(for: index, itemID: item.id)
        return HomeMockGoods(
            id: item.id,
            ownerID: item.ownerID,
            ownerDisplayName: item.ownerDisplayName,
            ownerHandle: item.ownerHandle,
            ownerAvatarURL: item.ownerAvatarURL,
            ownerGender: item.ownerGender,
            ownerAge: item.ownerAge,
            ownerAverageStars: item.ownerAverageStars,
            ownerEvaluationCount: item.ownerEvaluationCount,
            ownerCompletedTradeCount: item.ownerCompletedTradeCount,
            ownerPrefecture: item.ownerPrefecture,
            groupID: item.groupID,
            memberID: item.memberID,
            goodsTypeID: item.goodsTypeID,
            groupName: item.groupName,
            memberName: item.memberName,
            goodsTypeName: item.goodsTypeName,
            title: displayTitle,
            subtitle: displayTags.first ?? item.goodsTypeName ?? item.ownerPrefecture ?? item.kind?.inventoryKind ?? "",
            displayTags: displayTags,
            rawTagNames: HomeDiscoveryTagFormatter.matchingTagNames(for: item, goodsTypes: goodsTypes),
            ownerPaymentMethods: item.ownerPaymentMethods,
            ownerPaymentNote: item.ownerPaymentNote,
            shape: shape,
            palette: palette,
            symbol: displayTitle.first.map(String.init) ?? "M",
            imageURL: item.imageURL
        )
    }

    var masterDisplayName: String? {
        if memberID != nil, let memberName = normalizedMasterName(memberName) {
            return memberName
        }
        if let groupName = normalizedMasterName(groupName) {
            return groupName
        }
        return nil
    }

    var ownerPaymentSummaryText: String {
        UserPaymentMethod.displayText(
            for: ownerPaymentMethods,
            otherNote: ownerPaymentNote,
            emptyText: "支払い条件未設定"
        )
    }

    var ownerSummary: HomeDiscoveryGoodsOwnerSummary? {
        guard let ownerID else {
            return nil
        }
        return HomeDiscoveryGoodsOwnerSummary(
            id: ownerID,
            displayName: normalizedMasterName(ownerDisplayName) ?? normalizedMasterName(ownerHandle) ?? "ユーザー",
            handle: normalizedMasterName(ownerHandle),
            avatarURL: ownerAvatarURL,
            gender: ownerGender,
            age: ownerAge,
            prefecture: normalizedMasterName(ownerPrefecture),
            averageStars: ownerAverageStars,
            evaluationCount: ownerEvaluationCount,
            completedTradeCount: ownerCompletedTradeCount
        )
    }

    private func normalizedMasterName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct HomeDiscoveryGoodsOwnerSummary: Equatable, Sendable {
    var id: UUID
    var displayName: String
    var handle: String?
    var avatarURL: URL?
    var gender: UserGender?
    var age: Int?
    var prefecture: String?
    var averageStars: Double?
    var evaluationCount: Int?
    var completedTradeCount: Int?

    var initial: String {
        displayName.first.map { String($0).uppercased() } ?? "M"
    }

    var genderAgeText: String {
        [
            gender?.displayName,
            age.map { "\($0)歳" }
        ]
            .compactMap { $0 }
            .joined(separator: " / ")
    }

    var evaluationText: String {
        guard let evaluationCount else {
            return "評価なし"
        }
        guard let averageStars, evaluationCount > 0 else {
            return "評価\(evaluationCount)件 ★—"
        }
        return "評価\(evaluationCount)件 ★\(String(format: "%.1f", averageStars))"
    }

    var tradeText: String {
        "交換\(completedTradeCount ?? 0)件"
    }
}

struct HomeDiscoveryOwnerExchangeSummary: Equatable, Sendable {
    var methodTitle: String
    var detailText: String?

    static func fromListingSignals(_ signals: HomeCandidateConditionSignals) -> HomeDiscoveryOwnerExchangeSummary? {
        guard signals.goods.hasIndividualListingHit else {
            return nil
        }
        let exchange = signals.exchange
        let methodTitle = normalizedMethodTitle(nonBlank(exchange.partnerExchangeMethodTitle))
            ?? inferredMethodTitle(from: exchange)
        guard let methodTitle else {
            return nil
        }

        let detailParts = [
            exchange.localExchangeSelected ? nonBlank(exchange.partnerLocalConditionText) : nil,
            exchange.postalAcceptedByBoth ? shippingDetail(exchange.partnerShippingFeeTitle) : nil
        ].compactMap { $0 }

        return HomeDiscoveryOwnerExchangeSummary(
            methodTitle: methodTitle,
            detailText: detailParts.isEmpty ? nil : detailParts.joined(separator: " / ")
        )
    }

    private static func inferredMethodTitle(from exchange: HomeExchangeConditionSignals) -> String? {
        if exchange.localExchangeSelected && exchange.postalAcceptedByBoth {
            return "現地交換・郵送OK"
        }
        if exchange.localExchangeSelected {
            return "現地交換"
        }
        if exchange.postalAcceptedByBoth {
            return "郵送交換"
        }
        return nil
    }

    private static func shippingDetail(_ value: String?) -> String? {
        guard let value = nonBlank(value) else {
            return nil
        }
        return "送料 \(value)"
    }

    private static func nonBlank(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedMethodTitle(_ value: String?) -> String? {
        value == "どちらもOK" ? "現地交換・郵送OK" : value
    }
}

extension HomeMockGoodsShape {
    static func bestGuess(for title: String) -> HomeMockGoodsShape {
        if title.contains("缶") || title.localizedCaseInsensitiveContains("badge") {
            return .badge
        }
        if title.contains("アクスタ") || title.contains("スタンド") {
            return .stand
        }
        if title.contains("キーホルダー") || title.localizedCaseInsensitiveContains("key") {
            return .keychain
        }
        if title.contains("ぬい") || title.localizedCaseInsensitiveContains("plush") {
            return .plush
        }
        return .portrait
    }
}

private enum HomeMockGoodsPalette {
    static func palette(for index: Int, itemID: UUID) -> [Color] {
        let seed = abs(itemID.uuidString.hashValue + index)
        let palettes: [[Color]] = [
            [
                Color(red: 0.95, green: 0.84, blue: 0.58),
                MegrumTheme.pink.opacity(0.56),
                MegrumTheme.lavender.opacity(0.34)
            ],
            [
                MegrumTheme.lavender.opacity(0.78),
                Color.white.opacity(0.78),
                MegrumTheme.sky.opacity(0.38)
            ],
            [
                Color(red: 0.92, green: 0.70, blue: 0.58),
                MegrumTheme.pink.opacity(0.68),
                MegrumTheme.lavender.opacity(0.36)
            ],
            [
                MegrumTheme.sky.opacity(0.60),
                Color.white.opacity(0.92),
                MegrumTheme.pink.opacity(0.38)
            ]
        ]
        return palettes[seed % palettes.count]
    }
}
