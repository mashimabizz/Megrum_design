import MegrumCore
import MegrumDesign
import MapKit
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct MeguriScreen: View {
    @ObservedObject var appState: MegrumAppState
    @StateObject private var locationState = MegrumLocationState()
    @AppStorage("megrum.meguri.board.prefecture") private var storedBoardPrefecture = ""
    @AppStorage("megrum.meguri.board.scope") private var storedBoardScopeRaw = BoardThread.Audience.nearby3km.rawValue
    @State private var selectedThread: BoardThread?
    @State private var pendingCreatedThread: BoardThread?
    @State private var selectedGroom: GroomPost?
    @State private var selectedGroomPhotoItem: PhotosPickerItem?
    @State private var isShowingGroomComposer = false
    @State private var isShowingGroomCamera = false
    @State private var activeMap: MeguriMapKind?
    @State private var isShowingThreadComposer = false
    @State private var isShowingPrefecturePicker = false
    @State private var localNoticeMessage: String?
    @State private var boardSheetDetent: MeguriBoardSheetDetent = .regular
    @State private var shouldCenterHomeMapWhenLocationArrives = false
    @State private var homeCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.7056, longitude: 139.7519),
            span: MKCoordinateSpan(latitudeDelta: 0.030, longitudeDelta: 0.030)
        )
    )

    private var selectedBoardScope: BoardThread.Audience {
        BoardThread.Audience(rawValue: storedBoardScopeRaw) ?? .nearby3km
    }

    private var selectedBoardPrefecture: String? {
        let stored = storedBoardPrefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty {
            return stored
        }
        return appState.viewer?.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    var body: some View {
        MeguriHomeContent(
            cameraPosition: $homeCameraPosition,
            viewer: appState.viewer,
            grooms: appState.grooms,
            threads: appState.threads,
            replyCounts: appState.boardRepliesByThreadID.mapValues(\.count),
            isLoading: appState.isLoadingMeguri,
            selectedScope: selectedBoardScope,
            selectedPrefecture: selectedBoardPrefecture ?? "都道府県",
            notice: notice,
            isRequestingLocation: locationState.isRequestingLocation,
            boardSheetDetent: $boardSheetDetent,
            onOpenMap: { activeMap = .boards },
            onRecenterMap: centerHomeMapOnCurrentLocation,
            onSelectGroom: openGroomFromStrip,
            onSelectThread: { selectedThread = $0 },
            onNoticeAction: handleLocationNoticeAction,
            onChangeScope: updateBoardScope,
            onOpenPrefecture: { isShowingPrefecturePicker = true },
            onOpenGroomComposer: { isShowingGroomComposer = true },
            onOpenThreadComposer: { isShowingThreadComposer = true }
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .task {
            requestInitialLocationIfNeeded()
        }
        .task(id: appState.grooms.map(\.authorID)) {
            await preloadGroomAuthorProfiles()
        }
        .onReceive(locationState.$coordinate.compactMap { $0 }) { coordinate in
            handleCoordinateChange(coordinate)
        }
        .onChange(of: selectedGroomPhotoItem) { _, item in
            handleSelectedGroomPhotoItem(item)
        }
        .sheet(item: $selectedThread) { thread in
            NavigationStack {
                BoardThreadDetailScreen(
                    appState: appState,
                    thread: thread,
                    selectedPrefecture: selectedBoardPrefecture,
                    coordinate: locationState.coordinate
                )
            }
        }
        .sheet(
            isPresented: $isShowingThreadComposer,
            onDismiss: openPendingCreatedThreadIfNeeded
        ) {
            NavigationStack {
                BoardThreadComposerSheet(
                    appState: appState,
                    locationState: locationState,
                    fallbackCoordinate: locationState.coordinate,
                    selectedPrefecture: selectedBoardPrefecture,
                    onCreated: { thread in
                        boardSheetDetent = .regular
                        pendingCreatedThread = thread
                    }
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingPrefecturePicker) {
            NavigationStack {
                BoardPrefecturePickerSheet(
                    selectedPrefecture: selectedBoardPrefecture,
                    onSelect: selectBoardPrefecture
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
#if os(iOS)
        .fullScreenCover(isPresented: $isShowingGroomComposer) {
            GroomStoryComposerScreen(
                selectedPhotoItem: $selectedGroomPhotoItem,
                isCreating: appState.isCreatingGroomPost,
                canUseCamera: canUseCamera,
                onOpenCamera: {
                    isShowingGroomComposer = false
                    if canUseCamera {
                        isShowingGroomCamera = true
                    } else {
                        localNoticeMessage = "この端末ではカメラを利用できません。写真から選択してください。"
                    }
                }
            )
        }
#else
        .sheet(isPresented: $isShowingGroomComposer) {
            GroomStoryComposerScreen(
                selectedPhotoItem: $selectedGroomPhotoItem,
                isCreating: appState.isCreatingGroomPost,
                canUseCamera: false,
                onOpenCamera: {
                    localNoticeMessage = "この端末ではカメラを利用できません。写真から選択してください。"
                }
            )
        }
#endif
#if os(iOS)
        .sheet(isPresented: $isShowingGroomCamera) {
            NativeCameraCaptureView(
                onCapture: { imageData in
                    Task {
                        await publishGroomPhoto(data: imageData, imageContentType: "image/jpeg")
                    }
                },
                onFailure: { message in
                    localNoticeMessage = message
                }
            )
            .ignoresSafeArea()
        }
#endif
        .modifier(
            GroomViewerPresentationModifier(
                selectedGroom: $selectedGroom,
                grooms: appState.grooms,
                appState: appState
            )
        )
        .modifier(
            MeguriMapPresentationModifier(
                activeMap: $activeMap,
                appState: appState,
                locationState: locationState,
                selectedPrefecture: selectedBoardPrefecture,
                boardScope: selectedBoardScope
            )
        )
    }

    private func requestInitialLocationIfNeeded() {
        guard !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) else {
            return
        }
        locationState.requestCurrentLocation()
    }

    private func handleCoordinateChange(_ coordinate: MegrumLocationCoordinate) {
        if shouldCenterHomeMapWhenLocationArrives {
            shouldCenterHomeMapWhenLocationArrives = false
            centerHomeMap(on: coordinate, animated: true)
        }

        Task {
            await appState.loadMeguriFeed(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                prefecture: selectedBoardPrefecture,
                scope: selectedBoardScope
            )
        }
    }

    private func handleSelectedGroomPhotoItem(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await publishSelectedGroomPhoto(item)
        }
    }

    private func selectBoardPrefecture(_ prefecture: String) {
        storedBoardPrefecture = prefecture
        storedBoardScopeRaw = BoardThread.Audience.samePrefecture.rawValue
        Task {
            await reloadMeguriFeed(scope: .samePrefecture)
        }
    }

    private func preloadGroomAuthorProfiles() async {
        let authorIDs = Set(appState.grooms.map(\.authorID))
        for authorID in authorIDs where authorID != appState.viewer?.id && appState.publicProfilesByUserID[authorID] == nil {
            await appState.loadPublicUserProfile(userID: authorID, reportsFailure: false)
        }
    }

    private func updateBoardScope(_ scope: BoardThread.Audience) {
        storedBoardScopeRaw = scope.rawValue
        if scope == .nearby3km, locationState.coordinate == nil {
            locationState.requestCurrentLocation()
            return
        }
        Task {
            await reloadMeguriFeed(scope: scope)
        }
    }

    private func reloadMeguriFeed(scope: BoardThread.Audience? = nil) async {
        let targetScope = scope ?? selectedBoardScope
        if targetScope == .nearby3km, locationState.coordinate == nil {
            await MainActor.run {
                locationState.requestCurrentLocation()
            }
            return
        }
        await appState.loadMeguriFeed(
            latitude: locationState.coordinate?.latitude,
            longitude: locationState.coordinate?.longitude,
            prefecture: selectedBoardPrefecture,
            scope: targetScope
        )
    }

    private func publishSelectedGroomPhoto(_ item: PhotosPickerItem) async {
        defer {
            selectedGroomPhotoItem = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            localNoticeMessage = "写真を読み込めませんでした"
            return
        }
        await publishGroomPhoto(data: data, imageContentType: inferredPhotoMessageContentType(from: data))
    }

    private func publishGroomPhoto(data: Data, imageContentType: String) async {
        let created = await appState.createGroomPost(
            imageData: data,
            imageContentType: imageContentType,
            latitude: locationState.coordinate?.latitude,
            longitude: locationState.coordinate?.longitude
        )
        if created {
            localNoticeMessage = nil
            await reloadMeguriFeed()
        }
    }

    private func openGroomFromStrip(_ groom: GroomPost) {
        guard MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        ) else {
            if locationState.coordinate == nil {
                locationState.requestCurrentLocation()
            }
            localNoticeMessage = MeguriAccessPolicy.groomAccessMessage(
                groom,
                currentCoordinate: locationState.coordinate,
                viewerID: appState.viewer?.id
            )
            return
        }
        localNoticeMessage = nil
        selectedGroom = groom
    }

    private func centerHomeMapOnCurrentLocation() {
        guard let coordinate = locationState.coordinate else {
            shouldCenterHomeMapWhenLocationArrives = true
            locationState.requestCurrentLocation()
            return
        }
        centerHomeMap(on: coordinate, animated: true)
    }

    private func openPendingCreatedThreadIfNeeded() {
        guard let thread = pendingCreatedThread else {
            return
        }
        pendingCreatedThread = nil
        selectedThread = thread
    }

    private func centerHomeMap(on coordinate: MegrumLocationCoordinate, animated: Bool) {
        let region = MKCoordinateRegion(
            center: coordinate.clLocationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
        let update = {
            homeCameraPosition = .region(region)
        }
        if animated {
            withAnimation(.smooth(duration: 0.28)) {
                update()
            }
        } else {
            update()
        }
    }

    private var notice: MegrumLocationNotice? {
        MeguriNoticeResolver.notice(
            localMessage: localNoticeMessage,
            locationNotice: locationState.meguriNotice,
            appErrorMessage: appState.errorMessage
        )
    }

    private func handleLocationNoticeAction() {
        guard localNoticeMessage == nil, locationState.meguriNotice?.actionTitle != nil else {
            return
        }
        if locationState.permissionPhase == .denied || locationState.permissionPhase == .servicesDisabled {
            openAppSettings()
        } else {
            locationState.requestCurrentLocation()
        }
    }

    private func openAppSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
        #endif
    }

    private var canUseCamera: Bool {
#if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
#else
        false
#endif
    }

}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
