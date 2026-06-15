import CoreImage
import Foundation
import ImageIO
import MegrumCore
import Vision

enum FaceRecognitionServiceError: LocalizedError, Equatable, Sendable {
    case imageLoadFailed
    case visionRequestFailed
    case embeddingProviderUnavailable

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            "画像を読み込めませんでした。"
        case .visionRequestFailed:
            "顔の検出に失敗しました。"
        case .embeddingProviderUnavailable:
            "顔特徴量モデルが未設定です。"
        }
    }
}

protocol FaceDetectionService: Sendable {
    func detectFaces(in imageData: Data) async throws -> [DetectedFaceObservation]
}

protocol FaceEmbeddingService: Sendable {
    func embedding(for imageData: Data, face: DetectedFaceObservation) async throws -> FaceEmbedding
}

protocol FaceMatchingService: Sendable {
    func candidates(
        for embedding: FaceEmbedding,
        profiles: [MemberFaceProfile],
        limit: Int
    ) -> [FaceMatchCandidate]
}

protocol ImageTypeClassifier: Sendable {
    func classifyImage(_ imageData: Data) async throws -> MemberTaggingImageType
}

protocol RealPhotoMemberTaggingService: Sendable {
    func analyzeImage(
        _ imageData: Data,
        imageID: UUID,
        memberProfiles: [MemberFaceProfile]
    ) async throws -> FaceTaggingAnalysis
}

protocol AnimeRecognitionService: Sendable {
    func analyzeImage(
        _ imageData: Data,
        imageID: UUID,
        imageType: MemberTaggingImageType,
        memberProfiles: [MemberFaceProfile],
        thresholds: FaceRecognitionThresholds,
        candidateLimit: Int
    ) async throws -> FaceTaggingAnalysis
}

struct DefaultFaceMatchingService: FaceMatchingService {
    func candidates(
        for embedding: FaceEmbedding,
        profiles: [MemberFaceProfile],
        limit: Int = 3
    ) -> [FaceMatchCandidate] {
        FaceMatchResolver.candidates(for: embedding, profiles: profiles, limit: limit)
    }
}

struct UnavailableFaceEmbeddingService: FaceEmbeddingService {
    func embedding(for imageData: Data, face: DetectedFaceObservation) async throws -> FaceEmbedding {
        throw FaceRecognitionServiceError.embeddingProviderUnavailable
    }
}

struct VisionBackedImageTypeClassifier: ImageTypeClassifier {
    var detector: any FaceDetectionService

    init(detector: any FaceDetectionService = VisionFaceDetectionService()) {
        self.detector = detector
    }

    func classifyImage(_ imageData: Data) async throws -> MemberTaggingImageType {
        do {
            let faces = try await detector.detectFaces(in: imageData)
            return faces.isEmpty ? .unknown : .realPhoto
        } catch {
            return .unknown
        }
    }
}

struct ConservativeUnknownImageTypeClassifier: ImageTypeClassifier {
    func classifyImage(_ imageData: Data) async throws -> MemberTaggingImageType {
        .unknown
    }
}

struct UnavailableAnimeRecognitionService: AnimeRecognitionService {
    func analyzeImage(
        _ imageData: Data,
        imageID: UUID,
        imageType: MemberTaggingImageType,
        memberProfiles: [MemberFaceProfile],
        thresholds: FaceRecognitionThresholds,
        candidateLimit: Int
    ) async throws -> FaceTaggingAnalysis {
        FaceTaggingAnalysis(
            imageID: imageID,
            imageType: imageType,
            status: .unknown
        )
    }
}

struct DefaultFaceTaggingService: RealPhotoMemberTaggingService, Sendable {
    var detector: any FaceDetectionService
    var embeddingProvider: any FaceEmbeddingService
    var matcher: any FaceMatchingService
    var thresholds: FaceRecognitionThresholds
    var candidateLimit: Int

    init(
        detector: any FaceDetectionService = VisionFaceDetectionService(),
        embeddingProvider: any FaceEmbeddingService = UnavailableFaceEmbeddingService(),
        matcher: any FaceMatchingService = DefaultFaceMatchingService(),
        thresholds: FaceRecognitionThresholds = .default,
        candidateLimit: Int = 3
    ) {
        self.detector = detector
        self.embeddingProvider = embeddingProvider
        self.matcher = matcher
        self.thresholds = thresholds
        self.candidateLimit = max(1, candidateLimit)
    }

