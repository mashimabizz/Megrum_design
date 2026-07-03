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
    @State private var currentIndex: Int
    @State private var dragState = GroomViewerDragPresentationState()
    @State private var interactionState = GroomViewerInteractionState()
    @State private var isShowingOwnInsights = false
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
        appState.groomReplies(for: currentGroom.id).count
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
                .ignoresSafeArea()

            viewerSurface
                .offset(y: viewerVerticalOffset)
                .scaleEffect(viewerScale)
                .clipShape(RoundedRectangle(cornerRadius: viewerCornerRadius, style: .continuous))
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea()
        .task(id: currentGroom.id) {
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
        .sheet(isPresented: $isShowingOwnInsights) {
            GroomArchiveInsightsSheet(groom: currentGroom, appState: appState)
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
        #if os(iOS)
        .statusBarHidden(true)
        #endif
    }

    private var viewerSurface: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                AsyncImage(url: currentGroom.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .id(currentGroom.id)
                    case .failure:
                        GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
                    default:
                        ProgressView()
                            .tint(.white)
                            .controlSize(.large)
                    }
                }
                .padding(.horizontal, 8)

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

                Color.black
                    .frame(height: GroomViewerChromeLayout.topObstructionHeight(safeAreaTop: proxy.safeAreaInsets.top))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)

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
                                likeCount: currentGroomLikeCount,
                                commentCount: currentGroomCommentCount,
                                isDeleting: appState.deletingGroomPostID == currentGroom.id,
                                onOpenInsights: { isShowingOwnInsights = true },
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
                            onSubmitReply: submitGroomReply,
                            onToggleLike: toggleCurrentGroomLike,
                            replyDraft: $interactionState.replyDraft
                        )
                    }
                }
                .padding(.top, GroomViewerChromeLayout.topPadding(safeAreaTop: proxy.safeAreaInsets.top))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
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

    private func dismissViewer() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func toggleCurrentGroomLike() {
        Task {
            await appState.setGroomLiked(currentGroom.id, isLiked: !isCurrentGroomLiked)
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

enum GroomViewerChromeLayout {
    static let minimumTopObstructionHeight: CGFloat = 76
    static let chromeGapBelowObstruction: CGFloat = 10

    static func topPadding(safeAreaTop: CGFloat) -> CGFloat {
        topObstructionHeight(safeAreaTop: safeAreaTop) + chromeGapBelowObstruction
    }

    static func topObstructionHeight(safeAreaTop: CGFloat) -> CGFloat {
        max(minimumTopObstructionHeight, safeAreaTop)
    }
}
