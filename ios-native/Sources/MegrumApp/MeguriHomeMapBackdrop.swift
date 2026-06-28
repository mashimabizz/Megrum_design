import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriHomeMapBackdrop: View {
    @Binding var cameraPosition: MapCameraPosition
    var selectedKind: MeguriMapKind
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var currentCoordinate: MegrumLocationCoordinate?
    var viewerID: UUID?
    var onSelectGroom: (GroomPost) -> Void
    var onSelectThread: (BoardThread) -> Void
    var onTapCoordinate: (MegrumLocationCoordinate) -> Void
    var pendingCreationCoordinate: MegrumLocationCoordinate?
    var onCreateGroomAtPendingCoordinate: () -> Void
    var onCreateThreadAtPendingCoordinate: () -> Void
    var onCancelPendingCreationCoordinate: () -> Void

    var body: some View {
        GeometryReader { geometry in
            MapReader { proxy in
                ZStack(alignment: .topLeading) {
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                        if let currentCoordinate {
                            MapCircle(
                                center: currentCoordinate.clLocationCoordinate,
                                radius: MeguriAccessPolicy.groomOpenRadiusMeters
                            )
                            .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                            .stroke(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.8)

                            Annotation("現在地", coordinate: currentCoordinate.clLocationCoordinate) {
                                CurrentLocationDot()
                            }
                        }

                        if selectedKind == .all || selectedKind == .grooms {
                            ForEach(grooms) { groom in
                                Annotation("", coordinate: groom.coordinate) {
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
                        }

                        if selectedKind == .all || selectedKind == .boards {
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

                    }
                    .mapStyle(.standard(elevation: .flat, emphasis: .muted))
                    .simultaneousGesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                guard pendingCreationCoordinate == nil else {
                                    return
                                }
                                guard !isAnnotationTap(
                                    at: value.location,
                                    in: proxy
                                ) else {
                                    return
                                }
                                guard let coordinate = proxy.convert(value.location, from: .local) else {
                                    return
                                }
                                onTapCoordinate(
                                    MegrumLocationCoordinate(
                                        latitude: coordinate.latitude,
                                        longitude: coordinate.longitude
                                    )
                                )
                            }
                    )
                    .overlay {
                        LinearGradient(
                            colors: [.white.opacity(0.80), .white.opacity(0.28), .white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .center
                        )
                        .allowsHitTesting(false)
                    }

                    if let pendingCreationCoordinate,
                       let point = proxy.convert(pendingCreationCoordinate.clLocationCoordinate, to: .local) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onCancelPendingCreationCoordinate)
                            .transition(.opacity)
                            .zIndex(1)

                        MeguriMapCreationDropPin()
                            .id(pendingCreationCoordinate.creationPromptID)
                            .frame(width: 68, height: 72, alignment: .bottom)
                            .position(x: point.x, y: point.y - 36)
                            .transition(.opacity)
                            .zIndex(2)

                        let promptPosition = MeguriMapCreationPromptLayout.position(
                            for: point,
                            in: geometry.size
                        )
                        let promptPlacement = MeguriMapCreationPromptLayout.placement(
                            for: point,
                            in: geometry.size
                        )
                        let pointerOffset = MeguriMapCreationPromptLayout.pointerOffset(
                            for: point,
                            in: geometry.size
                        )

                        MeguriMapCreationPromptCallout(
                            placement: promptPlacement,
                            pointerOffset: pointerOffset,
                            onCreateGroom: onCreateGroomAtPendingCoordinate,
                            onCreateThread: onCreateThreadAtPendingCoordinate
                        )
                        .id(pendingCreationCoordinate.creationPromptID)
                        .position(x: promptPosition.x, y: promptPosition.y)
                        .transition(.opacity)
                        .zIndex(3)
                    }
                }
            }
        }
    }
}

private extension MeguriHomeMapBackdrop {
    func isAnnotationTap(at location: CGPoint, in proxy: MapProxy) -> Bool {
        if selectedKind == .all || selectedKind == .grooms {
            for groom in grooms {
                guard let point = proxy.convert(groom.coordinate, to: .local) else {
                    continue
                }
                if abs(location.x - point.x) <= 54, abs(location.y - point.y) <= 64 {
                    return true
                }
            }
        }

        if selectedKind == .all || selectedKind == .boards {
            for annotation in threads.compactMap(BoardMapAnnotation.init(thread:)) {
                guard let point = proxy.convert(annotation.coordinate, to: .local) else {
                    continue
                }
                if abs(location.x - point.x) <= 94, abs(location.y - point.y) <= 48 {
                    return true
                }
            }
        }

        return false
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
