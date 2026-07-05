import Foundation
import MegrumCore

/// Megrumプレミアムの期間プラン（1ヶ月・2ヶ月・3ヶ月・半年・1年）。
/// 1ヶ月は既存の App Store 商品を使い、他は期間別の商品IDを割り当てる。
struct SubscriptionPremiumPlan: Identifiable, Equatable, Sendable {
    var productID: String
    var title: String
    var months: Int
    var fallbackPriceText: String
    var perMonthText: String
    var badge: String?

    var id: String { productID }
}

enum SubscriptionPremiumPlanCatalog {
    static let plans: [SubscriptionPremiumPlan] = [
        SubscriptionPremiumPlan(
            productID: SubscriptionCatalog.megrumPlusMonthlyProductID,
            title: "1ヶ月",
            months: 1,
            fallbackPriceText: "¥500",
            perMonthText: "月あたり ¥500",
            badge: nil
        ),
        SubscriptionPremiumPlan(
            productID: "megrum.premium.2m",
            title: "2ヶ月",
            months: 2,
            fallbackPriceText: "¥950",
            perMonthText: "月あたり ¥475",
            badge: "5%おトク"
        ),
        SubscriptionPremiumPlan(
            productID: "megrum.premium.3m",
            title: "3ヶ月",
            months: 3,
            fallbackPriceText: "¥1,350",
            perMonthText: "月あたり ¥450",
            badge: "10%おトク"
        ),
        SubscriptionPremiumPlan(
            productID: "megrum.premium.6m",
            title: "半年",
            months: 6,
            fallbackPriceText: "¥2,400",
            perMonthText: "月あたり ¥400",
            badge: "20%おトク"
        ),
        SubscriptionPremiumPlan(
            productID: "megrum.premium.12m",
            title: "1年",
            months: 12,
            fallbackPriceText: "¥4,200",
            perMonthText: "月あたり ¥350",
            badge: "30%おトク"
        )
    ]

    static func plan(for productID: String) -> SubscriptionPremiumPlan {
        plans.first { $0.productID == productID } ?? plans[0]
    }
}

/// 無料プランとの比較表の1行。
struct SubscriptionComparisonRow: Identifiable, Equatable, Sendable {
    var id: String { title }
    var title: String
    var freeText: String
    var premiumText: String
    var freeIsAvailable: Bool
    var systemImage: String

    static let rows: [SubscriptionComparisonRow] = [
        SubscriptionComparisonRow(
            title: "個別募集",
            freeText: "3件まで",
            premiumText: "無制限",
            freeIsAvailable: true,
            systemImage: "rectangle.stack.badge.plus"
        ),
        SubscriptionComparisonRow(
            title: "ホーム・検索の上位表示",
            freeText: "×",
            premiumText: "○",
            freeIsAvailable: false,
            systemImage: "arrow.up.forward.circle.fill"
        ),
        SubscriptionComparisonRow(
            title: "グルームアーカイブ",
            freeText: "10件まで",
            premiumText: "無制限",
            freeIsAvailable: true,
            systemImage: "archivebox.fill"
        ),
        SubscriptionComparisonRow(
            title: "めぐり内メッセージ",
            freeText: "×",
            premiumText: "○",
            freeIsAvailable: false,
            systemImage: "message.fill"
        ),
        SubscriptionComparisonRow(
            title: "県外のチャットルーム閲覧",
            freeText: "×",
            premiumText: "○",
            freeIsAvailable: false,
            systemImage: "map.fill"
        )
    ]
}
