import Foundation
import MegrumCore

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
            return "現地交換、郵送OK"
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
        switch value {
        case "どちらもOK", "現地交換・郵送OK":
            return "現地交換、郵送OK"
        default:
            return value
        }
    }
}
