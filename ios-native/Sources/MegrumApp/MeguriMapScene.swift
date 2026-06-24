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
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var isVisualQAPreviewEnabled: Bool
    var isGroomOutOfRange: (GroomPost) -> Bool
    var isBoardOutOfRange: (BoardThread) -> Bool
    var onOpenGroom: (GroomPost) -> Void
    var onOpenThread: (BoardThread) -> Void

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
            if let rangeCircle {
                MapCircle(center: rangeCircle.center, radius: rangeCircle.radius)
                    .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                    .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.5)
            }

            switch kind {
            case .grooms:
                groomAnnotations
            case .boards:
                boardAnnotations
            }
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
        ForEach(grooms) { groom in
            Annotation("グルーム", coordinate: groom.coordinate) {
                Button {
                    onOpenGroom(groom)
                } label: {
                    GroomMapPin(groom: groom, isOutOfRange: isGroomOutOfRange(groom))
                }
                .buttonStyle(.plain)
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
