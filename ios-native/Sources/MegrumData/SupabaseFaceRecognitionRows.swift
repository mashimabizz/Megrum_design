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

struct MemberFaceProfileRow: Decodable, Equatable, Sendable {
    static let select = "id,character_id,profile_type,embedding,embedding_model,source_image_url,consent_recorded_at,deleted_at,character:characters_master(name)"

    var id: UUID
    var characterID: UUID
    var profileType: MemberProfileType?
    var embedding: [Double]
    var embeddingModel: String
    var sourceImageURL: String?
    var consentRecordedAt: Date?
    var deletedAt: Date?
    var character: FaceRecognitionRelation?

    enum CodingKeys: String, CodingKey {
        case id
        case characterID = "characterId"
        case profileType
        case embedding
        case embeddingModel
        case sourceImageURL = "sourceImageUrl"
        case consentRecordedAt
        case deletedAt
        case character
    }

    var memberFaceProfile: MemberFaceProfile {
        MemberFaceProfile(
            id: id,
            memberID: characterID,
            memberName: character?.name ?? "",
            embedding: FaceEmbedding(values: embedding, modelIdentifier: embeddingModel),
            profileType: profileType ?? .realFace,
            sourceImageURL: sourceImageURL.flatMap(URL.init(string:)),
            consentRecordedAt: consentRecordedAt,
            isDeleted: deletedAt != nil
        )
    }
}

struct FaceUploadedImagePayload: Encodable, Sendable {
    var userID: UUID
    var inventoryID: UUID?
    var storageBucket: String?
    var storagePath: String?
    var imageURL: String?
    var imageHash: String?
    var contentType: String
    var imageType: MemberTaggingImageType
    var analysisStatus: FaceMatchStatus?

    init(userID: UUID, input: FaceUploadedImageInput) {
        self.userID = userID
        self.inventoryID = input.inventoryID
        self.storageBucket = SupabaseTextNormalizer.optional(input.storageBucket)
        self.storagePath = SupabaseTextNormalizer.optional(input.storagePath)
        self.imageURL = SupabaseTextNormalizer.optional(input.imageURL)
        self.imageHash = SupabaseTextNormalizer.optional(input.imageHash)
        self.contentType = SupabaseTextNormalizer.optional(input.contentType) ?? "image/jpeg"
        self.imageType = input.imageType
        self.analysisStatus = input.analysisStatus
    }
}

struct DetectedFacePayload: Encodable, Sendable {
    var uploadedImageID: UUID
    var boundingBox: FaceBoundingBoxPayload
    var detectionConfidence: Double
    var qualityScore: Double
    var legacyQualityStatus: FaceQualityStatus
    var qualityStatus: MemberTaggingQualityStatus
    var imageType: MemberTaggingImageType
    var subjectType: MemberTaggingSubjectType
    var recognitionMethod: MemberTaggingRecognitionMethod
    var modelVersion: String?
    var profileType: MemberProfileType?
    var matchStatus: FaceMatchStatus
    var matchedCharacterID: UUID?
    var matchedConfidence: Double?

    enum CodingKeys: String, CodingKey {
        case uploadedImageID
        case boundingBox
        case detectionConfidence
        case qualityScore
        case legacyQualityStatus
        case qualityStatus
        case imageType
        case subjectType
        case recognitionMethod
        case modelVersion
        case profileType
        case matchStatus
        case matchedCharacterID
        case matchedConfidence
    }

    init(uploadedImageID: UUID, result: FaceTaggingResult) {
        self.uploadedImageID = uploadedImageID
        self.boundingBox = FaceBoundingBoxPayload(result.face.boundingBox)
        self.detectionConfidence = result.face.confidence
        self.qualityScore = result.face.qualityScore
        self.legacyQualityStatus = result.face.qualityStatus
        self.qualityStatus = result.qualityCategory
        self.imageType = result.imageType
        self.subjectType = result.subjectType
        self.recognitionMethod = result.recognitionMethod
        self.modelVersion = SupabaseTextNormalizer.optional(result.modelVersion)
        self.profileType = result.profileType
        self.matchStatus = result.status
        self.matchedCharacterID = result.matchedMemberID
        self.matchedConfidence = result.confidence
    }
}

struct FaceBoundingBoxPayload: Encodable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(_ box: FaceBoundingBox) {
        self.x = box.x
        self.y = box.y
        self.width = box.width
        self.height = box.height
    }
}

struct FaceMatchCandidatePayload: Encodable, Sendable {
    var detectedFaceID: UUID
    var characterID: UUID
    var confidence: Double
    var rank: Int
    var profileCount: Int

    init(detectedFaceID: UUID, candidate: FaceMatchCandidate) {
        self.detectedFaceID = detectedFaceID
        self.characterID = candidate.memberID
        self.confidence = candidate.confidence
        self.rank = candidate.rank
        self.profileCount = candidate.profileCount
    }
}

struct FaceMatchCorrectionPayload: Encodable, Sendable {
    var detectedFaceID: UUID
    var userID: UUID
    var originalMatchStatus: FaceMatchStatus
    var selectedCharacterID: UUID?
    var selectedMemberName: String?
    var imageType: MemberTaggingImageType
    var subjectType: MemberTaggingSubjectType
    var recognitionMethod: MemberTaggingRecognitionMethod
    var selectedProfileType: MemberProfileType?
    var shouldAddTrainingData: Bool

    init(userID: UUID, input: FaceMatchCorrectionInput) {
        self.detectedFaceID = input.detectedFaceID
        self.userID = userID
        self.originalMatchStatus = input.originalMatchStatus
        self.selectedCharacterID = input.selectedCharacterID
        self.selectedMemberName = SupabaseTextNormalizer.optional(input.selectedMemberName)
        self.imageType = input.imageType
        self.subjectType = input.subjectType
        self.recognitionMethod = input.recognitionMethod
        self.selectedProfileType = input.selectedProfileType
        self.shouldAddTrainingData = input.shouldAddTrainingData
    }
}

struct FaceMatchCorrectionRow: Decodable, Sendable {
    var id: UUID
}

struct FaceRecognitionRelation: Decodable, Equatable, Sendable {
    var name: String?
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
