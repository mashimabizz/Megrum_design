import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

extension TradingCardBulkRecognizer {
    static func detectRectangles(
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

    static func isTopLeftCenterOrderedBefore(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        if abs(lhs.y - rhs.y) > TradingCardRectangleDetectionConfig.rowTolerance {
            return lhs.y < rhs.y
        }
        if abs(lhs.x - rhs.x) > .ulpOfOne {
            return lhs.x < rhs.x
        }
        return false
    }

    static func crop(
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

    static func crop(
        rect normalizedRect: CGRect,
        from image: CIImage,
        context: CIContext
    ) throws -> Data {
        let extent = image.extent
        let cropRect = CGRect(
            x: extent.minX + normalizedRect.minX * extent.width,
            y: extent.minY + (1 - normalizedRect.maxY) * extent.height,
            width: normalizedRect.width * extent.width,
            height: normalizedRect.height * extent.height
        ).integral

        guard cropRect.width > 1, cropRect.height > 1 else {
            throw TradingCardBulkRecognitionError.cropFailed
        }
        return try jpegData(from: image.cropped(to: cropRect), context: context)
    }

    static func jpegData(from image: CIImage, context: CIContext) throws -> Data {
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

    static func normalizedBoundingRect(_ observation: VNRectangleObservation) -> CGRect {
        let xs = [
            observation.topLeft.x,
            observation.topRight.x,
            observation.bottomRight.x,
            observation.bottomLeft.x
        ]
        let ys = [
            observation.topLeft.y,
            observation.topRight.y,
            observation.bottomRight.y,
            observation.bottomLeft.y
        ]
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 1
        let minVisionY = ys.min() ?? 0
        let maxVisionY = ys.max() ?? 1
        return CGRect(
            x: minX,
            y: 1 - maxVisionY,
            width: maxX - minX,
            height: maxVisionY - minVisionY
        )
    }

    static func exifOrientation(from imageData: Data) -> CGImagePropertyOrientation {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawOrientation = properties[kCGImagePropertyOrientation] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: rawOrientation)
        else {
            return .up
        }
        return orientation
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
}

enum TradingCardRectangleDetectionConfig {
    static let maximumObservations = 30
    static let minimumAspectRatio: VNAspectRatio = 0.6
    static let maximumAspectRatio: VNAspectRatio = 0.85
    static let minimumSize: Float = 0.05
    static let minimumConfidence: VNConfidence = 0.6
    static let quadratureTolerance: VNDegrees = 20
    static let rowTolerance: CGFloat = 0.05
}
