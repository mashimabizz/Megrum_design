import CoreImage
import Foundation
import ImageIO
import MegrumCore
import Vision

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
