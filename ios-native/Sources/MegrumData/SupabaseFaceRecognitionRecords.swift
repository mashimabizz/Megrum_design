import Foundation
import MegrumCore

public struct FaceUploadedImageInput: Equatable, Sendable {
    public var inventoryID: UUID?
    public var storageBucket: String?
    public var storagePath: String?
    public var imageURL: String?
    public var imageHash: String?
    public var contentType: String
    public var imageType: MemberTaggingImageType
    public var analysisStatus: FaceMatchStatus?

    public init(
        inventoryID: UUID? = nil,
        storageBucket: String? = nil,
        storagePath: String? = nil,
        imageURL: String? = nil,
        imageHash: String? = nil,
        contentType: String = "image/jpeg",
        imageType: MemberTaggingImageType = .unknown,
        analysisStatus: FaceMatchStatus? = nil
    ) {
        self.inventoryID = inventoryID
        self.storageBucket = storageBucket
        self.storagePath = storagePath
        self.imageURL = imageURL
        self.imageHash = imageHash
        self.contentType = contentType
        self.imageType = imageType
        self.analysisStatus = analysisStatus
    }
}

public struct FaceUploadedImageRecord: Identifiable, Decodable, Equatable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var inventoryID: UUID?
    public var storageBucket: String?
    public var storagePath: String?
    public var imageURL: String?
    public var imageHash: String?
    public var contentType: String
    public var imageType: MemberTaggingImageType
    public var analysisStatus: FaceMatchStatus?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "userId"
        case inventoryID = "inventoryId"
        case storageBucket
        case storagePath
        case imageURL = "imageUrl"
        case imageHash
        case contentType
        case imageType
        case analysisStatus
        case createdAt
    }
}

public struct DetectedFaceRecord: Identifiable, Decodable, Equatable, Sendable {
    public var id: UUID
    public var uploadedImageID: UUID
    public var imageType: MemberTaggingImageType
    public var subjectType: MemberTaggingSubjectType
    public var recognitionMethod: MemberTaggingRecognitionMethod
    public var qualityStatus: MemberTaggingQualityStatus
    public var modelVersion: String?
    public var profileType: MemberProfileType?
    public var matchStatus: FaceMatchStatus
    public var matchedCharacterID: UUID?
    public var matchedConfidence: Double?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case uploadedImageID = "uploadedImageId"
        case imageType
        case subjectType
        case recognitionMethod
        case qualityStatus
        case modelVersion
        case profileType
        case matchStatus
        case matchedCharacterID = "matchedCharacterId"
        case matchedConfidence
        case createdAt
    }
}

public struct FaceMatchCandidateRecord: Identifiable, Decodable, Equatable, Sendable {
    public var id: UUID
    public var detectedFaceID: UUID
    public var characterID: UUID
    public var confidence: Double
    public var rank: Int
    public var profileCount: Int
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case detectedFaceID = "detectedFaceId"
        case characterID = "characterId"
        case confidence
        case rank
        case profileCount
        case createdAt
    }
}

public struct FaceMatchCorrectionInput: Equatable, Sendable {
    public var detectedFaceID: UUID
    public var originalMatchStatus: FaceMatchStatus
    public var selectedCharacterID: UUID?
    public var selectedMemberName: String?
    public var imageType: MemberTaggingImageType
    public var subjectType: MemberTaggingSubjectType
    public var recognitionMethod: MemberTaggingRecognitionMethod
    public var selectedProfileType: MemberProfileType?
    public var shouldAddTrainingData: Bool

    public init(
        detectedFaceID: UUID,
        originalMatchStatus: FaceMatchStatus,
        selectedCharacterID: UUID? = nil,
        selectedMemberName: String? = nil,
        imageType: MemberTaggingImageType = .unknown,
        subjectType: MemberTaggingSubjectType = .unknown,
        recognitionMethod: MemberTaggingRecognitionMethod = .manual,
        selectedProfileType: MemberProfileType? = nil,
        shouldAddTrainingData: Bool = false
    ) {
        self.detectedFaceID = detectedFaceID
        self.originalMatchStatus = originalMatchStatus
        self.selectedCharacterID = selectedCharacterID
        self.selectedMemberName = selectedMemberName
        self.imageType = imageType
        self.subjectType = subjectType
        self.recognitionMethod = recognitionMethod
        self.selectedProfileType = selectedProfileType
        self.shouldAddTrainingData = shouldAddTrainingData
    }
}

extension FaceUploadedImageRecord {
    static let select = "id,user_id,inventory_id,storage_bucket,storage_path,image_url,image_hash,content_type,image_type,analysis_status,created_at"
}

extension DetectedFaceRecord {
    static let select = "id,uploaded_image_id,image_type,subject_type,recognition_method,quality_status,model_version,profile_type,match_status,matched_character_id,matched_confidence,created_at"
}

extension FaceMatchCandidateRecord {
    static let select = "id,detected_face_id,character_id,confidence,rank,profile_count,created_at"
}
