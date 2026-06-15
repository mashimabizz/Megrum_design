import Foundation
import MegrumCore
@testable import MegrumApp
import XCTest

final class FaceTaggingServiceTests: XCTestCase {
    func testAnalyzeImageReturnsAutoMatchedResultWhenCandidateExceedsThreshold() async throws {
        let memberID = UUID()
        let face = usableFace()
        let service = DefaultFaceTaggingService(
            detector: MockFaceDetectionService(faces: [face]),
            embeddingProvider: MockFaceEmbeddingService(embedding: FaceEmbedding(values: [1, 0, 0], modelIdentifier: "test")),
            matcher: DefaultFaceMatchingService()
        )

        let analysis = try await service.analyzeImage(
            Data([0x01]),
            memberProfiles: [
                MemberFaceProfile(
                    memberID: memberID,
                    memberName: "Momo",
                    embedding: FaceEmbedding(values: [1, 0, 0], modelIdentifier: "test")
                )
            ]
        )

        XCTAssertEqual(analysis.status, .autoMatched)
        XCTAssertEqual(analysis.results.first?.status, .autoMatched)
        XCTAssertEqual(analysis.results.first?.matchedMemberID, memberID)
        XCTAssertEqual(analysis.results.first?.confidence, 1)
    }

    func testAnalyzeImageMarksImageAsNoFaceWhenDetectorFindsNothing() async throws {
        let service = DefaultFaceTaggingService(
            detector: MockFaceDetectionService(faces: []),
            embeddingProvider: MockFaceEmbeddingService(embedding: FaceEmbedding(values: [1], modelIdentifier: "test"))
        )

        let analysis = try await service.analyzeImage(Data([0x01]), memberProfiles: [])

        XCTAssertEqual(analysis.status, .noFace)
        XCTAssertTrue(analysis.results.isEmpty)
    }

    func testAnalyzeImageKeepsFlowAliveWhenEmbeddingProviderIsUnavailable() async throws {
        let service = DefaultFaceTaggingService(
            detector: MockFaceDetectionService(faces: [usableFace()]),
            embeddingProvider: UnavailableFaceEmbeddingService()
        )

        let analysis = try await service.analyzeImage(Data([0x01]), memberProfiles: [])

        XCTAssertEqual(analysis.status, .unknown)
        XCTAssertEqual(analysis.results.first?.status, .unknown)
        XCTAssertEqual(analysis.results.first?.errorMessage, "顔特徴量モデルが未設定です。")
    }

    func testUnifiedServiceRoutesRealPhotoToExistingRealPhotoFlow() async throws {
        let imageID = UUID()
        let realAnalysis = FaceTaggingAnalysis(
            imageID: imageID,
            imageType: .realPhoto,
            status: .needsReview
        )
        let service = UnifiedMemberTaggingService(
            imageTypeClassifier: MockImageTypeClassifier(imageType: .realPhoto),
            realPhotoService: MockRealPhotoMemberTaggingService(analysis: realAnalysis),
            animeRecognitionService: MockAnimeRecognitionService(),
            thresholds: .default
        )

        let analysis = try await service.analyzeImage(Data([0x01]), imageID: imageID, memberProfiles: [])

        XCTAssertEqual(analysis.imageType, .realPhoto)
        XCTAssertEqual(analysis.status, .needsReview)
    }

    func testUnifiedServiceRoutesAnimeImageToAnimeServiceWithAnimeThresholds() async throws {
        let imageID = UUID()
        let service = UnifiedMemberTaggingService(
            imageTypeClassifier: MockImageTypeClassifier(imageType: .anime),
            realPhotoService: MockRealPhotoMemberTaggingService(
                analysis: FaceTaggingAnalysis(imageID: imageID, imageType: .realPhoto, status: .autoMatched)
            ),
            animeRecognitionService: MockAnimeRecognitionService(),
            thresholds: .default
        )

        let analysis = try await service.analyzeImage(Data([0x01]), imageID: imageID, memberProfiles: [])

        XCTAssertEqual(analysis.imageType, .anime)
        XCTAssertEqual(analysis.status, .needsReview)
        XCTAssertEqual(analysis.results.first?.recognitionMethod, .animeEmbeddingSimilarity)
        XCTAssertEqual(analysis.results.first?.status, .needsReview)
    }

    func testUnifiedServiceSafelyReturnsUnknownForUnknownImageType() async throws {
        let service = UnifiedMemberTaggingService(
            imageTypeClassifier: MockImageTypeClassifier(imageType: .unknown),
            realPhotoService: MockRealPhotoMemberTaggingService(
                analysis: FaceTaggingAnalysis(imageType: .realPhoto, status: .autoMatched)
            ),
            animeRecognitionService: MockAnimeRecognitionService()
        )

        let analysis = try await service.analyzeImage(Data([0x01]), memberProfiles: [])

        XCTAssertEqual(analysis.imageType, .unknown)
        XCTAssertEqual(analysis.status, .unknown)
        XCTAssertTrue(analysis.results.isEmpty)
    }

    func testUnavailableAnimeRecognitionServiceDoesNotCrash() async throws {
        let service = UnifiedMemberTaggingService(
            imageTypeClassifier: MockImageTypeClassifier(imageType: .illustration),
            realPhotoService: MockRealPhotoMemberTaggingService(
                analysis: FaceTaggingAnalysis(imageType: .realPhoto, status: .autoMatched)
            ),
            animeRecognitionService: UnavailableAnimeRecognitionService()
        )

        let analysis = try await service.analyzeImage(Data([0x01]), memberProfiles: [])

        XCTAssertEqual(analysis.imageType, .illustration)
        XCTAssertEqual(analysis.status, .unknown)
        XCTAssertTrue(analysis.results.isEmpty)
    }

