import Foundation

public struct FaceBoundingBox: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        let minX = Self.clamped(x)
        let minY = Self.clamped(y)
        let maxX = Self.clamped(x + max(0, width))
        let maxY = Self.clamped(y + max(0, height))
        self.x = min(minX, maxX)
        self.y = min(minY, maxY)
        self.width = max(0, maxX - minX)
        self.height = max(0, maxY - minY)
    }

    public var area: Double {
        width * height
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

public struct FaceEmbedding: Codable, Hashable, Sendable {
    public var values: [Double]
    public var modelIdentifier: String
    public var createdAt: Date?

    public init(values: [Double], modelIdentifier: String, createdAt: Date? = nil) {
        self.values = values
        self.modelIdentifier = modelIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }
}

public struct MemberFaceProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var memberID: UUID
    public var memberName: String
    public var embedding: FaceEmbedding
    public var profileType: MemberProfileType
    public var sourceImageURL: URL?
    public var consentRecordedAt: Date?
    public var isDeleted: Bool

    public init(
        id: UUID = UUID(),
        memberID: UUID,
        memberName: String,
        embedding: FaceEmbedding,
        profileType: MemberProfileType = .realFace,
        sourceImageURL: URL? = nil,
        consentRecordedAt: Date? = nil,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.memberID = memberID
        self.memberName = memberName
        self.embedding = embedding
        self.profileType = profileType
        self.sourceImageURL = sourceImageURL
        self.consentRecordedAt = consentRecordedAt
        self.isDeleted = isDeleted
    }
}
