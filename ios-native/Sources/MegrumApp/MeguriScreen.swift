import MegrumCore
import MegrumDesign
import MapKit
import PhotosUI
import SwiftUI

struct MeguriScreen: View {
    @ObservedObject var appState: MegrumAppState
    var homeResetToken: UUID?
    var visualQAInitialScreen: VisualQAInitialScreen? = nil
    @Binding var pendingNotificationRouteIntent: NotificationRouteIntent?
    /// iter1226.421：右下固定フッターからチャットルーム一覧を開く。
    var onOpenBoardList: () -> Void = {}
    var onOpenMessages: () -> Void = {}
    var onOpenBoardThread: (MeguriBoardThreadRoute) -> Void = { _ in }
    var onOpenMeguriUserProfile: (UUID) -> Void = { _ in }
    var onOpenGroomViewer: ((GroomPost, UnitPoint) -> Void)?
    @StateObject var locationState = MegrumLocationState()
    @AppStorage("megrum.meguri.board.prefecture") var storedBoardPrefecture = ""
    @AppStorage("megrum.meguri.board.scope") var storedBoardScopeRaw = BoardThread.Audience.nearby3km.rawValue
    @State var pendingCreatedThread: BoardThread?
    @State var selectedGroom: GroomPost?
    @State var selectedGroomSourceAnchor: UnitPoint = .center
    @State var selectedGroomPhotoItem: PhotosPickerItem?
    @State var groomDraftPhotoData: Data?
    @State var groomDraftPhotoContentType = "image/jpeg"
    @State var isPreparingGroomPhoto = false
    @State var groomCreationCoordinate: MegrumLocationCoordinate?
    @State var isGroomCreationLocationLocked = false
    @State var isShowingGroomComposer = false
    @State var pendingGroomPublish: PendingGroomPublish?
    @State var isShowingGroomArchiveLimitAlert = false
    @State var isShowingPremiumFromArchiveLimit = false
    @State var isShowingGroomCamera = false
    @State var isShowingGroomArchive = false
    @State var isShowingMeguriProfileSettings = false
    @State var didOpenVisualQAMeguriProfileSettings = false
    @State var didOpenVisualQAGroomArchive = false
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
    @State var contentFilter = MeguriContentFilterState()
    @State var didRestoreHomePreferences = false
    @State var isShowingContentFilter = false
    @State var isShowingNotificationSettings = false
    @State var outOfRangeAlertMessage = ""
    @State var isShowingOutOfRangeAlert = false
    @State var boardSheetDetent: MeguriBoardSheetDetent = .compact
    @State var shouldCenterHomeMapWhenLocationArrives = false
    /// 起動後にめぐりを最初に開いた時だけ現在地センタリングする（タブ復帰では維持）。
    @State var didAutoCenterHomeMap = false
    @State var lastViewportFetchCenter: MegrumLocationCoordinate?
    @State var lastViewportFetchRadiusMeters: Double = 0
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

    func restoreHomePreferencesIfNeeded() {
        guard !didRestoreHomePreferences, let viewerID = appState.viewer?.id else {
            return
        }
        didRestoreHomePreferences = true
        if let storedKind = MeguriHomePreferenceStore.loadMapKind(userID: viewerID) {
            homeMapKind = storedKind
        }
        if let storedDraft = MeguriHomePreferenceStore.loadFilterDraft(userID: viewerID) {
            contentFilter.draft = storedDraft
        }
    }

    /// 自分の投稿はフィルタ・推し設定に関わらず常に見せる（自分のグルームが地図/一覧から消えないように）。iter1226.392。
    private func isOwnOrMatchesFilter(_ groom: GroomPost) -> Bool {
        groom.authorID == appState.viewer?.id || contentFilter.matches(groom: groom)
    }

    var visibleGrooms: [GroomPost] {
        appState.grooms.filter(isOwnOrMatchesFilter)
    }

