import Foundation

public struct DetectedFaceObservation: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var boundingBox: FaceBoundingBox
    public var confidence: Double
    public var qualityScore: Double
    public var qualityStatus: FaceQualityStatus
    public var qualityCategory: MemberTaggingQualityStatus
    public var subjectType: MemberTaggingSubjectType
    public var recognitionMethod: MemberTaggingRecognitionMethod

    public init(
        id: UUID = UUID(),
        boundingBox: FaceBoundingBox,
        confidence: Double,
        qualityScore: Double,
        qualityStatus: FaceQualityStatus,
        qualityCategory: MemberTaggingQualityStatus? = nil,
        subjectType: MemberTaggingSubjectType = .realFace,
        recognitionMethod: MemberTaggingRecognitionMethod = .visionFace
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.confidence = min(max(confidence, 0), 1)
        self.qualityScore = min(max(qualityScore, 0), 1)
        self.qualityStatus = qualityStatus
        self.qualityCategory = qualityCategory ?? Self.memberQualityStatus(from: qualityStatus)
        self.subjectType = subjectType
        self.recognitionMethod = recognitionMethod
    }

    private static func memberQualityStatus(from status: FaceQualityStatus) -> MemberTaggingQualityStatus {
        switch status {
        case .usable:
            .ok
        case .tooSmall:
            .tooSmall
        case .lowConfidence, .lowQuality:
            .lowQuality
        }
    }
}

public struct FaceMatchCandidate: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var memberID: UUID
    public var memberName: String
    public var confidence: Double
    public var rank: Int
    public var profileCount: Int

    public init(
        id: UUID = UUID(),
        memberID: UUID,
        memberName: String,
        confidence: Double,
        rank: Int,
        profileCount: Int
    ) {
        self.id = id
        self.memberID = memberID
        self.memberName = memberName
        self.confidence = min(max(confidence, 0), 1)
        self.rank = max(1, rank)
        self.profileCount = max(1, profileCount)
    }
}

public struct FaceTaggingResult: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var imageID: UUID?
    public var imageType: MemberTaggingImageType
    public var face: DetectedFaceObservation
    public var subjectType: MemberTaggingSubjectType
    public var status: FaceMatchStatus
    public var recognitionMethod: MemberTaggingRecognitionMethod
    public var qualityCategory: MemberTaggingQualityStatus
    public var modelVersion: String?
    public var profileType: MemberProfileType?
    public var matchedMemberID: UUID?
    public var matchedMemberName: String?
    public var confidence: Double?
    public var candidates: [FaceMatchCandidate]
    public var errorMessage: String?

    public var subjectID: UUID { id }

    public init(
        id: UUID = UUID(),
        imageID: UUID? = nil,
        imageType: MemberTaggingImageType = .realPhoto,
        face: DetectedFaceObservation,
        subjectType: MemberTaggingSubjectType? = nil,
        status: FaceMatchStatus,
        recognitionMethod: MemberTaggingRecognitionMethod? = nil,
        qualityCategory: MemberTaggingQualityStatus? = nil,
        modelVersion: String? = nil,
        profileType: MemberProfileType? = nil,
        matchedMemberID: UUID? = nil,
        matchedMemberName: String? = nil,
        confidence: Double? = nil,
        candidates: [FaceMatchCandidate] = [],
        errorMessage: String? = nil
    ) {
        self.id = id
        self.imageID = imageID
        self.imageType = imageType
        self.face = face
        self.subjectType = subjectType ?? face.subjectType
        self.status = status
        self.recognitionMethod = recognitionMethod ?? face.recognitionMethod
        self.qualityCategory = qualityCategory ?? face.qualityCategory
        self.modelVersion = modelVersion?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.profileType = profileType
        self.matchedMemberID = matchedMemberID
        self.matchedMemberName = matchedMemberName
        self.confidence = confidence.map { min(max($0, 0), 1) }
        self.candidates = candidates
        self.errorMessage = errorMessage
    }
}

public struct FaceTaggingAnalysis: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var imageID: UUID
    public var imageType: MemberTaggingImageType
    public var createdAt: Date
    public var status: FaceMatchStatus
    public var results: [FaceTaggingResult]

    public init(
        id: UUID = UUID(),
        imageID: UUID = UUID(),
        imageType: MemberTaggingImageType = .realPhoto,
        createdAt: Date = Date(),
        status: FaceMatchStatus,
        results: [FaceTaggingResult] = []
    ) {
        self.id = id
        self.imageID = imageID
        self.imageType = imageType
        self.createdAt = createdAt
        self.status = status
        self.results = results
    }
}
