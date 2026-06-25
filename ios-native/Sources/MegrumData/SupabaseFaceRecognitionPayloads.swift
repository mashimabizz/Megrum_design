import Foundation
import MegrumCore

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
