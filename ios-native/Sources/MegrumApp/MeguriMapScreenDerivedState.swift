import MapKit
import MegrumCore

extension MeguriMapScreen {
    var mapGrooms: [GroomPost] {
        // iter1226.433：ビューポート蓄積分も含める（再読み込みで圏外ピンが消えない）。
        appState.meguriMapDisplayGrooms
    }

    var mapThreads: [BoardThread] {
        appState.meguriMapDisplayThreads
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
        if appState.subscriptionState.hasMeguriBoardExtendedAccess {
            if kind == .all, rangeCircle != nil {
                return "グルームは1km圏内、チャットルームはプレミアム表示中"
            }
            if kind == .boards {
                return boardScope == .samePrefecture
                    ? "都道府県内のチャットルームをプレミアム表示中"
                    : "チャットルームをプレミアム表示中"
            }
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
