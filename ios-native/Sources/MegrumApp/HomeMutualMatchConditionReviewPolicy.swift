import Foundation
import MegrumCore

enum HomeMutualMatchConditionReviewPolicy {
    static func review(for pair: HomeMutualMatchProposalPair) -> HomeMutualMatchConditionReview {
        HomeMutualMatchConditionReview(
            exchangeItems: exchangeItems(for: pair.signals.exchange),
            paymentItems: paymentItems(for: pair.signals)
        )
    }

    private static func exchangeItems(
        for signals: HomeExchangeConditionSignals
    ) -> [HomeMutualMatchConditionReviewItem] {
        guard signals.localExchangeSelected || signals.postalAcceptedByBoth else {
            return [
                item(
                    category: "交換条件",
                    title: "交換手段が不一致",
                    detail: "現地交換か郵送交換のどちらで進めるか確認が必要です",
                    status: .mismatch
                )
            ]
        }

        if signals.postalAcceptedByBoth && !signals.localExchangeSelected {
            if signals.shippingFeeNeedsDiscussion {
                return [
                    item(
                        category: "交換条件",
                        title: "送料要相談",
                        detail: "郵送交換はできますが、送料負担を決める必要があります",
                        status: .needsDecision
                    )
                ]
            }

            return [
                item(
                    category: "交換条件",
                    title: "全一致",
                    detail: "郵送交換で進められます",
                    status: .matched
                )
            ]
        }

        if signals.postalAcceptedByBoth {
            if signals.localExchangeSelected
                && signals.prefectureMatches
                && signals.dateMatches
                && !signals.dateNeedsDiscussion {
                return [
                    item(
                        category: "交換条件",
                        title: "全一致",
                        detail: "現地交換も郵送交換も候補にできます",
                        status: .matched
                    )
                ]
            }

            var items = [
                item(
                    category: "交換条件",
                    title: signals.localExchangeSelected ? "郵送交換で成立可能" : "全一致",
                    detail: signals.localExchangeSelected ? "現地交換は必要に応じて調整できます" : "郵送交換で進められます",
                    status: .matched
                )
            ]

            if signals.localExchangeSelected && !signals.prefectureMatches {
                items.append(
                    item(
                        category: "交換条件",
                        title: "都道府県の確認が必要",
                        detail: "現地交換にする場合は場所をすり合わせます",
                        status: .needsDecision
                    )
                )
            }

            if signals.localExchangeSelected && (!signals.dateMatches || signals.dateNeedsDiscussion) {
                items.append(
                    item(
                        category: "交換条件",
                        title: "日程調整が必要",
                        detail: "現地交換にする場合は会える日程を決めます",
                        status: .needsDecision
                    )
                )
            }

            return items
        }

        var items: [HomeMutualMatchConditionReviewItem] = []

        if signals.prefectureMatches
            && signals.dateMatches
            && !signals.prefectureUnset
            && !signals.dateNeedsDiscussion {
            items.append(
                item(
                    category: "交換条件",
                    title: "全一致",
                    detail: "現地交換で進められます",
                    status: .matched
                )
            )
        } else {
            if signals.prefectureUnset {
                items.append(
                    item(
                        category: "交換条件",
                        title: "都道府県未設定",
                        detail: "現地交換にする場合は都道府県を確認します",
                        status: .needsDecision
                    )
                )
            }

            if !signals.prefectureMatches {
                items.append(
                    item(
                        category: "交換条件",
                        title: "都道府県の確認が必要",
                        detail: "現地交換の場所をすり合わせます",
                        status: .needsDecision
                    )
                )
            }

            if !signals.dateMatches || signals.dateNeedsDiscussion {
                items.append(
                    item(
                        category: "交換条件",
                        title: "日程調整が必要",
                        detail: "会える日程を決めます",
                        status: .needsDecision
                    )
                )
            }
        }

        return items
    }

    private static func paymentItems(
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
