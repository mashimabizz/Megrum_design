import MegrumCore
import XCTest

final class FaceRecognitionModelTests: XCTestCase {
    func testBoundingBoxClampsToNormalizedImageSpace() {
        let box = FaceBoundingBox(x: -0.2, y: 0.8, width: 0.5, height: 0.5)

        XCTAssertEqual(box.x, 0)
        XCTAssertEqual(box.y, 0.8)
        XCTAssertEqual(box.width, 0.3, accuracy: 0.0001)
        XCTAssertEqual(box.height, 0.2, accuracy: 0.0001)
    }

    func testCosineSimilarityAndCandidateRanking() throws {
        let target = FaceEmbedding(values: [1, 0, 0], modelIdentifier: "test")
        let bestMemberID = UUID()
        let weakerMemberID = UUID()
        let profiles = [
            MemberFaceProfile(
                memberID: weakerMemberID,
                memberName: "Beta",
                embedding: FaceEmbedding(values: [0, 1, 0], modelIdentifier: "test")
            ),
            MemberFaceProfile(
                memberID: bestMemberID,
                memberName: "Alpha",
                embedding: FaceEmbedding(values: [1, 0, 0], modelIdentifier: "test"),
                profileType: .realFace
            )
        ]

        let candidates = FaceMatchResolver.candidates(for: target, profiles: profiles, limit: 2)
        let best = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidates.map(\.memberID), [bestMemberID, weakerMemberID])
        XCTAssertEqual(best.confidence, 1, accuracy: 0.0001)
        XCTAssertEqual(best.rank, 1)
    }

    func testStatusUsesQualityAndThresholds() {
        let face = DetectedFaceObservation(
            boundingBox: FaceBoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            confidence: 0.95,
            qualityScore: 0.9,
            qualityStatus: .usable
        )
        let memberID = UUID()

        XCTAssertEqual(
            FaceMatchResolver.status(
                for: face,
                candidates: [
                    FaceMatchCandidate(
                        memberID: memberID,
                        memberName: "Momo",
                        confidence: 0.92,
                        rank: 1,
                        profileCount: 2
                    )
                ]
            ),
            .autoMatched
        )
        XCTAssertEqual(
            FaceMatchResolver.status(
                for: face,
                candidates: [
                    FaceMatchCandidate(
                        memberID: memberID,
                        memberName: "Momo",
                        confidence: 0.75,
                        rank: 1,
                        profileCount: 2
                    )
                ]
            ),
            .needsReview
        )

        let lowQualityFace = DetectedFaceObservation(
            boundingBox: FaceBoundingBox(x: 0.1, y: 0.1, width: 0.03, height: 0.03),
            confidence: 0.95,
            qualityScore: 0.2,
            qualityStatus: .tooSmall
        )
        XCTAssertEqual(
            FaceMatchResolver.status(
                for: lowQualityFace,
                candidates: [
                    FaceMatchCandidate(
                        memberID: memberID,
                        memberName: "Momo",
                        confidence: 1,
                        rank: 1,
                        profileCount: 1
                    )
                ]
            ),
            .lowQuality
        )
    }

    func testAnimeThresholdsAreStricterThanRealPhotoThresholds() {
        let thresholds = MemberTaggingThresholds.default

        XCTAssertEqual(thresholds.thresholds(for: .realPhoto).autoMatchMinimum, 0.90, accuracy: 0.0001)
        XCTAssertEqual(thresholds.thresholds(for: .realPhoto).reviewMinimum, 0.70, accuracy: 0.0001)
        XCTAssertEqual(thresholds.thresholds(for: .anime).autoMatchMinimum, 0.95, accuracy: 0.0001)
        XCTAssertEqual(thresholds.thresholds(for: .anime).reviewMinimum, 0.75, accuracy: 0.0001)
        XCTAssertEqual(thresholds.thresholds(for: .illustration), thresholds.thresholds(for: .anime))
        XCTAssertEqual(thresholds.thresholds(for: .manga), thresholds.thresholds(for: .anime))
    }

    func testStatusCanUseAnimeThresholds() {
        let face = DetectedFaceObservation(
            boundingBox: FaceBoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            confidence: 0.95,
            qualityScore: 0.9,
            qualityStatus: .usable,
            subjectType: .animeFace,
            recognitionMethod: .animeEmbeddingSimilarity
        )
        let memberID = UUID()

        XCTAssertEqual(
            FaceMatchResolver.status(
                for: face,
                candidates: [
                    FaceMatchCandidate(
                        memberID: memberID,
                        memberName: "Momo",
                        confidence: 0.94,
                        rank: 1,
                        profileCount: 2
                    )
                ],
                thresholds: .animeIllustration
            ),
            .needsReview
        )

        XCTAssertEqual(
            FaceMatchResolver.status(
                for: face,
                candidates: [
                    FaceMatchCandidate(
                        memberID: memberID,
                        memberName: "Momo",
                        confidence: 0.74,
                        rank: 1,
                        profileCount: 2
                    )
                ],
                thresholds: .animeIllustration
            ),
            .unknown
        )
    }

    func testCandidateMatchingCanFilterByProfileType() {
        let memberID = UUID()
        let candidates = FaceMatchResolver.candidates(
            for: FaceEmbedding(values: [1, 0, 0], modelIdentifier: "anime-test"),
            profiles: [
                MemberFaceProfile(
                    memberID: memberID,
                    memberName: "Real",
                    embedding: FaceEmbedding(values: [1, 0, 0], modelIdentifier: "real-test"),
                    profileType: .realFace
                ),
                MemberFaceProfile(
                    memberID: memberID,
                    memberName: "Anime",
                    embedding: FaceEmbedding(values: [1, 0, 0], modelIdentifier: "anime-test"),
                    profileType: .animeCharacter
                )
            ],
            profileTypes: [.animeCharacter]
        )

        XCTAssertEqual(candidates.first?.memberName, "Anime")
        XCTAssertEqual(candidates.first?.profileCount, 1)
    }
}
