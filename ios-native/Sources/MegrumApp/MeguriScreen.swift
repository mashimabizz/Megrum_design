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
    @State private var selectedGroom: GroomPost?
    @State private var selectedGroomPhotoItem: PhotosPickerItem?
    @State private var isShowingGroomCamera = false
    @State private var activeMap: MeguriMapKind?
    @State private var isShowingThreadComposer = false
    @State private var isShowingPrefecturePicker = false
    @State private var localNoticeMessage: String?

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
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                ScreenTitle(title: "グルーム", subtitle: "近くの投稿と掲示板")

                if let notice {
                    MeguriNoticeBanner(
                        message: notice.message,
                        actionTitle: notice.actionTitle
                    ) {
                        handleLocationNoticeAction()
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "グルーム", actionTitle: "地図で見る") {
                        activeMap = .grooms
                    }
                    GroomStrip(
                        grooms: appState.grooms,
                        selectedPhotoItem: $selectedGroomPhotoItem,
                        isCreating: appState.isCreatingGroomPost,
                        canUseCamera: canUseCamera,
                        onOpenCamera: {
                            if canUseCamera {
                                isShowingGroomCamera = true
                            } else {
                                localNoticeMessage = "この端末ではカメラを利用できません。写真から選択してください。"
                            }
                        }
                    ) { groom in
                        openGroomFromStrip(groom)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionHeader(title: "掲示板", actionTitle: "地図で見る") {
                            activeMap = .boards
                        }
                        if appState.isLoadingMeguri {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    BoardScopeSelector(
                        selectedScope: selectedBoardScope,
                        prefectureTitle: selectedBoardPrefecture ?? "都道府県を選択",
                        onNearbyTap: {
                            updateBoardScope(.nearby3km)
                        },
                        onPrefectureTap: {
                            isShowingPrefecturePicker = true
                        }
                    )

                    if appState.threads.isEmpty {
                        MeguriInlineEmptyState(
                            systemImage: "bubble.left.and.bubble.right",
                            title: selectedBoardScope == .nearby3km ? "3km圏内のスレッドはまだありません" : "この都道府県のスレッドはまだありません",
                            message: selectedBoardScope == .nearby3km ? "現在地の近くにいる人へ聞きたいことを投稿できます。" : "都道府県表示に切り替えた人へ届く掲示板です。"
                        )
                    } else {
                        ForEach(appState.threads) { thread in
                            Button {
                                selectedThread = thread
                            } label: {
                                BoardThreadCard(thread: thread)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .refreshable {
            await reloadMeguriFeed()
        }
        .task {
            locationState.requestCurrentLocation()
        }
        .onReceive(locationState.$coordinate.compactMap { $0 }) { coordinate in
            Task {
                await appState.loadMeguriFeed(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    prefecture: selectedBoardPrefecture,
                    scope: selectedBoardScope
                )
            }
        }
        .onChange(of: selectedGroomPhotoItem) { _, item in
            guard let item else {
                return
            }
            Task {
                await publishSelectedGroomPhoto(item)
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
        .sheet(isPresented: $isShowingThreadComposer) {
            NavigationStack {
                BoardThreadComposerSheet(
                    appState: appState,
                    coordinate: locationState.coordinate,
                    selectedPrefecture: selectedBoardPrefecture,
                    initialScope: selectedBoardScope
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingPrefecturePicker) {
            NavigationStack {
                BoardPrefecturePickerSheet(selectedPrefecture: selectedBoardPrefecture) { prefecture in
                    storedBoardPrefecture = prefecture
                    storedBoardScopeRaw = BoardThread.Audience.samePrefecture.rawValue
                    Task {
                        await reloadMeguriFeed(scope: .samePrefecture)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
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
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            Button {
                isShowingThreadComposer = true
            } label: {
                Label("スレッドを立てる", systemImage: "plus")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: MegrumTheme.lavender.opacity(0.32), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
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
        await publishGroomPhoto(data: data, imageContentType: inferredImageContentType(from: data))
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

    private var notice: MegrumLocationNotice? {
        if let localNoticeMessage {
            return MegrumLocationNotice(message: localNoticeMessage, actionTitle: nil)
        }
        if let locationNotice = locationState.meguriNotice {
            return locationNotice
        }
        if let errorMessage = appState.errorMessage {
            return MegrumLocationNotice(message: errorMessage, actionTitle: nil)
        }
        return nil
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

    private func inferredImageContentType(from data: Data) -> String {
        let bytes = [UInt8](data.prefix(12))
        if bytes.count >= 8,
           bytes[0] == 0x89,
           bytes[1] == 0x50,
           bytes[2] == 0x4E,
           bytes[3] == 0x47 {
            return "image/png"
        }
        if bytes.count >= 12,
           bytes[0] == 0x52,
           bytes[1] == 0x49,
           bytes[2] == 0x46,
           bytes[3] == 0x46,
           bytes[8] == 0x57,
           bytes[9] == 0x45,
           bytes[10] == 0x42,
           bytes[11] == 0x50 {
            return "image/webp"
        }
        return "image/jpeg"
    }
}

private struct BoardThreadComposerSheet: View {
    @ObservedObject var appState: MegrumAppState
    var coordinate: MegrumLocationCoordinate?
    var selectedPrefecture: String?
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var scope: BoardThread.Audience = .nearby3km

    init(
        appState: MegrumAppState,
        coordinate: MegrumLocationCoordinate?,
        selectedPrefecture: String?,
        initialScope: BoardThread.Audience = .nearby3km
    ) {
        self.appState = appState
        self.coordinate = coordinate
        self.selectedPrefecture = selectedPrefecture
        _scope = State(initialValue: initialScope)
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && missingContextMessage == nil
            && !appState.isCreatingBoardThread
    }

    private var missingContextMessage: String? {
        switch scope {
        case .nearby3km:
            if coordinate == nil {
                return "3km圏内のスレッドには現在地が必要です"
            }
            if selectedPrefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil,
               appState.viewer?.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil {
                return "3km圏内のスレッドには都道府県設定が必要です"
            }
            return nil
        case .samePrefecture:
            if selectedPrefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil,
               appState.viewer?.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil {
                return "都道府県を選択してください"
            }
            return nil
        case .sameSpot, .global:
            return "この公開範囲はまだ作成できません"
        }
    }

    private var submitLatitude: Double? {
        scope == .nearby3km ? coordinate?.latitude : nil
    }

    private var submitLongitude: Double? {
        scope == .nearby3km ? coordinate?.longitude : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("スレッドを立てる")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Text("周辺の人と現地情報を共有できます")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Picker("公開範囲", selection: $scope) {
                    Text("3km圏内").tag(BoardThread.Audience.nearby3km)
                    Text(selectedPrefecture ?? appState.viewer?.prefecture ?? "都道府県").tag(BoardThread.Audience.samePrefecture)
                }
                .pickerStyle(.segmented)

                if let missingContextMessage {
                    MeguriNoticeBanner(message: missingContextMessage)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("タイトル")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    TextField("例：物販列どのくらい？", text: $title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .padding(15)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("本文")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    ZStack(alignment: .topLeading) {
                        if bodyText.isEmpty {
                            Text("いま見えている状況や聞きたいことを書いてください")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.72))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                        }

                        TextEditor(text: $bodyText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 170)
                            .background(.clear)
                    }
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                Task {
                    let created = await appState.createBoardThread(
                        title: title,
                        body: bodyText,
                        scope: scope,
                        latitude: submitLatitude,
                        longitude: submitLongitude,
                        prefecture: selectedPrefecture
                    )
                    if created {
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if appState.isCreatingBoardThread {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("作成する")
                    }
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.48)
        }
        .navigationTitle("掲示板")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private struct GroomViewerPresentationModifier: ViewModifier {
    @Binding var selectedGroom: GroomPost?
    var grooms: [GroomPost]
    @ObservedObject var appState: MegrumAppState

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(item: $selectedGroom) { groom in
            GroomViewerScreen(grooms: grooms, initialGroom: groom, appState: appState)
        }
        #else
        content.sheet(item: $selectedGroom) { groom in
            GroomViewerScreen(grooms: grooms, initialGroom: groom, appState: appState)
        }
        #endif
    }
}

private struct MeguriMapPresentationModifier: ViewModifier {
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

private struct GroomViewerScreen: View {
    var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var replyDraft = ""

    init(grooms: [GroomPost], initialGroom: GroomPost, appState: MegrumAppState) {
        let fallbackGrooms = grooms.isEmpty ? [initialGroom] : grooms
        self.grooms = fallbackGrooms
        self.initialGroom = initialGroom
        self.appState = appState
        _currentIndex = State(initialValue: fallbackGrooms.firstIndex(where: { $0.id == initialGroom.id }) ?? 0)
    }

    private var currentGroom: GroomPost {
        grooms[max(0, min(currentIndex, grooms.count - 1))]
    }

    private var isCurrentGroomLiked: Bool {
        appState.isGroomLiked(currentGroom.id)
    }

    private var canReplyToCurrentGroom: Bool {
        appState.viewer?.id != currentGroom.authorID
    }

    private var isSendingReply: Bool {
        appState.sendingGroomReplyPostID == currentGroom.id
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: currentGroom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .id(currentGroom.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .failure:
                    GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
                default:
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 8)
            .offset(y: dragOffset.height * 0.28)
            .scaleEffect(max(0.92, 1 - abs(dragOffset.height) / 900))

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        move(by: -1)
                    }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        move(by: 1)
                    }
            }

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(grooms.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentIndex ? .white : .white.opacity(0.28))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()

                HStack(spacing: 10) {
                    if canReplyToCurrentGroom {
                        TextField("返信を送る", text: $replyDraft)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .tint(.white)
                            .submitLabel(.send)
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(.white.opacity(0.16), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
                            .onSubmit {
                                submitGroomReply()
                            }

                        Button {
                            submitGroomReply()
                        } label: {
                            Group {
                                if isSendingReply {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .heavy))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(MegrumTheme.lavender, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingReply)
                        .opacity(replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.52 : 1)
                    } else {
                        Spacer()
                    }

                    Button {
                        Task {
                            await appState.setGroomLiked(currentGroom.id, isLiked: !isCurrentGroomLiked)
                        }
                    } label: {
                        Image(systemName: isCurrentGroomLiked ? "heart.fill" : "heart")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(isCurrentGroomLiked ? MegrumTheme.pink : .white)
                            .frame(width: 54, height: 54)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isCurrentGroomLiked ? "いいねを取り消す" : "いいね")
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .task(id: currentGroom.id) {
            await appState.markGroomViewed(currentGroom.id)
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }

    private func move(by delta: Int) {
        let nextIndex = currentIndex + delta
        guard grooms.indices.contains(nextIndex) else {
            if delta > 0 {
                dismiss()
            }
            return
        }
        withAnimation(.smooth(duration: 0.18)) {
            currentIndex = nextIndex
        }
    }

    private func submitGroomReply() {
        let body = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isSendingReply else {
            return
        }
        Task {
            let sent = await appState.sendGroomReply(
                postID: currentGroom.id,
                recipientID: currentGroom.authorID,
                body: body,
                groomImageURL: currentGroom.imageURL
            )
            if sent {
                replyDraft = ""
            }
        }
    }
}

private enum MeguriMapKind: String, Identifiable {
    case grooms
    case boards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grooms:
            "グルームマップ"
        case .boards:
            "掲示板マップ"
        }
    }

    var radiusMeters: CLLocationDistance {
        switch self {
        case .grooms:
            1_000
        case .boards:
            3_000
        }
    }

    var regionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.024, longitudeDelta: 0.024)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        }
    }
}

private struct MeguriMapScreen: View {
    var kind: MeguriMapKind
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var selectedPrefecture: String?
    var boardScope: BoardThread.Audience
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedGroom: GroomPost?
    @State private var selectedThread: BoardThread?
    @State private var mapNotice: String?
    @State private var hasCenteredMapOnLocation = false

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
        let initialGrooms = appState.groomMapPosts.isEmpty ? appState.grooms : appState.groomMapPosts
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: kind.initialCenter(userCoordinate: locationState.coordinate, grooms: initialGrooms, threads: appState.threads), span: kind.regionSpan)))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
                if let rangeCircle {
                    MapCircle(center: rangeCircle.center, radius: rangeCircle.radius)
                        .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                        .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.5)
                }

                switch kind {
                case .grooms:
                    ForEach(mapGrooms) { groom in
                        Annotation("グルーム", coordinate: groom.coordinate) {
                            Button {
                                openGroomIfInRange(groom)
                            } label: {
                                GroomMapPin(groom: groom, isOutOfRange: isGroomOutOfRange(groom))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                case .boards:
                    ForEach(appState.threads.compactMap(BoardMapAnnotation.init(thread:))) { annotation in
                        Annotation(annotation.thread.title, coordinate: annotation.coordinate) {
                            Button {
                                selectedThread = annotation.thread
                            } label: {
                                BoardMapPin(thread: annotation.thread)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()

            VStack(spacing: 10) {
                MapGlassHeader(title: kind.title) {
                    dismiss()
                }

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
        }
        .task {
            locationState.requestCurrentLocation()
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
                    alignCameraToVisibleContent(userCoordinate: coordinate, animated: true, force: true)
                }
            }
        }
        .sheet(item: $selectedGroom) { groom in
            GroomMapDetailSheet(groom: groom)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedThread) { thread in
            NavigationStack {
                BoardThreadDetailScreen(
                    appState: appState,
                    thread: thread,
                    selectedPrefecture: selectedPrefecture,
                    coordinate: locationState.coordinate
                )
            }
        }
    }

    private func alignCameraToVisibleContent(
        userCoordinate: MegrumLocationCoordinate?,
        animated: Bool,
        force: Bool = false
    ) {
        if !force, userCoordinate != nil, hasCenteredMapOnLocation {
            return
        }

        let region = kind.visibleRegion(
            userCoordinate: userCoordinate,
            grooms: mapGrooms,
            threads: appState.threads,
            boardScope: boardScope
        )
        let update = {
            cameraPosition = .region(region)
        }
        if animated {
            withAnimation(.smooth(duration: 0.28)) {
                update()
            }
        } else {
            update()
        }
        if userCoordinate != nil {
            hasCenteredMapOnLocation = true
        }
    }

    private var mapGrooms: [GroomPost] {
        appState.groomMapPosts.isEmpty ? appState.grooms : appState.groomMapPosts
    }

    private var isLoadingMapContent: Bool {
        switch kind {
        case .grooms:
            appState.isLoadingGroomMap
        case .boards:
            appState.isLoadingMeguri
        }
    }

    private func reloadMapContent(latitude: Double?, longitude: Double?) async {
        switch kind {
        case .grooms:
            await appState.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: 3_000
            )
        case .boards:
            if boardScope == .nearby3km, (latitude == nil || longitude == nil) {
                await MainActor.run {
                    locationState.requestCurrentLocation()
                }
                return
            }
            await appState.loadMeguriFeed(
                latitude: latitude,
                longitude: longitude,
                prefecture: selectedPrefecture,
                scope: mapBoardScope
            )
        }
    }

    private var rangeCircle: (center: CLLocationCoordinate2D, radius: CLLocationDistance)? {
        guard let coordinate = locationState.coordinate else {
            return nil
        }
        if kind == .boards, boardScope != .nearby3km {
            return nil
        }
        return (coordinate.clLocationCoordinate, kind.radiusMeters)
    }

    private var mapStatusMessage: String? {
        if isLoadingMapContent || locationState.isRequestingLocation {
            return "現在地と投稿を読み込み中"
        }
        if let locationErrorMessage = locationState.locationErrorMessage, kind == .grooms || boardScope == .nearby3km {
            return locationErrorMessage
        }
        if kind == .boards, boardScope == .samePrefecture {
            return "都道府県内の位置つきスレッドを表示中"
        }
        if kind == .grooms, rangeCircle != nil {
            return "現在地周辺のグルームを表示中。1km外は閲覧できません"
        }
        if rangeCircle == nil {
            return "範囲円は現在地取得後に表示されます"
        }
        return nil
    }

    private var mapBoardScope: BoardThread.Audience {
        switch kind {
        case .grooms:
            .nearby3km
        case .boards:
            boardScope
        }
    }

    private func openGroomIfInRange(_ groom: GroomPost) {
        guard kind == .grooms else {
            selectedGroom = groom
            return
        }
        if canOpen(groom: groom) {
            mapNotice = nil
            selectedGroom = groom
            return
        }
        guard locationState.coordinate != nil else {
            withAnimation(.smooth(duration: 0.2)) {
                mapNotice = MeguriAccessPolicy.groomAccessMessage(
                    groom,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
                )
            }
            locationState.requestCurrentLocation()
            return
        }
        withAnimation(.smooth(duration: 0.2)) {
            mapNotice = groomRangeNotice(groom)
        }
    }

    private func isGroomOutOfRange(_ groom: GroomPost) -> Bool {
        !MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func canOpen(groom: GroomPost) -> Bool {
        MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func distanceFromCurrentLocation(to groom: GroomPost) -> CLLocationDistance? {
        MeguriAccessPolicy.distanceMeters(from: locationState.coordinate, to: groom)
    }

    private func groomRangeNotice(_ groom: GroomPost) -> String {
        MeguriAccessPolicy.groomAccessMessage(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }
}

private struct MapGlassHeader: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(.regularMaterial, in: Capsule())

            Spacer()

            Color.clear
                .frame(width: 42, height: 42)
        }
    }
}

private struct MapStatusBadge: View {
    var message: String
    var isLoading: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(MegrumTheme.lavender)
            } else {
                Image(systemName: "location")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            Text(message)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 38)
        .background(.regularMaterial, in: Capsule())
    }
}

private struct GroomMapPin: View {
    var groom: GroomPost
    var isOutOfRange: Bool

    var body: some View {
        VStack(spacing: 0) {
            GroomThumbnailCircle(url: groom.imageURL, size: 58)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .overlay(alignment: .bottomTrailing) {
                    if isOutOfRange {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(MegrumTheme.ink)
                            .frame(width: 21, height: 21)
                            .background(.regularMaterial, in: Circle())
                            .offset(x: 3, y: 3)
                    }
                }
                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)
                .saturation(isOutOfRange ? 0.25 : 1)
                .opacity(isOutOfRange ? 0.68 : 1)

            Triangle()
                .fill(.white)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .accessibilityLabel(isOutOfRange ? "1km圏外のグルーム" : "グルーム")
    }
}

private struct BoardMapPin: View {
    var thread: BoardThread

    var body: some View {
        Text(thread.title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(MegrumTheme.lavender, in: Capsule())
            .overlay(alignment: .bottom) {
                Triangle()
                    .fill(MegrumTheme.lavender)
                    .frame(width: 14, height: 8)
                    .offset(y: 6)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.2), radius: 12, y: 7)
            .accessibilityLabel("掲示板 \(thread.title)")
    }
}

private struct GroomMapDetailSheet: View {
    var groom: GroomPost

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("グルーム")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            AsyncImage(url: groom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.86))
                        .overlay {
                            GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: MegrumTheme.ink)
                        }
                default:
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MegrumTheme.sky, MegrumTheme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(20)
        .background(MegrumTheme.canvas)
    }
}

private struct GroomThumbnailCircle: View {
    var url: URL
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                GroomImageFailureView(message: nil, foregroundColor: .white)
            default:
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(width: size, height: size)
        .background(
            LinearGradient(
                colors: [MegrumTheme.sky, MegrumTheme.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Circle())
        .contentShape(Circle())
    }
}

private struct GroomImageFailureView: View {
    var message: String?
    var foregroundColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.system(size: message == nil ? 20 : 30, weight: .bold))

            if let message {
                Text(message)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(foregroundColor.opacity(0.78))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BoardThreadDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var thread: BoardThread
    var selectedPrefecture: String?
    var coordinate: MegrumLocationCoordinate?
    @Environment(\.dismiss) private var dismiss
    @State private var draftReply = ""

    private var replies: [BoardReply] {
        appState.boardReplies(for: thread.id)
    }

    private var replyContextScope: BoardThread.Audience {
        thread.audience == .sameSpot ? .nearby3km : thread.audience
    }

    private var missingReplyContextMessage: String? {
        switch replyContextScope {
        case .nearby3km:
            coordinate == nil ? "このスレッドへの返信には現在地が必要です" : nil
        case .samePrefecture:
            selectedPrefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil
                && appState.viewer?.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank == nil
                ? "このスレッドへの返信には都道府県設定が必要です"
                : nil
        case .sameSpot, .global:
            nil
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    BoardThreadStarterBubble(
                        thread: thread,
                        isMine: thread.authorID == appState.viewer?.id
                    )

                    if let missingReplyContextMessage {
                        MeguriNoticeBanner(message: missingReplyContextMessage)
                    }

                    ForEach(replies) { reply in
                        BoardReplyBubble(
                            reply: reply,
                            isMine: reply.authorID == appState.viewer?.id
                        )
                    }

                    if appState.loadingBoardRepliesThreadID == thread.id {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("返信を読み込み中")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    } else if replies.isEmpty {
                        Text("まだ返信はありません")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(BoardThreadScrollAnchor.bottom)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 88)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: replies.count) { _, _ in
                scrollToLatest(proxy)
            }
            .safeAreaInset(edge: .bottom) {
                BoardReplyInput(
                    text: $draftReply,
                    isSending: appState.sendingBoardReplyThreadID == thread.id,
                    isDisabled: missingReplyContextMessage != nil
                ) {
                    sendReply(proxy: proxy)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(thread.title)
            .megrumInlineNavigationTitle()
            .task {
                await appState.loadBoardReplies(
                    threadID: thread.id,
                    latitude: coordinate?.latitude,
                    longitude: coordinate?.longitude,
                    prefecture: selectedPrefecture,
                    scope: replyContextScope
                )
                await MainActor.run {
                    scrollToLatest(proxy, animated: false)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sendReply(proxy: ScrollViewProxy) {
        let trimmedReply = draftReply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReply.isEmpty, appState.sendingBoardReplyThreadID != thread.id else {
            return
        }

        Task {
            let sent = await appState.sendBoardReply(
                threadID: thread.id,
                body: trimmedReply,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude,
                prefecture: selectedPrefecture,
                scope: replyContextScope
            )
            if sent {
                await MainActor.run {
                    draftReply = ""
                    scrollToLatest(proxy)
                }
            }
        }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy, animated: Bool = true) {
        let scroll = {
            proxy.scrollTo(BoardThreadScrollAnchor.bottom, anchor: .bottom)
        }
        if animated {
            withAnimation(.smooth(duration: 0.22)) {
                scroll()
            }
        } else {
            scroll()
        }
    }
}

private enum BoardThreadScrollAnchor: Hashable {
    case bottom
}

private struct BoardThreadStarterBubble: View {
    var thread: BoardThread
    var isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 5) {
            VStack(alignment: .leading, spacing: 8) {
                Text(thread.title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(thread.body)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isMine ? .white.opacity(0.94) : MegrumTheme.ink.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .frame(maxWidth: 292, alignment: .leading)
            .background(
                isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.92)),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: MegrumTheme.ink.opacity(isMine ? 0.08 : 0.05), radius: 12, y: 6)

            Text(thread.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct BoardReplyBubble: View {
    var reply: BoardReply
    var isMine: Bool

    private var bodyText: String {
        reply.status == .deleted ? "削除済みです" : reply.body
    }

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 5) {
            Text(bodyText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: 292, alignment: .leading)
                .background(
                    isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Text(reply.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct BoardReplyInput: View {
    @Binding var text: String
    var isSending: Bool
    var isDisabled = false
    var onSend: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending && !isDisabled
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField("返信を入力", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1...4)
                .submitLabel(.send)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
                }
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .disabled(isDisabled)

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.45)
        }
        .opacity(isDisabled ? 0.62 : 1)
    }
}

private struct BoardScopeSelector: View {
    var selectedScope: BoardThread.Audience
    var prefectureTitle: String
    var onNearbyTap: () -> Void
    var onPrefectureTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onNearbyTap) {
                scopeChip(
                    title: "3km圏内",
                    systemImage: "location.fill",
                    isSelected: selectedScope == .nearby3km
                )
            }
            .buttonStyle(.plain)

            Button(action: onPrefectureTap) {
                scopeChip(
                    title: prefectureTitle,
                    systemImage: "map.fill",
                    isSelected: selectedScope == .samePrefecture
                )
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .contain)
    }

    private func scopeChip(title: String, systemImage: String, isSelected: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(isSelected ? .white.opacity(0.28) : MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: isSelected ? MegrumTheme.lavender.opacity(0.22) : MegrumTheme.ink.opacity(0.05), radius: 10, y: 5)
    }
}

private struct BoardPrefecturePickerSheet: View {
    var selectedPrefecture: String?
    var onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(japanesePrefectures, id: \.self) { prefecture in
            Button {
                onSelect(prefecture)
                dismiss()
            } label: {
                HStack {
                    Text(prefecture)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Spacer()

                    if selectedPrefecture == prefecture {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(prefecture)を掲示板の都道府県に設定")
        }
        .navigationTitle("都道府県を選択")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private struct SectionHeader: View {
    var title: String
    var actionTitle: String
    var action: () -> Void = {}

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 25, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Button(actionTitle, action: action)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct MeguriNoticeBanner: View {
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct MeguriInlineEmptyState: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct GroomStrip: View {
    var grooms: [GroomPost]
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var isCreating: Bool
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
    var onSelect: (GroomPost) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                Button(action: onOpenCamera) {
                    GroomAddTile(title: "撮影", systemImage: "camera.fill", isLoading: isCreating)
                }
                .buttonStyle(.plain)
                .disabled(isCreating)
                .opacity(canUseCamera ? 1 : 0.58)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    GroomAddTile(title: "写真", systemImage: "photo.on.rectangle", isLoading: isCreating)
                }
                .buttonStyle(.plain)
                .disabled(isCreating)

                if grooms.isEmpty {
                    MeguriInlineEmptyState(
                        systemImage: "sparkles",
                        title: "近くのグルームはまだありません",
                        message: "撮影すると、いま近くにいる人へだけ届きます。"
                    )
                    .frame(width: 230)
                }

                ForEach(grooms) { groom in
                    Button {
                        onSelect(groom)
                    } label: {
                        VStack(spacing: 8) {
                            GroomThumbnailCircle(url: groom.imageURL, size: 72)

                            Text("1km圏内")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                    .buttonStyle(.plain)
                    .id(groom.id)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct GroomAddTile: View {
    var title: String
    var systemImage: String
    var isLoading: Bool

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 72, height: 72)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .tint(MegrumTheme.lavender)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 23, weight: .heavy))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
                .overlay {
                    Circle()
                        .stroke(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }

            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private struct BoardThreadCard: View {
    var thread: BoardThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scopeText)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

                Spacer()
            }

            Text(thread.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(thread.body)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(2)
        }
        .padding(16)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 14, y: 7)
    }

    private var scopeText: String {
        switch thread.audience {
        case .nearby3km:
            "3km圏内"
        case .samePrefecture:
            thread.prefecture ?? "都道府県"
        case .sameSpot:
            "スポット"
        case .global:
            "全体"
        }
    }
}

private struct BoardMapAnnotation: Identifiable {
    var thread: BoardThread
    var coordinate: CLLocationCoordinate2D

    var id: UUID { thread.id }

    init?(thread: BoardThread) {
        guard let latitude = thread.latitude, let longitude = thread.longitude else {
            return nil
        }
        self.thread = thread
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

enum MeguriAccessPolicy {
    static let groomOpenRadiusMeters: CLLocationDistance = 1_000
    static let boardNearbyRadiusMeters: CLLocationDistance = 3_000

    static func distanceMeters(
        from currentCoordinate: MegrumLocationCoordinate?,
        to groom: GroomPost
    ) -> CLLocationDistance? {
        guard let currentCoordinate else {
            return nil
        }
        let currentLocation = CLLocation(
            latitude: currentCoordinate.latitude,
            longitude: currentCoordinate.longitude
        )
        let groomLocation = CLLocation(
            latitude: groom.latitude,
            longitude: groom.longitude
        )
        return currentLocation.distance(from: groomLocation)
    }

    static func canOpenGroom(
        _ groom: GroomPost,
        currentCoordinate: MegrumLocationCoordinate?,
        viewerID: UUID?
    ) -> Bool {
        if groom.authorID == viewerID {
            return true
        }
        guard let distance = distanceMeters(from: currentCoordinate, to: groom) else {
            return false
        }
        return distance <= groomOpenRadiusMeters
    }

    static func groomAccessMessage(
        _ groom: GroomPost,
        currentCoordinate: MegrumLocationCoordinate?,
        viewerID: UUID?
    ) -> String {
        if groom.authorID == viewerID {
            return ""
        }
        guard let distance = distanceMeters(from: currentCoordinate, to: groom) else {
            return "現在地取得後にグルームを開けます"
        }
        return "現在地から\(distance.meguriDistanceText)。1km圏外のグルームは見れません"
    }
}

private extension GroomPost {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension MeguriMapKind {
    func initialCenter(userCoordinate: MegrumLocationCoordinate?, grooms: [GroomPost], threads: [BoardThread]) -> CLLocationCoordinate2D {
        if let userCoordinate {
            return userCoordinate.clLocationCoordinate
        }

        switch self {
        case .grooms:
            return grooms.first?.coordinate ?? Self.fallbackCenter
        case .boards:
            if let thread = threads.first(where: { $0.latitude != nil && $0.longitude != nil }),
               let latitude = thread.latitude,
               let longitude = thread.longitude {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            return Self.fallbackCenter
        }
    }

    func visibleRegion(
        userCoordinate: MegrumLocationCoordinate?,
        grooms: [GroomPost],
        threads: [BoardThread],
        boardScope: BoardThread.Audience
    ) -> MKCoordinateRegion {
        let userLocation = userCoordinate?.clLocationCoordinate
        var rect = MKMapRect.null

        if let userLocation, shouldCenterRangeCircle(boardScope: boardScope) {
            rect = rect.union(.meguriRect(centeredAt: userLocation, radiusMeters: radiusMeters))
        } else if let userLocation, annotationCoordinates(grooms: grooms, threads: threads).isEmpty {
            rect = rect.union(.meguriRect(centeredAt: userLocation, radiusMeters: 220))
        }

        for coordinate in annotationCoordinates(grooms: grooms, threads: threads) where coordinate.isMeguriValid {
            rect = rect.union(.meguriRect(centeredAt: coordinate, radiusMeters: 150))
        }

        guard !rect.isNull else {
            return MKCoordinateRegion(
                center: initialCenter(userCoordinate: userCoordinate, grooms: grooms, threads: threads),
                span: regionSpan
            )
        }

        return MKCoordinateRegion(rect.meguriPadded())
            .meguriClamped(minimum: minimumRegionSpan, maximum: maximumRegionSpan)
    }

    private func annotationCoordinates(grooms: [GroomPost], threads: [BoardThread]) -> [CLLocationCoordinate2D] {
        switch self {
        case .grooms:
            return grooms.map(\.coordinate)
        case .boards:
            return threads.compactMap { thread in
                guard let latitude = thread.latitude, let longitude = thread.longitude else {
                    return nil
                }
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
    }

    private func shouldCenterRangeCircle(boardScope: BoardThread.Audience) -> Bool {
        switch self {
        case .grooms:
            return true
        case .boards:
            return boardScope == .nearby3km
        }
    }

    private var minimumRegionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        }
    }

    private var maximumRegionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
        }
    }

    static var fallbackCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    }
}

private extension MKMapRect {
    static func meguriRect(centeredAt coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) -> MKMapRect {
        let point = MKMapPoint(coordinate)
        let metersPerMapPoint = max(MKMetersPerMapPointAtLatitude(coordinate.latitude), 0.000_001)
        let radiusMapPoints = max(radiusMeters / metersPerMapPoint, 1)
        return MKMapRect(
            x: point.x - radiusMapPoints,
            y: point.y - radiusMapPoints,
            width: radiusMapPoints * 2,
            height: radiusMapPoints * 2
        )
    }

    func meguriPadded(fraction: Double = 0.24) -> MKMapRect {
        insetBy(dx: -size.width * fraction, dy: -size.height * fraction)
    }
}

private extension MKCoordinateRegion {
    func meguriClamped(minimum: MKCoordinateSpan, maximum: MKCoordinateSpan) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta.meguriClamped(minimum.latitudeDelta, maximum.latitudeDelta),
                longitudeDelta: span.longitudeDelta.meguriClamped(minimum.longitudeDelta, maximum.longitudeDelta)
            )
        )
    }
}

private extension CLLocationCoordinate2D {
    var isMeguriValid: Bool {
        CLLocationCoordinate2DIsValid(self)
    }
}

private extension Double {
    func meguriClamped(_ lowerBound: Double, _ upperBound: Double) -> Double {
        min(max(self, lowerBound), upperBound)
    }
}

private extension CLLocationDistance {
    var meguriDistanceText: String {
        if self < 1_000 {
            return "\(Int(rounded()))m"
        }
        return String(format: "%.1fkm", self / 1_000)
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}

private let japanesePrefectures = [
    "北海道",
    "青森県",
    "岩手県",
    "宮城県",
    "秋田県",
    "山形県",
    "福島県",
    "茨城県",
    "栃木県",
    "群馬県",
    "埼玉県",
    "千葉県",
    "東京都",
    "神奈川県",
    "新潟県",
    "富山県",
    "石川県",
    "福井県",
    "山梨県",
    "長野県",
    "岐阜県",
    "静岡県",
    "愛知県",
    "三重県",
    "滋賀県",
    "京都府",
    "大阪府",
    "兵庫県",
    "奈良県",
    "和歌山県",
    "鳥取県",
    "島根県",
    "岡山県",
    "広島県",
    "山口県",
    "徳島県",
    "香川県",
    "愛媛県",
    "高知県",
    "福岡県",
    "佐賀県",
    "長崎県",
    "熊本県",
    "大分県",
    "宮崎県",
    "鹿児島県",
    "沖縄県"
]