    func analyzeImage(
        _ imageData: Data,
        imageID: UUID = UUID(),
        memberProfiles: [MemberFaceProfile]
    ) async throws -> FaceTaggingAnalysis {
        let faces = try await detector.detectFaces(in: imageData)
        guard !faces.isEmpty else {
            return FaceTaggingAnalysis(imageID: imageID, imageType: .realPhoto, status: .noFace)
        }

        var results: [FaceTaggingResult] = []
        for face in faces {
            guard face.qualityStatus.isUsable else {
                results.append(
                    FaceTaggingResult(
                        imageID: imageID,
                        imageType: .realPhoto,
                        face: face,
                        subjectType: .realFace,
                        status: .lowQuality,
                        recognitionMethod: .visionFace,
                        profileType: .realFace
                    )
                )
                continue
            }

            do {
                let embedding = try await embeddingProvider.embedding(for: imageData, face: face)
                let candidates = matcher.candidates(
                    for: embedding,
                    profiles: memberProfiles.filter { $0.profileType == .realFace },
                    limit: candidateLimit
                )
                let status = FaceMatchResolver.status(
                    for: face,
                    candidates: candidates,
                    thresholds: thresholds
                )
                let best = status == .autoMatched ? candidates.first : nil
                results.append(
                    FaceTaggingResult(
                        imageID: imageID,
                        imageType: .realPhoto,
                        face: face,
                        subjectType: .realFace,
                        status: status,
                        recognitionMethod: .realFaceEmbedding,
                        modelVersion: embedding.modelIdentifier,
                        profileType: .realFace,
                        matchedMemberID: best?.memberID,
                        matchedMemberName: best?.memberName,
                        confidence: best?.confidence,
                        candidates: candidates
                    )
                )
            } catch {
                results.append(
                    FaceTaggingResult(
                        imageID: imageID,
                        imageType: .realPhoto,
                        face: face,
                        subjectType: .realFace,
                        status: .unknown,
                        recognitionMethod: .realFaceEmbedding,
                        profileType: .realFace,
                        errorMessage: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    )
                )
            }
        }

        return FaceTaggingAnalysis(
            imageID: imageID,
            imageType: .realPhoto,
            status: aggregateStatus(from: results),
            results: results
        )
    }

    private func aggregateStatus(from results: [FaceTaggingResult]) -> FaceMatchStatus {
        if results.contains(where: { $0.status == .autoMatched }) {
            return .autoMatched
        }
        if results.contains(where: { $0.status == .needsReview }) {
            return .needsReview
        }
        if results.allSatisfy({ $0.status == .lowQuality }) {
            return .lowQuality
        }
        return .unknown
    }
}

struct UnifiedMemberTaggingService: Sendable {
    var imageTypeClassifier: any ImageTypeClassifier
    var realPhotoService: any RealPhotoMemberTaggingService
    var animeRecognitionService: any AnimeRecognitionService
    var thresholds: MemberTaggingThresholds
    var candidateLimit: Int

    init(
        imageTypeClassifier: any ImageTypeClassifier = VisionBackedImageTypeClassifier(),
        realPhotoService: any RealPhotoMemberTaggingService = DefaultFaceTaggingService(),
        animeRecognitionService: any AnimeRecognitionService = UnavailableAnimeRecognitionService(),
        thresholds: MemberTaggingThresholds = .default,
        candidateLimit: Int = 3
    ) {
        self.imageTypeClassifier = imageTypeClassifier
        self.realPhotoService = realPhotoService
        self.animeRecognitionService = animeRecognitionService
        self.thresholds = thresholds
        self.candidateLimit = max(1, candidateLimit)
    }