    var visibleMapGrooms: [GroomPost] {
        // ガイドツアー中はサンプルピンを表示レイヤで注入する（実データ・フィルタ非依存で確実に見せる）。
        if appState.isTutorialActive {
            return TutorialSampleMeguriData.grooms
        }
        // iter1226.433：ビューポート読み込みで蓄積した圏外グルームも（再読み込み後も）消えずに出す。
        return appState.meguriMapDisplayGrooms.filter(isOwnOrMatchesFilter)
    }

    var visibleThreads: [BoardThread] {
        if appState.isTutorialActive {
            return TutorialSampleMeguriData.threads
        }
        // iter1226.433：ビューポート読み込みで蓄積した圏外チャットルームも消えずに出す。
        return appState.meguriMapDisplayThreads.filter { contentFilter.matches(thread: $0) }
    }

    var body: some View {
        MeguriHomeContent(
            cameraPosition: $homeCameraPosition,
            viewer: appState.viewer,
            meguriProfile: appState.meguriProfile,
            grooms: visibleGrooms,
            mapGrooms: visibleMapGrooms,
            threads: visibleThreads,
            replyPreviewsByThreadID: appState.boardReplyPreviewsByThreadID,
            currentCoordinate: appState.isTutorialActive
                ? TutorialSampleMeguriData.centerCoordinate
                : locationState.coordinate,
            subscriptionState: appState.subscriptionState,
            notice: notice,
            isRequestingLocation: locationState.isRequestingLocation,
            unreadMessageCount: appState.meguriUnreadMessageCount,
            isContentFilterActive: contentFilter.hasActiveFilters,
            selectedMapKind: $homeMapKind,
            onOpenContentFilter: { isShowingContentFilter = true },
            onRecenterMap: centerHomeMapOnCurrentLocation,
            onOpenMessages: onOpenMessages,
            onSelectGroom: openGroomFromStrip,
            onSelectThread: openThreadFromHome,
            onTapMapCoordinate: handleHomeMapTap,
            pendingCreationCoordinate: pendingMapCreationCoordinate,
            onCreateGroomAtPendingCoordinate: openGroomComposerAtPendingCoordinate,
            onCreateThreadAtPendingCoordinate: openThreadComposerAtPendingCoordinate,
            onCancelPendingCreationCoordinate: dismissPendingMapCreationCoordinate,
            onNoticeAction: handleLocationNoticeAction,
            onOpenGroomArchive: { isShowingGroomArchive = true },
            onOpenMeguriProfile: { isShowingMeguriProfileSettings = true },
            onOpenNotificationSettings: { isShowingNotificationSettings = true },
            isLoadingViewport: appState.isLoadingMeguriViewport,
            onViewportChange: handleViewportChange
        )
        .allowsHitTesting(!isShowingGroomArchive)
        // iter1226.421：右下の固定フッター＝チャットルーム一覧アイコン。
        .overlay(alignment: .bottomTrailing) {
            Button(action: onOpenBoardList) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(MegrumTheme.primaryGradient, in: Circle())
                    .shadow(color: MegrumTheme.primaryShadow, radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.bottom, 118)
            .accessibilityLabel("チャットルーム一覧を開く")
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .alert(
            "アーカイブの上限",
            isPresented: $isShowingGroomArchiveLimitAlert,
            presenting: pendingGroomPublish
        ) { pending in
            Button("このまま投稿する") {
                confirmPendingGroomPublish(pending)
            }
            Button("Megrumプレミアムを見る") {
                pendingGroomPublish = nil
                isShowingPremiumFromArchiveLimit = true
            }
            Button("キャンセル", role: .cancel) {
                pendingGroomPublish = nil
            }
        } message: { _ in
            Text("グルームアーカイブが10件を超えるため、最古のアーカイブが消去されます。Megrumプレミアムの加入で無制限でアーカイブできます。")
        }
        .sheet(isPresented: $isShowingPremiumFromArchiveLimit) {
            NavigationStack {
                SubscriptionSettingsScreen(appState: appState)
            }
        }
        .task {
            requestInitialLocationIfNeeded()
        }
        .onChange(of: appState.isTutorialActive) { _, isActive in
            // ツアー終了時に、抑制していた位置情報リクエストを呼び直す。
            if !isActive {
                requestInitialLocationIfNeeded()
                withAnimation(.easeOut(duration: 0.16)) {
                    pendingMapCreationCoordinate = nil
                }
            }
        }
        .onChange(of: appState.tutorialMeguriCalloutRequestID) { _, requestID in
            // ガイドツアーの実演：指のタップに合わせて、地図中心付近に実物の作成コールアウトを出す。
            // ツアー中は位置情報を抑制しているため 1km 判定は通さない（見せるだけで作成はしない）。
            guard requestID != nil else { return }
            // 指のタップ位置に吹き出しが出るよう、中心より北へずらす。
            // 1km円（半径≈0.009度）の内側に収まるオフセットにする（円周ぎりぎりだと圏外に見える）。
            let center = homeCameraPosition.region?.center
                ?? CLLocationCoordinate2D(latitude: 35.7056, longitude: 139.7519)
            withAnimation(.easeOut(duration: 0.16)) {
                pendingMapCreationCoordinate = MegrumLocationCoordinate(
                    latitude: center.latitude + 0.006,
                    longitude: center.longitude
                )
            }
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
        .onAppear {
            openVisualQASheetsIfNeeded()
            handlePendingNotificationRouteIntent(pendingNotificationRouteIntent)
        }
        .task(id: appState.viewer?.id) {
            restoreHomePreferencesIfNeeded()
        }
        .onChange(of: homeMapKind) { _, newValue in
            guard didRestoreHomePreferences, let viewerID = appState.viewer?.id else {
                return
            }
            MeguriHomePreferenceStore.saveMapKind(newValue, userID: viewerID)
        }
        .onChange(of: contentFilter) { _, newValue in
            guard didRestoreHomePreferences, let viewerID = appState.viewer?.id else {
                return
            }
            MeguriHomePreferenceStore.saveFilterDraft(newValue.draft, userID: viewerID)
        }
        .task(id: appState.grooms.map(\.authorID)) {
            await preloadGroomAuthorProfiles()
        }
        .task(id: visibleThreads.map(\.id)) {
            await appState.loadBoardReplyPreviews(threadIDs: visibleThreads.map(\.id))
        }
        .onReceive(locationState.$coordinate.compactMap { $0 }) { coordinate in
            handleCoordinateChange(coordinate)
        }
        .onChange(of: selectedGroomPhotoItem) { _, item in
            handleSelectedGroomPhotoItem(item)
        }
        .onChange(of: homeResetToken) { _, _ in
            resetToHome()
        }
        .onChange(of: pendingNotificationRouteIntent) { _, intent in
            handlePendingNotificationRouteIntent(intent)
        }
        .alert(MeguriAccessPolicy.outOfRangeTitle, isPresented: $isShowingOutOfRangeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(outOfRangeAlertMessage)
        }
        .overlay(alignment: toastPlacement.alignment) {
            if let toastMessage {
                MeguriToastView(message: toastMessage)
                    .padding(.top, toastPlacement == .top ? 8 : 0)
                    .padding(.bottom, toastPlacement == .bottom ? 104 : 0)
                    .transition(toastPlacement.transition)
            }
        }
        .sheet(isPresented: $isShowingMeguriProfileSettings) {
            NavigationStack {
                MeguriProfileSettingsSheet(appState: appState)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingNotificationSettings) {
            NavigationStack {
                MeguriNotificationSettingsSheet(
                    appState: appState,
                    currentCoordinate: locationState.coordinate
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingContentFilter) {
            NavigationStack {
                MeguriContentFilterSheet(
                    filter: $contentFilter,
                    groups: appState.oshiGroups,
                    characters: appState.oshiCharacters,
                    userOshiSelections: appState.userOshiSelections,
                    inventory: appState.inventory,
                    wishes: appState.wishes,
                    isLoadingGroups: appState.isLoadingOshiGroups,
                    isLoadingCharacters: appState.isLoadingOshiCharacters,
                    onLoadGroups: {
                        await appState.loadOshiGroups()
                    },
                    onLoadCharacters: { group in
                        await appState.loadOshiCharacters(group: group)
                    },
                    onLoadUserOshiSelections: {
                        await appState.loadUserOshiSelections()
                    }
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .modifier(
            MeguriScreenPresentationModifier(
                appState: appState,
                locationState: locationState,
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
                selectedGroomSourceAnchor: $selectedGroomSourceAnchor,
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
                onResetGroomDraft: resetGroomDraft,
                onOpenMeguriUserProfile: onOpenMeguriUserProfile
            )
        )
    }

    private func openVisualQASheetsIfNeeded() {
        if visualQAInitialScreen == .meguriProfileSettings, !didOpenVisualQAMeguriProfileSettings {
            didOpenVisualQAMeguriProfileSettings = true
            isShowingMeguriProfileSettings = true
        }
        if visualQAInitialScreen == .groomArchive, !didOpenVisualQAGroomArchive {
            didOpenVisualQAGroomArchive = true
            isShowingGroomArchive = true
        }
    }

    private func handlePendingNotificationRouteIntent(_ intent: NotificationRouteIntent?) {
        if case .groomDetail(let idString) = intent {
            openGroomDetailFromNotification(idString: idString)
            return
        }
        guard case .ownGroom(let postIDString) = intent else {
            return
        }
        openOwnGroomFromNotification(postIDString: postIDString)
    }

    /// FB(iter1226.390): プッシュから特定グルームを開く。圏外は遭遇済み×プレミアムのゲートで判定する。
    private func openGroomDetailFromNotification(idString: String) {
        guard let id = UUID(uuidString: idString) else {
            pendingNotificationRouteIntent = nil
            return
        }
        if locationState.coordinate == nil {
            locationState.startUpdatingCurrentLocation()
        }
        Task {
            let existing = appState.groomMapPosts.first { $0.id == id }
                ?? appState.grooms.first { $0.id == id }
            let groom: GroomPost?
            if let existing {
                groom = existing
            } else {
                groom = await appState.loadGroomPost(id: id)
            }
            pendingNotificationRouteIntent = nil
            guard let groom else {
                showToast("グルームが見つかりませんでした")
                return
            }
            // ゲート付きで開く（圏内=無料／圏外=遭遇済み×プレミアムのみ／それ以外はメッセージ）。
            openGroomFromStrip(groom, sourceAnchor: .center)
        }
    }

    private func openOwnGroomFromNotification(postIDString: String?) {
        let postID = postIDString.flatMap(UUID.init(uuidString:))
        if openOwnGroomIfAvailable(postID: postID) {
            pendingNotificationRouteIntent = nil
            return
        }

        Task {
            await appState.loadMeguriFeed(
                latitude: locationState.coordinate?.latitude,
                longitude: locationState.coordinate?.longitude,
                prefecture: selectedBoardPrefecture,
                scope: selectedBoardScope,
                force: true
            )
            if !openOwnGroomIfAvailable(postID: postID), postID != nil {
                await appState.loadGroomArchive()
                _ = openOwnGroomIfAvailable(postID: postID)
            }
            pendingNotificationRouteIntent = nil
        }
    }

    @discardableResult
    private func openOwnGroomIfAvailable(postID: UUID?) -> Bool {
        let groom = appState.ownVisibleGroom(postID: postID)
            ?? postID.flatMap { postID in
                appState.ownGroomArchive.first { $0.id == postID }
            }
        guard let groom else {
            return false
        }
        selectedGroomSourceAnchor = .center
        presentGroomViewer(groom, sourceAnchor: .center)
        Task {
            await appState.loadGroomEngagement(postIDs: [groom.id], reportsFailure: false)
        }
        return true
    }
}
