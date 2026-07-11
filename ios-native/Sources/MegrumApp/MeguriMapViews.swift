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
    @State var selectedThread: BoardThread?
    @State var mapNotice: String?
    @State var outOfRangeAlertMessage = ""
    @State var isShowingOutOfRangeAlert = false
    @State var hasCenteredMapOnLocation = false
    /// iter1226.453：めぐりホーム（マップ）のグルームもホームレールと同じ標準zoomで開く。
    @Namespace private var groomZoomNamespace

    /// iter1226.457：ホームレールと同じ「source常設・タップ即提示」。タップで即セットして開く。
    @State var viewerRoute: GroomMapViewerRoute?

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
                viewedGroomIDs: appState.viewedGroomIDs,
                isGroomOutOfRange: isGroomOutOfRange,
                isBoardOutOfRange: isBoardOutOfRange,
                onOpenGroom: openGroomIfInRange,
                onOpenGroomCluster: openGroomCluster,
                onOpenThread: openThreadIfInRange,
                groomZoomNamespace: groomZoomNamespace
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
            #if canImport(UIKit)
            // iter1226.457：フィード再取得を待たず、キャッシュ済み一覧の代表画像から先に温める
            //（地図を開いてすぐタップした時の初回デコード競争を減らす）。
            let cachedRepresentatives = GroomMapCluster.clusters(from: appState.meguriMapDisplayGrooms)
                .compactMap { $0.posts.first?.imageURL }
            if !cachedRepresentatives.isEmpty {
                Task {
                    await GroomImageMemoryStore.shared.prewarm(urls: cachedRepresentatives)
                }
            }
            #endif
            await reloadMapContent(
                latitude: locationState.coordinate?.latitude,
                longitude: locationState.coordinate?.longitude
            )
            await MainActor.run {
                alignCameraToVisibleContent(userCoordinate: locationState.coordinate, animated: false)
            }
        }
        #if canImport(UIKit)
        // iter1226.457：ホームレール同様、タップ前に表示中ピンの代表画像をデコード済みで温めておく。
        // タップ後の preload では開き心地に間に合わない（開いた瞬間の写真ポップイン防止）。
        .task(id: mapGrooms.map(\.id)) {
            let representatives = GroomMapCluster.clusters(from: mapGrooms)
                .compactMap { $0.posts.first?.imageURL }
            guard !representatives.isEmpty else { return }
            await GroomImageMemoryStore.shared.prewarm(urls: representatives)
        }
        #endif
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
        // iter1226.457：ホームレールと同一方式（fullScreenCover + navigationTransition(.zoom)）。
        // source は overlay の常設ピンとして既に layout 済みなので、タップ即提示で zoom がマッチする。
        .fullScreenCover(item: $viewerRoute) { route in
            let _ = GroomOpenMetricsLog.emit("mapCover", "build groom=\(route.initialGroom.id)")
            GroomViewerScreen(
                grooms: route.grooms,
                initialGroom: route.initialGroom,
                appState: appState,
                onDismiss: { viewerRoute = nil }
            )
            .modifier(GroomMapZoomDestination(sourceID: route.sourceID, namespace: groomZoomNamespace))
        }
        #else
        .sheet(item: $viewerRoute) { route in
            GroomViewerScreen(grooms: route.grooms, initialGroom: route.initialGroom, appState: appState)
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
