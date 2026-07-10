import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriMapPresentationModifier: ViewModifier {
    @Binding var activeMap: MeguriMapKind?
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var selectedPrefecture: String?
    var boardScope: BoardThread.Audience

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(item: $activeMap) { kind in
            NavigationStack {
                MeguriMapScreen(
                    kind: kind,
                    appState: appState,
                    locationState: locationState,
                    selectedPrefecture: selectedPrefecture,
                    boardScope: boardScope
                )
            }
        }
        #else
        content.sheet(item: $activeMap) { kind in
            NavigationStack {
                MeguriMapScreen(
                    kind: kind,
                    appState: appState,
                    locationState: locationState,
                    selectedPrefecture: selectedPrefecture,
                    boardScope: boardScope
                )
            }
        }
        #endif
    }
}

struct MeguriMapScreen: View {
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var selectedPrefecture: String?
    var boardScope: BoardThread.Audience
    @Environment(\.dismiss) private var dismiss
    @State var kind: MeguriMapKind
    @State var cameraPosition: MapCameraPosition
    @State var selectedGroom: GroomPost?
    @State var selectedGroomGroup: GroomMapGroomSelection?
    @State var selectedThread: BoardThread?
    @State var mapNotice: String?
    @State var outOfRangeAlertMessage = ""
    @State var isShowingOutOfRangeAlert = false
    @State var hasCenteredMapOnLocation = false

    init(
        kind: MeguriMapKind,
        appState: MegrumAppState,
        locationState: MegrumLocationState,
        selectedPrefecture: String?,
        boardScope: BoardThread.Audience
    ) {
        self.kind = kind
        self.appState = appState
        self.locationState = locationState
        self.selectedPrefecture = selectedPrefecture
        self.boardScope = boardScope
        _kind = State(initialValue: kind)
        let initialGrooms = appState.meguriMapDisplayGrooms
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: kind.initialCenter(userCoordinate: locationState.coordinate, grooms: initialGrooms, threads: appState.meguriMapDisplayThreads), span: kind.regionSpan)))
    }

    var body: some View {
        ZStack(alignment: .top) {
            MeguriMapScene(
                cameraPosition: $cameraPosition,
                kind: kind,
                rangeCircle: rangeCircle,
                currentCoordinate: locationState.coordinate,
                grooms: mapGrooms,
                threads: mapThreads,
                isVisualQAPreviewEnabled: VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment),
                isGroomOutOfRange: isGroomOutOfRange,
                isBoardOutOfRange: isBoardOutOfRange,
                onOpenGroom: openGroomIfInRange,
                onOpenGroomCluster: openGroomCluster,
                onOpenThread: openThreadIfInRange
            )

            VStack(spacing: 10) {
                MapGlassHeader(title: kind.title) {
                    dismiss()
                }

                MeguriMapFilterControl(activeKind: $kind)

                if let mapNotice {
                    MapStatusBadge(
                        message: mapNotice,
                        isLoading: false
                    )
                } else if let mapStatusMessage {
                    MapStatusBadge(
                        message: mapStatusMessage,
                        isLoading: isLoadingMapContent || locationState.isRequestingLocation
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)

            VStack {
                HStack {
                    Spacer()
                    MeguriMapRecenterButton(
                        isRequesting: locationState.isRequestingLocation,
                        action: centerMapOnCurrentLocation
                    )
                }
                .padding(.top, 72)
                .padding(.trailing, 18)

                Spacer()
            }
        }
        .task {
            if !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) {
                locationState.startUpdatingCurrentLocation()
            }
            await reloadMapContent(
                latitude: locationState.coordinate?.latitude,
                longitude: locationState.coordinate?.longitude
            )
            await MainActor.run {
                alignCameraToVisibleContent(userCoordinate: locationState.coordinate, animated: false)
            }
        }
        .onReceive(locationState.$coordinate.compactMap { $0 }) { coordinate in
            Task {
                await reloadMapContent(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                await MainActor.run {
                    mapNotice = nil
                    alignCameraToVisibleContent(userCoordinate: coordinate, animated: true)
                }
            }
        }
        .onChange(of: kind) { _, _ in
            Task {
                await reloadMapContent(
                    latitude: locationState.coordinate?.latitude,
                    longitude: locationState.coordinate?.longitude
                )
                await MainActor.run {
                    alignCameraToVisibleContent(userCoordinate: locationState.coordinate, animated: true, force: true)
                }
            }
        }
        #if os(iOS)
        .groomViewerImmersiveOverlay(item: $selectedGroom) { groom, dismiss in
            GroomViewerScreen(
                grooms: mapGrooms,
                initialGroom: groom,
                appState: appState,
                onDismiss: dismiss
            )
        }
        .groomViewerImmersiveOverlay(item: $selectedGroomGroup) { selection, dismiss in
            GroomViewerScreen(
                grooms: selection.grooms,
                initialGroom: selection.initialGroom,
                appState: appState,
                onDismiss: dismiss
            )
        }
        #else
        .sheet(item: $selectedGroom) { groom in
            GroomMapDetailSheet(groom: groom)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedGroomGroup) { selection in
            GroomViewerScreen(grooms: selection.grooms, initialGroom: selection.initialGroom, appState: appState)
        }
        #endif
        .megrumSlideItemPresentation(
            item: $selectedThread,
            backSwipeInteractionScope: .fullScreen
        ) { thread, dismiss in
            NavigationStack {
                BoardThreadDetailScreen(
                    appState: appState,
                    thread: thread,
                    selectedPrefecture: selectedPrefecture,
                    coordinate: locationState.coordinate,
                    onClose: dismiss
                )
            }
        }
        .alert(MeguriAccessPolicy.outOfRangeTitle, isPresented: $isShowingOutOfRangeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(outOfRangeAlertMessage)
        }
    }

}

struct GroomMapGroomSelection: Identifiable {
    var grooms: [GroomPost]
    var initialGroom: GroomPost

    var id: String {
        grooms.map { $0.id.uuidString }.joined(separator: "-")
    }
}

struct MeguriMapFilterControl: View {
    @Binding var activeKind: MeguriMapKind

    var body: some View {
        Picker("表示", selection: $activeKind) {
            Text("すべて").tag(MeguriMapKind.all)
            Text("グルーム").tag(MeguriMapKind.grooms)
            Text("チャットルーム").tag(MeguriMapKind.boards)
        }
        .pickerStyle(.segmented)
        .padding(6)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        }
        .padding(.horizontal, 34)
    }
}
