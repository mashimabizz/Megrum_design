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
    /// iter1226.449：ユーザー名タップで、グルームを閉じずに上へ重ねて開くプロフィール。
    /// 表示中は story 進捗を一時停止し、閉じたら続行する。
    @State private var profileSheetRoute: MeguriUserProfileRoute?
    /// iter1226.449：他人のグルーム最下部のメッセージ入力（インスタのストーリー返信風）。
    @State private var messageDraft = ""
    /// 入力モード（UITextField の first responder を双方向で制御。上スワイプ・タップで true）。
    @State private var isMessageFieldFocused = false
    /// iter1226.451：非プレミアムでメッセージ入力しようとした時のプレミアム案内。
    @State private var isShowingMessagePremiumSheet = false
    /// iter1226.451：送信完了トースト。
    @State private var showsSentToast = false
    /// iter1226.449：ビューアは `.ignoresSafeArea()` で SwiftUI の自動キーボード回避が
    /// 効かないため、キーボード高さを自前で観測して入力欄を持ち上げる。
    @State private var keyboardHeight: CGFloat = 0
    @State private var storyProgress = 0.0
    /// FB(iter1226.403)：開くトランジション中はデータ取得・進捗ループ・常時演出を止めてカクつきを防ぐ。
    /// スケール拡大アニメ（約0.34s）が落ち着いてから重い処理を始める。
    @State private var isOpeningSettled = false
    /// iter1226.448：ホスト（没入オーバーレイ）の開くスプリング完了通知。
    /// 準備待ちで開始が遅れても「本当に開き終わってから」重い処理を解禁できる。
    /// nil はホスト以外の提示で、従来のタイマーへフォールバックする。
    @Environment(\.megrumGroomViewerOpenSettled) private var hostOpenSettled: Bool?
    /// iter1226.441：押下即発火タップの進行状態（isConsumed=発火済み or ドラッグへ移行）。
    @State private var activePageTap: PageTapTouch?
    #if canImport(UIKit)
    /// iter1226.467：投稿者切替のキューブ回転を、タップ・スワイプ・自動送りで
    /// 共通化した統一遷移状態。source/target の実ビューを回し、完了時にだけ
    /// currentIndex を commit する（回転前の index 変更・全画面ラスタライズを排除）。
    @State private var cubeTransition: GroomViewerCubeTransition?
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
        let grouped = GroomViewerAuthorNavigation.orderedGroupingAuthors(base)
        // iter1226.439：他ユーザーの閲覧中に自分のグルームが一連へ混ざらないようにスコープする。
        // 自分のグルームを開いた時は従来どおり自分の一連だけ（iter1226.402）。
        let viewerID = appState.viewer?.id
        let ordered: [GroomPost]
        if let viewerID, initialGroom.authorID == viewerID {
            ordered = grouped.filter { $0.authorID == viewerID }
        } else if let viewerID {
            ordered = grouped.filter { $0.authorID != viewerID }
        } else {
            ordered = grouped
        }
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
        .overlay {
            // iter1226.451：送信完了トースト（中央・グレー背景・白文字）。
            if showsSentToast {
                GroomMessageSentToast()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .groomOpenMetricsProbe("screen")
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = UIScreen.main.bounds.height
            withAnimation(.easeOut(duration: 0.24)) {
                keyboardHeight = max(0, screenHeight - frame.origin.y)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.24)) {
                keyboardHeight = 0
            }
        }
        #endif
        .onChange(of: hostOpenSettled) { _, settled in
            // iter1226.448：ホストの開くスプリング完了と正確に同期して重い処理を解禁する。
            if settled == true, !isOpeningSettled {
                isOpeningSettled = true
                GroomOpenMetricsLog.emit("screen", "openingSettled(host)")
            }
        }
        .task {
            // ホスト以外の提示（fullScreenCover等）向けフォールバック：
            // 開くアニメ（spring 0.34s）相当を待ってから重い処理を解禁する。
            guard hostOpenSettled == nil else {
                if hostOpenSettled == true {
                    isOpeningSettled = true
                }
                return
            }
            try? await Task.sleep(nanoseconds: 430_000_000)
            guard hostOpenSettled == nil else { return }
            isOpeningSettled = true
            GroomOpenMetricsLog.emit("screen", "openingSettled(timer)")
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
        // iter1226.451：非プレミアムがメッセージを送ろうとした時のプレミアム案内。
        .sheet(isPresented: $isShowingMessagePremiumSheet) {
            GroomMessageLockedPremiumSheet(onClose: { isShowingMessagePremiumSheet = false })
        }
        // iter1226.449：ユーザー名タップ→グルームを閉じずに上へ重ねてプロフィール表示。
        // sheet はグルームの上に載り、閉じると story 進捗が続行する（pause 条件で停止済み）。
        .sheet(item: $profileSheetRoute) { route in
            NavigationStack {
                MeguriUserProfileRouteScreen(
                    appState: appState,
                    userID: route.userID,
                    onClose: { profileSheetRoute = nil },
                    onOpenMessage: { userID in
                        profileSheetRoute = nil
                        // プロフィールを閉じてから、そのユーザー宛のメッセージ入力へフォーカス。
                        if userID == currentGroom.authorID {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                isMessageFieldFocused = true
                            }
                        }
                    }
                )
            }
        }
        // iter1226.442：タップゾーン側の DragGesture(minimumDistance:0) が子ビューで先に
        // タッチを取り、この外側ジェスチャが発火しなくなるため simultaneous で共存させる。
        // （タップ側は12pt以上動いたら自分を取り消してこちらに譲る）
        .simultaneousGesture(
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
                    // iter1226.451：上スワイプでメッセージ入力モードへ（他人グルームのみ）。
                    if value.translation.height < -60,
                       abs(value.translation.height) > abs(value.translation.width),
                       !isMine(currentGroom) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            dragState.reset()
                        }
                        enterMessageInput()
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
    /// 横スワイプ中：指の移動量に合わせて直方体を回す（iter1226.467：統一遷移状態）。
    /// 対象は次/前の投稿者ブロック（インスタと同じ「ユーザー単位」の切替）。
    private func updateCubeDrag(translationX: CGFloat) {
        if cubeTransition == nil {
            guard isOpeningSettled else {
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
            cubeTransition = GroomViewerCubeTransition(
                sourceIndex: currentIndex,
                targetIndex: targetIndex,
                direction: direction,
                progress: 0,
                origin: .gesture
            )
        }
        // タップ/自動送りの回転中に横ドラッグが来ても更新しない（直列化）。
        guard let transition = cubeTransition, transition.origin == .gesture else {
            return
        }
        let progress = GroomViewerCubeGeometry.dragProgress(
            translationX: translationX,
            direction: transition.direction,
            width: surfaceWidth
        )
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cubeTransition?.progress = reduceMotion ? 0 : progress
        }
    }

    /// 指を離した時：しきい値を超えていれば残りを回し切って確定、超えていなければ戻す。
    private func finishCubeDrag(translationX: CGFloat, predictedTranslationX: CGFloat) {
        guard let transition = cubeTransition, transition.origin == .gesture else {
            return
        }
        let progress = GroomViewerCubeGeometry.dragProgress(
            translationX: translationX,
            direction: transition.direction,
            width: surfaceWidth
        )
        let predicted = GroomViewerCubeGeometry.dragProgress(
            translationX: predictedTranslationX,
            direction: transition.direction,
            width: surfaceWidth
        )
        let commits = GroomViewerCubeTransitionPlanner.swipeCommits(progress: progress, predicted: predicted)

        if reduceMotion {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                if commits {
                    currentIndex = transition.targetIndex
                }
                cubeTransition = nil
            }
            return
        }

        withAnimation(.easeInOut(duration: GroomViewerCubeGeometry.settleDuration)) {
            cubeTransition?.progress = commits ? 1 : 0
        } completion: {
            guard cubeTransition?.id == transition.id else {
                return
            }
            if commits {
                // 完了：アニメーション無しの同一 Transaction で currentIndex を確定し遷移を解除。
                // source/target とも実ビュー（キャッシュ済み画像）なので旧画像のチラつきは出ない。
                commitCubeTransition(transition)
            } else {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    cubeTransition = nil
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
                // iter1226.467：出ていく面（source＝現在のグルーム）を実ビューのまま回す
                //（スナップショット廃止）。回転中でなければ恒等変換で通常表示。
                // 面には画像だけでなくユーザー名バー・いいね/コメント等のUIも張り付く。
                groomFace(for: currentGroom, topPadding: topPadding, isInteractive: true)
                    .groomOpenMetricsProbe("face")
                    .modifier(GroomViewerCubeFaceModifier(transform: liveFaceTransform(width: proxy.size.width), shade: liveFaceShade))

                // 入ってくる面（target）：タップ・スワイプ・自動送りいずれも同じ実ビューを回し込む。
                if let transition = cubeTransition, grooms.indices.contains(transition.targetIndex) {
                    groomFace(for: grooms[transition.targetIndex], topPadding: topPadding, isInteractive: false)
                        .modifier(
                            GroomViewerCubeFaceModifier(
                                transform: GroomViewerCubeGeometry.incoming(
                                    progress: transition.progress,
                                    direction: transition.direction,
                                    width: proxy.size.width
                                ),
                                shade: GroomViewerCubeGeometry.incomingShade(progress: transition.progress)
                            )
                        )
                        .allowsHitTesting(false)
                }
                #else
                groomFace(for: currentGroom, topPadding: topPadding, isInteractive: true)
                #endif

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
            .groomOpenMetricsProbe("surface")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea(.container, edges: .top))
    }

    /// iter1226.453：画像を入力欄/コントロール手前で止めるための下インセット。
    /// 他人グルーム＝メッセージ入力欄の高さ、自分グルーム＝下端の小さめ余白。
    private func imageBottomInset(for groom: GroomPost) -> CGFloat {
        #if canImport(UIKit)
        let safeBottom = MegrumWindowInsets.bottom
        return isMine(groom) ? safeBottom + 20 : safeBottom + 62
        #else
        return 0
        #endif
    }

    /// キューブの1面：グルーム画像＋ページ進捗＋ユーザー名バー＋いいね/コメント等のUI一式。
    /// isInteractive=false（回転中の面）はUIを見た目だけ表示する（操作は本体面のみ）。
    @ViewBuilder
    private func groomFace(for groom: GroomPost, topPadding: CGFloat, isInteractive: Bool) -> some View {
        let identity = identity(for: groom)
        ZStack {
            Color.black

            // iter1226.453：画像はステータスバー「手前まで」＋メッセージ入力欄「手前まで」に収める
            //（ステータスバー領域・入力欄領域には画像を出さない＝インスタのストーリーと同じ）。
            // 合成キャンバスは9:16なので、この上下インセットを引いた領域にちょうど収まる。
            GroomViewerCachedImage(url: groom.imageURL)
                .groomOpenMetricsProbe(isInteractive ? "photo" : "photo-aux")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, MegrumWindowInsets.top)
                .padding(.bottom, imageBottomInset(for: groom))

            // iter1226.450：上部（ステータスバー〜ユーザー名）に薄いダークグラデ。
            // 明るい画像でも名前・時刻が読めるように、名前より奥（chromeより下）に敷く。
            LinearGradient(
                colors: [.black.opacity(0.55), .black.opacity(0.16), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: topPadding + 64)
            .frame(maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
            .ignoresSafeArea(.container, edges: .top)

            // iter1226.450：下部（いいね/メニュー〜メッセージ入力）にも薄いダークグラデ。
            // フルブリードで明るい画像でも、白いアイコン・入力欄が沈まないように奥へ敷く。
            LinearGradient(
                colors: [.clear, .black.opacity(0.22), .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
            .ignoresSafeArea(.container, edges: .bottom)

            #if canImport(UIKit)
            // iter1226.451：メッセージ入力フォーカス中は画像を薄暗くする（タップで解除）。
            // 暗転は「徐々にフェードイン（0.38s）」、解除は「素早くフェードアウト（0.12s）」の非対称。
            if isInteractive {
                Color.black
                    .opacity(isMessageFieldFocused ? 0.55 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(isMessageFieldFocused)
                    .contentShape(Rectangle())
                    .onTapGesture { isMessageFieldFocused = false }
                    .animation(
                        isMessageFieldFocused ? .easeIn(duration: 0.38) : .easeOut(duration: 0.12),
                        value: isMessageFieldFocused
                    )
            }
            #endif

            if isInteractive, !isMessageFieldFocused {
                // FB(iter1226.422)：左右タップで前/次へ即遷移（ダブルタップいいねは廃止）。
                // iter1226.441：外側のスワイプ（回転/閉じる）と共存させるため simultaneous にする。
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .simultaneousGesture(pageTapGesture(delta: -1))

                    Color.clear
                        .contentShape(Rectangle())
                        .simultaneousGesture(pageTapGesture(delta: 1))
                }
            }

            VStack(spacing: 0) {
                // iter1226.439：進捗バーは「その投稿者の一連（この一覧で見られる数）」だけで分割する。
                let groomIndex = index(of: groom)
                let blockRange = GroomViewerAuthorNavigation.authorBlockRange(
                    authorIDs: grooms.map(\.authorID),
                    currentIndex: groomIndex
                )
                GroomViewerPageIndicator(
                    totalCount: blockRange.count,
                    currentIndex: groomIndex - blockRange.lowerBound,
                    currentProgress: groom.id == currentGroom.id ? storyProgress : 0
                )

                GroomViewerTopBar(
                    authorName: identity.displayName,
                    postTimeText: GroomPostRelativeTimeFormatter.relativeText(from: groom.createdAt),
                    authorAvatarID: identity.avatarID,
                    authorAvatarURL: identity.avatarURL,
                    onOpenProfile: { profileSheetRoute = MeguriUserProfileRoute(userID: groom.authorID) }
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
                    // iter1226.450：他人のグルームは「いいね/メニュー列」の下に、
                    // インスタのストーリー返信風メッセージ入力を積む（同じ VStack 内なので
                    // 立方体回転にも追従する）。操作できるのは本体面のみ。
                    VStack(spacing: 6) {
                        GroomViewerBottomControls(
                            canLike: canReply(to: groom),
                            isLiked: appState.isGroomLiked(groom.id),
                            likeCount: likeCount(for: groom),
                            onToggleLike: { toggleLike(for: groom) },
                            onOpenLikes: { isShowingLikes = true },
                            onReport: { interactionState.showReportConfirmation() },
                            onBlock: { interactionState.showBlockConfirmation() }
                        )

                        #if canImport(UIKit)
                        Group {
                            // iter1226.454：開閉zoom遷移の最中は UITextField(UIViewRepresentable) が
                            // 変形に追従せずズレて描画されるため、遷移が落ち着くまで静的ピルを出す。
                            if isInteractive, isOpeningSettled {
                                GroomViewerMessageComposer(
                                    canSend: appState.subscriptionState.hasMeguriMessageAccess,
                                    text: $messageDraft,
                                    isFocused: $isMessageFieldFocused,
                                    isSending: appState.sendingGroomReplyPostID == groom.id,
                                    onSend: { sendGroomMessage(to: groom) },
                                    onBlockedTap: { isShowingMessagePremiumSheet = true }
                                )
                            } else {
                                GroomViewerMessageComposerStatic()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, isInteractive && keyboardHeight > 0 ? keyboardHeight : MegrumWindowInsets.bottom)
                        #endif
                    }
                }
            }
            .padding(.top, topPadding)
        }
    }

    #if canImport(UIKit)
    /// 本体（source＝現在のグルーム）に当てるキューブ変換。
    /// 回転中は「出ていく面」、通常時は恒等（iter1226.467：タップ/スワイプ/自動送り共通）。
    private func liveFaceTransform(width: CGFloat) -> GroomViewerCubeGeometry.FaceTransform {
        if let transition = cubeTransition {
            return GroomViewerCubeGeometry.outgoing(
                progress: transition.progress,
                direction: transition.direction,
                width: width
            )
        }
        return GroomViewerCubeGeometry.FaceTransform(offsetX: 0, degrees: 0, anchorX: 0.5)
    }

    private var liveFaceShade: Double {
        if let transition = cubeTransition {
            return GroomViewerCubeGeometry.outgoingShade(progress: transition.progress)
        }
        return 0
    }
    #endif

    /// 進捗一時停止の判定に使う「キューブ回転中」フラグ（iter1226.467：全遷移に拡大）。
    private var isCubeTransitionActive: Bool {
        #if canImport(UIKit)
        cubeTransition != nil
        #else
        false
        #endif
    }

    /// タップ／自動送りで前後のグルームへ移る（iter1226.467：統一遷移＋直列化）。
    /// 投稿者境界では「currentIndex を変えずに回転→完了時に commit」する。
    private func move(by delta: Int, origin: GroomViewerCubeTransition.Origin = .tap) {
        #if canImport(UIKit)
        let decision = GroomViewerCubeTransitionPlanner.decideMove(
            authorIDs: grooms.map(\.authorID),
            currentIndex: currentIndex,
            delta: delta,
            reduceMotion: reduceMotion,
            isOpeningSettled: isOpeningSettled,
            hasActiveTransition: cubeTransition != nil
        )
        switch decision {
        case .ignore:
            return
        case .dismiss:
            dismissViewer()
        case .immediate(let index):
            commitIndexImmediately(index)
        case .transition(let source, let target, let direction):
            startCubeTransition(source: source, target: target, direction: direction, origin: origin)
        }
        #else
        let nextIndex = currentIndex + delta
        guard grooms.indices.contains(nextIndex) else {
            if delta > 0 {
                dismissViewer()
            }
            return
        }
        currentIndex = nextIndex
        #endif
    }

    #if canImport(UIKit)
    /// 同一投稿者・Reduce Motion・未settled：アニメーション無しで即切替。
    private func commitIndexImmediately(_ index: Int) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentIndex = index
        }
    }

    /// タップ／自動送りのキューブ回転を開始する（source/target とも実ビュー）。
    /// currentIndex は変えず、progress を 0→1 へアニメーションし、完了時に commit する。
    private func startCubeTransition(
        source: Int,
        target: Int,
        direction: Int,
        origin: GroomViewerCubeTransition.Origin
    ) {
        // 切替先画像を先読み（ネットワーク完了は待たず、タップ応答を遅らせない）。
        prefetchGroomImage(at: target)

        let transition = GroomViewerCubeTransition(
            sourceIndex: source,
            targetIndex: target,
            direction: direction,
            progress: 0,
            origin: origin
        )
        var startTransaction = Transaction()
        startTransaction.disablesAnimations = true
        withTransaction(startTransaction) {
            cubeTransition = transition
        }
        // iter1226.441：出だしを最速に（easeOut）。押した瞬間から回り始める体感。
        withAnimation(.easeOut(duration: GroomViewerCubeGeometry.animationDuration)) {
            cubeTransition?.progress = 1
        } completion: {
            commitCubeTransition(transition)
        }
    }

    /// 回転完了：アニメーション無しの同一 Transaction で currentIndex を確定し遷移を解除する。
    /// 連打で新しい遷移が始まっていたら（id が変わる）古い完了処理は破棄する。
    private func commitCubeTransition(_ transition: GroomViewerCubeTransition) {
        guard cubeTransition?.id == transition.id else {
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentIndex = transition.targetIndex
            cubeTransition = nil
        }
    }
    #endif

    @MainActor
    private func runStoryProgress(for groomID: UUID) async {
        storyProgress = 0
        // iter1226.450：進捗バーを「もっと細かく」動かす。30fps（約33ms刻み）で更新し、
        // 1グルームあたり約7秒で満ちる（従来は100ms刻み・20秒で、動きが粗く止まって見えた）。
        let totalDuration: Double = 7.0
        let tickSeconds: Double = 1.0 / 30.0
        let steps = max(1, Int((totalDuration / tickSeconds).rounded()))
        let tickNanos = UInt64(tickSeconds * 1_000_000_000)
        for step in 1...steps {
            if Task.isCancelled || currentGroom.id != groomID {
                return
            }
            // コメント・いいね一覧・プロフィール重ね表示・メッセージ入力中と、
            // キューブ回転中（タップ/スワイプ/自動送り）は進捗を止める（iter1226.449 / iter1226.467）。
            while isShowingComments || isShowingLikes || isCubeTransitionActive
                || profileSheetRoute != nil || isMessageFieldFocused {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled || currentGroom.id != groomID {
                    return
                }
            }
            try? await Task.sleep(nanoseconds: tickNanos)
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
        move(by: 1, origin: .automatic)
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

    /// FB(iter1226.422)：タップで前/次へ切り替える（ダブルタップいいねは廃止）。
    /// iter1226.441：指を離すのを待たず「押した瞬間」に発火する。
    /// タッチ開始から短い猶予（90ms）で発火し、その間に指が動き出したら（スワイプ/閉じる
    /// ドラッグへ移行したら）取り消す。素早いタップは離した瞬間に即発火。
    private func pageTapGesture(delta: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let distance = hypot(value.translation.width, value.translation.height)
                if activePageTap == nil {
                    let id = UUID()
                    activePageTap = PageTapTouch(id: id)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 90_000_000)
                        guard let current = activePageTap, current.id == id, !current.isConsumed else {
                            return
                        }
                        activePageTap = PageTapTouch(id: id, isConsumed: true)
                        performPageTap(delta: delta)
                    }
                } else if distance > 12, let current = activePageTap, !current.isConsumed {
                    // ドラッグへ移行：タップ扱いを取り消す（回転/閉じるスワイプ側が処理する）。
                    activePageTap = PageTapTouch(id: current.id, isConsumed: true)
                }
            }
            .onEnded { value in
                defer {
                    activePageTap = nil
                }
                guard let current = activePageTap, !current.isConsumed else {
                    return
                }
                guard hypot(value.translation.width, value.translation.height) <= 12 else {
                    return
                }
                performPageTap(delta: delta)
            }
    }

    private func performPageTap(delta: Int) {
        // 範囲判定・末尾での閉じる・回転中の直列化は move(by:) 内の planner に委譲する（iter1226.467）。
        move(by: delta)
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

    /// iter1226.449：他人グルーム最下部の入力からメッセージ（グルーム返信＝著者へのDM）を送る。
    private func sendGroomMessage(to groom: GroomPost) {
        let body = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isMine(groom) else { return }
        // iter1226.451：グルームのメッセージ送信はプレミアム必須。
        guard appState.subscriptionState.hasMeguriMessageAccess else {
            isMessageFieldFocused = false
            isShowingMessagePremiumSheet = true
            return
        }
        guard appState.sendingGroomReplyPostID != groom.id else { return }
        Task {
            let sent = await appState.sendGroomReply(
                postID: groom.id,
                recipientID: groom.authorID,
                body: body,
                groomImageURL: groom.imageURL
            )
            if sent {
                messageDraft = ""
                isMessageFieldFocused = false
                showSentToast()
            }
        }
    }

    /// iter1226.451：メッセージ入力モードへ入る（プレミアムなら入力、そうでなければ案内）。
    private func enterMessageInput() {
        guard !isMine(currentGroom) else { return }
        if appState.subscriptionState.hasMeguriMessageAccess {
            isMessageFieldFocused = true
        } else {
            isShowingMessagePremiumSheet = true
        }
    }

    /// iter1226.451：送信完了トーストを一定時間表示する。
    private func showSentToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            showsSentToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(.easeIn(duration: 0.3)) {
                showsSentToast = false
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
        // iter1226.454：進捗バー・ユーザー名を画面上部ぎりぎり（ステータスバー直下）へ。
        // 以前は「セーフエリア＋10pt」で下がり過ぎていた。Dynamic Island の下端付近まで上げる。
        max(0, topObstructionHeight(safeAreaTop: safeAreaTop) - 6)
    }

    /// ステータスバー領域だけを黒帯にして、コンテンツはその直下まで表示する。
    /// `ignoresSafeArea` 済みの階層では GeometryReader の safeAreaTop が 0 に
    /// なるため、ウィンドウ実測値でフォールバックする。
    static func topObstructionHeight(safeAreaTop: CGFloat) -> CGFloat {
        max(safeAreaTop, MegrumWindowInsets.top)
    }
}

/// iter1226.441：押下即発火タップの1タッチぶんの状態。
struct PageTapTouch {
    var id: UUID
    var isConsumed = false
}

#if canImport(UIKit)
/// ドラッグの軸ロック（縦=閉じる／横=キューブ回転）。
enum GroomViewerDragAxis {
    case horizontal
    case vertical
}

#endif

#if canImport(UIKit)
/// グルーム写真のデコード済みメモリキャッシュ（iter1226.441 / iter1226.446 キー正規化）。
/// ビューアを開く前（ホームのレール表示時）に先読みしておき、開いた最初の
/// フレームから写真ごと拡大できるようにする（枠と中身が別々に出るのを防ぐ）。
///
/// iter1226.446：キーは署名付きURL全体ではなく**ストレージパスへ正規化**する。
/// 署名トークンはフィード再取得（位置更新等）のたびに回転するため、URL全体を
/// キーにすると実機（移動中）ではほぼ毎回キャッシュミスになり、ビューアを
/// 開き終わった直後に写真がポップインして「ガクッ」と見えていた。
@MainActor
final class GroomImageMemoryStore {
    static let shared = GroomImageMemoryStore()
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 80
    }

    static func cacheKey(for url: URL) -> NSString {
        (GroomSignedURLPathExtractor.storagePath(from: url) ?? url.absoluteString) as NSString
    }

    /// 検証用：実機で起きる「未キャッシュで開く」状態をシミュレータで再現する
    /// （キーごとに最初の1回だけミスさせる。prewarm も無効化する）。
    nonisolated static var simulatesColdImages: Bool {
        ProcessInfo.processInfo.environment["MEGRUM_VISUAL_QA_COLD_IMAGES"] == "1"
    }

    private var coldMissSimulatedKeys = Set<NSString>()

    /// iter1226.448：進行中ダウンロードの共有テーブル。
    /// 以前は「開く準備待ち（ensureLoaded）」と「表示ビュー（GroomViewerCachedImage）」が
    /// 同じ画像を**別々に**ダウンロードしており、実機では (1) 帯域を食い合って遅延が倍増し
    /// 準備待ちがタイムアウト、(2) 準備待ち側が先に完了しても表示ビューは自分のDL完了まで
    /// スピナーのまま、という「枠だけ開いて写真が後からポップイン」の直接原因だった。
    private var inFlightLoads: [NSString: Task<UIImage?, Never>] = [:]

    func image(for url: URL) -> UIImage? {
        let key = Self.cacheKey(for: url)
        if Self.simulatesColdImages, !coldMissSimulatedKeys.contains(key) {
            coldMissSimulatedKeys.insert(key)
            return nil
        }
        return cache.object(forKey: key)
    }

    /// 画像をキャッシュ経由で取得する。未キャッシュなら1本だけダウンロードを走らせ、
    /// 同一画像への同時要求（開く準備待ち・表示ビュー・先読み）は全て同じ結果を待つ。
    func loadedImage(for url: URL) async -> UIImage? {
        if let hit = image(for: url) {
            return hit
        }
        let key = Self.cacheKey(for: url)
        if let inFlight = inFlightLoads[key] {
            return await inFlight.value
        }
        // iter1226.448：デコードはメインアクターから切り離す。起動直後の一斉先読みで
        // メインスレッドがデコード占有され、開くアニメの開始・タイムアウトまで
        // 巻き添えで遅延していた（実機計測で確認）。
        let load = Task.detached(priority: .userInitiated) { () -> UIImage? in
            if Self.simulatesColdImages {
                // 実機のネットワーク遅延を模擬
                try? await Task.sleep(nanoseconds: 450_000_000)
            }
            guard let data = try? await GoodsRemoteImageDataLoader.loadData(from: url),
                  let loaded = UIImage(data: data)
            else {
                return nil
            }
            return await loaded.byPreparingForDisplay() ?? loaded
        }
        inFlightLoads[key] = load
        let prepared = await load.value
        inFlightLoads[key] = nil
        if let prepared {
            cache.setObject(prepared, forKey: key)
        }
        return prepared
    }

    /// 指定URLの画像がキャッシュ済みになるまで読み込む（開くアニメーションの準備待ちに使う）。
    /// タイムアウトしたら false（呼び出し側はスピナー付きで開く）。
    func ensureLoaded(url: URL, timeoutNanoseconds: UInt64) async -> Bool {
        if image(for: url) != nil {
            return true
        }
        let loadTask = Task { @MainActor () -> Bool in
            await self.loadedImage(for: url) != nil
        }
        let timeoutTask = Task { () -> Bool in
            try? await Task.sleep(nanoseconds: timeoutNanoseconds)
            return false
        }
        defer {
            timeoutTask.cancel()
        }
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask { await loadTask.value }
            group.addTask { await timeoutTask.value }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: Self.cacheKey(for: url))
    }

    /// 未キャッシュのURLを並列に読み込み・デコードして格納する（ベストエフォート）。
    /// iter1226.448：共有ロード（in-flight合流）経由にし、開く準備待ち・表示ビューと
    /// 同じ画像を重複ダウンロードしない。
    func prewarm(urls: [URL]) async {
        guard !Self.simulatesColdImages else {
            return
        }
        let missing = urls.filter { cache.object(forKey: Self.cacheKey(for: $0)) == nil }
        guard !missing.isEmpty else {
            return
        }
        // 各 loadedImage は in-flight 表へ登録した自前の Task で並列に走るため、
        // ここは起動→合流の順で待つだけでよい。
        let loads = missing.map { url in
            Task { _ = await self.loadedImage(for: url) }
        }
        for load in loads {
            _ = await load.value
        }
    }
}
#endif

