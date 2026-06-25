import Foundation

public struct TradeEvidencePhoto: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var photoURL: URL
    public var position: Int
    public var takenAt: Date?
    public var takenBy: UUID

    public init(
        id: UUID,
        proposalID: UUID,
        photoURL: URL,
        position: Int,
        takenAt: Date? = nil,
        takenBy: UUID
    ) {
        self.id = id
        self.proposalID = proposalID
        self.photoURL = photoURL
        self.position = max(1, position)
        self.takenAt = takenAt
        self.takenBy = takenBy
    }

    public func isUploadedBy(_ userID: UUID?) -> Bool {
        takenBy == userID
    }
}

public struct TradeEvidenceCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var imageData: Data
    public var imageContentType: String

    public init(proposalID: UUID, imageData: Data, imageContentType: String) {
        self.proposalID = proposalID
        self.imageData = imageData
        self.imageContentType = imageContentType
    }
}

public struct TradeEvaluationCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var stars: Int
    public var comment: String?

    public init(proposalID: UUID, stars: Int, comment: String? = nil) {
        self.proposalID = proposalID
        self.stars = stars
        self.comment = comment
    }
}