    func testCorrectionDraftKeepsTrainingDataEnabledByDefault() {
        let result = FaceTaggingResult(
            imageType: .anime,
            face: usableFace(
                qualityCategory: .stylized,
                subjectType: .animeFace,
                recognitionMethod: .animeEmbeddingSimilarity
            ),
            subjectType: .animeFace,
            status: .needsReview,
            recognitionMethod: .animeEmbeddingSimilarity,
            qualityCategory: .stylized,
            profileType: .animeCharacter
        )

        let draft = FaceTaggingCorrectionDraft(result: result)

        XCTAssertTrue(draft.shouldAddTrainingData)
        XCTAssertEqual(draft.imageType, .anime)
        XCTAssertEqual(draft.profileType, .animeCharacter)
    }

    func testFaceTaggingReviewQueuePresentsOneContextAtATime() {
        var queue = FaceTaggingReviewQueue()
        let first = faceTaggingReviewContext(target: .draft)
        let second = faceTaggingReviewContext(target: .createPhoto(UUID()))

        queue.enqueue(first)
        queue.enqueue(second)

        XCTAssertEqual(queue.current, first)
        XCTAssertEqual(queue.pendingCount, 1)

        queue.presentNextIfNeeded()

        XCTAssertEqual(queue.current, first)
        XCTAssertEqual(queue.pendingCount, 1)

        queue.current = nil
        queue.presentNextIfNeeded()

        XCTAssertEqual(queue.current, second)
        XCTAssertEqual(queue.pendingCount, 0)
    }

    private func usableFace(
        qualityCategory: MemberTaggingQualityStatus? = nil,
        subjectType: MemberTaggingSubjectType = .realFace,
        recognitionMethod: MemberTaggingRecognitionMethod = .visionFace
    ) -> DetectedFaceObservation {
        DetectedFaceObservation(
            boundingBox: FaceBoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.3),
            confidence: 0.96,
            qualityScore: 0.9,
            qualityStatus: .usable,
            qualityCategory: qualityCategory,
            subjectType: subjectType,
            recognitionMethod: recognitionMethod
        )
    }

    private func faceTaggingReviewContext(target: FaceTaggingReviewTarget) -> FaceTaggingReviewContext {
        FaceTaggingReviewContext(
            target: target,
            imageData: Data([0x01]),
            analysis: FaceTaggingAnalysis(status: .unknown)
        )
    }
}

private struct MockImageTypeClassifier: ImageTypeClassifier {
    var imageType: MemberTaggingImageType

    func classifyImage(_ imageData: Data) async throws -> MemberTaggingImageType {
        imageType
    }
}

private struct MockRealPhotoMemberTaggingService: RealPhotoMemberTaggingService {
    var analysis: FaceTaggingAnalysis

    func analyzeImage(
        _ imageData: Data,
        imageID: UUID,
        memberProfiles: [MemberFaceProfile]
    ) async throws -> FaceTaggingAnalysis {
        analysis
    }
}

private struct MockAnimeRecognitionService: AnimeRecognitionService {
    func analyzeImage(
        _ imageData: Data,
        imageID: UUID,
        imageType: MemberTaggingImageType,
        memberProfiles: [MemberFaceProfile],
        thresholds: FaceRecognitionThresholds,
        candidateLimit: Int
    ) async throws -> FaceTaggingAnalysis {
        let memberID = UUID()
        let face = DetectedFaceObservation(
            boundingBox: FaceBoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.3),
            confidence: 0.9,
            qualityScore: 0.9,
            qualityStatus: .usable,
            qualityCategory: .stylized,
            subjectType: .animeFace,
            recognitionMethod: .animeEmbeddingSimilarity
        )
        let candidate = FaceMatchCandidate(
            memberID: memberID,
            memberName: "Anime Momo",
            confidence: 0.94,
            rank: 1,
            profileCount: 1
        )
        let status = FaceMatchResolver.status(
            for: face,
            candidates: [candidate],
            thresholds: thresholds
        )
        return FaceTaggingAnalysis(
            imageID: imageID,
            imageType: imageType,
            status: status,
            results: [
                FaceTaggingResult(
                    imageID: imageID,
                    imageType: imageType,
                    face: face,
                    subjectType: .animeFace,
                    status: status,
                    recognitionMethod: .animeEmbeddingSimilarity,
                    qualityCategory: .stylized,
                    modelVersion: "anime-test",
                    profileType: .animeCharacter,
                    matchedMemberID: status == .autoMatched ? memberID : nil,
                    matchedMemberName: status == .autoMatched ? "Anime Momo" : nil,
                    confidence: candidate.confidence,
                    candidates: [candidate]
                )
            ]
        )
    }
}

private struct MockFaceDetectionService: FaceDetectionService {
    var faces: [DetectedFaceObservation]

    func detectFaces(in imageData: Data) async throws -> [DetectedFaceObservation] {
        faces
    }
}

private struct MockFaceEmbeddingService: FaceEmbeddingService {
    var embedding: FaceEmbedding

    func embedding(for imageData: Data, face: DetectedFaceObservation) async throws -> FaceEmbedding {
        embedding
    }
}
