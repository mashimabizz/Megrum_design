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

    var profileMetaText: String {
        [
            genderText,
            evaluationCountText,
            averageRatingText
        ]
            .joined(separator: "　")
    }

    var genderText: String {
        gender?.displayName ?? "性別未設定"
    }

    var evaluationCountText: String {
        guard let evaluationCount else {
            return "評価なし"
        }
        return "評価\(evaluationCount)件"
    }

    var averageRatingText: String {
        guard let averageStars, (evaluationCount ?? 0) > 0 else {
            return "平均評価—"
        }
        return "平均評価\(String(format: "%.1f", averageStars))"
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
    var rows: [String]

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
        let rows = [
            exchange.localExchangeSelected ? localDisplayLine(exchange.partnerLocalConditionText) : nil,
            exchange.postalAcceptedByBoth ? mailDisplayLine(exchange.partnerShippingFeeTitle) : nil
        ].compactMap { $0 }

        return HomeDiscoveryOwnerExchangeSummary(
            methodTitle: methodTitle,
            detailText: detailParts.isEmpty ? nil : detailParts.joined(separator: " / "),
            rows: rows
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
        if value.hasPrefix("送料") {
            return value
        }
        return "送料 \(value)"
    }

    private static func localDisplayLine(_ value: String?) -> String? {
        guard let value = nonBlank(value), !isExcluded(value) else {
            return nil
        }
        let parts = splitDetail(value)
        guard let prefecture = parts.first else {
            return nil
        }
        let schedule = parts.reversed().first { !isPlaceConsultation($0) && $0 != prefecture }
            .map(scheduleDisplayText)
            ?? "日程相談"
        return "現地交換：\(prefecture)、\(schedule)"
    }

    private static func mailDisplayLine(_ value: String?) -> String? {
        guard let value = nonBlank(value), !isExcluded(value) else {
            return nil
        }
        let parts = splitDetail(value)
        let fee = parts.first
            .map { cleanedValue($0, prefixes: ["送料:", "送料"]) }
            .flatMap { nonBlank($0) }
            ?? "要相談"
        let shippingDays = parts.dropFirst().first
            .map { cleanedValue($0, prefixes: ["発送目安:", "発送目安", "発送"]) }
            .flatMap { nonBlank($0) }
            ?? "発送目安相談"
        return "郵送交換：送料 \(fee)、発送目安 \(shippingDays)"
    }

    private static func splitDetail(_ value: String) -> [String] {
        value
            .components(separatedBy: " / ")
            .flatMap { $0.components(separatedBy: "、") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func cleanedValue(_ value: String, prefixes: [String]) -> String {
        var result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in prefixes where result.hasPrefix(prefix) {
            result = String(result.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }
        return result
    }

    private static func scheduleDisplayText(_ value: String) -> String {
        isScheduleConsultation(value) ? "日程相談" : value
    }

    private static func isExcluded(_ value: String) -> Bool {
        ["対象外", "未設定"].contains(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func isPlaceConsultation(_ value: String) -> Bool {
        ["相談", "場所相談"].contains(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func isScheduleConsultation(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return ["相談", "相談して決める", "日程は相談", "日程相談"].contains(trimmed)
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
