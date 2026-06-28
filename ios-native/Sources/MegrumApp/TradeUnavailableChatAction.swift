import MegrumCore

enum TradeUnavailableChatAction: String, Identifiable {
    case location
    case photo
    case outfitPhoto

    static func messageFailureAction(for messageType: TradeMessageType) -> TradeUnavailableChatAction? {
        switch messageType {
        case .photo:
            .photo
        case .outfitPhoto:
            .outfitPhoto
        case .text, .location, .arrivalStatus, .system:
            nil
        }
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location:
            "現在地を共有"
        case .photo:
            "写真を送信"
        case .outfitPhoto:
            "服装写真を共有"
        }
    }

    var systemImage: String {
        switch self {
        case .location:
            "location.fill"
        case .photo:
            "photo.on.rectangle"
        case .outfitPhoto:
            "person.crop.rectangle"
        }
    }

    var description: String {
        switch self {
        case .location:
            "現在地を取得できませんでした。端末の位置情報許可を確認してください。"
        case .photo:
            "写真を送信できませんでした。写真の選択権限と通信状態を確認してください。"
        case .outfitPhoto:
            "服装写真を送信できませんでした。写真の選択権限と通信状態を確認してください。"
        }
    }
}
