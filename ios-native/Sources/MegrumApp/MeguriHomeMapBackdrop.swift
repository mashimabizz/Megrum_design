import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriHomeMapBackdrop: View {
    @Binding var cameraPosition: MapCameraPosition
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var currentCoordinate: MegrumLocationCoordinate?
    var viewerID: UUID?
    var onSelectGroom: (GroomPost) -> Void
    var onSelectThread: (BoardThread) -> Void

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            if let currentCoordinate {
                MapCircle(
                    center: currentCoordinate.clLocationCoordinate,
                    radius: MeguriAccessPolicy.groomOpenRadiusMeters
                )
                .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                .stroke(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.8)
            }

            ForEach(grooms) { groom in
                Annotation("グルーム", coordinate: groom.coordinate) {
                    Button {
                        onSelectGroom(groom)
                    } label: {
                        GroomMapPin(
                            groom: groom,
                            isOutOfRange: !MeguriAccessPolicy.canOpenGroom(
                                groom,
                                currentCoordinate: currentCoordinate,
                                viewerID: viewerID
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(threads.compactMap(BoardMapAnnotation.init(thread:))) { annotation in
                Annotation(annotation.thread.title, coordinate: annotation.coordinate) {
                    Button {
                        onSelectThread(annotation.thread)
                    } label: {
                        BoardMapPin(
                            thread: annotation.thread,
                            isOutOfRange: !MeguriAccessPolicy.canOpenBoard(
                                annotation.thread,
                                currentCoordinate: currentCoordinate,
                                viewerID: viewerID
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .overlay {
            LinearGradient(
                colors: [.white.opacity(0.80), .white.opacity(0.28), .white.opacity(0.04)],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
    }
}

private extension BoardThread {
    var shortMapTitle: String {
        if title.contains("物販") {
            return "物販列"
        }
        if title.contains("駅") || title.contains("広場") {
            return "駅前広場"
        }
        return String(title.prefix(4))
    }
}
