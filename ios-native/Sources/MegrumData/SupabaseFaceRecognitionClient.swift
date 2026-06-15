import Foundation
import MegrumCore

public enum SupabaseFaceRecognitionClientError: Error, Equatable, Sendable {
    case emptyDetectedFaces
    case emptyCandidates
}

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

    private enum CodingKeys: String, CodingKey {
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

    private enum CodingKeys: String, CodingKey {
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

    private enum CodingKeys: String, CodingKey {
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

public final class SupabaseFaceRecognitionClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadMemberFaceProfiles(memberIDs: [UUID] = [], limit: Int = 500) async throws -> [MemberFaceProfile] {
        let rows: [MemberFaceProfileRow] = try await client.fetchRows(
            from: "member_face_profiles",
            select: MemberFaceProfileRow.select,
            queryItems: loadMemberFaceProfileQueryItems(memberIDs: memberIDs, limit: limit)
        )
        return rows.map(\.memberFaceProfile)
    }

    public func createUploadedImage(userID: UUID, input: FaceUploadedImageInput) async throws -> FaceUploadedImageRecord {
        let rows: [FaceUploadedImageRecord] = try await client.insertRows(
            into: "face_uploaded_images",
            values: [FaceUploadedImagePayload(userID: userID, input: input)],
            select: FaceUploadedImageRecord.select
        )
        return rows.first ?? FaceUploadedImageRecord(
            id: UUID(),
            userID: userID,
            inventoryID: input.inventoryID,
            storageBucket: input.storageBucket,
            storagePath: input.storagePath,
            imageURL: input.imageURL,
            imageHash: input.imageHash,
            contentType: input.contentType,
            imageType: input.imageType,
            analysisStatus: input.analysisStatus,
            createdAt: nil
        )
    }

    public func createDetectedFaces(
        uploadedImageID: UUID,
        results: [FaceTaggingResult]
    ) async throws -> [DetectedFaceRecord] {
        guard !results.isEmpty else {
            throw SupabaseFaceRecognitionClientError.emptyDetectedFaces
        }
        let rows: [DetectedFaceRecord] = try await client.insertRows(
            into: "detected_faces",
            values: results.map { DetectedFacePayload(uploadedImageID: uploadedImageID, result: $0) },
            select: DetectedFaceRecord.select
        )
        return rows
    }

    public func createMatchCandidates(
        detectedFaceID: UUID,
        candidates: [FaceMatchCandidate]
    ) async throws -> [FaceMatchCandidateRecord] {
        guard !candidates.isEmpty else {
            throw SupabaseFaceRecognitionClientError.emptyCandidates
        }
        return try await client.insertRows(
            into: "face_match_candidates",
            values: candidates.map { FaceMatchCandidatePayload(detectedFaceID: detectedFaceID, candidate: $0) },
            select: FaceMatchCandidateRecord.select
        )
    }

    public func createCorrection(userID: UUID, input: FaceMatchCorrectionInput) async throws {
        let _: [FaceMatchCorrectionRow] = try await client.insertRows(
            into: "face_match_corrections",
            values: [FaceMatchCorrectionPayload(userID: userID, input: input)],
            select: "id"
        )
    }

    public func makeLoadMemberFaceProfilesRequest(memberIDs: [UUID] = [], limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/member_face_profiles",
            queryItems: [URLQueryItem(name: "select", value: MemberFaceProfileRow.select)]
                + loadMemberFaceProfileQueryItems(memberIDs: memberIDs, limit: limit)
        )
    }

    public func makeCreateUploadedImageRequest(userID: UUID, input: FaceUploadedImageInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "face_uploaded_images",
            values: [FaceUploadedImagePayload(userID: userID, input: input)],
            select: FaceUploadedImageRecord.select
        )
    }

    public func makeCreateDetectedFacesRequest(
        uploadedImageID: UUID,
        results: [FaceTaggingResult]
    ) throws -> URLRequest {
        guard !results.isEmpty else {
            throw SupabaseFaceRecognitionClientError.emptyDetectedFaces
        }
        return try client.makeInsertRequest(
            into: "detected_faces",
            values: results.map { DetectedFacePayload(uploadedImageID: uploadedImageID, result: $0) },
            select: DetectedFaceRecord.select
        )
    }

    public func makeCreateMatchCandidatesRequest(
        detectedFaceID: UUID,
        candidates: [FaceMatchCandidate]
    ) throws -> URLRequest {
        guard !candidates.isEmpty else {
            throw SupabaseFaceRecognitionClientError.emptyCandidates
        }
        return try client.makeInsertRequest(
            into: "face_match_candidates",
            values: candidates.map { FaceMatchCandidatePayload(detectedFaceID: detectedFaceID, candidate: $0) },
            select: FaceMatchCandidateRecord.select
        )
    }

    public func makeCreateCorrectionRequest(userID: UUID, input: FaceMatchCorrectionInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "face_match_corrections",
            values: [FaceMatchCorrectionPayload(userID: userID, input: input)],
            select: "id"
        )
    }

    private func loadMemberFaceProfileQueryItems(memberIDs: [UUID], limit: Int) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "deleted_at", value: "is.null"),
            URLQueryItem(name: "order", value: "character_id.asc,created_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, limit))")
        ]
        let ids = Array(Set(memberIDs))
        if !ids.isEmpty {
            items.append(
                URLQueryItem(
                    name: "character_id",
                    value: "in.(\(ids.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")))"
                )
            )
        }
        return items
    }
}

