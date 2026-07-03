import Foundation

enum HomeMutualMatchConditionReviewItemFactory {
    static func make(
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
