import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMapRangeCircle {
    var center: CLLocationCoordinate2D
    var radius: CLLocationDistance
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
    var onOpenGroomCluster: ([GroomPost], CLLocationCoordinate2D) -> Void
    var onOpenThread: (BoardThread) -> Void
    /// iter1226.453：グルームを開く標準zoomの source namespace（ピンから全画面へ連続変形）。
    var groomZoomNamespace: Namespace.ID? = nil
    /// iter1226.455：開こうとしているグルーム（ミラーを出す対象）。
    var pendingZoom: PendingGroomMapZoom? = nil
    /// ミラーの layout 完了フレームを親へ伝える。
    var onZoomMirrorFrameChange: (CGRect) -> Void = { _ in }

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
                groomZoomMirrorOverlay(proxy: proxy)
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
        .onPreferenceChange(GroomZoomSourceFrameKey.self) { frame in
            onZoomMirrorFrameChange(frame)
        }
    }

    /// iter1226.455：ピンの画面位置に、実ピンと同じ見た目の可視ミラーを重ねる。
    /// これを zoom source（matchedTransitionSource）にし、layout 完了を preference で親へ知らせる。
    @ViewBuilder
    private func groomZoomMirrorOverlay(proxy: MapProxy) -> some View {
        #if canImport(UIKit)
        if #available(iOS 18.0, *),
           let groomZoomNamespace,
           let pendingZoom,
           let point = proxy.convert(pendingZoom.coordinate, to: .local) {
            Group {
                if pendingZoom.isCluster {
                    GroomClusterMapPin(count: pendingZoom.clusterCount)
                } else {
                    GroomMapPin(
                        groom: pendingZoom.representative,
                        isOutOfRange: false,
                        isRead: pendingZoom.isRead
                    )
                }
            }
            .matchedTransitionSource(id: pendingZoom.id, in: groomZoomNamespace)
            .position(point)
            .allowsHitTesting(false)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: GroomZoomSourceFrameKey.self,
                        value: geometry.frame(in: .global)
                    )
                }
            }
        }
        #endif
    }

    @MapContentBuilder
    private var groomAnnotations: some MapContent {
        ForEach(GroomMapCluster.clusters(from: grooms)) { cluster in
            Annotation(cluster.title, coordinate: cluster.coordinate) {
                if cluster.posts.count > 1 {
                    Button {
                        onOpenGroomCluster(cluster.posts, cluster.coordinate)
                    } label: {
                        GroomClusterMapPin(count: cluster.posts.count)
                            // iter1226.455：ミラー表示中の実ピンは隠して二重表示を避ける。
                            .opacity(isMirrored(cluster.posts.first) ? 0 : 1)
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
                        .opacity(isMirrored(groom) ? 0 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func isMirrored(_ groom: GroomPost?) -> Bool {
        guard let groom, let pendingZoom else { return false }
        return pendingZoom.representative.id == groom.id
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
