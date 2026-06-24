import Foundation

enum HomeMutualMatchConditionReviewStatus: Equatable {
    case matched
    case needsDecision
    case mismatch
    case skipped

    var label: String {
        switch self {
        case .matched:
            return "一致"
        case .needsDecision:
            return "要相談"
        case .mismatch:
            return "不一致"
        case .skipped:
            return "確認不要"
        }
    }
}

struct HomeMutualMatchConditionReviewItem: Identifiable, Equatable {
    var id: String { "\(category)-\(title)-\(detail)" }
    var category: String
    var title: String
    var detail: String
    var status: HomeMutualMatchConditionReviewStatus
}

struct HomeMutualMatchConditionReview: Equatable {
    var exchangeItems: [HomeMutualMatchConditionReviewItem]
    var paymentItems: [HomeMutualMatchConditionReviewItem]

    var allItems: [HomeMutualMatchConditionReviewItem] {
        exchangeItems + paymentItems
    }
}

struct HomeMutualMatchConditionReviewPoint: Identifiable, Equatable {
    var id: String { title }
    var title: String
    var tagTitle: String
    var partnerValue: String
    var viewerValue: String
    var status: HomeMutualMatchConditionReviewStatus
}

extension [HomeMutualMatchConditionReviewItem] {
    func containsTitle(_ title: String) -> Bool {
        contains { $0.title == title }
    }
}
