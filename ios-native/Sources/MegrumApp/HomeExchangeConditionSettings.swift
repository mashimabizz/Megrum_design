import Foundation
import MegrumCore

enum HomeExchangeSettingsStorageKeys {
    static let preference = "megrum.home.exchangeSettings.preference"
    static let requiresSamePrefecture = "megrum.home.exchangeSettings.requiresSamePrefecture"
    static let requiresDateOverlap = "megrum.home.exchangeSettings.requiresDateOverlap"
}

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

struct HomeDefaultExchangeSettings: Equatable, Sendable {
    var preference: HomeExchangePreference
    var requiresSamePrefecture: Bool
    var requiresDateOverlap: Bool

    static let standard = HomeDefaultExchangeSettings(
        preference: .both,
        requiresSamePrefecture: true,
        requiresDateOverlap: false
    )

    init(
        preference: HomeExchangePreference = .both,
        requiresSamePrefecture: Bool = true,
        requiresDateOverlap: Bool = false
    ) {
        self.preference = preference
        self.requiresSamePrefecture = requiresSamePrefecture
        self.requiresDateOverlap = requiresDateOverlap
    }

    init(preferenceRawValue: String, requiresSamePrefecture _: Bool, requiresDateOverlap _: Bool) {
        self.init(
            preference: HomeExchangePreference(rawValue: preferenceRawValue) ?? Self.standard.preference,
            requiresSamePrefecture: Self.standard.requiresSamePrefecture,
            requiresDateOverlap: Self.standard.requiresDateOverlap
        )
    }

    var summaryText: String {
        preference.displayName
    }

    func applying(to signals: HomeCandidateConditionSignals) -> HomeCandidateConditionSignals {
        var updated = signals
        updated.exchange = applying(to: signals.exchange)
        return updated
    }

    func applying(to signals: HomeExchangeConditionSignals) -> HomeExchangeConditionSignals {
        HomeExchangeConditionSignals(
            postalAcceptedByBoth: preference.acceptsMail && signals.postalAcceptedByBoth,
            localExchangeSelected: preference.acceptsLocal && signals.localExchangeSelected,
            prefectureMatches: requiresSamePrefecture ? signals.prefectureMatches : true,
            dateMatches: requiresDateOverlap ? signals.dateMatches : true,
            prefectureUnset: requiresSamePrefecture ? signals.prefectureUnset : false,
            shippingFeeNeedsDiscussion: preference.acceptsMail && signals.shippingFeeNeedsDiscussion
        )
    }

    func applying(to signalsByItemID: [UUID: HomeCandidateConditionSignals]) -> [UUID: HomeCandidateConditionSignals] {
        signalsByItemID.mapValues(applying)
    }
}
