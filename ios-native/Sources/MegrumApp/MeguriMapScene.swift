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
    var onOpenGroomCluster: ([GroomPost]) -> Void
    var onOpenThread: (BoardThread) -> Void
    /// iter1226.453：グルームを開く標準zoomの source namespace（ピンから全画面へ連続変形）。
    var groomZoomNamespace: Namespace.ID? = nil

    var body: some View {
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
        .mapControls {
            if !isVisualQAPreviewEnabled {
                MapUserLocationButton()
            }
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()
    }

    @MapContentBuilder
    private var groomAnnotations: some MapContent {
        ForEach(GroomMapCluster.clusters(from: grooms)) { cluster in
            Annotation(cluster.title, coordinate: cluster.coordinate) {
                if cluster.posts.count > 1 {
                    Button {
                        onOpenGroomCluster(cluster.posts)
                    } label: {
                        groomZoomSource(cluster.posts.first?.id) {
                            GroomClusterMapPin(count: cluster.posts.count)
                        }
                    }
                    .buttonStyle(.plain)
                } else if let groom = cluster.posts.first {
                    Button {
                        onOpenGroom(groom)
                    } label: {
                        groomZoomSource(groom.id) {
                            GroomMapPin(
                                groom: groom,
                                isOutOfRange: isGroomOutOfRange(groom),
                                isRead: viewedGroomIDs.contains(groom.id)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// iter1226.453：iOS18+ かつ namespace 指定時のみ、ピンを zoom 遷移の source にする。
    @ViewBuilder
    private func groomZoomSource(_ id: UUID?, @ViewBuilder content: () -> some View) -> some View {
        #if canImport(UIKit)
        if #available(iOS 18.0, *), let groomZoomNamespace, let id {
            content().matchedTransitionSource(id: id, in: groomZoomNamespace)
        } else {
            content()
        }
        #else
        content()
        #endif
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
