import MapKit
import MegrumCore
import SwiftUI

/// iter1226.455：めぐりマップのグルームを標準zoomで開くための二段階提示の状態。
///
/// 背景：MapKit の `Annotation` 内に置いた `matchedTransitionSource` は zoom の source として
/// 解決されない（中身が MapKit 側レイヤでホストされる）。また source を「タップと同時」に出すと、
/// 提示と同一トランザクションで生まれるため layout 未確定で zoom がマッチできない。
///
/// 対策（別AI相談の推奨構成）：
/// 1. タップ時はまだビューアを開かず `pendingZoom` だけ立てる
/// 2. 実ピンと同じ見た目の **可視ミラー**を MapProxy 変換位置へ置き `matchedTransitionSource` を付ける
/// 3. ミラーの layout 完了（preference でフレーム受信）を待ってから `viewerRoute` を立てる
/// 4. 二重 fullScreenCover をやめ、Map を包む `NavigationStack` へ `navigationDestination` で push
struct PendingGroomMapZoom: Identifiable, Equatable {
    /// このpresentation専用のsource ID（提示側 zoom(sourceID:) と一致させる）。
    let id: UUID
    /// ミラーを置くピンの座標（単体＝グルーム座標、クラスタ＝クラスタ中心）。
    var latitude: Double
    var longitude: Double
    /// ミラーの見た目に使う代表グルーム。
    var representative: GroomPost
    /// ビューアで辿るグルーム列（1km圏内の一連）。
    var grooms: [GroomPost]
    /// 最初に表示するグルーム。
    var initialGroom: GroomPost
    /// クラスタか（クラスタなら件数バッジのミラーを出す）。
    var isCluster: Bool
    var clusterCount: Int
    /// 既読リング表示用。
    var isRead: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func == (lhs: PendingGroomMapZoom, rhs: PendingGroomMapZoom) -> Bool {
        lhs.id == rhs.id
            && lhs.latitude == rhs.latitude
            && lhs.longitude == rhs.longitude
            && lhs.initialGroom.id == rhs.initialGroom.id
    }
}

/// push で提示するビューアのルート。`sourceID` は `PendingGroomMapZoom.id` と一致する。
struct GroomMapViewerRoute: Identifiable, Hashable {
    let sourceID: UUID
    var grooms: [GroomPost]
    var initialGroom: GroomPost

    var id: UUID { sourceID }

    static func == (lhs: GroomMapViewerRoute, rhs: GroomMapViewerRoute) -> Bool {
        lhs.sourceID == rhs.sourceID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sourceID)
    }
}

/// ミラーの layout 完了を検知する preference（フレームが有効になったら提示してよい合図）。
struct GroomZoomSourceFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}
