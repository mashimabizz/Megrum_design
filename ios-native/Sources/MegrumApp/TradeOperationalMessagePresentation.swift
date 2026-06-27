import CoreGraphics
import Foundation
import MegrumCore

struct TradeOperationalMessagePresentation: Equatable, Sendable {
    var title: String
    var systemImage: String
    var body: String
    var detail: String?

    init(message: TradeMessage) {
        switch message.messageType {
        case .location:
            title = message.locationLabel.nilIfBlank ?? "現在地共有"
            systemImage = "location.fill"
            body = Self.locationBody(message: message)
            detail = "位置情報"
        case .arrivalStatus:
            title = "到着ステータス"
            systemImage = "checkmark.circle.fill"
            body = message.body.nilIfBlank ?? "到着状況を共有しました"
            detail = message.meta["status"].flatMap(Self.arrivalDetail(for:))
        default:
            title = "取引メッセージ"
            systemImage = "info.circle.fill"
            body = message.body.nilIfBlank ?? "取引が更新されました"
            detail = nil
        }
    }

    private static func locationBody(message: TradeMessage) -> String {
        if let body = message.body.nilIfBlank {
            return body
        }
        if let latitude = message.locationLatitude, let longitude = message.locationLongitude {
            let latText = latitude.formatted(.number.precision(.fractionLength(5)))
            let lngText = longitude.formatted(.number.precision(.fractionLength(5)))
            return "緯度 \(latText) / 経度 \(lngText)"
        }
        return "現在地を共有しました"
    }

    private static func arrivalDetail(for rawStatus: String) -> String? {
        switch TradeArrivalStatus(rawValue: rawStatus) {
        case .enroute:
            "移動中"
        case .arrived:
            "到着済み"
        case .left:
            "離れました"
        case .none:
            nil
        }
    }
}

enum TradePhotoMessageLayout {
    static func isPhotoMessage(_ messageType: TradeMessageType) -> Bool {
        messageType == .photo || messageType == .outfitPhoto
    }

    static func thumbnailSize(for messageType: TradeMessageType) -> CGSize {
        switch messageType {
        case .outfitPhoto:
            CGSize(width: 142, height: 188)
        case .photo:
            CGSize(width: 150, height: 150)
        case .text, .location, .arrivalStatus, .system:
            CGSize(width: 150, height: 150)
        }
    }

    static func label(for messageType: TradeMessageType) -> String? {
        switch messageType {
        case .photo:
            "写真"
        case .outfitPhoto:
            "服装写真"
        case .text, .location, .arrivalStatus, .system:
            nil
        }
    }
}