/// グルーム表示用のキャッシュ対応画像。読み込み中も直前の画像を出したままにして、
/// 切り替え時のローディング表示・表示後のガクつきをなくす。
private struct GroomViewerCachedImage: View {
    var url: URL

    #if canImport(UIKit)
    @State private var image: UIImage?

    init(url: URL) {
        self.url = url
        // iter1226.441：デコード済みキャッシュがあれば最初のフレームから同期表示する。
        _image = State(initialValue: GroomImageMemoryStore.shared.image(for: url))
    }
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
            // iter1226.446：署名URLが回転してもストレージパスが同じなら
            // デコード済みキャッシュから即表示し、再ダウンロードしない。
            if let cached = GroomImageMemoryStore.shared.image(for: url) {
                if image !== cached {
                    GroomOpenMetricsLog.emit("image", "store-hit size=\(Int(cached.size.width))x\(Int(cached.size.height))")
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        image = cached
                    }
                }
                return
            }
            GroomOpenMetricsLog.emit("image", "store-miss shared-load-start")
            // iter1226.448：自前ダウンロードをやめ、ストアの共有ロードに合流する。
            // 開く準備待ち（ensureLoaded）が先に取得した画像を、待ち合わせ無しでそのまま使う。
            let loaded = await GroomImageMemoryStore.shared.loadedImage(for: url)
            guard !Task.isCancelled else {
                return
            }
            if let loaded {
                GroomOpenMetricsLog.emit("image", "shared-load-set size=\(Int(loaded.size.width))x\(Int(loaded.size.height))")
                // ページ切替はフェードさせず「パッ」と切り替える（デジタルな切替）。
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    image = loaded
                }
            } else if image == nil {
                hasFailed = true
            }
        }
        #endif
    }
}

