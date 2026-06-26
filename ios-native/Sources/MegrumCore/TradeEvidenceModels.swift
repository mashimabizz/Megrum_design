import Foundation

public struct TradeEvidencePhoto: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var photoURL: URL
    public var position: Int
    public var takenAt: Date?
    public var takenBy: UUID
    public var approvedBySender: Bool
    public var approvedByReceiver: Bool

    public init(
        id: UUID,
        proposalID: UUID,
        photoURL: URL,
        position: Int,
        takenAt: Date? = nil,
        takenBy: UUID,
        approvedBySender: Bool = false,
        approvedByReceiver: Bool = false
    ) {
        self.id = id
        self.proposalID = proposalID
        self.photoURL = photoURL
        self.position = max(1, position)
        self.takenAt = takenAt
        self.takenBy = takenBy
        self.approvedBySender = approvedBySender
        self.approvedByReceiver = approvedByReceiver
    }

    public func isUploadedBy(_ userID: UUID?) -> Bool {
        takenBy == userID
    }

    public func isApproved(by userID: UUID?, in proposal: TradeProposal) -> Bool {
        guard let userID, proposal.isParticipant(userID) else {
            return false
        }
        if takenBy == userID {
            return true
        }
        return proposal.isSender(userID) ? approvedBySender : approvedByReceiver
    }

    public func isPartnerApproved(for userID: UUID?, in proposal: TradeProposal) -> Bool {
        guard let userID, let partnerID = proposal.partnerID(for: userID) else {
            return false
        }
        return isApproved(by: partnerID, in: proposal)
    }
}

public struct TradeEvidenceCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var imageData: Data
    public var imageContentType: String
    public var systemMessageBody: String?

    public init(
        proposalID: UUID,
        imageData: Data,
        imageContentType: String,
        systemMessageBody: String? = nil
    ) {
        self.proposalID = proposalID
        self.imageData = imageData
        self.imageContentType = imageContentType
        self.systemMessageBody = systemMessageBody
    }
}

public struct TradeEvaluationCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var stars: Int
    public var comment: String?
    public var systemMessageBody: String?
    public var raterDisplayName: String?
    public var raterHandle: String?

    public init(
        proposalID: UUID,
        stars: Int,
        comment: String? = nil,
        systemMessageBody: String? = nil,
        raterDisplayName: String? = nil,
        raterHandle: String? = nil
    ) {
        self.proposalID = proposalID
        self.stars = stars
        self.comment = comment
        self.systemMessageBody = systemMessageBody
        self.raterDisplayName = raterDisplayName
        self.raterHandle = raterHandle
    }
}
