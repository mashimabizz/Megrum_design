import Foundation
import MegrumCore

enum HomeMutualMatchConditionReviewPointPolicy {
    static func points(
        for pair: HomeMutualMatchProposalPair,
        review: HomeMutualMatchConditionReview
    ) -> [HomeMutualMatchConditionReviewPoint] {
        [
            exchangeMethodPoint(signals: pair.signals.exchange, review: review),
            localExchangePoint(signals: pair.signals.exchange, review: review),
            postalExchangePoint(signals: pair.signals.exchange, review: review),
            amountPoint(pair: pair),
            paymentPoint(signals: pair.signals.payment, review: review)
        ]
    }

    private static func exchangeMethodPoint(
        signals: HomeExchangeConditionSignals,
        review: HomeMutualMatchConditionReview
    ) -> HomeMutualMatchConditionReviewPoint {
        let isMismatch = review.exchangeItems.containsTitle("交換手段が不一致")
        let resolvedTitle = HomeMutualMatchExchangeConditionReviewDisplay.resolvedMethodTitle(signals)
        let needsDiscussion = !isMismatch && resolvedTitle == nil
            && HomeMutualMatchExchangeConditionReviewDisplay.methodNeedsDiscussion(signals)
        return HomeMutualMatchConditionReviewPoint(
            title: "交換条件",
            tagTitle: isMismatch ? "交換条件不一致" : (resolvedTitle ?? (needsDiscussion ? "要相談" : "OK")),
            partnerValue: HomeMutualMatchExchangeConditionReviewDisplay.methodTitle(
                signals.partnerExchangeMethodTitle,
                signals: signals
            ),
            viewerValue: HomeMutualMatchExchangeConditionReviewDisplay.methodTitle(
                signals.viewerExchangeMethodTitle,
                signals: signals
            ),
            status: isMismatch ? .mismatch : (needsDiscussion ? .needsDecision : .matched)
        )
    }

    private static func localExchangePoint(
        signals: HomeExchangeConditionSignals,
        review: HomeMutualMatchConditionReview
    ) -> HomeMutualMatchConditionReviewPoint {
        guard signals.localRouteAvailable else {
            return HomeMutualMatchConditionReviewPoint(
                title: "現地交換条件",
                tagTitle: "ー",
                partnerValue: "",
                viewerValue: "",
                status: .skipped
            )
        }

        let issueTags = localIssueTags(signals: signals, review: review)
        return HomeMutualMatchConditionReviewPoint(
            title: "現地交換条件",
            tagTitle: issueTags.isEmpty ? "OK" : issueTags.joined(separator: " / "),
            partnerValue: HomeMutualMatchExchangeConditionReviewDisplay.localConditionText(
                signals.partnerLocalConditionText
            ) ?? "未設定",
            viewerValue: HomeMutualMatchExchangeConditionReviewDisplay.localConditionText(
                signals.viewerLocalConditionText
            ) ?? "未設定",
            status: issueTags.isEmpty ? .matched : .needsDecision
        )
    }

    private static func postalExchangePoint(
        signals: HomeExchangeConditionSignals,
        review: HomeMutualMatchConditionReview
    ) -> HomeMutualMatchConditionReviewPoint {
        let needsDiscussion = review.exchangeItems.containsTitle("送料要相談")
        let isRelevant = signals.postalAcceptedByBoth || signals.viewerShippingFeeTitle != nil || signals.partnerShippingFeeTitle != nil
        return HomeMutualMatchConditionReviewPoint(
            title: "郵送交換条件",
            tagTitle: needsDiscussion ? "送料要相談" : (isRelevant ? "OK" : "ー"),
            partnerValue: isRelevant ? signals.partnerShippingFeeTitle ?? "未設定" : "",
            viewerValue: isRelevant ? signals.viewerShippingFeeTitle ?? "未設定" : "",
            status: needsDiscussion ? .needsDecision : (isRelevant ? .matched : .skipped)
        )
    }

