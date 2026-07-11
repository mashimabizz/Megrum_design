import Foundation
import MegrumCore
import SwiftUI

/// iter1226.457：めぐりマップのグルーム標準zoomの source ID。
///
/// ホームレールと同じ「source常設・タップ即提示」構成にするための安定ID。
/// 表示中の単体ピン／クラスタごとに1つ割り当て、overlay側の常設ミラーの
/// `matchedTransitionSource(id:)` と、提示側の `zoom(sourceID:)` の両方で使う。
/// （毎タップ `UUID()` を作る方式だと source が後付け生成になり、初回タップ不発と
/// 提示ラグの原因だった。presentation の識別は `GroomMapViewerRoute.id` に分離する。）
enum GroomMapZoomSourceID: Hashable {
    case groom(UUID)
    case cluster(String)

    init(cluster: GroomMapCluster) {
        if cluster.posts.count == 1, let post = cluster.posts.first {
            self = .groom(post.id)
        } else {
            self = .cluster(cluster.id)
        }
    }
}

/// fullScreenCover で提示するビューアのルート。
/// `id`（presentation識別）と `sourceID`（zoomの起点）は別物として保持する。
struct GroomMapViewerRoute: Identifiable {
    let id = UUID()
    let sourceID: GroomMapZoomSourceID
    var grooms: [GroomPost]
    var initialGroom: GroomPost
}

/// iOS18+ でグルームビューアを標準zoomで開く宛先モディファイア
/// （めぐりマップ／めぐりホームのインライン地図で共用）。
struct GroomMapZoomDestination: ViewModifier {
    var sourceID: GroomMapZoomSourceID
    var namespace: Namespace.ID

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
        #else
        content
        #endif
    }
}
