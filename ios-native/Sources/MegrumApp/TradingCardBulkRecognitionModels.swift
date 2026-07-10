import CoreGraphics
import Foundation
import MegrumCore

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

struct TradingCardCropFrame: Equatable, Identifiable, Sendable {
    var id: UUID
    var rect: CGRect
    var source: TradingCardBulkRecognitionResult.Source

    init(
        id: UUID = UUID(),
        rect: CGRect,
        source: TradingCardBulkRecognitionResult.Source = .detected
    ) {
        self.id = id
        self.rect = TradingCardCropFrame.normalized(rect)
        self.source = source
    }

    private static func normalized(_ rect: CGRect) -> CGRect {
        let x = min(max(rect.minX, 0), 1)
        let y = min(max(rect.minY, 0), 1)
        let maxX = min(max(rect.maxX, 0), 1)
        let maxY = min(max(rect.maxY, 0), 1)
        return CGRect(
            x: min(x, maxX),
            y: min(y, maxY),
            width: abs(maxX - x),
            height: abs(maxY - y)
        )
    }
}