// MARK: - 開くトランジションの実機計測（iter1226.448 調査用）

/// `MEGRUM_DEBUG_GROOM_OPEN_METRICS=1` で、開くトランジション前後のレイアウト矩形の
/// 変化をタイムスタンプ付きで stdout へ出す。実機で「開き終わった瞬間のガクッ」を
/// 直接観測するための計測フックで、通常実行では完全に無効。
enum GroomOpenMetricsLog {
    static let isEnabled: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.environment["MEGRUM_DEBUG_GROOM_OPEN_METRICS"] == "1"
        #else
        false
        #endif
    }()

    static func emit(_ label: String, _ message: String) {
        guard isEnabled else { return }
        print(String(format: "[GroomOpenMetrics] t=%.3f %@ %@", ProcessInfo.processInfo.systemUptime, label, message))
    }
}

struct GroomOpenMetricsProbe: ViewModifier {
    var label: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if GroomOpenMetricsLog.isEnabled {
            content.background(
                GeometryReader { g in
                    let frame = g.frame(in: .global)
                    let safeTop = g.safeAreaInsets.top
                    Color.clear
                        .onAppear {
                            GroomOpenMetricsLog.emit(label, Self.describe(frame, safeTop))
                        }
                        .onChange(of: frame) { _, f in
                            GroomOpenMetricsLog.emit(label, Self.describe(f, safeTop))
                        }
                        .onChange(of: safeTop) { _, top in
                            GroomOpenMetricsLog.emit(label, Self.describe(frame, top))
                        }
                }
            )
        } else {
            content
        }
    }

    static func describe(_ f: CGRect, _ safeTop: CGFloat) -> String {
        String(format: "frame=(%.1f,%.1f %.1fx%.1f) safeTop=%.1f", f.minX, f.minY, f.width, f.height, safeTop)
    }
}

extension View {
    func groomOpenMetricsProbe(_ label: String) -> some View {
        modifier(GroomOpenMetricsProbe(label: label))
    }
}
