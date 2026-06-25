import MegrumCore
import MegrumDesign
import MapKit
import PhotosUI
import SwiftUI

struct MeguriScreen: View {
    @ObservedObject var appState: MegrumAppState
    @StateObject var locationState = MegrumLocationState()
    @AppStorage("megrum.meguri.board.prefecture") var storedBoardPrefecture = ""
    @AppStorage("megrum.meguri.board.scope") var storedBoardScopeRaw = BoardThread.Audience.nearby3km.rawValue
    @State var selectedThread: BoardThread?
    @State var pendingCreatedThread: BoardThread?
    @State var selectedGroom: GroomPost?
    @State var selectedGroomPhotoItem: PhotosPickerItem?
    @State var groomDraftPhotoData: Data?
    @State var groomDraftPhotoContentType = "image/jpeg"
    @State var isPreparingGroomPhoto = false
    @State var groomCreationCoordinate: MegrumLocationCoordinate?
    @State var isShowingGroomComposer = false
    @State var isShowingGroomCamera = false
    @State var isShowingGroomArchive = false
    @State var activeMap: MeguriMapKind?
    @State var isShowingThreadComposer = false
    @State var isShowingPrefecturePicker = false
    @State var localNoticeMessage: String?
    @State var toastMessage: String?
    @State var toastID = UUID()
    @State var outOfRangeAlertMessage = ""
    @State var isShowingOutOfRangeAlert = false
    @State var boardSheetDetent: MeguriBoardSheetDetent = .regular
    @State var shouldCenterHomeMapWhenLocationArrives = false
    @State var homeCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.7056, longitude: 139.7519),
            span: MKCoordinateSpan(latitudeDelta: 0.030, longitudeDelta: 0.030)
        )
    )

    var selectedBoardScope: BoardThread.Audience {
        BoardThread.Audience(rawValue: storedBoardScopeRaw) ?? .nearby3km
    }

    var selectedBoardPrefecture: String? {
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
        .modifier(
            MeguriScreenPresentationModifier(
                appState: appState,
                locationState: locationState,
                selectedThread: $selectedThread,
                isShowingThreadComposer: $isShowingThreadComposer,
                isShowingPrefecturePicker: $isShowingPrefecturePicker,
                selectedGroomPhotoItem: $selectedGroomPhotoItem,
                groomCreationCoordinate: $groomCreationCoordinate,
                groomDraftPhotoData: $groomDraftPhotoData,
                groomDraftPhotoContentType: $groomDraftPhotoContentType,
                isPreparingGroomPhoto: isPreparingGroomPhoto,
                isShowingGroomComposer: $isShowingGroomComposer,
                isShowingGroomCamera: $isShowingGroomCamera,
                isShowingGroomArchive: $isShowingGroomArchive,
                selectedGroom: $selectedGroom,
                activeMap: $activeMap,
                selectedPrefecture: selectedBoardPrefecture,
                boardScope: selectedBoardScope,
                canUseCamera: canUseCamera,
                onThreadComposerDismiss: openPendingCreatedThreadIfNeeded,
                onThreadCreated: { thread in
                    boardSheetDetent = .regular
                    pendingCreatedThread = thread
                },
                onSelectPrefecture: selectBoardPrefecture,
                onRequestLocation: {
                    locationState.requestCurrentLocation()
                },
                onOpenGroomCamera: {
                    #if os(iOS)
                    isShowingGroomComposer = false
                    if canUseCamera {
                        isShowingGroomCamera = true
                    } else {
                        showToast("この端末ではカメラを利用できません。写真から選択してください。")
                    }
                    #else
                    showToast("この端末ではカメラを利用できません。写真から選択してください。")
                    #endif
                },
                onPrepareCapturedGroomPhoto: prepareCapturedGroomPhoto,
                onShowToast: showToast,
                onPublishGroomPhoto: publishGroomPhoto,
                onResetGroomDraft: resetGroomDraft
            )
        )
    }
}
