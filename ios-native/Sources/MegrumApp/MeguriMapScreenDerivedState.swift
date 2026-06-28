import MapKit
import MegrumCore

extension MeguriMapScreen {
    var mapGrooms: [GroomPost] {
        appState.groomMapPosts.isEmpty ? appState.grooms : appState.groomMapPosts
    }

    var isLoadingMapContent: Bool {
        switch kind {
        case .all:
            appState.isLoadingGroomMap || appState.isLoadingMeguri
        case .grooms:
            appState.isLoadingGroomMap
        case .boards:
            appState.isLoadingMeguri
        }
    }

    var rangeCircle: MeguriMapRangeCircle? {
        guard let coordinate = locationState.coordinate else {
            return nil
        }
        return MeguriMapRangeCircle(center: coordinate.clLocationCoordinate, radius: kind.radiusMeters)
    }

    var mapStatusMessage: String? {
        if isLoadingMapContent || locationState.isRequestingLocation {
            return "現在地と投稿を読み込み中"
        }
        if let locationErrorMessage = locationState.locationErrorMessage, kind == .grooms || boardScope == .nearby3km {
            return locationErrorMessage
        }
        if kind == .all, rangeCircle != nil {
            return "現在地周辺のグルームとチャットルームを表示中。1km圏外は閲覧できません"
        }
        if kind == .boards, boardScope == .samePrefecture {
            return "都道府県内の位置つきチャットルームを表示中。1km圏外は閲覧できません"
        }
        if kind == .grooms, rangeCircle != nil {
            return "現在地周辺のグルームを表示中。1km圏外は閲覧できません"
        }
        if kind == .boards, rangeCircle != nil {
            return "現在地周辺のチャットルームを表示中。1km圏外は閲覧できません"
        }
        if rangeCircle == nil {
            return "範囲円は現在地取得後に表示されます"
        }
        return nil
    }

    var mapBoardScope: BoardThread.Audience {
        switch kind {
        case .all:
            boardScope
        case .grooms:
            .nearby3km
        case .boards:
            boardScope
        }
    }
}
