import Foundation
import MegrumCore

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

struct FaceRecognitionRelation: Decodable, Equatable, Sendable {
    var name: String?
}
