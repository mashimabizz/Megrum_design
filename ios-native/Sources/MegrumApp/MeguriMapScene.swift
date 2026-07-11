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
    var onOpenGroomCluster: ([GroomPost], GroomMapZoomSourceID) -> Void
    var onOpenThread: (BoardThread) -> Void
    /// iter1226.453：グルームを開く標準zoomの source namespace（ピンから全画面へ連続変形）。
    var groomZoomNamespace: Namespace.ID? = nil

    /// iter1226.457：カメラ移動のたびに body を再評価させ、overlay の常設ピンを追従させる。
    /// （@State の読み取りが無いと SwiftUI が変化を追跡しないため、overlay 内で読む。）
    @State private var cameraUpdateTick = 0

    /// iter1226.457：ホームレールと同じ「source常設・タップ即提示」構成。
    /// MapKit Annotation 内の View は zoom source として解決されないため、
    /// iOS18+ では **overlay 側の常設ピンを唯一の可視ピン**にして matchedTransitionSource を付け、
    /// Annotation 側は透明のタップ領域だけにする（タップ判定は MapKit 側が確実）。
    private var usesOverlayPins: Bool {
        #if canImport(UIKit)
        if #available(iOS 18.0, *), groomZoomNamespace != nil {
            return true
        }
        #endif
        return false
    }

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
                groomZoomSourcePinsOverlay(proxy: proxy)
            }
            .overlay {
                MeguriMapBrandToneOverlay()
            }
            .mapControls {
                if !isVisualQAPreviewEnabled {
                    MapUserLocationButton()
                }
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .continuous) { _ in
                cameraUpdateTick &+= 1
            }
        }
        .ignoresSafeArea()
    }

    /// iter1226.457：表示中の単体ピン／クラスタの画面位置に、実際に見えるピンを常設で重ねる。
    /// 各ピンが常時 matchedTransitionSource を持つため、タップ時には source が既に layout 済み
    /// ＝ホームレールと同じ「タップ即・一体でズーム」になる。
    @ViewBuilder
    private func groomZoomSourcePinsOverlay(proxy: MapProxy) -> some View {
        #if canImport(UIKit)
        if #available(iOS 18.0, *), let groomZoomNamespace, kind != .boards {
            // カメラ変化の tick を読むことで、パン/ズーム中も位置が追従する。
            let _ = cameraUpdateTick
            ForEach(GroomMapCluster.clusters(from: grooms)) { cluster in
                if let point = proxy.convert(cluster.coordinate, to: .local) {
                    Group {
                        if cluster.posts.count > 1 {
                            GroomClusterMapPin(count: cluster.posts.count)
                        } else if let groom = cluster.posts.first {
                            GroomMapPin(
                                groom: groom,
                                isOutOfRange: isGroomOutOfRange(groom),
                                isRead: viewedGroomIDs.contains(groom.id)
                            )
                        }
                    }
                    .matchedTransitionSource(id: GroomMapZoomSourceID(cluster: cluster), in: groomZoomNamespace)
                    .position(point)
                    .allowsHitTesting(false)
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
                        onOpenGroomCluster(cluster.posts, GroomMapZoomSourceID(cluster: cluster))
                    } label: {
                        if usesOverlayPins {
                            // 見た目は overlay 側の常設ピン。ここはタップ領域だけ。
                            Color.clear
                                .frame(width: 66, height: 66)
                                .contentShape(Rectangle())
                        } else {
                            GroomClusterMapPin(count: cluster.posts.count)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(cluster.title)
                } else if let groom = cluster.posts.first {
                    Button {
                        onOpenGroom(groom)
                    } label: {
                        if usesOverlayPins {
                            Color.clear
                                .frame(width: 66, height: 66)
                                .contentShape(Rectangle())
                        } else {
                            GroomMapPin(
                                groom: groom,
                                isOutOfRange: isGroomOutOfRange(groom),
                                isRead: viewedGroomIDs.contains(groom.id)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("グルーム")
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
