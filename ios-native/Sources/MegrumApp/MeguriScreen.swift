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
    @State private var groomDraftPhotoData: Data?
    @State private var groomDraftPhotoContentType = "image/jpeg"
    @State private var isPreparingGroomPhoto = false
    @State private var groomCreationCoordinate: MegrumLocationCoordinate?
    @State private var isShowingGroomComposer = false
    @State private var isShowingGroomCamera = false
    @State private var isShowingGroomArchive = false
    @State private var activeMap: MeguriMapKind?
    @State private var isShowingThreadComposer = false
    @State private var isShowingPrefecturePicker = false
    @State private var localNoticeMessage: String?
    @State private var toastMessage: String?
    @State private var toastID = UUID()
    @State private var outOfRangeAlertMessage = ""
    @State private var isShowingOutOfRangeAlert = false
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
        return (appState.viewer?.prefecture).nilIfBlank
    }

    var body: some View {
        MeguriHomeContent(
            cameraPosition: $homeCameraPosition,
            viewer: appState.viewer,
            grooms: appState.grooms,
            mapGrooms: appState.groomMapPosts.isEmpty ? appState.grooms : appState.groomMapPosts,
            threads: appState.threads,
            replyCounts: appState.boardRepliesByThreadID.mapValues(\.count),
            currentCoordinate: locationState.coordinate,
            isLoading: appState.isLoadingMeguri,
            selectedScope: selectedBoardScope,
            selectedPrefecture: selectedBoardPrefecture ?? "都道府県",
            notice: notice,
            isRequestingLocation: locationState.isRequestingLocation,
            boardSheetDetent: $boardSheetDetent,
            onOpenMap: { activeMap = .boards },
            onRecenterMap: centerHomeMapOnCurrentLocation,
            onSelectGroom: openGroomFromStrip,
            onSelectThread: openThreadFromHome,
            onNoticeAction: handleLocationNoticeAction,
            onChangeScope: updateBoardScope,
            onOpenPrefecture: { isShowingPrefecturePicker = true },
            onOpenGroomComposer: openGroomComposer,
            onOpenThreadComposer: openThreadComposer,
            onOpenGroomArchive: { isShowingGroomArchive = true }
        )
        .allowsHitTesting(!isShowingGroomArchive)
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
        .alert(MeguriAccessPolicy.outOfRangeTitle, isPresented: $isShowingOutOfRangeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(outOfRangeAlertMessage)
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                MeguriToastView(message: toastMessage)
                    .padding(.bottom, 104)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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
                selectedCreationCoordinate: $groomCreationCoordinate,
                draftPhotoData: $groomDraftPhotoData,
                draftPhotoContentType: $groomDraftPhotoContentType,
                isPreparingPhoto: isPreparingGroomPhoto,
                isCreating: appState.isCreatingGroomPost,
                canUseCamera: canUseCamera,
                currentCoordinate: locationState.coordinate,
                isRequestingLocation: locationState.isRequestingLocation,
                onRequestLocation: {
                    locationState.requestCurrentLocation()
                },
                onOpenCamera: {
                    isShowingGroomComposer = false
                    if canUseCamera {
                        isShowingGroomCamera = true
                    } else {
                        showToast("この端末ではカメラを利用できません。写真から選択してください。")
                    }
                },
                onPublish: publishGroomPhoto,
                onDiscard: resetGroomDraft
            )
        }
#else
        .sheet(isPresented: $isShowingGroomComposer) {
            GroomStoryComposerScreen(
                selectedPhotoItem: $selectedGroomPhotoItem,
                selectedCreationCoordinate: $groomCreationCoordinate,
                draftPhotoData: $groomDraftPhotoData,
                draftPhotoContentType: $groomDraftPhotoContentType,
                isPreparingPhoto: isPreparingGroomPhoto,
                isCreating: appState.isCreatingGroomPost,
                canUseCamera: false,
                currentCoordinate: locationState.coordinate,
                isRequestingLocation: locationState.isRequestingLocation,
                onRequestLocation: {
                    locationState.requestCurrentLocation()
                },
                onOpenCamera: {
                    showToast("この端末ではカメラを利用できません。写真から選択してください。")
                },
                onPublish: publishGroomPhoto,
                onDiscard: resetGroomDraft
            )
        }
#endif
#if os(iOS)
        .sheet(isPresented: $isShowingGroomCamera) {
            NativeCameraCaptureView(
                onCapture: { imageData in
                    prepareCapturedGroomPhoto(imageData)
                },
                onFailure: { message in
                    showToast(message)
                }
            )
            .ignoresSafeArea()
        }
