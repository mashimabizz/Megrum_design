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
