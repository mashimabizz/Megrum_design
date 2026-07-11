import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMapRangeCircle {
    var center: CLLocationCoordinate2D
    var radius: CLLocationDistance
}

/// iter1226.454：めぐりマップのグルームを標準zoomで開くための source アンカー。
/// MapKit Annotation 内の matchedTransitionSource は効かないので、この座標を MapProxy で
/// 画面点に変換し、そこへ不可視アンカーを重ねる。id は提示側の zoom(sourceID:) と一致させる。
struct GroomMapZoomAnchor: Equatable {
    var id: UUID
    var coordinate: CLLocationCoordinate2D

    static func == (lhs: GroomMapZoomAnchor, rhs: GroomMapZoomAnchor) -> Bool {
        lhs.id == rhs.id
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct MeguriMapScene: View {
    @Binding var cameraPosition: MapCameraPosition
    var kind: MeguriMapKind
    var rangeCircle: MeguriMapRangeCircle?
    var currentCoordinate: MegrumLocationCoordinate?
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var isVisualQAPreviewEnabled: Bool
    /// iter1226.444：既読グルームのピン枠をグレーにする判定用。
    var viewedGroomIDs: Set<UUID> = []
    var isGroomOutOfRange: (GroomPost) -> Bool
    var isBoardOutOfRange: (BoardThread) -> Bool
    var onOpenGroom: (GroomPost) -> Void
    var onOpenGroomCluster: ([GroomPost]) -> Void
    var onOpenThread: (BoardThread) -> Void
    /// iter1226.453：グルームを開く標準zoomの source namespace（ピンから全画面へ連続変形）。
    var groomZoomNamespace: Namespace.ID? = nil
    /// iter1226.454：開こうとしているグルームの zoom source アンカー。
    /// MapKit の Annotation 内 matchedTransitionSource は効かないため、MapProxy で
    /// 座標→画面点に変換し、その位置に不可視アンカーを重ねて zoom source にする。
    var zoomAnchor: GroomMapZoomAnchor? = nil

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
                if let rangeCircle {
                    MapCircle(center: rangeCircle.center, radius: rangeCircle.radius)
                        .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                        .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.5)
                }

                if let currentCoordinate {
                    Annotation("現在地", coordinate: currentCoordinate.clLocationCoordinate) {
                        CurrentLocationDot()
                    }
                }

                switch kind {
                case .all:
                    groomAnnotations
                    boardAnnotations
                case .grooms:
                    groomAnnotations
                case .boards:
                    boardAnnotations
                }
            }
            .mapStyle(MeguriMapVisualStyle.quietStandard)
            .overlay {
                MeguriMapBrandToneOverlay()
            }
            .overlay {
                groomZoomAnchorOverlay(proxy: proxy)
            }
            .mapControls {
                if !isVisualQAPreviewEnabled {
                    MapUserLocationButton()
                }
                MapCompass()
                MapScaleView()
            }
        }
        .ignoresSafeArea()
    }

    /// ピンの画面位置に置く不可視の zoom source アンカー（iOS18+）。
    @ViewBuilder
    private func groomZoomAnchorOverlay(proxy: MapProxy) -> some View {
        #if canImport(UIKit)
        if #available(iOS 18.0, *),
           let groomZoomNamespace,
           let zoomAnchor,
           let point = proxy.convert(zoomAnchor.coordinate, to: .local) {
            Color.clear
                .frame(width: 48, height: 58)
                .matchedTransitionSource(id: zoomAnchor.id, in: groomZoomNamespace)
                .position(point)
                .allowsHitTesting(false)
        }
        #endif
    }

    @MapContentBuilder
    private var groomAnnotations: some MapContent {
        ForEach(GroomMapCluster.clusters(from: grooms)) { cluster in
            Annotation(cluster.title, coordinate: cluster.coordinate) {
                if cluster.posts.count > 1 {
                    Button {
                        onOpenGroomCluster(cluster.posts)
                    } label: {
                        GroomClusterMapPin(count: cluster.posts.count)
                    }
                    .buttonStyle(.plain)
                } else if let groom = cluster.posts.first {
                    Button {
                        onOpenGroom(groom)
                    } label: {
                        GroomMapPin(
                            groom: groom,
                            isOutOfRange: isGroomOutOfRange(groom),
                            isRead: viewedGroomIDs.contains(groom.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @MapContentBuilder
    private var boardAnnotations: some MapContent {
        ForEach(threads.compactMap(BoardMapAnnotation.init(thread:))) { annotation in
            Annotation(annotation.thread.title, coordinate: annotation.coordinate) {
                Button {
                    onOpenThread(annotation.thread)
                } label: {
                    BoardMapPin(
                        thread: annotation.thread,
                        isOutOfRange: isBoardOutOfRange(annotation.thread)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
