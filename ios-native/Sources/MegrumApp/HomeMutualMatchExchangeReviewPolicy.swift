import Foundation

enum HomeMutualMatchExchangeReviewPolicy {
    static func items(
        for signals: HomeExchangeConditionSignals
    ) -> [HomeMutualMatchConditionReviewItem] {
        guard signals.localExchangeSelected || signals.postalAcceptedByBoth else {
            return [
                HomeMutualMatchConditionReviewItemFactory.make(
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
                    HomeMutualMatchConditionReviewItemFactory.make(
                        category: "交換条件",
                        title: "送料要相談",
                        detail: "郵送交換はできますが、送料負担を決める必要があります",
                        status: .needsDecision
                    )
                ]
            }

            return [
                HomeMutualMatchConditionReviewItemFactory.make(
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
                    HomeMutualMatchConditionReviewItemFactory.make(
                        category: "交換条件",
                        title: "全一致",
                        detail: "現地交換も郵送交換も候補にできます",
                        status: .matched
                    )
                ]
            }

            var items = [
                HomeMutualMatchConditionReviewItemFactory.make(
                    category: "交換条件",
                    title: signals.localExchangeSelected ? "郵送交換で成立可能" : "全一致",
                    detail: signals.localExchangeSelected ? "現地交換は必要に応じて調整できます" : "郵送交換で進められます",
                    status: .matched
                )
            ]

            if signals.localExchangeSelected && !signals.prefectureMatches {
                items.append(
                    HomeMutualMatchConditionReviewItemFactory.make(
                        category: "交換条件",
                        title: "都道府県の確認が必要",
                        detail: "現地交換にする場合は場所をすり合わせます",
                        status: .needsDecision
                    )
                )
            }

            if signals.localExchangeSelected && (!signals.dateMatches || signals.dateNeedsDiscussion) {
                items.append(
                    HomeMutualMatchConditionReviewItemFactory.make(
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
                HomeMutualMatchConditionReviewItemFactory.make(
                    category: "交換条件",
                    title: "全一致",
                    detail: "現地交換で進められます",
                    status: .matched
                )
            )
        } else {
            if signals.prefectureUnset {
                items.append(
                    HomeMutualMatchConditionReviewItemFactory.make(
                        category: "交換条件",
                        title: "都道府県未設定",
                        detail: "現地交換にする場合は都道府県を確認します",
                        status: .needsDecision
                    )
                )
            }

            if !signals.prefectureMatches {
                items.append(
                    HomeMutualMatchConditionReviewItemFactory.make(
                        category: "交換条件",
                        title: "都道府県の確認が必要",
                        detail: "現地交換の場所をすり合わせます",
                        status: .needsDecision
                    )
                )
            }

            if !signals.dateMatches || signals.dateNeedsDiscussion {
                items.append(
                    HomeMutualMatchConditionReviewItemFactory.make(
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

}
