import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomViewerPresentationModifier: ViewModifier {
    @Binding var selectedGroom: GroomPost?
    var sourceAnchor: UnitPoint = .center
    var grooms: [GroomPost]
    @ObservedObject var appState: MegrumAppState
    var onOpenMeguriUserProfile: (UUID) -> Void = { _ in }

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .groomViewerImmersiveOverlay(item: $selectedGroom, sourceAnchor: sourceAnchor) { groom, dismiss in
                GroomViewerScreen(
                    grooms: grooms,
                    initialGroom: groom,
                    appState: appState,
                    onDismiss: dismiss,
                    onOpenMeguriUserProfile: onOpenMeguriUserProfile
                )
            }
        #else
        content
            .sheet(item: $selectedGroom) { groom in
                GroomViewerScreen(
                    grooms: grooms,
                    initialGroom: groom,
                    appState: appState,
                    onOpenMeguriUserProfile: onOpenMeguriUserProfile
                )
                .background(Color.black.ignoresSafeArea())
            }
        #endif
    }
}

struct GroomViewerScreen: View {
    var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    var onDismiss: (() -> Void)?
    var onOpenMeguriUserProfile: (UUID) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    static let doubleTapSpaceName = "groom-viewer-double-tap"
    @State private var doubleTapHearts: [GroomDoubleTapHeart] = []
    @State private var pendingViewerTap: PendingViewerTap?
    @State private var pendingDismissTask: Task<Void, Never>?

    private struct PendingViewerTap {
        var time: Date
        var indexBeforeTap: Int
    }
    @State private var currentIndex: Int
    @State private var dragState = GroomViewerDragPresentationState()
    @State private var interactionState = GroomViewerInteractionState()
    @State private var isShowingComments = false
    @State private var isShowingLikes = false
    @State private var isShowingDeleteConfirmation = false
    @State private var storyProgress = 0.0

    init(
        grooms: [GroomPost],
        initialGroom: GroomPost,
        appState: MegrumAppState,
        onDismiss: (() -> Void)? = nil,
        onOpenMeguriUserProfile: @escaping (UUID) -> Void = { _ in }
    ) {
        let fallbackGrooms = grooms.contains(where: { $0.id == initialGroom.id })
            ? grooms
            : [initialGroom] + grooms
        self.grooms = fallbackGrooms
        self.initialGroom = initialGroom
        self.appState = appState
        self.onDismiss = onDismiss
        self.onOpenMeguriUserProfile = onOpenMeguriUserProfile
        _currentIndex = State(initialValue: fallbackGrooms.firstIndex(where: { $0.id == initialGroom.id }) ?? 0)
    }

    private var currentGroom: GroomPost {
        grooms[max(0, min(currentIndex, grooms.count - 1))]
    }

    private var isCurrentGroomLiked: Bool {
        appState.isGroomLiked(currentGroom.id)
    }

    private var canReplyToCurrentGroom: Bool {
        guard let viewerID = appState.viewer?.id else {
            return false
        }
        return viewerID != currentGroom.authorID
    }

    private var isCurrentGroomMine: Bool {
        currentGroom.authorID == appState.viewer?.id
    }

    private var isSendingReply: Bool {
        appState.sendingGroomReplyPostID == currentGroom.id
    }

    private var currentGroomLikeCount: Int {
        if isCurrentGroomMine {
            return appState.groomReactions(for: currentGroom.id).count
        }
        return appState.groomLikeCount(currentGroom.id, fallback: currentGroom.likeCount)
    }

    private var currentGroomCommentCount: Int {
        let replies = appState.groomReplies(for: currentGroom.id)
        // コメントは投稿者本人以外には自分の送信分しか見えないため、件数も揃える。
        if isCurrentGroomMine {
            return replies.count
        }
        guard let viewerID = appState.viewer?.id else {
            return replies.count
        }
        return replies.filter { $0.senderID == viewerID }.count
    }

    /// 自分のグルームに付いたいいねを、浮遊エフェクト用の表示データへ変換する。
    private var floatingLikers: [GroomFloatingLiker] {
        guard isCurrentGroomMine else {
            return []
        }
        return appState.groomReactions(for: currentGroom.id)
            .sorted { $0.createdAt > $1.createdAt }
            .map { reaction in
                // 自分のいいねは自分の交換プロフィールのアイコンで解決する
                //（publicProfilesByUserID には自分は入らないため）。
                let fallbackAvatarURL = reaction.userID == appState.viewer?.id
                    ? appState.viewer?.avatarURL
                    : appState.publicProfilesByUserID[reaction.userID]?.profile.avatarURL
                let identity = appState.meguriIdentity(
                    for: reaction.userID,
                    fallbackAvatarURL: fallbackAvatarURL
                )
                return GroomFloatingLiker(
                    id: reaction.userID,
                    avatarID: identity.avatarID,
                    avatarURL: identity.avatarURL,
                    initial: String(identity.displayName.prefix(1)).uppercased()
                )
            }
    }

