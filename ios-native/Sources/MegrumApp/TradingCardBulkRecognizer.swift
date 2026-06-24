import CoreGraphics
import CoreImage
import Foundation

enum TradingCardBulkRecognizer {
    static func recognizeCards(
        in imageData: Data,
        maximumCards: Int = TradingCardRectangleDetectionConfig.maximumObservations
    ) async throws -> [TradingCardBulkRecognitionResult] {
        try await Task.detached(priority: .userInitiated) {
            try recognizeCardsSynchronously(in: imageData, maximumCards: maximumCards)
        }.value
    }

    static func detectCropFrames(
        in imageData: Data,
        maximumCards: Int = TradingCardRectangleDetectionConfig.maximumObservations
    ) async throws -> [TradingCardCropFrame] {
        try await Task.detached(priority: .userInitiated) {
            try detectCropFramesSynchronously(in: imageData, maximumCards: maximumCards)
        }.value
    }

    static func cropFrames(
        _ frames: [TradingCardCropFrame],
        in imageData: Data
    ) async throws -> [TradingCardBulkRecognitionResult] {
        try await Task.detached(priority: .userInitiated) {
            try cropFramesSynchronously(frames, in: imageData)
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

    static func detectCropFramesSynchronously(
        in imageData: Data,
        maximumCards: Int = TradingCardRectangleDetectionConfig.maximumObservations
    ) throws -> [TradingCardCropFrame] {
        guard let rawImage = CIImage(data: imageData) else {
            throw TradingCardBulkRecognitionError.imageLoadFailed
        }
        let image = rawImage.oriented(exifOrientation(from: imageData))
        return try detectRectangles(in: image, maximumCards: maximumCards)
            .map { observation in
                TradingCardCropFrame(
                    rect: normalizedBoundingRect(observation),
                    source: .detected
                )
            }
    }

    static func cropFramesSynchronously(
        _ frames: [TradingCardCropFrame],
        in imageData: Data
    ) throws -> [TradingCardBulkRecognitionResult] {
        guard let rawImage = CIImage(data: imageData) else {
            throw TradingCardBulkRecognitionError.imageLoadFailed
        }
        let image = rawImage.oriented(exifOrientation(from: imageData))
        let context = CIContext(options: [.useSoftwareRenderer: false])
        return try frames.map { frame in
            TradingCardBulkRecognitionResult(
                id: frame.id,
                data: try crop(rect: frame.rect, from: image, context: context),
                source: frame.source
            )
        }
    }
}
