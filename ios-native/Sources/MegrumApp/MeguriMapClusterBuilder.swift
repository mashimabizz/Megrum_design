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

        /// クラスタアイコンとして採用する統合前マーカー（決定的に先頭を選ぶ）。
        var representative: Item? { items.first }
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

        var memberIDs: [String] {
            switch self {
            case .single(let item): [item.id]
            case .cluster(let cluster): cluster.items.map(\.id)
            }
        }

        var displayLatitude: Double {
            switch self {
            case .single(let item): item.latitude ?? 0
            case .cluster(let cluster): cluster.latitude
            }
        }

        var displayLongitude: Double {
            switch self {
            case .single(let item): item.longitude ?? 0
            case .cluster(let cluster): cluster.longitude
            }
        }
    }

    /// 地図上の表示位置つきマーカー。統合/分解モーフ中は本来の座標と
    /// 異なる位置（寄っていく先・散らばる前のクラスタ位置）を取る。
    struct DisplayedElement: Identifiable, Equatable {
        var element: Element
        var latitude: Double
        var longitude: Double
        var popsIn: Bool
        var opacity: Double

        var id: String { element.id }

        init(element: Element, popsIn: Bool) {
            self.element = element
            self.latitude = element.displayLatitude
            self.longitude = element.displayLongitude
            self.popsIn = popsIn
            self.opacity = 1
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

    /// 近接マーカーの統合。グリッド割りではなく「しきい値未満で連結した
    /// まとまり（連結成分）」で組む。しきい値（=表示スパン比例）が大きく
    /// なるほど成分は育つ一方で崩れないため、一度統合されたまとまりは
    /// 地図の縮小に伴って形を保ったまま、近づいた別のマーカー/まとまりと
    /// さらに統合されていく。
    static func elements(items: [Item], spanLatitudeDelta: Double) -> [Element] {
        let located = items.filter { $0.latitude != nil && $0.longitude != nil }
        let cell = cellDegrees(spanLatitudeDelta: spanLatitudeDelta)
        guard cell > 0, located.count > 1 else {
            return located.map(Element.single).sorted { $0.id < $1.id }
        }

        // Union-Find で「距離 < cell」のペアを連結していく。
        var parent = Array(0..<located.count)
        func root(_ index: Int) -> Int {
            var current = index
            while parent[current] != current {
                parent[current] = parent[parent[current]]
                current = parent[current]
            }
            return current
        }
        for lhs in 0..<(located.count - 1) {
            for rhs in (lhs + 1)..<located.count {
                let dLat = abs((located[lhs].latitude ?? 0) - (located[rhs].latitude ?? 0))
                let dLng = abs((located[lhs].longitude ?? 0) - (located[rhs].longitude ?? 0))
                if max(dLat, dLng) < cell {
                    let lhsRoot = root(lhs)
                    let rhsRoot = root(rhs)
                    if lhsRoot != rhsRoot {
                        parent[rhsRoot] = lhsRoot
                    }
                }
            }
        }

        var groups: [Int: [Item]] = [:]
        for index in located.indices {
            groups[root(index), default: []].append(located[index])
        }

        return groups.values
            .map { groupedItems -> Element in
                if groupedItems.count == 1, let single = groupedItems.first {
                    return .single(single)
                }
                let sorted = groupedItems.sorted { $0.id < $1.id }
                let latitude = sorted.compactMap(\.latitude).reduce(0, +) / Double(sorted.count)
                let longitude = sorted.compactMap(\.longitude).reduce(0, +) / Double(sorted.count)
                return .cluster(
                    Cluster(
                        id: sorted.map(\.id).joined(separator: "+"),
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
        func splitCount(at span: Double) -> Int {
            elements(items: cluster.items, spanLatitudeDelta: span).count
        }

        // 最低でも1段は分解されるスパンまで必ず狭める。
        // （全メンバーが同一座標の場合だけは分解不能なので下限で打ち切る）
        var span = max(currentSpanLatitudeDelta, minimumSplitSpan)
        var splittingSpan: Double?
        for _ in 0..<28 {
            span /= 2
            if splitCount(at: span) >= desiredSplitRange.lowerBound {
                splittingSpan = span
                break
            }
            if span < minimumSplitSpan / 1_000 {
                break
            }
        }
        guard let splittingSpan else {
            return minimumSplitSpan
        }

        // 分解後のマーカーの広がりが視界に収まるよう少し引いて見せたいが、
        // 引いた結果また統合されてしまうなら分解を優先する。
        let spread = coordinateSpread(of: cluster)
        let widened = max(splittingSpan, spread * 1.6, minimumSplitSpan)
        if widened > splittingSpan, splitCount(at: widened) >= desiredSplitRange.lowerBound {
            return widened
        }
        return splittingSpan
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
