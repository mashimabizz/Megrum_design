import Foundation
import MapKit

/// めぐり地図のズームアウト時、「おおよその件数」表示へ切り替える判定と
/// 取得パラメータ（セルサイズ・取得範囲）を決める純ロジック（iter1226.434）。
enum MeguriMapDensityPlanner {
    /// これ以上ズームアウトしたら密度（件数）表示へ切り替えるスパン（緯度差）。
    /// 約13km表示。実データのピンはこの手前まで（3km圏＋ビューポート読み込み）。
    static let activationSpanLatitudeDelta: Double = 0.12
    /// 取得範囲は表示範囲より少し広げる（パン直後のチラつき防止）。
    static let boundsPaddingRatio: Double = 0.25
    /// セルサイズの下限（約2km）と上限（約200km）。
    static let minCellDegrees: Double = 0.02
    static let maxCellDegrees: Double = 2.0
    /// 表示スパンに対するセル分割数。クラスタリングと同じ感覚の粒度にする。
    static let cellsPerSpan: Double = 5.0

    struct Bounds: Equatable {
        var minLatitude: Double
        var minLongitude: Double
        var maxLatitude: Double
        var maxLongitude: Double
    }

    static func isDensityMode(spanLatitudeDelta: Double) -> Bool {
        spanLatitudeDelta > activationSpanLatitudeDelta
    }

    static func cellDegrees(spanLatitudeDelta: Double) -> Double {
        min(max(spanLatitudeDelta / cellsPerSpan, minCellDegrees), maxCellDegrees)
    }

    static func fetchBounds(region: MKCoordinateRegion) -> Bounds {
        let latPad = region.span.latitudeDelta * boundsPaddingRatio
        let lngPad = region.span.longitudeDelta * boundsPaddingRatio
        return Bounds(
            minLatitude: max(region.center.latitude - region.span.latitudeDelta / 2 - latPad, -90),
            minLongitude: max(region.center.longitude - region.span.longitudeDelta / 2 - lngPad, -180),
            maxLatitude: min(region.center.latitude + region.span.latitudeDelta / 2 + latPad, 90),
            maxLongitude: min(region.center.longitude + region.span.longitudeDelta / 2 + lngPad, 180)
        )
    }

    /// 密度バブルタップ時のズーム先スパン。
    /// 必ずピン表示モード（activation 未満）に入るところまで寄せる。
    static func zoomSpan(currentSpanLatitudeDelta: Double) -> Double {
        let cell = cellDegrees(spanLatitudeDelta: currentSpanLatitudeDelta)
        return max(min(cell * 2.0, activationSpanLatitudeDelta * 0.8), 0.02)
    }
}
