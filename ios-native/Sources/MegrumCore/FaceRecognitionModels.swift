import Foundation

public enum FaceMatchStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case autoMatched = "auto_matched"
    case needsReview = "needs_review"
    case unknown
    case noFace = "no_face"
    case noSubject = "no_subject"
    case lowQuality = "low_quality"

    public var id: String { rawValue }
}

public enum MemberTaggingImageType: String, Codable, CaseIterable, Identifiable, Sendable {
    case realPhoto = "real_photo"
    case anime
    case illustration
    case manga
    case unknown

    public var id: String { rawValue }

    public var usesAnimeThresholds: Bool {
        switch self {
        case .anime, .illustration, .manga:
            true
        case .realPhoto, .unknown:
            false
        }
    }
}

public enum MemberTaggingSubjectType: String, Codable, CaseIterable, Identifiable, Sendable {
    case realFace = "real_face"
    case animeFace = "anime_face"
    case character
    case unknown

    public var id: String { rawValue }
}

public enum MemberTaggingRecognitionMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case visionFace = "vision_face"
    case coreMLRealFace = "coreml_real_face"
    case realFaceEmbedding = "real_face_embedding"
    case animeFaceDetector = "anime_face_detector"
    case animeCharacterClassifier = "anime_character_classifier"
    case animeEmbeddingSimilarity = "anime_embedding_similarity"
    case manual
    case unknown

    public var id: String { rawValue }
}

public enum MemberTaggingQualityStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case ok
    case lowQuality = "low_quality"
    case tooSmall = "too_small"
    case occluded
    case sideFace = "side_face"
    case stylized
    case unknown

    public var id: String { rawValue }
}

public enum MemberProfileType: String, Codable, CaseIterable, Identifiable, Sendable {
    case realFace = "real_face"
    case animeFace = "anime_face"
    case animeCharacter = "anime_character"
    case illustrationEmbedding = "illustration_embedding"

    public var id: String { rawValue }
}

public enum FaceQualityStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case usable
    case tooSmall = "too_small"
    case lowConfidence = "low_confidence"
    case lowQuality = "low_quality"

    public var id: String { rawValue }

    public var isUsable: Bool {
        self == .usable
    }
}

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
