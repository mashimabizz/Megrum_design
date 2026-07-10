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
    /// FB(iter1226.395)：削除で前後のグルームへ移れるよう可変にする。
    @State private var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    var onDismiss: (() -> Void)?
    var onOpenMeguriUserProfile: (UUID) -> Void = { _ in }
    /// FB(iter1226.401)：閉じる時に縮んでいく先（グルーム一覧のタイル位置など）。下スワイプ縮小の基点に使う。
    var closeAnchor: UnitPoint = .center
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentIndex: Int
    @State private var dragState = GroomViewerDragPresentationState()
    @State private var interactionState = GroomViewerInteractionState()
    @State private var isShowingComments = false
    @State private var isShowingLikes = false
    @State private var isShowingDeleteConfirmation = false
    @State private var storyProgress = 0.0
    /// FB(iter1226.403)：開くトランジション中はデータ取得・進捗ループ・常時演出を止めてカクつきを防ぐ。
    /// スケール拡大アニメ（約0.34s）が落ち着いてから重い処理を始める。
    @State private var isOpeningSettled = false
    #if canImport(UIKit)
    /// iter1226.435：投稿者切替時のキューブ回転（iter1226.438：面はUIごと描画）。
    @State private var cubeSpin: GroomViewerCubeSpin?
    @State private var cubeProgress: Double = 0
    /// iter1226.437：横スワイプで指に追従して直方体を回すインタラクティブ切替。
    @State private var cubeDrag: GroomViewerCubeDrag?
    @State private var cubeDragProgress: Double = 0
    /// ドラッグ開始時に縦（閉じる）か横（キューブ）かを固定する。
    @State private var activeDragAxis: GroomViewerDragAxis?
    /// キューブ計算に使う表示幅（viewerSurface の実測値）。
    @State private var surfaceWidth: CGFloat = 390
    #endif

    init(
        grooms: [GroomPost],
        initialGroom: GroomPost,
        appState: MegrumAppState,
        onDismiss: (() -> Void)? = nil,
        onOpenMeguriUserProfile: @escaping (UUID) -> Void = { _ in },
        closeAnchor: UnitPoint = .center
    ) {
        let base = grooms.contains(where: { $0.id == initialGroom.id })
            ? grooms
            : [initialGroom] + grooms
        // iter1226.438：投稿者ごとの「一連」にグルーピング（ブロック内は古い→新しい、iter1226.402踏襲）。
        // タップで一連を見終わってから次の投稿者へ移る（境界でキューブ回転）。
        let ordered = GroomViewerAuthorNavigation.orderedGroupingAuthors(base)
        _grooms = State(initialValue: ordered)
        self.initialGroom = initialGroom
        self.appState = appState
        self.onDismiss = onDismiss
        self.onOpenMeguriUserProfile = onOpenMeguriUserProfile
        self.closeAnchor = closeAnchor
        _currentIndex = State(initialValue: ordered.firstIndex(where: { $0.id == initialGroom.id }) ?? 0)
    }

    private var currentGroom: GroomPost {
        grooms[max(0, min(currentIndex, grooms.count - 1))]
    }

    private var isCurrentGroomLiked: Bool {
        appState.isGroomLiked(currentGroom.id)
    }

    private var canReplyToCurrentGroom: Bool {
        canReply(to: currentGroom)
    }

    private var isCurrentGroomMine: Bool {
        isMine(currentGroom)
    }

    private var isSendingReply: Bool {
        appState.sendingGroomReplyPostID == currentGroom.id
    }

    private var currentGroomLikeCount: Int {
        likeCount(for: currentGroom)
    }

    private var currentGroomCommentCount: Int {
        commentCount(for: currentGroom)
    }

    // iter1226.438：キューブの面ごとにUIを描くため、current固定だった判定をグルーム引数化。
    private func isMine(_ groom: GroomPost) -> Bool {
        groom.authorID == appState.viewer?.id
    }

    private func canReply(to groom: GroomPost) -> Bool {
        guard let viewerID = appState.viewer?.id else {
            return false
        }
        return viewerID != groom.authorID
    }

    private func likeCount(for groom: GroomPost) -> Int {
        // iter1226.428：自分のグルームはリアクション一覧の件数が主だが、
        // 取得途中や欠損時にフィードRPC由来の like_count より少なく見えないようにする。
        if isMine(groom) {
            return max(
                appState.groomReactions(for: groom.id).count,
                appState.groomLikeCount(groom.id, fallback: groom.likeCount)
            )
        }
        return appState.groomLikeCount(groom.id, fallback: groom.likeCount)
    }

    private func commentCount(for groom: GroomPost) -> Int {
        let replies = appState.groomReplies(for: groom.id)
        // コメントは投稿者本人以外には自分の送信分しか見えないため、件数も揃える。
        if isMine(groom) {
            return replies.count
        }
        guard let viewerID = appState.viewer?.id else {
            return replies.count
        }
        return replies.filter { $0.senderID == viewerID }.count
    }

    private func identity(for groom: GroomPost) -> MeguriProfileIdentity {
        appState.meguriIdentity(
            for: groom.authorID,
            fallbackName: groom.authorID == appState.viewer?.id ? appState.viewer?.displayName : nil,
            fallbackHandle: groom.authorID == appState.viewer?.id ? appState.viewer?.handle : nil,
            fallbackAvatarURL: groom.authorID == appState.viewer?.id ? appState.viewer?.avatarURL : nil
        )
    }

    private func index(of groom: GroomPost) -> Int {
        grooms.firstIndex(where: { $0.id == groom.id }) ?? currentIndex
    }

    private func toggleLike(for groom: GroomPost) {
        // いいね（ON/OFFどちらも）に触覚フィードバックを添える
        MegrumHaptics.buttonTap()
        Task {
            await appState.setGroomLiked(groom.id, isLiked: !appState.isGroomLiked(groom.id))
        }
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
        identity(for: currentGroom)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.container, edges: .top)

            viewerSurface
                .scaleEffect(viewerScale, anchor: closeAnchor)
                .offset(y: viewerVerticalOffset)
                .clipShape(RoundedRectangle(cornerRadius: viewerCornerRadius, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea(.container, edges: .top))
        .ignoresSafeArea()
        .task {
            // 開くスケールアニメ（spring 0.34s）が終わるまで待ってから重い処理を解禁する。
            try? await Task.sleep(nanoseconds: 430_000_000)
            isOpeningSettled = true
        }
        .task(id: currentGroom.id) {
            await waitUntilOpeningSettled()
            guard !Task.isCancelled else { return }
            prefetchNeighborGroomImages()
            await appState.markGroomViewed(currentGroom.id)
            // iter1226.427：表示中のグルームを取り直す（他ユーザーからのいいねを数に反映）。
            await appState.refreshGroomPostSnapshot(currentGroom.id)
            await appState.loadGroomEngagement(postIDs: [currentGroom.id], reportsFailure: false)
            await appState.loadMeguriProfiles(userIDs: [currentGroom.authorID], reportsFailure: false)
            if currentGroom.authorID != appState.viewer?.id,
               appState.publicProfilesByUserID[currentGroom.authorID] == nil {
                await appState.loadPublicUserProfile(userID: currentGroom.authorID, reportsFailure: false)
            }
        }
        .task(id: currentGroom.id) {
            await waitUntilOpeningSettled()
            guard !Task.isCancelled else { return }
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
                    #if canImport(UIKit)
                    if activeDragAxis == nil {
                        activeDragAxis = abs(value.translation.width) > abs(value.translation.height)
                            ? .horizontal
                            : .vertical
                    }
                    switch activeDragAxis {
                    case .horizontal:
                        updateCubeDrag(translationX: value.translation.width)
                    case .vertical, nil:
                        dragState.update(with: value.translation)
                    }
                    #else
                    dragState.update(with: value.translation)
                    #endif
                }
                .onEnded { value in
                    #if canImport(UIKit)
                    let axis = activeDragAxis
                    activeDragAxis = nil
                    if axis == .horizontal {
                        finishCubeDrag(
                            translationX: value.translation.width,
                            predictedTranslationX: value.predictedEndTranslation.width
                        )
                        return
                    }
                    #endif
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

    #if canImport(UIKit)
    /// 横スワイプ中：指の移動量に合わせて直方体を回す。
    /// 対象は次/前の投稿者ブロック（インスタと同じ「ユーザー単位」の切替）。
    private func updateCubeDrag(translationX: CGFloat) {
        if cubeDrag == nil {
            guard cubeSpin == nil, isOpeningSettled else {
                return
            }
            let direction = translationX < 0 ? 1 : -1
            guard let targetIndex = GroomViewerAuthorNavigation.authorSwitchTargetIndex(
                authorIDs: grooms.map(\.authorID),
                currentIndex: currentIndex,
                direction: direction
            ) else {
                return
            }
            prefetchGroomImage(at: targetIndex)
            cubeDrag = GroomViewerCubeDrag(direction: direction, targetIndex: targetIndex)
        }
        guard let cubeDrag else {
            return
        }
        let progress = GroomViewerCubeGeometry.dragProgress(
            translationX: translationX,
            direction: cubeDrag.direction,
            width: surfaceWidth
        )
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cubeDragProgress = reduceMotion ? 0 : progress
        }
    }

    /// 指を離した時：しきい値を超えていれば残りを回し切って確定、超えていなければ戻す。
    private func finishCubeDrag(translationX: CGFloat, predictedTranslationX: CGFloat) {
        guard let drag = cubeDrag else {
            return
        }
        let progress = GroomViewerCubeGeometry.dragProgress(
            translationX: translationX,
            direction: drag.direction,
            width: surfaceWidth
        )
        let predicted = GroomViewerCubeGeometry.dragProgress(
            translationX: predictedTranslationX,
            direction: drag.direction,
            width: surfaceWidth
        )
        let commits = progress > GroomViewerCubeGeometry.commitProgressThreshold
            || predicted > GroomViewerCubeGeometry.commitPredictedThreshold

        if reduceMotion {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                if commits {
                    currentIndex = drag.targetIndex
                }
                cubeDrag = nil
                cubeDragProgress = 0
            }
            return
        }

        withAnimation(.easeInOut(duration: GroomViewerCubeGeometry.settleDuration)) {
            cubeDragProgress = commits ? 1 : 0
        } completion: {
            guard cubeDrag?.id == drag.id else {
                return
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            if commits {
                withTransaction(transaction) {
                    currentIndex = drag.targetIndex
                }
                // 切替先の面（オーバーレイ）を数フレーム残し、本体の画像読み込みが
                // 追いつくのを待ってから外す（旧画像が一瞬見えるのを防ぐ）。
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 140_000_000)
                    var innerTransaction = Transaction()
                    innerTransaction.disablesAnimations = true
                    withTransaction(innerTransaction) {
                        cubeDrag = nil
                        cubeDragProgress = 0
                    }
                }
            } else {
                withTransaction(transaction) {
                    cubeDrag = nil
                    cubeDragProgress = 0
                }
            }
        }
    }

    /// 指定インデックスの画像を先読み（スワイプ開始時の切替先など）。
    private func prefetchGroomImage(at index: Int) {
        guard grooms.indices.contains(index) else {
            return
        }
        let url = grooms[index].imageURL
        Task(priority: .userInitiated) {
            await GoodsRemoteImageDataLoader.preload(urls: [url])
        }
    }
    #endif

    private var viewerSurface: some View {
        GeometryReader { proxy in
            let topPadding = GroomViewerChromeLayout.topPadding(safeAreaTop: proxy.safeAreaInsets.top)
            ZStack {
                Color.black.ignoresSafeArea(.container, edges: .top)

                #if canImport(UIKit)
                // iter1226.438：キューブの各面には画像だけでなく、ユーザー名バー・
                // いいね/コメント等のUIも張り付けたまま回す（インスタと同じ見え方）。
                if let cubeSpin {
                    groomFace(for: cubeSpin.fromGroom, topPadding: topPadding, isInteractive: false)
                        .modifier(
                            GroomViewerCubeFaceModifier(
                                transform: GroomViewerCubeGeometry.outgoing(
                                    progress: cubeProgress,
                                    direction: cubeSpin.direction,
                                    width: proxy.size.width
                                ),
                                shade: GroomViewerCubeGeometry.outgoingShade(progress: cubeProgress)
                            )
                        )
                        .allowsHitTesting(false)
                }

                groomFace(for: currentGroom, topPadding: topPadding, isInteractive: true)
                    .modifier(GroomViewerCubeFaceModifier(transform: liveFaceTransform(width: proxy.size.width), shade: liveFaceShade))

                // iter1226.437：横スワイプ中は切替先（次/前の投稿者）の面を指に追従して回し込む。
                if let cubeDrag {
                    groomFace(for: grooms[cubeDrag.targetIndex], topPadding: topPadding, isInteractive: false)
                        .modifier(
                            GroomViewerCubeFaceModifier(
                                transform: GroomViewerCubeGeometry.incoming(
                                    progress: cubeDragProgress,
                                    direction: cubeDrag.direction,
                                    width: proxy.size.width
                                ),
                                shade: GroomViewerCubeGeometry.incomingShade(progress: cubeDragProgress)
                            )
                        )
                        .allowsHitTesting(false)
                }
                #else
                groomFace(for: currentGroom, topPadding: topPadding, isInteractive: true)
                #endif

                Color.black
                    .frame(height: GroomViewerChromeLayout.topObstructionHeight(safeAreaTop: proxy.safeAreaInsets.top))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)

                // いいね演出：背景から湧くハート＋（自分のグルームなら）いいねした人のアイコン浮遊。
                // 開くトランジションが落ち着いてから開始（パーティクル更新が開閉アニメと競合しないように）。
                if isOpeningSettled {
                    GroomLikeHeartRainLayer(
                        groomID: currentGroom.id,
                        likeCount: currentGroomLikeCount
                    )
                    GroomLikeFloatingLikersLayer(
                        groomID: currentGroom.id,
                        likers: floatingLikers
                    )
                }
            }
            #if canImport(UIKit)
            .onAppear {
                surfaceWidth = proxy.size.width
            }
            .onChange(of: proxy.size.width) { _, width in
                surfaceWidth = width
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea(.container, edges: .top))
    }

    /// キューブの1面：グルーム画像＋ページ進捗＋ユーザー名バー＋いいね/コメント等のUI一式。
    /// isInteractive=false（回転中の面）はUIを見た目だけ表示する（操作は本体面のみ）。
    @ViewBuilder
    private func groomFace(for groom: GroomPost, topPadding: CGFloat, isInteractive: Bool) -> some View {
        let identity = identity(for: groom)
        ZStack {
            Color.black

            GroomViewerCachedImage(url: groom.imageURL)
                .padding(.horizontal, 8)

            if isInteractive {
                // FB(iter1226.422)：左右タップで前/次へ即遷移（ダブルタップいいねは廃止）。
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(pageTapGesture(delta: -1))

                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(pageTapGesture(delta: 1))
                }
            }

            VStack(spacing: 0) {
                GroomViewerPageIndicator(
                    totalCount: grooms.count,
                    currentIndex: index(of: groom),
                    currentProgress: groom.id == currentGroom.id ? storyProgress : 0
                )

                GroomViewerTopBar(
                    authorName: identity.displayName,
                    postTimeText: GroomPostRelativeTimeFormatter.relativeText(from: groom.createdAt),
                    authorAvatarID: identity.avatarID,
                    authorAvatarURL: identity.avatarURL,
                    canModerate: canReply(to: groom),
                    onReport: { interactionState.showReportConfirmation() },
                    onBlock: { interactionState.showBlockConfirmation() },
                    onOpenProfile: { onOpenMeguriUserProfile(groom.authorID) }
                ) {
                    dismissViewer()
                }

                Spacer()

                if isMine(groom) {
                    HStack {
                        Spacer()
                        GroomViewerOwnerBottomControls(
                            isLiked: appState.isGroomLiked(groom.id),
                            likeCount: likeCount(for: groom),
                            commentCount: commentCount(for: groom),
                            isDeleting: appState.deletingGroomPostID == groom.id,
                            onToggleLike: { toggleLike(for: groom) },
                            onOpenComments: { isShowingComments = true },
                            onOpenLikes: { isShowingLikes = true },
                            onDelete: { isShowingDeleteConfirmation = true }
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                } else {
                    GroomViewerBottomControls(
                        canReply: canReply(to: groom),
                        canLike: canReply(to: groom),
                        isSendingReply: appState.sendingGroomReplyPostID == groom.id,
                        isLiked: appState.isGroomLiked(groom.id),
                        likeCount: likeCount(for: groom),
                        commentCount: commentCount(for: groom),
                        onToggleLike: { toggleLike(for: groom) },
                        onOpenComments: { isShowingComments = true },
                        onOpenLikes: { isShowingLikes = true }
                    )
                }
            }
            .padding(.top, topPadding)
        }
    }

    #if canImport(UIKit)
    /// 本体（現在のグルーム画像）に当てるキューブ変換。
    /// スワイプ中＝出ていく面、タップ/自動送りの回転中＝入ってくる面、通常時＝恒等。
    private func liveFaceTransform(width: CGFloat) -> GroomViewerCubeGeometry.FaceTransform {
        if let cubeDrag {
            return GroomViewerCubeGeometry.outgoing(
                progress: cubeDragProgress,
                direction: cubeDrag.direction,
                width: width
            )
        }
        if let cubeSpin {
            return GroomViewerCubeGeometry.incoming(
                progress: cubeProgress,
                direction: cubeSpin.direction,
                width: width
            )
        }
        return GroomViewerCubeGeometry.FaceTransform(offsetX: 0, degrees: 0, anchorX: 0.5)
    }

    private var liveFaceShade: Double {
        if cubeDrag != nil {
            return GroomViewerCubeGeometry.outgoingShade(progress: cubeDragProgress)
        }
        if cubeSpin != nil {
            return GroomViewerCubeGeometry.incomingShade(progress: cubeProgress)
        }
        return 0
    }
    #endif

    private var isCubeDragActive: Bool {
        #if canImport(UIKit)
        cubeDrag != nil
        #else
        false
        #endif
    }

    private func move(by delta: Int) {
        let nextIndex = currentIndex + delta
        guard grooms.indices.contains(nextIndex) else {
            if delta > 0 {
                dismissViewer()
            }
            return
        }
        // iter1226.435：投稿者が変わる時だけ、Instagramストーリーズ風のキューブ回転で切り替える。
        // 同じ投稿者の連続グルームは従来どおり「パッ」と切り替え（iter1226.422）。
        let previousGroom = currentGroom
        let switchesAuthor = grooms[nextIndex].authorID != previousGroom.authorID
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentIndex = nextIndex
        }
        #if canImport(UIKit)
        if switchesAuthor, !reduceMotion, isOpeningSettled, cubeDrag == nil {
            startCubeSpin(direction: delta >= 0 ? 1 : -1, from: previousGroom)
        }
        #endif
    }

    #if canImport(UIKit)
    private func startCubeSpin(direction: Int, from previousGroom: GroomPost) {
        let spin = GroomViewerCubeSpin(fromGroom: previousGroom, direction: direction)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cubeSpin = spin
            cubeProgress = 0
        }
        withAnimation(.easeInOut(duration: GroomViewerCubeGeometry.animationDuration)) {
            cubeProgress = 1
        } completion: {
            // 連打で新しい回転が始まっていたら（idが変わる）古い完了処理は破棄。
            guard cubeSpin?.id == spin.id else {
                return
            }
            cubeSpin = nil
        }
    }
    #endif

    @MainActor
    private func runStoryProgress(for groomID: UUID) async {
        storyProgress = 0
        let steps = 200
        for step in 1...steps {
            if Task.isCancelled || currentGroom.id != groomID {
                return
            }
            // コメント・いいね一覧を開いている間と、スワイプでキューブを回している間は進捗を止める。
            while isShowingComments || isShowingLikes || isCubeDragActive {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled || currentGroom.id != groomID {
                    return
                }
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            if Task.isCancelled || currentGroom.id != groomID || !isOpeningSettled {
                // 閉じ始めたら（isOpeningSettled=false）進捗更新を止め、閉じアニメと競合させない。
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
        // 閉じるアニメ中の状態更新（進捗ループ・常時演出）を止めてカクつきを防ぐ。
        isOpeningSettled = false
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    /// 開くトランジションが落ち着つくまで待つ（重い処理・毎フレーム更新の開始ゲート）。
    private func waitUntilOpeningSettled() async {
        while !isOpeningSettled {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 40_000_000)
        }
    }

    /// FB(iter1226.422)：タップした瞬間に前/次へ切り替える（ダブルタップいいねは廃止）。
    /// 最後のグルームで右タップしたら即閉じる。
    private func pageTapGesture(delta: Int) -> some Gesture {
        TapGesture()
            .onEnded {
                let nextIndex = currentIndex + delta
                if grooms.indices.contains(nextIndex) {
                    move(by: delta)
                } else if delta > 0 {
                    dismissViewer()
                }
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
        let targetIndex = currentIndex
        Task {
            let deleted = await appState.deleteOwnGroom(target)
            guard deleted else { return }
            // FB(iter1226.395)：削除しても閉じず、前後のグルームへ移る（無くなったら閉じる）。
            guard let removeAt = grooms.firstIndex(where: { $0.id == target.id }) ?? Optional(targetIndex),
                  grooms.indices.contains(removeAt)
            else {
                dismissViewer()
                return
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                grooms.remove(at: removeAt)
                if grooms.isEmpty {
                    dismissViewer()
                } else {
                    // 削除位置がそのまま「次のグルーム」を指す。末尾だった場合は1つ前へ。
                    currentIndex = min(removeAt, grooms.count - 1)
                }
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

#if canImport(UIKit)
/// iter1226.435：投稿者切替キューブ回転の1回ぶんの状態。
/// iter1226.438：面にはUIごと張り付けるため、画像スナップではなく直前のグルーム自体を持つ。
struct GroomViewerCubeSpin {
    var fromGroom: GroomPost
    var direction: Int
    var id = UUID()
}

/// iter1226.437：横スワイプで指に追従して回すキューブの状態。
struct GroomViewerCubeDrag {
    var direction: Int
    var targetIndex: Int
    var id = UUID()
}

/// ドラッグの軸ロック（縦=閉じる／横=キューブ回転）。
enum GroomViewerDragAxis {
    case horizontal
    case vertical
}

#endif

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
                    // FB(iter1226.403)：デコードを表示前に済ませる（初回描画時のメインスレッドデコードで
                    // 開くアニメがカクつくのを防ぐ）。
                    let prepared = await loaded.byPreparingForDisplay() ?? loaded
                    guard !Task.isCancelled else { return }
                    // ページ切替はフェードさせず「パッ」と切り替える（デジタルな切替）。
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        image = prepared
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
