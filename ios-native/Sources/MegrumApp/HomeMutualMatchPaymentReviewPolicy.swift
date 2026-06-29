import Foundation

enum HomeMutualMatchPaymentReviewPolicy {
    static func items(
        for signals: HomeCandidateConditionSignals
    ) -> [HomeMutualMatchConditionReviewItem] {
        guard signals.includesCashOption else {
            return [
                item(
                    category: "支払条件",
                    title: "物々交換なら確認不要",
                    detail: "この組み合わせでは支払方法の一致を優先しません",
                    status: .skipped
                )
            ]
        }

        switch signals.payment.status {
        case .compatible:
            return [
                item(
                    category: "支払条件",
                    title: "全一致",
                    detail: "共通で使える支払方法があります",
                    status: .matched
                )
            ]
        case .methodMismatch:
            return [
                item(
                    category: "支払条件",
                    title: "支払方法不一致",
                    detail: "金額条件を含むため、共通で使える支払方法を確認してください",
                    status: .mismatch
                )
            ]
        case .viewerUnset:
            return [
                item(
                    category: "支払条件",
                    title: "自分の支払条件未設定",
                    detail: "金額条件を含むため、先に自分の支払条件を設定してください",
                    status: .needsDecision
                )
            ]
        case .partnerUnset:
            return [
                item(
                    category: "支払条件",
                    title: "相手の支払条件未設定",
                    detail: "金額条件を含むため、相手の支払方法を確認してください",
                    status: .needsDecision
                )
            ]
        case .unset:
            return [
                item(
                    category: "支払条件",
                    title: "支払条件未設定",
                    detail: "双方の支払条件を設定してから進めると安心です",
                    status: .needsDecision
                )
            ]
        case .needsDiscussion:
            return [
                item(
                    category: "支払条件",
                    title: "支払方法要相談",
                    detail: "その他の支払方法を含むため、使える方法を相談してください",
                    status: .needsDecision
                )
            ]
        case .skipped:
            return [
                item(
                    category: "支払条件",
                    title: "物々交換なら確認不要",
                    detail: "この組み合わせでは支払方法の一致を優先しません",
                    status: .skipped
                )
            ]
        }
    }

    private static func item(
        category: String,
        title: String,
        detail: String,
        status: HomeMutualMatchConditionReviewStatus
    ) -> HomeMutualMatchConditionReviewItem {
        HomeMutualMatchConditionReviewItem(
            category: category,
            title: title,
            detail: detail,
            status: status
        )
    }
}

private extension HomeCandidateConditionSignals {
    var includesCashOption: Bool {
        payment.requiresPayment || individualListingSelection?.wantedOptions.contains(where: \.isCashOffer) == true
    }
}
