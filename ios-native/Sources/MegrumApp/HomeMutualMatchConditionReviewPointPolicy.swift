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
        let resolvedTitle = resolvedExchangeMethodTitle(signals)
        let needsDiscussion = !isMismatch && resolvedTitle == nil && exchangeMethodNeedsDiscussion(signals)
        return HomeMutualMatchConditionReviewPoint(
            title: "交換条件",
            tagTitle: isMismatch ? "交換条件不一致" : (resolvedTitle ?? (needsDiscussion ? "要相談" : "OK")),
            partnerValue: displayExchangeMethodTitle(signals.partnerExchangeMethodTitle) ?? inferredExchangeMethodTitle(signals),
            viewerValue: displayExchangeMethodTitle(signals.viewerExchangeMethodTitle) ?? inferredExchangeMethodTitle(signals),
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
            partnerValue: displayLocalConditionText(signals.partnerLocalConditionText) ?? "未設定",
            viewerValue: displayLocalConditionText(signals.viewerLocalConditionText) ?? "未設定",
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

    private static func resolvedExchangeMethodTitle(_ signals: HomeExchangeConditionSignals) -> String? {
        guard let viewerMethod = handoffDraft(from: signals.viewerExchangeMethodTitle),
              let partnerMethod = handoffDraft(from: signals.partnerExchangeMethodTitle)
        else {
            return nil
        }

        switch (viewerMethod, partnerMethod) {
        case (.both, .local), (.local, .both):
            return IndividualListingHandoffDraft.local.title
        case (.both, .mail), (.mail, .both):
            return IndividualListingHandoffDraft.mail.title
        default:
            return nil
        }
    }

    private static func exchangeMethodNeedsDiscussion(_ signals: HomeExchangeConditionSignals) -> Bool {
        let methods = [
            handoffDraft(from: signals.viewerExchangeMethodTitle),
            handoffDraft(from: signals.partnerExchangeMethodTitle)
        ]

        if methods.allSatisfy({ $0 == .both }) {
            return true
        }

        if methods.contains(where: { $0 == .both }) && methods.contains(where: { $0 == nil }) {
            return true
        }

        return inferredExchangeMethodTitle(signals) == IndividualListingHandoffDraft.both.title
    }

    private static func handoffDraft(from title: String?) -> IndividualListingHandoffDraft? {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty
        else {
            return nil
        }
        return IndividualListingHandoffDraft.allCases.first { draft in
            draft.title == title || (draft == .both && title == "どちらもOK")
        }
    }

    private static func displayExchangeMethodTitle(_ title: String?) -> String? {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty
        else {
            return nil
        }
        return title == "どちらもOK" ? IndividualListingHandoffDraft.both.title : title
    }

    private static func displayLocalConditionText(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty
        else {
            return nil
        }
        let parts = value
            .components(separatedBy: " / ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { part -> String? in
                guard !part.isEmpty else {
                    return nil
                }
                let normalized = normalizedForDisplay(part)
                if normalized == normalizedForDisplay("場所相談") || normalized == normalizedForDisplay("相談") {
                    return nil
                }
                if normalized == normalizedForDisplay(IndividualListingExchangeSummary.defaultLocalSchedule) {
                    return "日程は相談"
                }
                return part
            }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    private static func normalizedForDisplay(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }

    private static func inferredExchangeMethodTitle(_ signals: HomeExchangeConditionSignals) -> String {
        switch (signals.localExchangeSelected, signals.postalAcceptedByBoth) {
        case (true, true):
            return IndividualListingHandoffDraft.both.title
        case (true, false):
            return "現地交換"
        case (false, true):
            return "郵送交換"
        case (false, false):
            return "未設定"
        }
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