    private var viewerVerticalOffset: CGFloat {
        dragState.verticalOffset
    }

    private var viewerScale: CGFloat {
        dragState.scale
    }

    private var viewerCornerRadius: CGFloat {
        dragState.cornerRadius
    }

    private var authorName: String {
        authorIdentity.displayName
    }

    private var authorIdentity: MeguriProfileIdentity {
        appState.meguriIdentity(
            for: currentGroom.authorID,
            fallbackName: currentGroom.authorID == appState.viewer?.id ? appState.viewer?.displayName : nil,
            fallbackHandle: currentGroom.authorID == appState.viewer?.id ? appState.viewer?.handle : nil,
            fallbackAvatarURL: currentGroom.authorID == appState.viewer?.id ? appState.viewer?.avatarURL : nil
        )
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.container, edges: .top)

            viewerSurface
                .offset(y: viewerVerticalOffset)
                .scaleEffect(viewerScale)
                .clipShape(RoundedRectangle(cornerRadius: viewerCornerRadius, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea(.container, edges: .top))
        .ignoresSafeArea()
        .task(id: currentGroom.id) {
            prefetchNeighborGroomImages()
            await appState.markGroomViewed(currentGroom.id)
            await appState.loadGroomEngagement(postIDs: [currentGroom.id], reportsFailure: false)
            await appState.loadMeguriProfiles(userIDs: [currentGroom.authorID], reportsFailure: false)
            if currentGroom.authorID != appState.viewer?.id,
               appState.publicProfilesByUserID[currentGroom.authorID] == nil {
                await appState.loadPublicUserProfile(userID: currentGroom.authorID, reportsFailure: false)
            }
        }
        .task(id: currentGroom.id) {
            await runStoryProgress(for: currentGroom.id)
        }
        .confirmationDialog("このグルームを通報しますか？", isPresented: $interactionState.isShowingReportConfirmation, titleVisibility: .visible) {
            Button("通報する", role: .destructive) {
                Task {
                    _ = await appState.reportGroom(currentGroom)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("運営が内容を確認します。")
        }
        .confirmationDialog("この投稿者をブロックしますか？", isPresented: $interactionState.isShowingBlockConfirmation, titleVisibility: .visible) {
            Button("ブロックする", role: .destructive) {
                Task {
                    let blocked = await appState.blockGroomAuthor(currentGroom)
                    if blocked {
                        dismissViewer()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("グルームとチャットルームで相手の投稿が表示されにくくなります。グッズ交換のブロックとは別です。")
        }
        .confirmationDialog("このグルームを削除しますか？", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                deleteCurrentGroom()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("削除すると、めぐりホームとグルームアーカイブから表示されなくなります。")
        }
        .sheet(isPresented: $isShowingComments) {
            GroomViewerCommentsSheet(
                groom: currentGroom,
                appState: appState,
                canReply: canReplyToCurrentGroom,
                isSendingReply: isSendingReply,
                replyDraft: $interactionState.replyDraft,
                onSubmitReply: submitGroomReply,
                onOpenProfile: onOpenMeguriUserProfile
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingLikes) {
            GroomViewerLikesSheet(
                groom: currentGroom,
                appState: appState,
                onOpenProfile: onOpenMeguriUserProfile
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    dragState.update(with: value.translation)
                }
                .onEnded { value in
                    if dragState.shouldDismiss(for: value.translation) {
                        dismissViewer()
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            dragState.reset()
                        }
                    }
                }
        )
    }

    private var viewerSurface: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea(.container, edges: .top)

                GroomViewerCachedImage(url: currentGroom.imageURL)
                    .padding(.horizontal, 8)

                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(pageTapGesture(delta: -1))

                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(pageTapGesture(delta: 1))
                }
                .coordinateSpace(name: Self.doubleTapSpaceName)

                // ダブルタップいいねの大きなハート（ドクン→ふわり上昇フェード）
                ForEach(doubleTapHearts) { heart in
                    GroomDoubleTapHeartView(position: heart.position)
                }

                Color.black
                    .frame(height: GroomViewerChromeLayout.topObstructionHeight(safeAreaTop: proxy.safeAreaInsets.top))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)

                // いいね演出：背景から湧くハート＋（自分のグルームなら）いいねした人のアイコン浮遊
                GroomLikeHeartRainLayer(
                    groomID: currentGroom.id,
                    likeCount: currentGroomLikeCount
                )
                GroomLikeFloatingLikersLayer(
                    groomID: currentGroom.id,
                    likers: floatingLikers
                )

                VStack(spacing: 0) {
                    GroomViewerPageIndicator(
                        totalCount: grooms.count,
                        currentIndex: currentIndex,
                        currentProgress: storyProgress
                    )

                    GroomViewerTopBar(
                        authorName: authorName,
                        postTimeText: GroomPostRelativeTimeFormatter.relativeText(from: currentGroom.createdAt),
                        authorAvatarID: authorIdentity.avatarID,
                        authorAvatarURL: authorIdentity.avatarURL,
                        canModerate: canReplyToCurrentGroom,
                        onReport: { interactionState.showReportConfirmation() },
                        onBlock: { interactionState.showBlockConfirmation() },
                        onOpenProfile: { onOpenMeguriUserProfile(currentGroom.authorID) }
                    ) {
                        dismissViewer()
                    }

                    Spacer()

                    if isCurrentGroomMine {
                        HStack {
                            Spacer()
                            GroomViewerOwnerBottomControls(
                                isLiked: isCurrentGroomLiked,
                                likeCount: currentGroomLikeCount,
                                commentCount: currentGroomCommentCount,
                                isDeleting: appState.deletingGroomPostID == currentGroom.id,
                                onToggleLike: toggleCurrentGroomLike,
                                onOpenComments: { isShowingComments = true },
                                onOpenLikes: { isShowingLikes = true },
                                onDelete: { isShowingDeleteConfirmation = true }
                            )
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                    } else {
                        GroomViewerBottomControls(
                            canReply: canReplyToCurrentGroom,
                            canLike: canReplyToCurrentGroom,
                            isSendingReply: isSendingReply,
                            isLiked: isCurrentGroomLiked,
                            likeCount: currentGroomLikeCount,
                            commentCount: currentGroomCommentCount,
                            onToggleLike: toggleCurrentGroomLike,
                            onOpenComments: { isShowingComments = true },
                            onOpenLikes: { isShowingLikes = true }
                        )
                    }
                }
                .padding(.top, GroomViewerChromeLayout.topPadding(safeAreaTop: proxy.safeAreaInsets.top))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea(.container, edges: .top))
    }

    private func move(by delta: Int) {
        let nextIndex = currentIndex + delta
        guard grooms.indices.contains(nextIndex) else {
            if delta > 0 {
                dismissViewer()
            }
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentIndex = nextIndex
        }
    }

    @MainActor
    private func runStoryProgress(for groomID: UUID) async {
        storyProgress = 0
        let steps = 200
        for step in 1...steps {
            if Task.isCancelled || currentGroom.id != groomID {
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            if Task.isCancelled || currentGroom.id != groomID {
                return
            }
            let nextProgress = Double(step) / Double(steps)
            if reduceMotion {
                storyProgress = step == steps ? 1 : 0
            } else {
                storyProgress = nextProgress
            }
        }
        guard currentGroom.id == groomID else {
            return
        }
        move(by: 1)
    }

    /// 前後のグルーム画像を先読みして、切り替え時にローディングを挟まないようにする。
    private func prefetchNeighborGroomImages() {
        let neighborOffsets = [-1, 1, 2]
        let urls = neighborOffsets.compactMap { offset -> URL? in
            let index = currentIndex + offset
            guard grooms.indices.contains(index) else {
                return nil
            }
            return grooms[index].imageURL
        }
        guard !urls.isEmpty else {
            return
        }
        Task(priority: .userInitiated) {
            await GoodsRemoteImageDataLoader.preload(urls: urls)
        }
    }

    private func dismissViewer() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func toggleCurrentGroomLike() {
        // いいね（ON/OFFどちらも）に触覚フィードバックを添える
        MegrumHaptics.buttonTap()
        Task {
            await appState.setGroomLiked(currentGroom.id, isLiked: !isCurrentGroomLiked)
        }
    }

    /// タップした瞬間にページを切り替える（ダブルタップ判定を待たない）。
    /// ダブルタップいいねは自前のタイミング判定で検出し、
    /// 1回目のタップで進んでいた場合は元のグルームへ即戻していいねする。
    private func pageTapGesture(delta: Int) -> some Gesture {
        SpatialTapGesture(coordinateSpace: .named(Self.doubleTapSpaceName))
            .onEnded { value in
                handleViewerTap(delta: delta, location: value.location)
            }
    }

    private static let doubleTapWindow: TimeInterval = 0.30

    private func handleViewerTap(delta: Int, location: CGPoint) {
        let now = Date()
        if let pending = pendingViewerTap,
           now.timeIntervalSince(pending.time) < Self.doubleTapWindow {
            // 2回目のタップ＝ダブルタップいいね。
            pendingViewerTap = nil
            pendingDismissTask?.cancel()
            pendingDismissTask = nil
            // 1回目で次へ進んでいたら、いいね対象（元のグルーム）へ即戻す。
            if currentIndex != pending.indexBeforeTap {
                move(by: pending.indexBeforeTap - currentIndex)
            }
            handleDoubleTapLike(at: location)
            return
        }

        pendingViewerTap = PendingViewerTap(time: now, indexBeforeTap: currentIndex)
        let nextIndex = currentIndex + delta
        if grooms.indices.contains(nextIndex) {
            // 押した瞬間に切り替える。
            move(by: delta)
        } else if delta > 0 {
            // 最後のグルームで閉じる操作だけは、ダブルタップいいねの
            // 猶予（0.3秒）を待ってから閉じる（即閉じるとダブルタップ不能になるため）。
            pendingDismissTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 320_000_000)
                guard !Task.isCancelled else {
                    return
                }
                dismissViewer()
            }
        }
    }

    private func handleDoubleTapLike(at location: CGPoint) {
        MegrumHaptics.buttonTap()
        if canReplyToCurrentGroom || isCurrentGroomMine, !isCurrentGroomLiked {
            Task {
                await appState.setGroomLiked(currentGroom.id, isLiked: true)
            }
        }
        let heart = GroomDoubleTapHeart(position: location)
        doubleTapHearts.append(heart)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            doubleTapHearts.removeAll { $0.id == heart.id }
        }
    }

