import Foundation

public enum TradeDisputeCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case short
    case wrong
    case noshow
    case cancel
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .short:
            "受け取った点数が少ない"
        case .wrong:
            "グッズが違う・状態が悪い"
        case .noshow:
            "相手が現れなかった"
        case .cancel:
            "合意済みのキャンセル"
        case .other:
            "その他"
        }
    }
}

public struct TradeDisputeCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var category: TradeDisputeCategory
    public var factMemo: String

    public init(proposalID: UUID, category: TradeDisputeCategory, factMemo: String) {
        self.proposalID = proposalID
        self.category = category
        self.factMemo = factMemo
    }
}

public struct TradeDisputeTicket: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var ticketNo: String
    public var status: String
    public var submittedAt: Date

    public init(
        id: UUID,
        proposalID: UUID,
        ticketNo: String,
        status: String,
        submittedAt: Date = .now
    ) {
        self.id = id
        self.proposalID = proposalID
        self.ticketNo = ticketNo
        self.status = status
        self.submittedAt = submittedAt
    }
}
