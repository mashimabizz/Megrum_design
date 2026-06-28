import MegrumDesign
import SwiftUI

struct HomeMutualMatchAttentionTag: Identifiable, Equatable {
    var id: String { title }
    var title: String
    var systemImage: String
    var tint: Color

    private static let readyTint = MegrumTheme.ok
    private static let attentionTint = MegrumTheme.conditionPossible

    static let ready = HomeMutualMatchAttentionTag(
        title: "そのまま打診OK",
        systemImage: "checkmark.circle",
        tint: Self.readyTint
    )

    static let tagMismatch = HomeMutualMatchAttentionTag(
        title: "シリーズ不一致？",
        systemImage: "exclamationmark.triangle",
        tint: Self.attentionTint
    )

    static let amountIncluded = HomeMutualMatchAttentionTag(
        title: "金額込み候補",
        systemImage: "yensign.circle",
        tint: Self.attentionTint
    )

    static let amountInsufficient = HomeMutualMatchAttentionTag(
        title: "金額不足",
        systemImage: "exclamationmark.circle",
        tint: Self.attentionTint
    )

    static let exchangeMethodMismatch = HomeMutualMatchAttentionTag(
        title: "交換手段不一致",
        systemImage: "arrow.left.arrow.right.circle",
        tint: Self.attentionTint
    )

    static let prefectureNeedsDiscussion = HomeMutualMatchAttentionTag(
        title: "交換場所要相談",
        systemImage: "mappin.circle",
        tint: Self.attentionTint
    )

    static let dateNeedsDiscussion = HomeMutualMatchAttentionTag(
        title: "日程要相談",
        systemImage: "calendar.badge.exclamationmark",
        tint: Self.attentionTint
    )

    static let prefectureUnset = HomeMutualMatchAttentionTag(
        title: "都道府県未設定",
        systemImage: "mappin.slash",
        tint: Self.attentionTint
    )

    static let shippingFeeNeedsDiscussion = HomeMutualMatchAttentionTag(
        title: "送料要相談",
        systemImage: "shippingbox",
        tint: Self.attentionTint
    )

    static let paymentMethodMismatch = HomeMutualMatchAttentionTag(
        title: "支払方法不一致",
        systemImage: "creditcard.trianglebadge.exclamationmark",
        tint: Self.attentionTint
    )

    static let viewerPaymentUnset = HomeMutualMatchAttentionTag(
        title: "自分の支払条件未設定",
        systemImage: "person.crop.circle.badge.exclamationmark",
        tint: Self.attentionTint
    )

    static let partnerPaymentUnset = HomeMutualMatchAttentionTag(
        title: "相手の支払条件未設定",
        systemImage: "person.crop.circle.badge.exclamationmark",
        tint: Self.attentionTint
    )

    static let paymentUnset = HomeMutualMatchAttentionTag(
        title: "支払条件未設定",
        systemImage: "yensign.circle",
        tint: Self.attentionTint
    )

    static let paymentMethodNeedsDiscussion = HomeMutualMatchAttentionTag(
        title: "支払方法要相談",
        systemImage: "ellipsis.message",
        tint: Self.attentionTint
    )
}
