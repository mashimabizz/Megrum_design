import MegrumCore

enum HomeExchangePreference: String, CaseIterable, Identifiable, Sendable {
    case local
    case mail
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地交換・郵送OK"
        }
    }

    var detailText: String {
        switch self {
        case .local:
            "会場や駅周辺など、直接会える相手を優先します。"
        case .mail:
            "発送で交換できる相手を優先します。"
        case .both:
            "現地と郵送のどちらかが合う相手を広く表示します。"
        }
    }

    var acceptsLocal: Bool {
        self == .local || self == .both
    }

    var acceptsMail: Bool {
        self == .mail || self == .both
    }
}

extension HomeExchangePreference {
    var listingHandoffDraft: IndividualListingHandoffDraft {
        switch self {
        case .local:
            .local
        case .mail:
            .mail
        case .both:
            .both
        }
    }
}
