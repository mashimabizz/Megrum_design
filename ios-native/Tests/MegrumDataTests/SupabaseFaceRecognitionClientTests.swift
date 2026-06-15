import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseFaceRecognitionClientTests: XCTestCase {
    func testBuildsLoadMemberFaceProfilesRequest() throws {
        let client = SupabaseFaceRecognitionClient(configuration: configuration)
        let memberID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeLoadMemberFaceProfilesRequest(memberIDs: [memberID], limit: 40)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/member_face_profiles?select=id,character_id,profile_type,embedding,embedding_model,source_image_url,consent_recorded_at,deleted_at,character:characters_master(name)"))
        XCTAssertTrue(url.contains("deleted_at=is.null"))
        XCTAssertTrue(url.contains("order=character_id.asc,created_at.desc"))
        XCTAssertTrue(url.contains("limit=40"))
        XCTAssertTrue(url.contains("character_id=in.(22222222-2222-2222-2222-222222222222)"))
    }

    func testBuildsCreateUploadedImageRequest() throws {
        let client = SupabaseFaceRecognitionClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let inventoryID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let request = try client.makeCreateUploadedImageRequest(
            userID: userID,
            input: FaceUploadedImageInput(
                inventoryID: inventoryID,
                storageBucket: "goods-photos",
                storagePath: "u/a.jpg",
                imageHash: "sha256:test",
                contentType: "image/jpeg",
                imageType: .realPhoto,
                analysisStatus: .needsReview
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/face_uploaded_images?select=id,user_id,inventory_id,storage_bucket,storage_path,image_url,image_hash,content_type,image_type,analysis_status,created_at")
        XCTAssertEqual(json.first?["user_id"] as? String, userID.uuidString.lowercased())
        XCTAssertEqual(json.first?["inventory_id"] as? String, inventoryID.uuidString.lowercased())
        XCTAssertEqual(json.first?["storage_bucket"] as? String, "goods-photos")
        XCTAssertEqual(json.first?["storage_path"] as? String, "u/a.jpg")
        XCTAssertEqual(json.first?["image_hash"] as? String, "sha256:test")
        XCTAssertEqual(json.first?["content_type"] as? String, "image/jpeg")
        XCTAssertEqual(json.first?["image_type"] as? String, "real_photo")
        XCTAssertEqual(json.first?["analysis_status"] as? String, "needs_review")
    }

    func testBuildsCreateDetectedFacesRequest() throws {
        let client = SupabaseFaceRecognitionClient(configuration: configuration)
        let uploadedImageID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let memberID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let result = FaceTaggingResult(
            imageType: .realPhoto,
            face: DetectedFaceObservation(
                boundingBox: FaceBoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
                confidence: 0.96,
                qualityScore: 0.9,
                qualityStatus: .usable,
                subjectType: .realFace,
                recognitionMethod: .realFaceEmbedding
            ),
            subjectType: .realFace,
            status: .autoMatched,
            recognitionMethod: .realFaceEmbedding,
            qualityCategory: .ok,
            modelVersion: "real-v1",
            profileType: .realFace,
            matchedMemberID: memberID,
            matchedMemberName: "Momo",
            confidence: 0.94
        )

        let request = try client.makeCreateDetectedFacesRequest(uploadedImageID: uploadedImageID, results: [result])
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let box = try XCTUnwrap(json.first?["bounding_box"] as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/detected_faces?select=id,uploaded_image_id,image_type,subject_type,recognition_method,quality_status,model_version,profile_type,match_status,matched_character_id,matched_confidence,created_at")
        XCTAssertEqual(json.first?["uploaded_image_id"] as? String, uploadedImageID.uuidString.lowercased())
        XCTAssertEqual(json.first?["image_type"] as? String, "real_photo")
        XCTAssertEqual(json.first?["subject_type"] as? String, "real_face")
        XCTAssertEqual(json.first?["recognition_method"] as? String, "real_face_embedding")
        XCTAssertEqual(json.first?["legacy_quality_status"] as? String, "usable")
        XCTAssertEqual(json.first?["quality_status"] as? String, "ok")
        XCTAssertEqual(json.first?["model_version"] as? String, "real-v1")
        XCTAssertEqual(json.first?["profile_type"] as? String, "real_face")
        XCTAssertEqual(json.first?["match_status"] as? String, "auto_matched")
        XCTAssertEqual(json.first?["matched_character_id"] as? String, memberID.uuidString.lowercased())
        XCTAssertEqual(json.first?["matched_confidence"] as? Double, 0.94)
        XCTAssertEqual(box["x"] as? Double, 0.1)
        XCTAssertEqual(box["y"] as? Double, 0.2)
        XCTAssertEqual(try XCTUnwrap(box["width"] as? Double), 0.3, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(box["height"] as? Double), 0.4, accuracy: 0.0001)
    }

    func testBuildsCreateMatchCandidatesRequest() throws {
        let client = SupabaseFaceRecognitionClient(configuration: configuration)
        let detectedFaceID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let memberID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeCreateMatchCandidatesRequest(
            detectedFaceID: detectedFaceID,
            candidates: [
                FaceMatchCandidate(
                    memberID: memberID,
                    memberName: "Momo",
                    confidence: 0.91,
                    rank: 1,
                    profileCount: 4
                )
            ]
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/face_match_candidates?select=id,detected_face_id,character_id,confidence,rank,profile_count,created_at")
        XCTAssertEqual(json.first?["detected_face_id"] as? String, detectedFaceID.uuidString.lowercased())
        XCTAssertEqual(json.first?["character_id"] as? String, memberID.uuidString.lowercased())
        XCTAssertEqual(json.first?["confidence"] as? Double, 0.91)
        XCTAssertEqual(json.first?["rank"] as? Int, 1)
        XCTAssertEqual(json.first?["profile_count"] as? Int, 4)
    }

    func testBuildsCreateCorrectionRequest() throws {
        let client = SupabaseFaceRecognitionClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let detectedFaceID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let selectedMemberID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeCreateCorrectionRequest(
            userID: userID,
            input: FaceMatchCorrectionInput(
                detectedFaceID: detectedFaceID,
                originalMatchStatus: .needsReview,
                selectedCharacterID: selectedMemberID,
                selectedMemberName: " Momo ",
                imageType: .anime,
                subjectType: .animeFace,
                recognitionMethod: .manual,
                selectedProfileType: .animeCharacter,
                shouldAddTrainingData: true
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/face_match_corrections?select=id")
        XCTAssertEqual(json.first?["detected_face_id"] as? String, detectedFaceID.uuidString.lowercased())
        XCTAssertEqual(json.first?["user_id"] as? String, userID.uuidString.lowercased())
        XCTAssertEqual(json.first?["original_match_status"] as? String, "needs_review")
        XCTAssertEqual(json.first?["selected_character_id"] as? String, selectedMemberID.uuidString.lowercased())
        XCTAssertEqual(json.first?["selected_member_name"] as? String, "Momo")
        XCTAssertEqual(json.first?["image_type"] as? String, "anime")
        XCTAssertEqual(json.first?["subject_type"] as? String, "anime_face")
        XCTAssertEqual(json.first?["recognition_method"] as? String, "manual")
        XCTAssertEqual(json.first?["selected_profile_type"] as? String, "anime_character")
        XCTAssertEqual(json.first?["should_add_training_data"] as? Bool, true)
    }

    func testCreateDetectedFacesRejectsEmptyResults() {
        let client = SupabaseFaceRecognitionClient(configuration: configuration)

        XCTAssertThrowsError(
            try client.makeCreateDetectedFacesRequest(uploadedImageID: UUID(), results: [])
        ) { error in
            XCTAssertEqual(error as? SupabaseFaceRecognitionClientError, .emptyDetectedFaces)
        }
    }

    func testCreateMatchCandidatesRejectsEmptyCandidates() {
        let client = SupabaseFaceRecognitionClient(configuration: configuration)

        XCTAssertThrowsError(
            try client.makeCreateMatchCandidatesRequest(detectedFaceID: UUID(), candidates: [])
        ) { error in
            XCTAssertEqual(error as? SupabaseFaceRecognitionClientError, .emptyCandidates)
        }
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test",
            accessToken: "session_token"
        )
    }
}
