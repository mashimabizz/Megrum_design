import Foundation
import MegrumCore

public enum SupabaseFaceRecognitionClientError: Error, Equatable, Sendable {
    case emptyDetectedFaces
    case emptyCandidates
}

public final class SupabaseFaceRecognitionClient: @unchecked Sendable {
    let client: SupabaseRESTClient

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
}