private struct MemberFaceProfileRow: Decodable, Equatable, Sendable {
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

    private enum CodingKeys: String, CodingKey {
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

private struct FaceUploadedImagePayload: Encodable, Sendable {
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
        self.storageBucket = input.storageBucket?.trimmedNonEmpty
        self.storagePath = input.storagePath?.trimmedNonEmpty
        self.imageURL = input.imageURL?.trimmedNonEmpty
        self.imageHash = input.imageHash?.trimmedNonEmpty
        self.contentType = input.contentType.trimmedNonEmpty ?? "image/jpeg"
        self.imageType = input.imageType
        self.analysisStatus = input.analysisStatus
    }
}

private struct DetectedFacePayload: Encodable, Sendable {
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

    private enum CodingKeys: String, CodingKey {
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
        self.modelVersion = result.modelVersion?.trimmedNonEmpty
        self.profileType = result.profileType
        self.matchStatus = result.status
        self.matchedCharacterID = result.matchedMemberID
        self.matchedConfidence = result.confidence
    }
}

private struct FaceBoundingBoxPayload: Encodable, Sendable {
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

private struct FaceMatchCandidatePayload: Encodable, Sendable {
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

private struct FaceMatchCorrectionPayload: Encodable, Sendable {
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
        self.selectedMemberName = input.selectedMemberName?.trimmedNonEmpty
        self.imageType = input.imageType
        self.subjectType = input.subjectType
        self.recognitionMethod = input.recognitionMethod
        self.selectedProfileType = input.selectedProfileType
        self.shouldAddTrainingData = input.shouldAddTrainingData
    }
}

private struct FaceMatchCorrectionRow: Decodable, Sendable {
    var id: UUID
}

private struct FaceRecognitionRelation: Decodable, Equatable, Sendable {
    var name: String?
}

private extension FaceUploadedImageRecord {
    static let select = "id,user_id,inventory_id,storage_bucket,storage_path,image_url,image_hash,content_type,image_type,analysis_status,created_at"
}

private extension DetectedFaceRecord {
    static let select = "id,uploaded_image_id,image_type,subject_type,recognition_method,quality_status,model_version,profile_type,match_status,matched_character_id,matched_confidence,created_at"
}

private extension FaceMatchCandidateRecord {
    static let select = "id,detected_face_id,character_id,confidence,rank,profile_count,created_at"
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