#endif
#if os(iOS)
        .fullScreenCover(isPresented: $isShowingGroomArchive) {
            GroomArchiveScreen(
                appState: appState,
                currentCoordinate: locationState.coordinate
            )
        }
#else
        .sheet(isPresented: $isShowingGroomArchive) {
            GroomArchiveScreen(
                appState: appState,
                currentCoordinate: locationState.coordinate
            )
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
            await appState.loadGroomMapPosts(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radiusMeters: 3_000
            )
        }
    }

    private func handleSelectedGroomPhotoItem(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await prepareSelectedGroomPhoto(item)
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
        if let coordinate = locationState.coordinate {
            await appState.loadGroomMapPosts(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radiusMeters: 3_000
            )
        }
    }

    private func prepareSelectedGroomPhoto(_ item: PhotosPickerItem) async {
        isPreparingGroomPhoto = true
        defer {
            selectedGroomPhotoItem = nil
            isPreparingGroomPhoto = false
        }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            showToast("写真を読み込めませんでした")
            return
        }
        groomDraftPhotoData = data
        groomDraftPhotoContentType = inferredPhotoMessageContentType(from: data)
        if groomCreationCoordinate == nil {
            groomCreationCoordinate = locationState.coordinate
        }
    }

    private func prepareCapturedGroomPhoto(_ imageData: Data) {
        groomDraftPhotoData = imageData
        groomDraftPhotoContentType = "image/jpeg"
        if groomCreationCoordinate == nil {
            groomCreationCoordinate = locationState.coordinate
        }
        isShowingGroomCamera = false
        isShowingGroomComposer = true
    }

    private func publishGroomPhoto(
        data: Data,
        imageContentType: String,
        caption: String?,
        coordinate: MegrumLocationCoordinate
    ) async -> Bool {
        guard locationState.coordinate != nil else {
            locationState.requestCurrentLocation()
            showToast("現在地を確認してから投稿してください")
            return false
        }
        guard MeguriAccessPolicy.canCreateAt(
            coordinate,
            currentCoordinate: locationState.coordinate
        ) else {
            showToast(
                MeguriAccessPolicy.creationLocationMessage(
                    selectedCoordinate: coordinate,
                    currentCoordinate: locationState.coordinate
                )
            )
            return false
        }

        let created = await appState.createGroomPost(
            imageData: data,
            imageContentType: imageContentType,
            caption: caption,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        if created {
            localNoticeMessage = nil
            await reloadMeguriFeed()
            return true
        } else {
            let message = appState.errorMessage ?? "グルームを投稿できませんでした"
            showToast(message)
            appState.clearErrorMessage()
            return false
        }
    }

    private func openGroomComposer() {
        resetGroomDraft()
        if locationState.coordinate == nil {
            locationState.requestCurrentLocation()
        }
        isShowingGroomComposer = true
    }

    private func resetGroomDraft() {
        selectedGroomPhotoItem = nil
        groomDraftPhotoData = nil
        groomDraftPhotoContentType = "image/jpeg"
        groomCreationCoordinate = nil
        isPreparingGroomPhoto = false
    }

    private func openThreadComposer() {
        if locationState.coordinate == nil {
            locationState.requestCurrentLocation()
        }
        isShowingThreadComposer = true
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
            showOutOfRangeAlert(
                MeguriAccessPolicy.groomAccessMessage(
                    groom,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
                )
            )
            return
        }
        localNoticeMessage = nil
        selectedGroom = groom
    }

    private func openThreadFromHome(_ thread: BoardThread) {
        guard MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        ) else {
            if locationState.coordinate == nil {
                locationState.requestCurrentLocation()
            }
            showOutOfRangeAlert(
                MeguriAccessPolicy.boardAccessMessage(
                    thread,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
                )
            )
            return
        }
        selectedThread = thread
    }

    private func showOutOfRangeAlert(_ message: String) {
        outOfRangeAlertMessage = message.isEmpty ? "半径1km以内のグルームと掲示板のみ開けます。" : message
        isShowingOutOfRangeAlert = true
    }

    private func showToast(_ message: String) {
        let toastID = UUID()
        self.toastID = toastID
        withAnimation(.smooth(duration: 0.18)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard self.toastID == toastID else {
                return
            }
            withAnimation(.smooth(duration: 0.18)) {
                toastMessage = nil
            }
        }
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
