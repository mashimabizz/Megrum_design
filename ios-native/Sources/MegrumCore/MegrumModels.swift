import Foundation

public enum ExchangeMethod: String, Codable, Sendable, CaseIterable, Identifiable {
    case hand
    case mail
    case both

    public var id: String { rawValue }

    public init?(exchangeTypeValue: String?) {
        switch exchangeTypeValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "hand", "local", "in_person":
            self = .hand
        case "mail", "postal", "shipping":
            self = .mail
        case "both", "any":
            self = .both
        default:
            return nil
        }
    }

    public var displayName: String {
        switch self {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地交換・郵送OK"
        }
    }
}

public enum ProposalStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case draft
    case sent
    case negotiating
    case agreementOneSide = "agreement_one_side"
    case agreed
    case rejected
    case expired
    case cancelled
    case completed

    public var id: String { rawValue }
}

public enum MatchBucket: String, Codable, Sendable, CaseIterable, Identifiable {
    case matched
    case possible
    case noMatch = "no_match"

    public var id: String { rawValue }
}
