import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct BoardThreadDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var thread: BoardThread
    var selectedPrefecture: String?
    var coordinate: MegrumLocationCoordinate?
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.megrumSlidePresentationDismiss) private var slideDismiss
    @State private var replyComposerState = BoardThreadReplyComposerState()
    @State private var photoPresentationState = MeguriMessagePhotoPresentationState()
    @State private var isShowingReportConfirmation = false
    @State private var showsJoinIdentitySheet = false
    @State private var replyTarget: ChatReplyTarget?
    @State private var reportTargetMessage: BoardThreadChatMessageDisplay?
    @State private var pendingReplyAfterJoin: (() -> Void)?

    private var currentThread: BoardThread {
        appState.threads.first { $0.id == thread.id } ?? thread
    }

    private var replies: [BoardReply] {
        appState.boardReplies(for: currentThread.id)
    }

    private var replyContextScope: BoardThread.Audience {
        currentThread.audience == .sameSpot ? .nearby3km : currentThread.audience
    }

    private var missingReplyContextMessage: String? {
        if currentThread.isClosed {
            return "このチャットルームは終了しています"
        }
        return switch replyContextScope {
        case .nearby3km:
            coordinate == nil ? "このチャットルームへの返信には現在地が必要です" : nil
        case .samePrefecture:
            selectedPrefecture.nilIfBlank == nil
                && (appState.viewer?.prefecture).nilIfBlank == nil
                ? "このチャットルームへの返信には都道府県設定が必要です"
                : nil
        case .sameSpot, .global:
            nil
        }
    }

    private var detailPresentation: BoardThreadDetailPresentation {
        BoardThreadDetailPresentationBuilder(
            thread: currentThread,
            replies: replies,
            viewer: appState.viewer,
            profilesByUserID: appState.publicProfilesByUserID,
            grooms: appState.grooms
        )
        .makePresentation()
    }

    @State private var headerChromeHeight: CGFloat = 120
    @State private var isHeaderRowCollapsed = false
    @State private var chatHeaderCollapseTracker = ChatHeaderCollapseTracker()
    /// 他の人のルームに入る時の 紹介→プロフィール→注意 の入室フェーズ。
    @State private var roomEntryPhase: BoardRoomEntryPhase = .undetermined

    var body: some View {
        let presentation = detailPresentation

        ScrollViewReader { proxy in
            ZStack {
                MegrumTheme.canvas
                    .ignoresSafeArea()

                // ヘッダーは半透明ガラスで浮かせ、チャットはその下をすべって透ける。
                // 下方向へスクロールしたらルーム名称の行だけ隠す（バナーは残す）。
                // 一度隠れたらスクロールを止めても隠れたままで、明確に上へ
                // スクロールした時だけ戻る（バウンスでは戻らない）。
                ZStack(alignment: .top) {
                    ScrollView(showsIndicators: false) {
                        Color.clear
                            .frame(height: headerChromeHeight + 6)
                            .megrumReportsScrollContentTop()
                        BoardThreadChatTimeline(
                            messages: presentation.chatMessages,
                            isLoadingReplies: appState.loadingBoardRepliesThreadID == currentThread.id,
                            missingReplyContextMessage: missingReplyContextMessage,
                            onReact: react(to:reaction:),
                            onOpenImage: { url in
                                photoPresentationState.selectRemoteImage(url)
                            },
                            onReply: { message in
                                let quotedMessageID: UUID? = {
                                    if case .reply(let id) = message.target { return id }
                                    return nil
                                }()
                                replyTarget = ChatReplyTarget(
                                    messageID: quotedMessageID,
                                    senderID: message.authorID,
                                    senderName: message.displayName,
                                    avatarID: message.avatarID,
                                    avatarURL: message.avatarURL,
                                    initial: message.initial,
                                    body: ChatReplyQuoteFormatter.copyText(of: message.body),
                                    imageURL: message.imageURLs.first
                                )
                            },
                            onReport: { message in
                                reportTargetMessage = message
                            },
                            onJumpToMessage: { messageID in
                                if let display = presentation.chatMessages.first(where: { $0.target == .reply(messageID) }) {
                                    withAnimation(.snappy(duration: 0.3)) {
                                        proxy.scrollTo(display.id, anchor: .center)
                                    }
                                }
                            }
                        )
                        .padding(.top, 14)

                        Color.clear
                            .frame(height: 1)
                            .id(BoardThreadScrollAnchor.bottom)
                    }
                    .coordinateSpace(name: MegrumScrollContentTopSpace.name)
                    .scrollDismissesKeyboard(.interactively)

                    VStack(spacing: 0) {
                        BoardThreadDetailHeader(
                            title: currentThread.title,
                            onClose: close,
                            onReport: { isShowingReportConfirmation = true }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        // ルーム名称の行だけ折りたたむ（バナーは常時表示）。
                        .frame(height: isHeaderRowCollapsed ? 0 : nil, alignment: .bottom)
                        .clipped()
                        .opacity(isHeaderRowCollapsed ? 0 : 1)

                        AdBannerSlot(
                            placement: .boardRoomHeaderBanner,
                            displayContext: AdDisplayContext(
                                viewerID: appState.viewer?.id,
                                isPremiumSubscriber: appState.subscriptionState.suppressesAds
                            ),
                            bottomSpacing: 6
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity)
                    .megrumTranslucentTopChromeBackground()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { newValue in
                        // コンテンツ上部の余白は展開時の高さ基準で固定する
                        //（収納で余白が動くとスクロール位置が跳ねるため）。
                        if !isHeaderRowCollapsed {
                            headerChromeHeight = newValue
                        }
                    }
                }
                .onPreferenceChange(MegrumScrollContentTopPreferenceKey.self) { contentTop in
                    MainActor.assumeIsolated {
                        let next = chatHeaderCollapseTracker.updatedCollapsedState(
                            contentTop: contentTop,
                            isCollapsed: isHeaderRowCollapsed
                        )
                        guard next != isHeaderRowCollapsed else {
                            return
                        }
                        withAnimation(.snappy(duration: 0.22)) {
                            isHeaderRowCollapsed = next
                        }
                    }
                }

                if let selectedRemoteImage = photoPresentationState.selectedRemoteImage {
                    FullScreenRemoteImageView(
                        url: selectedRemoteImage.url,
                        onDismiss: {
                            photoPresentationState.clearSelectedRemoteImage()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(10)
                }

                // 入室フロー：紹介画面（参加ボタン）→ プロフィール設定 → 注意事項
                if roomEntryPhase == .intro {
                    BoardRoomEntryIntroView(
                        thread: currentThread,
                        participantCount: presentation.participantAvatars.count,
                        onJoin: { showsJoinIdentitySheet = true },
                        onClose: close
                    )
                    .zIndex(30)
                    .transition(.opacity)
                }
                if roomEntryPhase == .notice {
                    BoardRoomEntryNoticeOverlay {
                        withAnimation(.snappy(duration: 0.2)) {
                            roomEntryPhase = .entered
                        }
                    }
                    .zIndex(31)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 入室確定前（紹介画面・注意事項）は入力欄を出さない。
                if roomEntryPhase == .entered || roomEntryPhase == .undetermined {
                    VStack(spacing: 0) {
                        if let replyTarget {
                            ChatReplyComposerPreview(target: replyTarget) {
                                self.replyTarget = nil
                            }
                        }
                        BoardReplyInput(
                            text: $replyComposerState.draftReply,
                            isSending: appState.sendingBoardReplyThreadID == currentThread.id,
                            isDisabled: missingReplyContextMessage != nil,
                            canUseCamera: canUseCamera,
                            onOpenCamera: openCamera,
                            onOpenPhotoLibrary: openPhotoLibrary
                        ) {
                            sendReply(proxy: proxy)
                        }
                    }
                }
            }
            .confirmationDialog(
                "このメッセージを通報しますか？",
                isPresented: Binding(
                    get: { reportTargetMessage != nil },
                    set: { if !$0 { reportTargetMessage = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("通報する", role: .destructive) {
                    if let message = reportTargetMessage {
                        Task {
                            _ = await appState.reportUser(
                                targetUserID: message.authorID,
                                reason: .harassment,
                                note: "チャットルームのメッセージ通報: \(ChatReplyQuoteFormatter.preview(of: message.body))"
                            )
                        }
                    }
                    reportTargetMessage = nil
                }
                Button("キャンセル", role: .cancel) {
                    reportTargetMessage = nil
                }
            } message: {
                Text("運営が内容を確認します。")
            }
            .photosPicker(
                isPresented: $photoPresentationState.isShowingPhotoLibraryPicker,
                selection: $photoPresentationState.selectedPhotoItem,
                matching: .images
            )
            #if os(iOS)
            .sheet(isPresented: $photoPresentationState.isShowingCamera) {
                NativeCameraCaptureView { imageData in
                    handleCapturedImage(imageData, proxy: proxy)
                }
                .ignoresSafeArea()
            }
            #endif
            .onChange(of: photoPresentationState.selectedPhotoItem) { _, item in
                handleSelectedPhoto(item, proxy: proxy)
            }
            .sheet(isPresented: $showsJoinIdentitySheet) {
                BoardRoomJoinIdentitySheet(
                    onConfirm: { name, avatarID in
                        if let viewerID = appState.viewer?.id {
                            MeguriRoomIdentityStore.save(
                                MeguriRoomIdentityStore.Identity(displayName: name, avatarID: avatarID),
                                threadID: currentThread.id,
                                userID: viewerID
                            )
                        }
                        showsJoinIdentitySheet = false
                        pendingReplyAfterJoin?()
                        pendingReplyAfterJoin = nil
                        if roomEntryPhase == .intro {
                            withAnimation(.snappy(duration: 0.2)) {
                                roomEntryPhase = .notice
                            }
                        }
                    },
                    onCancel: {
                        showsJoinIdentitySheet = false
                        pendingReplyAfterJoin = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .boardThreadDetailNavigationChromeHidden()
            .confirmationDialog("このチャットルームを通報しますか？", isPresented: $isShowingReportConfirmation, titleVisibility: .visible) {
                Button("通報する", role: .destructive) {
                    Task {
                        _ = await appState.reportBoardThread(currentThread.id)
                    }
                }
                .disabled(appState.reportingBoardThreadID == currentThread.id)

                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("内容を運営に送信します。")
            }
            .onChange(of: presentation.chatMessages.map(\.id)) { _, _ in
                scrollToLatest(proxy)
            }
            .task {
                determineRoomEntryPhaseIfNeeded(afterRepliesLoaded: false)
                await appState.loadBoardReplies(
                    threadID: currentThread.id,
                    latitude: coordinate?.latitude,
                    longitude: coordinate?.longitude,
                    prefecture: selectedPrefecture,
                    scope: replyContextScope
                )
                await preloadParticipantProfiles()
                await MainActor.run {
                    // 過去に返信済み（＝参加済み）なら紹介画面を出さずに入室扱いへ。
                    determineRoomEntryPhaseIfNeeded(afterRepliesLoaded: true)
                    scrollToLatest(proxy, animated: false)
                }
            }
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else if let slideDismiss {
            slideDismiss()
        } else {
            dismiss()
        }
    }

    private func react(to target: BoardThreadChatMessageTarget, reaction: BoardMessageReaction?) {
        Task {
            switch target {
            case .thread(let threadID):
                await appState.setBoardThreadReaction(threadID: threadID, reaction: reaction)
            case .reply(let replyID):
                await appState.setBoardReplyReaction(replyID: replyID, reaction: reaction)
            }
        }
    }

    private func preloadParticipantProfiles() async {
        let viewerID = appState.viewer?.id
        guard currentThread.anonymousDisplayName?.isBlank != false && currentThread.anonymousAvatarID?.isBlank != false else {
            return
        }
        if currentThread.authorID != viewerID && appState.publicProfilesByUserID[currentThread.authorID] == nil {
            await appState.loadPublicUserProfile(userID: currentThread.authorID, reportsFailure: false)
        }
    }

    /// 入室フェーズを決める：自分のルーム・参加済み（部屋プロフィールあり/過去に返信あり）
    /// なら通常入室、未参加なら紹介画面から。
    private func determineRoomEntryPhaseIfNeeded(afterRepliesLoaded: Bool) {
        guard roomEntryPhase == .undetermined || (roomEntryPhase == .intro && afterRepliesLoaded) else {
            return
        }
        let phase: BoardRoomEntryPhase = resolvedRoomIdentity() == nil ? .intro : .entered
        if roomEntryPhase != phase {
            roomEntryPhase = phase
        }
    }

    /// この部屋での自分の名前・アイコン。nil = 未参加（参加シートで決めてもらう）。
    private func resolvedRoomIdentity() -> (name: String?, avatarID: String?)? {
        guard let viewerID = appState.viewer?.id else {
            return (nil, nil)
        }
        if currentThread.authorID == viewerID {
            // 作成者はスレッド作成時に決めた名前・アイコンをそのまま使う
            return (nil, nil)
        }
        if let stored = MeguriRoomIdentityStore.load(threadID: currentThread.id, userID: viewerID) {
            return (stored.displayName, stored.avatarID)
        }
        if let ownIdentityReply = replies.last(where: { reply in
            reply.authorID == viewerID
                && (reply.anonymousDisplayName?.nilIfBlank != nil || reply.anonymousAvatarID?.nilIfBlank != nil)
        }) {
            return (ownIdentityReply.anonymousDisplayName, ownIdentityReply.anonymousAvatarID)
        }
        if replies.contains(where: { $0.authorID == viewerID }) {
            // 過去に名前なしで参加済み（旧データ）はそのまま
            return (nil, nil)
        }
        return nil
    }

    private func sendReply(proxy: ScrollViewProxy) {
        guard let replyBody = replyComposerState.replyBodyForSubmission(
            isSending: appState.sendingBoardReplyThreadID == currentThread.id
        ) else {
            return
        }

        let outgoingBody: String
        if let replyTarget {
            outgoingBody = ChatReplyQuoteFormatter.compose(reply: replyTarget, body: replyBody)
        } else {
            outgoingBody = replyBody
        }
        guard let identity = resolvedRoomIdentity() else {
            pendingReplyAfterJoin = {
                performSendReply(body: outgoingBody, proxy: proxy)
            }
            showsJoinIdentitySheet = true
            return
        }
        performSendReply(body: outgoingBody, identity: identity, proxy: proxy)
    }

    private func performSendReply(
        body replyBody: String,
        identity: (name: String?, avatarID: String?)? = nil,
        proxy: ScrollViewProxy
    ) {
        let identity = identity ?? resolvedRoomIdentity() ?? (nil, nil)
        Task {
            let sent = await appState.sendBoardReply(
                threadID: currentThread.id,
                body: replyBody,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude,
                prefecture: selectedPrefecture,
                scope: replyContextScope,
                anonymousDisplayName: identity.name,
                anonymousAvatarID: identity.avatarID
            )
            if sent {
                await MainActor.run {
                    replyComposerState.clearDraftAfterSend(succeeded: sent)
                    replyTarget = nil
                    scrollToLatest(proxy)
                }
            }
        }
    }

    private func openCamera() {
        guard missingReplyContextMessage == nil else {
            return
        }
        photoPresentationState.isShowingCamera = true
    }

    private func openPhotoLibrary() {
        guard missingReplyContextMessage == nil else {
            return
        }
        photoPresentationState.isShowingPhotoLibraryPicker = true
    }

    private func handleSelectedPhoto(_ item: PhotosPickerItem?, proxy: ScrollViewProxy) {
        guard let item else {
            return
        }
        Task {
            await addPhoto(from: item, proxy: proxy)
        }
    }

    private func handleCapturedImage(_ imageData: Data, proxy: ScrollViewProxy) {
        Task {
            await addPhoto(data: imageData, imageContentType: "image/jpeg", proxy: proxy)
        }
    }

    private func addPhoto(from item: PhotosPickerItem, proxy: ScrollViewProxy) async {
        defer {
            photoPresentationState.clearSelectedPhotoItem()
        }
        guard missingReplyContextMessage == nil,
              let data = try? await item.loadTransferable(type: Data.self)
        else {
            return
        }
        let upload = normalizedChatPhotoUpload(from: data)
        await addPhoto(data: upload.data, imageContentType: upload.contentType, proxy: proxy)
    }

    private func addPhoto(data: Data, imageContentType: String, proxy: ScrollViewProxy) async {
        guard missingReplyContextMessage == nil else {
            return
        }
        guard let identity = resolvedRoomIdentity() else {
            await MainActor.run {
                pendingReplyAfterJoin = {
                    Task {
                        await performSendPhotoReply(data: data, imageContentType: imageContentType, proxy: proxy)
                    }
                }
                showsJoinIdentitySheet = true
            }
            return
        }
        await performSendPhotoReply(data: data, imageContentType: imageContentType, identity: identity, proxy: proxy)
    }

    private func performSendPhotoReply(
        data: Data,
        imageContentType: String,
        identity: (name: String?, avatarID: String?)? = nil,
        proxy: ScrollViewProxy
    ) async {
        let identity = identity ?? resolvedRoomIdentity() ?? (nil, nil)
        let sent = await appState.sendBoardPhotoReply(
            threadID: currentThread.id,
            imageData: data,
            imageContentType: imageContentType,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            prefecture: selectedPrefecture,
            scope: replyContextScope,
            anonymousDisplayName: identity.name,
            anonymousAvatarID: identity.avatarID
        )
        if sent {
            await MainActor.run {
                scrollToLatest(proxy)
            }
        }
    }

    private var canUseCamera: Bool {
        #if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
        #else
        false
        #endif
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

private extension View {
    @ViewBuilder
    func boardThreadDetailNavigationChromeHidden() -> some View {
        #if os(iOS)
        self
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
        #else
        self
        #endif
    }
}