    private func submitGroomReply() {
        guard let body = interactionState.replyBodyForSubmission(isSending: isSendingReply) else {
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
                interactionState.clearReplyAfterSend(succeeded: sent)
            }
        }
    }

    private func deleteCurrentGroom() {
        let target = currentGroom
        Task {
            let deleted = await appState.deleteOwnGroom(target)
            if deleted {
                dismissViewer()
            }
        }
    }
}

@MainActor
enum GroomViewerChromeLayout {
    static let chromeGapBelowObstruction: CGFloat = 10

    static func topPadding(safeAreaTop: CGFloat) -> CGFloat {
        topObstructionHeight(safeAreaTop: safeAreaTop) + chromeGapBelowObstruction
    }

    /// ステータスバー領域だけを黒帯にして、コンテンツはその直下まで表示する。
    /// `ignoresSafeArea` 済みの階層では GeometryReader の safeAreaTop が 0 に
    /// なるため、ウィンドウ実測値でフォールバックする。
    static func topObstructionHeight(safeAreaTop: CGFloat) -> CGFloat {
        max(safeAreaTop, MegrumWindowInsets.top)
    }
}

/// グルーム表示用のキャッシュ対応画像。読み込み中も直前の画像を出したままにして、
/// 切り替え時のローディング表示・表示後のガクつきをなくす。
private struct GroomViewerCachedImage: View {
    var url: URL

    #if canImport(UIKit)
    @State private var image: UIImage?
    #endif
    @State private var hasFailed = false

    var body: some View {
        ZStack {
            #if canImport(UIKit)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            } else if hasFailed {
                GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
            } else {
                ProgressView()
                    .tint(.white)
                    .controlSize(.large)
            }
            #else
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
                default:
                    ProgressView().tint(.white).controlSize(.large)
                }
            }
            #endif
        }
        #if canImport(UIKit)
        .task(id: url) {
            hasFailed = false
            do {
                let data = try await GoodsRemoteImageDataLoader.loadData(from: url)
                guard !Task.isCancelled else {
                    return
                }
                if let loaded = UIImage(data: data) {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        image = loaded
                    }
                } else if image == nil {
                    hasFailed = true
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                if image == nil {
                    hasFailed = true
                }
            }
        }
        #endif
    }
}
