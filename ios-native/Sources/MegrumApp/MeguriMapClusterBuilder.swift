import Foundation
import MegrumCore

/// めぐり地図のマーカー（グルーム/チャットルーム混在）を、表示中のズーム
/// レベルに応じて近接グループへ統合するための純ロジック。
/// セル幅は表示スパンに比例させ、同一セルに落ちたマーカーを1クラスタにする。
enum MeguriMapClusterBuilder {
    /// 表示スパンに対するセル分割数。大きいほど統合されにくい。
    static let cellsPerSpan: Double = 6.5
    /// クラスタタップ時に「数個程度へ分解」とみなす分割数の範囲。
    static let desiredSplitRange = 2...8
    /// 分解ズームの下限スパン（度）。これ以上は寄らない。
    static let minimumSplitSpan: Double = 0.0016

    enum Item: Identifiable, Equatable {
        case groom(GroomPost)
        case thread(BoardThread)

        var id: String {
            switch self {
            case .groom(let groom): "groom:\(groom.id.uuidString.lowercased())"
            case .thread(let thread): "thread:\(thread.id.uuidString.lowercased())"
            }
        }

        var latitude: Double? {
            switch self {
            case .groom(let groom): groom.latitude
            case .thread(let thread): thread.latitude
            }
        }

        var longitude: Double? {
            switch self {
            case .groom(let groom): groom.longitude
            case .thread(let thread): thread.longitude
            }
        }
    }

    struct Cluster: Identifiable, Equatable {
        var id: String
        var items: [Item]
        /// 統合前に立っていたマーカー座標の中間地点（平均）。
        var latitude: Double
        var longitude: Double

        var count: Int { items.count }
    }

    enum Element: Identifiable, Equatable {
        case single(Item)
        case cluster(Cluster)

        var id: String {
            switch self {
            case .single(let item): item.id
            case .cluster(let cluster): "cluster:\(cluster.id)"
            }
        }
    }

    static func elements(
        grooms: [GroomPost],
        threads: [BoardThread],
        spanLatitudeDelta: Double
    ) -> [Element] {
        let items = grooms.map(Item.groom) + threads.map(Item.thread)
        return elements(items: items, spanLatitudeDelta: spanLatitudeDelta)
    }

    static func elements(items: [Item], spanLatitudeDelta: Double) -> [Element] {
        let located = items.filter { $0.latitude != nil && $0.longitude != nil }
        let cell = cellDegrees(spanLatitudeDelta: spanLatitudeDelta)
        guard cell > 0 else {
            return located.map(Element.single)
        }

        let grouped = Dictionary(grouping: located) { item -> String in
            let lat = Int(((item.latitude ?? 0) / cell).rounded(.down))
            let lng = Int(((item.longitude ?? 0) / cell).rounded(.down))
            return "\(lat):\(lng)"
        }

        return grouped
            .map { key, groupedItems -> Element in
                if groupedItems.count == 1, let single = groupedItems.first {
                    return .single(single)
                }
                let sorted = groupedItems.sorted { $0.id < $1.id }
                let latitude = sorted.compactMap(\.latitude).reduce(0, +) / Double(sorted.count)
                let longitude = sorted.compactMap(\.longitude).reduce(0, +) / Double(sorted.count)
                return .cluster(
                    Cluster(
                        id: key,
                        items: sorted,
                        latitude: latitude,
                        longitude: longitude
                    )
                )
            }
            .sorted { $0.id < $1.id }
    }

    static func cellDegrees(spanLatitudeDelta: Double) -> Double {
        guard spanLatitudeDelta.isFinite, spanLatitudeDelta > 0 else {
            return 0
        }
        return spanLatitudeDelta / cellsPerSpan
    }

    /// クラスタをタップした時の分解ズーム先スパン。
    /// スパンを半分ずつ狭めていき、クラスタが「数個程度」（2〜8）に
    /// 分解される最初のスパンを返す。分解されたマーカーが視界に収まるよう、
    /// クラスタ内の広がりよりは狭くしない。
    static func splitSpan(for cluster: Cluster, currentSpanLatitudeDelta: Double) -> Double {
        var span = max(currentSpanLatitudeDelta, minimumSplitSpan)
        for _ in 0..<10 {
            span /= 2
            if span <= minimumSplitSpan {
                return minimumSplitSpan
            }
            let split = elements(items: cluster.items, spanLatitudeDelta: span)
            if split.count >= desiredSplitRange.lowerBound {
                // 分解後のマーカーの広がり（緯度・経度差）が視界に収まるように調整。
                let spread = coordinateSpread(of: cluster)
                return max(span, spread * 1.6, minimumSplitSpan)
            }
        }
        return max(span, minimumSplitSpan)
    }

    private static func coordinateSpread(of cluster: Cluster) -> Double {
        let latitudes = cluster.items.compactMap(\.latitude)
        let longitudes = cluster.items.compactMap(\.longitude)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLng = longitudes.min(), let maxLng = longitudes.max() else {
            return 0
        }
        return max(maxLat - minLat, maxLng - minLng)
    }
}