    func analyzeImage(
        _ imageData: Data,
        imageID: UUID = UUID(),
        memberProfiles: [MemberFaceProfile]
    ) async throws -> FaceTaggingAnalysis {
        let imageType = (try? await imageTypeClassifier.classifyImage(imageData)) ?? .unknown
        switch imageType {
        case .realPhoto:
            return try await realPhotoService.analyzeImage(
                imageData,
                imageID: imageID,
                memberProfiles: memberProfiles
            )
        case .anime, .illustration, .manga:
            do {
                return try await animeRecognitionService.analyzeImage(
                    imageData,
                    imageID: imageID,
                    imageType: imageType,
                    memberProfiles: memberProfiles,
                    thresholds: thresholds.thresholds(for: imageType),
                    candidateLimit: candidateLimit
                )
            } catch {
                return FaceTaggingAnalysis(
                    imageID: imageID,
                    imageType: imageType,
                    status: .unknown
                )
            }
        case .unknown:
            return FaceTaggingAnalysis(
                imageID: imageID,
                imageType: .unknown,
                status: .unknown
            )
        }
    }
}

struct VisionFaceDetectionService: FaceDetectionService {
    var configuration: VisionFaceDetectionConfiguration

    init(configuration: VisionFaceDetectionConfiguration = .default) {
        self.configuration = configuration
    }

    func detectFaces(in imageData: Data) async throws -> [DetectedFaceObservation] {
        try await Task.detached(priority: .userInitiated) {
            try detectFacesSynchronously(in: imageData, configuration: configuration)
        }.value
    }
}

struct VisionFaceDetectionConfiguration: Equatable, Sendable {
    static let `default` = VisionFaceDetectionConfiguration()

    var minimumConfidence: Double
    var minimumFaceSide: Double

    init(minimumConfidence: Double = 0.5, minimumFaceSide: Double = 0.08) {
        self.minimumConfidence = min(max(minimumConfidence, 0), 1)
        self.minimumFaceSide = min(max(minimumFaceSide, 0), 1)
    }
}

private func detectFacesSynchronously(
    in imageData: Data,
    configuration: VisionFaceDetectionConfiguration
) throws -> [DetectedFaceObservation] {
    guard let rawImage = CIImage(data: imageData) else {
        throw FaceRecognitionServiceError.imageLoadFailed
    }
    let image = rawImage.oriented(faceExifOrientation(from: imageData))
    let request = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])

    do {
        try handler.perform([request])
    } catch {
        throw FaceRecognitionServiceError.visionRequestFailed
    }

    let observations = request.results ?? []
    return observations
        .map { observation in
            makeDetectedFaceObservation(observation, configuration: configuration)
        }
        .sorted { lhs, rhs in
            if abs(lhs.boundingBox.y - rhs.boundingBox.y) > 0.02 {
                return lhs.boundingBox.y < rhs.boundingBox.y
            }
            return lhs.boundingBox.x < rhs.boundingBox.x
        }
}

private func makeDetectedFaceObservation(
    _ observation: VNFaceObservation,
    configuration: VisionFaceDetectionConfiguration
) -> DetectedFaceObservation {
    let boundingBox = FaceBoundingBox(
        x: Double(observation.boundingBox.minX),
        y: Double(1 - observation.boundingBox.maxY),
        width: Double(observation.boundingBox.width),
        height: Double(observation.boundingBox.height)
    )
    let confidence = Double(observation.confidence)
    let minSide = min(boundingBox.width, boundingBox.height)
    let sizeScore = min(max(minSide / max(configuration.minimumFaceSide * 2, 0.001), 0), 1)
    let qualityScore = min(confidence, sizeScore)
    let qualityStatus: FaceQualityStatus
    if minSide < configuration.minimumFaceSide {
        qualityStatus = .tooSmall
    } else if confidence < configuration.minimumConfidence {
        qualityStatus = .lowConfidence
    } else if qualityScore < 0.35 {
        qualityStatus = .lowQuality
    } else {
        qualityStatus = .usable
    }

    return DetectedFaceObservation(
        boundingBox: boundingBox,
        confidence: confidence,
        qualityScore: qualityScore,
        qualityStatus: qualityStatus
    )
}

private func faceExifOrientation(from imageData: Data) -> CGImagePropertyOrientation {
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let rawOrientation = properties[kCGImagePropertyOrientation] as? UInt32,
          let orientation = CGImagePropertyOrientation(rawValue: rawOrientation)
    else {
        return .up
    }
    return orientation
}
