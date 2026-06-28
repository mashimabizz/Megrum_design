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
    @State var isGroomCreationLocationLocked = false
    @State var isShowingGroomComposer = false
    @State var isShowingGroomCamera = false
    @State var isShowingGroomArchive = false
    @State var isShowingMeguriMessages = false
    @State var isShowingMeguriProfileSettings = false
    @State var activeMap: MeguriMapKind?
    @State var homeMapKind: MeguriMapKind = .all
    @State var isShowingThreadComposer = false
    @State var threadCreationCoordinate: MegrumLocationCoordinate?
    @State var pendingMapCreationCoordinate: MegrumLocationCoordinate?
    @State var isShowingPrefecturePicker = false
    @State var localNoticeMessage: String?
    @State var toastMessage: String?
    @State var toastPlacement: MeguriToastPlacement = .bottom
    @State var toastID = UUID()
    @State var outOfRangeAlertMessage = ""
    @State var isShowingOutOfRangeAlert = false
    @State var boardSheetDetent: MeguriBoardSheetDetent = .compact
    @State var shouldCenterHomeMapWhenLocationArrives = false
    @State var homeCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.7056, longitude: 139.7519),
            span: MeguriHomeMapCamera.focusedSpan
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
            meguriProfile: appState.meguriProfile,
            grooms: appState.grooms,
            mapGrooms: appState.groomMapPosts.isEmpty ? appState.grooms : appState.groomMapPosts,
            threads: appState.threads,
            currentCoordinate: locationState.coordinate,
            notice: notice,
            isRequestingLocation: locationState.isRequestingLocation,
            unreadMessageCount: appState.meguriUnreadMessageCount,
            selectedMapKind: $homeMapKind,
            onRecenterMap: centerHomeMapOnCurrentLocation,
            onOpenMessages: {
                isShowingMeguriMessages = true
            },
            onSelectGroom: openGroomFromStrip,
            onSelectThread: openThreadFromHome,
            onTapMapCoordinate: handleHomeMapTap,
            pendingCreationCoordinate: pendingMapCreationCoordinate,
            onCreateGroomAtPendingCoordinate: openGroomComposerAtPendingCoordinate,
            onCreateThreadAtPendingCoordinate: openThreadComposerAtPendingCoordinate,
            onCancelPendingCreationCoordinate: dismissPendingMapCreationCoordinate,
            onNoticeAction: handleLocationNoticeAction,
            onOpenGroomArchive: { isShowingGroomArchive = true },
            onOpenMeguriProfile: { isShowingMeguriProfileSettings = true }
        )
        .allowsHitTesting(!isShowingGroomArchive)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .task {
            requestInitialLocationIfNeeded()
        }
        .onDisappear {
            locationState.stopUpdatingCurrentLocation()
        }
        .task {
            await appState.loadMeguriMessages()
        }
        .task {
            await appState.loadMeguriProfile(reportsFailure: false)
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
        .overlay(alignment: toastPlacement.alignment) {
            if let toastMessage {
                MeguriToastView(message: toastMessage)
                    .padding(.top, toastPlacement == .top ? 92 : 0)
                    .padding(.bottom, toastPlacement == .bottom ? 104 : 0)
                    .transition(toastPlacement.transition)
            }
        }
        .sheet(isPresented: $isShowingMeguriMessages) {
            NavigationStack {
                MeguriMessageInboxScreen(appState: appState)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingMeguriProfileSettings) {
            NavigationStack {
                MeguriProfileSettingsSheet(appState: appState)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .modifier(
            MeguriScreenPresentationModifier(
                appState: appState,
                locationState: locationState,
                selectedThread: $selectedThread,
                isShowingThreadComposer: $isShowingThreadComposer,
                threadCreationCoordinate: $threadCreationCoordinate,
                isShowingPrefecturePicker: $isShowingPrefecturePicker,
                selectedGroomPhotoItem: $selectedGroomPhotoItem,
                groomCreationCoordinate: $groomCreationCoordinate,
                isGroomCreationLocationLocked: isGroomCreationLocationLocked,
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
                    locationState.startUpdatingCurrentLocation()
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
                onShowToast: { message in
                    showToast(message)
                },
                onPublishGroomPhoto: publishGroomPhoto,
                onResetGroomDraft: resetGroomDraft
            )
        )
    }
}