    private static func amountPoint(pair: HomeMutualMatchProposalPair) -> HomeMutualMatchConditionReviewPoint {
        let partnerIsAmountCondition = pair.receiverDisplayItem.data.kind != .goods
        let viewerIsAmountCondition = pair.senderDisplayItem.data.kind != .goods
        guard partnerIsAmountCondition || viewerIsAmountCondition else {
            return HomeMutualMatchConditionReviewPoint(
                title: "金額条件",
                tagTitle: "ー",
                partnerValue: "",
                viewerValue: "",
                status: .skipped
            )
        }

        let compatibility = HomeMutualMatchCashCompatibilityPolicy.compatibility(
            requestedAmount: partnerIsAmountCondition ? pair.receiverDisplayItem.cashAmount : nil,
            counterpartAmount: viewerIsAmountCondition ? pair.senderDisplayItem.cashAmount : nil
        )
        let tagTitle: String
        let status: HomeMutualMatchConditionReviewStatus
        switch compatibility {
        case .matched, .amountIncluded:
            tagTitle = "金額込み候補"
            status = .needsDecision
        case .amountInsufficient:
            tagTitle = "金額不足"
            status = .mismatch
        }

        return HomeMutualMatchConditionReviewPoint(
            title: "金額条件",
            tagTitle: tagTitle,
            partnerValue: amountValue(pair.receiverDisplayItem),
            viewerValue: amountValue(pair.senderDisplayItem),
            status: status
        )
    }

    private static func paymentPoint(
        signals: HomePaymentConditionSignals,
        review: HomeMutualMatchConditionReview
    ) -> HomeMutualMatchConditionReviewPoint {
        if review.paymentItems.first?.status == .skipped {
            return HomeMutualMatchConditionReviewPoint(
                title: "支払条件",
                tagTitle: "ー",
                partnerValue: "",
                viewerValue: "",
                status: .skipped
            )
        }

        let tagTitle: String
        let status: HomeMutualMatchConditionReviewStatus
        switch signals.status {
        case .skipped:
            tagTitle = "ー"
            status = .skipped
        case .compatible:
            tagTitle = "OK"
            status = .matched
        case .methodMismatch:
            tagTitle = "支払方法不一致"
            status = .mismatch
        case .viewerUnset:
            tagTitle = "自分の支払条件未設定"
            status = .needsDecision
        case .partnerUnset:
            tagTitle = "相手の支払条件未設定"
            status = .needsDecision
        case .unset:
            tagTitle = "支払条件未設定"
            status = .needsDecision
        case .needsDiscussion:
            tagTitle = "支払方法要相談"
            status = .needsDecision
        }

        return HomeMutualMatchConditionReviewPoint(
            title: "支払条件",
            tagTitle: tagTitle,
            partnerValue: status == .skipped ? "" : paymentMethodsText(signals.partnerMethods),
            viewerValue: status == .skipped ? "" : paymentMethodsText(signals.viewerMethods),
            status: status
        )
    }

    private static func localIssueTags(
        signals: HomeExchangeConditionSignals,
        review: HomeMutualMatchConditionReview
    ) -> [String] {
        var tags: [String] = []
        if signals.localRoutePrefectureUnset || review.exchangeItems.containsTitle("都道府県未設定") {
            tags.append("都道府県未設定")
        } else if !signals.localRoutePrefectureMatches || review.exchangeItems.containsTitle("都道府県の確認が必要") {
            tags.append("交換場所要相談")
        }
        if !signals.localRouteDateMatches || signals.localRouteDateNeedsDiscussion || review.exchangeItems.containsTitle("日程調整が必要") {
            tags.append("日程要相談")
        }
        return tags
    }

    private static func amountValue(_ item: HomeMutualMatchProposalItem) -> String {
        switch item.data.kind {
        case .goods:
            return "対象外"
        case .fixedPrice, .cashAmount:
            return item.title
        }
    }

    private static func paymentMethodsText(_ methods: [UserPaymentMethod]) -> String {
        UserPaymentMethod.displayText(
            for: methods,
            otherNote: nil,
            emptyText: "未設定"
        )
    }
}
