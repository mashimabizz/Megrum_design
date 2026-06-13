import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import MegrumCore
import UniformTypeIdentifiers
import Vision

enum TradingCardBulkRecognitionError: LocalizedError {
    case imageLoadFailed
    case cgImageUnavailable
    case cropFailed
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            "画像を読み込めませんでした。"
        case .cgImageUnavailable:
            "画像データを処理できませんでした。"
        case .cropFailed:
            "カード画像の切り出しに失敗しました。"
        case .writeFailed:
            "切り出し画像を保存できませんでした。"
        }
    }
}

struct TradingCardBulkRecognitionResult: Equatable, Identifiable, Sendable {
    enum Source: Equatable, Sendable {
        case detected
        case fallbackOriginal
    }

    var id: UUID
    var data: Data
    var contentType: String
    var source: Source

    init(
        id: UUID = UUID(),
        data: Data,
        contentType: String = "image/jpeg",
        source: Source
    ) {
        self.id = id
        self.data = data
        self.contentType = contentType
        self.source = source
    }

    var upload: GoodsPhotoUpload {
        GoodsPhotoUpload(data: data, contentType: contentType)
    }
}

enum TradingCardBulkRecognizer {
    static func recognizeCards(
        in imageData: Data,
        maximumCards: Int = TradingCardRectangleDetectionConfig.maximumObservations
    ) async throws -> [TradingCardBulkRecognitionResult] {
        try await Task.detached(priority: .userInitiated) {
            try recognizeCardsSynchronously(in: imageData, maximumCards: maximumCards)
        }.value
    }

    static func sortedTopLeftCenters(_ centers: [CGPoint]) -> [CGPoint] {
        centers.sorted(by: isTopLeftCenterOrderedBefore)
    }

    static func recognizeCardsSynchronously(
        in imageData: Data,
        maximumCards: Int = TradingCardRectangleDetectionConfig.maximumObservations
    ) throws -> [TradingCardBulkRecognitionResult] {
        guard let rawImage = CIImage(data: imageData) else {
            throw TradingCardBulkRecognitionError.imageLoadFailed
        }
        let image = rawImage.oriented(exifOrientation(from: imageData))
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let observations = try detectRectangles(in: image, maximumCards: maximumCards)

        guard !observations.isEmpty else {
            return [
                TradingCardBulkRecognitionResult(
                    data: try jpegData(from: image, context: context),
                    source: .fallbackOriginal
                )
            ]
        }

        let crops = try observations.map { observation in
            TradingCardBulkRecognitionResult(
                data: try crop(observation: observation, from: image, context: context),
                source: .detected
            )
        }

        return crops.isEmpty
            ? [
                TradingCardBulkRecognitionResult(
                    data: try jpegData(from: image, context: context),
                    source: .fallbackOriginal
                )
            ]
            : crops
    }

    private static func detectRectangles(
        in image: CIImage,
        maximumCards: Int
    ) throws -> [VNRectangleObservation] {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = max(1, maximumCards)
        request.minimumAspectRatio = TradingCardRectangleDetectionConfig.minimumAspectRatio
        request.maximumAspectRatio = TradingCardRectangleDetectionConfig.maximumAspectRatio
        request.minimumSize = TradingCardRectangleDetectionConfig.minimumSize
        request.minimumConfidence = TradingCardRectangleDetectionConfig.minimumConfidence
        request.quadratureTolerance = TradingCardRectangleDetectionConfig.quadratureTolerance

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        return observations.sorted { lhs, rhs in
            isTopLeftCenterOrderedBefore(normalizedTopLeftCenter(lhs), normalizedTopLeftCenter(rhs))
        }
    }

    private static func isTopLeftCenterOrderedBefore(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        if abs(lhs.y - rhs.y) > TradingCardRectangleDetectionConfig.rowTolerance {
            return lhs.y < rhs.y
        }
        if abs(lhs.x - rhs.x) > .ulpOfOne {
            return lhs.x < rhs.x
        }
        return false
    }

    private static func crop(
        observation: VNRectangleObservation,
        from image: CIImage,
        context: CIContext
    ) throws -> Data {
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            throw TradingCardBulkRecognitionError.cropFailed
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: ciPoint(observation.topLeft, extent: image.extent)), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: ciPoint(observation.topRight, extent: image.extent)), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: ciPoint(observation.bottomRight, extent: image.extent)), forKey: "inputBottomRight")
        filter.setValue(CIVector(cgPoint: ciPoint(observation.bottomLeft, extent: image.extent)), forKey: "inputBottomLeft")

        guard let outputImage = filter.outputImage else {
            throw TradingCardBulkRecognitionError.cropFailed
        }

        return try jpegData(from: outputImage, context: context)
    }

    private static func jpegData(from image: CIImage, context: CIContext) throws -> Data {
        guard let cgImage = context.createCGImage(image, from: image.extent.integral) else {
            throw TradingCardBulkRecognitionError.cgImageUnavailable
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw TradingCardBulkRecognitionError.writeFailed
        }
        let options = [
            kCGImageDestinationLossyCompressionQuality: 0.92
        ] as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, options)
        guard CGImageDestinationFinalize(destination) else {
            throw TradingCardBulkRecognitionError.writeFailed
        }
        return data as Data
    }

    private static func ciPoint(_ point: CGPoint, extent: CGRect) -> CGPoint {
        CGPoint(
            x: extent.minX + point.x * extent.width,
            y: extent.minY + point.y * extent.height
        )
    }

    private static func normalizedTopLeftCenter(_ observation: VNRectangleObservation) -> CGPoint {
        let visionCenterY = (
            observation.topLeft.y
                + observation.topRight.y
                + observation.bottomRight.y
                + observation.bottomLeft.y
        ) / 4
        return CGPoint(
            x: (
                observation.topLeft.x
                    + observation.topRight.x
                    + observation.bottomRight.x
                    + observation.bottomLeft.x
            ) / 4,
            y: 1 - visionCenterY
        )
    }

    private static func exifOrientation(from imageData: Data) -> CGImagePropertyOrientation {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawOrientation = properties[kCGImagePropertyOrientation] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: rawOrientation)
        else {
            return .up
        }
        return orientation
    }
}

private enum TradingCardRectangleDetectionConfig {
    static let maximumObservations = 30
    static let minimumAspectRatio: VNAspectRatio = 0.6
    static let maximumAspectRatio: VNAspectRatio = 0.85
    static let minimumSize: Float = 0.05
    static let minimumConfidence: VNConfidence = 0.6
    static let quadratureTolerance: VNDegrees = 20
    static let rowTolerance: CGFloat = 0.05
}
