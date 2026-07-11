import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct MeguriMessagePeerRoute: Identifiable, Hashable {
    enum Scope: Hashable {
        case all
        case conversation(sourceGroomPostID: UUID?)
    }

    var peerID: UUID
    var scope: Scope = .all

    var id: String {
        switch scope {
        case .all:
            return "\(peerID.uuidString.lowercased()):all"
        case .conversation(let sourceGroomPostID):
            let sourceID = sourceGroomPostID?.uuidString.lowercased() ?? "direct"
            return "\(peerID.uuidString.lowercased()):\(sourceID)"
        }
    }
}

@MainActor
struct MeguriMessageInboxScreen: View {
    @ObservedObject var appState: MegrumAppState
    var visualQAInitialScreen: VisualQAInitialScreen? = nil
    var onClose: (() -> Void)?
    var onOpenThread: (MeguriMessageThread) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.megrumSlidePresentationDismiss) private var slideDismiss
    @State private var didOpenVisualQATargetThread = false

    private var threads: [MeguriMessageThread] {
        appState.meguriMessageThreads
    }

    private var canReadMessages: Bool {
        appState.subscriptionState.hasMeguriMessageAccess
    }

    var body: some View {
        NavigationStack {
            inboxContent
                .environment(\.groomContextImageURLResolver) { [appState] url in
                    await appState.freshGroomContextImageURL(from: url)
                }
                .navigationTitle("メッセージ")
                .megrumInlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        // FB(iter1226.422)：スライド遷移に合わせ「閉じる」→戻るアイコンにする。
                        Button {
                            close()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel("戻る")
                    }
                }
                .refreshable {
                    await appState.loadSubscriptionState(reportsFailure: false)
                    await appState.loadMeguriMessages()
                }
                .task {
                    await appState.loadSubscriptionState(reportsFailure: false)
                    await appState.loadMeguriMessages()
                    openVisualQATargetThreadIfNeeded()
                }
                .onChange(of: threads.map(\.peerID)) { _, _ in
                    openVisualQATargetThreadIfNeeded()
                }
        }
        .megrumVisibleNavigationBar()
    }

    private var inboxContent: some View {
        List {
            inboxRows
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    private var inboxRows: some View {
        Group {
            if appState.isLoadingMeguriMessages, threads.isEmpty {
                MeguriMessageInboxLoadingRow()
            } else if threads.isEmpty {
                MeguriMessageInboxEmptyState()
            } else {
                ForEach(threads) { thread in
                    MeguriMessageThreadRow(
                        thread: thread,
                        viewerID: appState.viewer?.id,
                        canReadMessages: canReadMessages,
                        onOpenThread: { openThread(thread) }
                    )
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteThread(thread)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func deleteThread(_ thread: MeguriMessageThread) {
        withAnimation(.snappy(duration: 0.25)) {
            appState.hideMeguriMessageThread(thread)
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

    private func openThread(_ thread: MeguriMessageThread) {
        onOpenThread(thread)
    }

    private func openVisualQATargetThreadIfNeeded() {
        guard visualQAInitialScreen == .meguriMessageThread,
              !didOpenVisualQATargetThread,
              let thread = threads.first
        else {
            return
        }
        didOpenVisualQATargetThread = true
        openThread(thread)
    }

}

private struct MeguriMessageThreadRow: View {
    var thread: MeguriMessageThread
    var viewerID: UUID?
    var canReadMessages: Bool
    var onOpenThread: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MeguriProfileAvatarView(
                avatarID: thread.avatarID,
                avatarURL: thread.avatarURL,
                fallback: thread.displayName,
                size: 52
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(thread.displayName)
                        // FB(iter1226.424)：相手の名前は太字にしない。
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)

                    if let handle = thread.handle?.nilIfBlank {
                        Text("@\(handle)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    Text(thread.lastMessage.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                HStack(spacing: 8) {
                    if let contextTitle {
                        MeguriMessageThreadContextPill(
                            title: contextTitle,
                            imageURL: thread.sourceGroomImageURL,
                            messageCreatedAt: thread.lastMessage.createdAt
                        )
                    }

                    if shouldMosaicPreview {
                        MeguriLockedMessagePreview(text: lockedPreviewText)
                    } else {
                        Text(thread.lastMessagePreview)
                            .font(.system(size: 13, weight: thread.unreadCount > 0 ? .black : .semibold, design: .rounded))
                            .foregroundStyle(thread.unreadCount > 0 ? MegrumTheme.ink : MegrumTheme.muted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    if thread.unreadCount > 0 {
                        MeguriUnreadCountBadge(count: thread.unreadCount, size: .threadRow)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenThread)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let unreadText = thread.unreadCount > 0 ? "、未読\(thread.unreadCount)件" : ""
        if shouldMosaicPreview {
            return "\(thread.displayName)、プレミアムで表示できるメッセージ\(unreadText)"
        }
        return "\(thread.displayName)、\(thread.lastMessagePreview)\(unreadText)"
    }

    private var shouldMosaicPreview: Bool {
        thread.lastMessage.locked || (!canReadMessages && thread.lastMessage.senderID == thread.peerID)
    }

    private var contextTitle: String? {
        guard thread.sourceGroomPostID != nil else {
            return nil
        }
        if let viewerID, thread.sourceGroomOwnerID == viewerID {
            return "あなたのグルーム"
        }
        return "グルームへの返信"
    }

    private var lockedPreviewText: String {
        if let body = thread.lastMessage.body?.nilIfBlank {
            return body
        }
        return thread.lastMessage.messageType == .image ? "画像が届きました" : "メッセージが届きました"
    }
}

private struct MeguriMessageThreadContextPill: View {
    var title: String
    var imageURL: URL?
    var messageCreatedAt: Date?

    /// グルーム失効後（メッセージから24時間超）はサムネイルを出さない。
    private var isImageUnavailable: Bool {
        guard let messageCreatedAt else {
            return false
        }
        return GroomContextCardPolicy.isCertainlyExpired(messageCreatedAt: messageCreatedAt)
    }

    var body: some View {
        HStack(spacing: 6) {
            if let imageURL, !isImageUnavailable {
                GroomContextResolvedImage(staleURL: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(MegrumTheme.lavender.opacity(0.18))
                    }
                }
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
        .accessibilityHidden(true)
    }
}

private struct MeguriMessageInboxLoadingRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("メッセージを読み込んでいます")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
}

private struct MeguriMessageInboxEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "message.fill")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 50, height: 50)
                .background(MegrumTheme.lavender.opacity(0.12), in: Circle())

            Text("まだメッセージはありません")
                .font(.headline.weight(.bold))
                .foregroundStyle(MegrumTheme.ink)
            Text("グルームへの返信や、めぐりで届いた会話がここに表示されます。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 26)
    }
}

@MainActor
struct MeguriMessagesScreen: View {
    @ObservedObject var appState: MegrumAppState
    var route: MeguriMessagePeerRoute
    var onClose: (() -> Void)?
    var onOpenUserProfile: (UUID) -> Void = { _ in }
    @State private var presentationState = MeguriMessagesPresentationState()
    @State private var photoPresentationState = MeguriMessagePhotoPresentationState()
    @State private var replyTarget: ChatReplyTarget?
    @State private var reportTargetMessage: MeguriMessage?

    private var messages: [MeguriMessage] {
        switch route.scope {
        case .all:
            appState.meguriMessages(with: route.peerID)
        case .conversation(let sourceGroomPostID):
            appState.meguriMessages(
                in: MeguriMessageConversationKey(
                    peerID: route.peerID,
                    sourceGroomPostID: sourceGroomPostID
                )
            )
        }
    }

    private var canUseMeguriMessages: Bool {
        appState.subscriptionState.hasMeguriMessageAccess
    }

    var body: some View {
        ZStack {
            content
                .environment(\.groomContextImageURLResolver) { [appState] url in
                    await appState.freshGroomContextImageURL(from: url)
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
        }
        .photosPicker(
            isPresented: $photoPresentationState.isShowingPhotoLibraryPicker,
            selection: $photoPresentationState.selectedPhotoItem,
            matching: .images
        )
#if os(iOS)
        .sheet(isPresented: $photoPresentationState.isShowingCamera) {
            NativeCameraCaptureView { imageData in
                handleCapturedImage(imageData)
            }
            .ignoresSafeArea()
        }
#endif
        .onChange(of: photoPresentationState.selectedPhotoItem) { _, item in
            handleSelectedPhoto(item)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle(peerTitle)
        .megrumInlineNavigationTitle()
        .megrumVisibleNavigationBar()
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .heavy))
                    }
                    .accessibilityLabel("メッセージ一覧に戻る")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        presentationState.reportTarget = moderationTarget
                    } label: {
                        Label("通報する", systemImage: "exclamationmark.bubble")
                    }

                Button(role: .destructive) {
                        presentationState.blockTarget = moderationTarget
                    } label: {
                        Label("ブロックする", systemImage: "hand.raised")
                    }
                    .disabled(appState.blockingUserID == route.peerID)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                }
                .accessibilityLabel("メッセージメニュー")
            }
        }
        .alert("\(SubscriptionCatalog.currentPremiumDisplayName)でやり取りできます", isPresented: $presentationState.isShowingMegrumPlusPrompt) {
            Button("詳しく見る") {
                presentationState.showMegrumPlus()
            }
            Button("あとで", role: .cancel) {}
        } message: {
            Text("\(SubscriptionCatalog.currentPremiumDisplayName)に入ると、めぐり内で届いたメッセージの本文表示と返信ができるようになります。")
        }
        .sheet(isPresented: $presentationState.isShowingMegrumPlus) {
            NavigationStack {
                SubscriptionSettingsScreen(appState: appState)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $presentationState.reportTarget) { target in
            NavigationStack {
                UserReportSheet(
                    target: target,
                    isSubmitting: appState.reportingUserID == target.userID
                ) { reason, note in
                    Task {
                        _ = await appState.reportUser(
                            targetUserID: target.userID,
                            reason: reason,
                            note: note
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            "このユーザーをブロックしますか？",
            isPresented: Binding(
                get: { presentationState.blockTarget != nil },
                set: { isPresented in
                    presentationState.updateBlockConfirmationPresentation(isPresented)
                }
            ),
            titleVisibility: .visible
        ) {
            if let blockTarget = presentationState.blockTarget {
                Button("ブロックする", role: .destructive) {
                    Task {
                        if await appState.blockUser(blockTarget.userID) {
                            presentationState.updateBlockConfirmationPresentation(false)
                            onClose?()
                        }
                    }
                }
                .disabled(appState.blockingUserID == blockTarget.userID)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この相手のめぐりメッセージは一覧から非表示になります。解除は設定の「めぐりでブロックした人」からできます。")
        }
        .task {
            await appState.loadSubscriptionState(reportsFailure: false)
            await appState.loadMeguriMessages()
            if canUseMeguriMessages {
                await appState.markMeguriMessagesRead(
                    peerID: route.peerID,
                    sourceGroomPostID: routeSourceGroomPostID,
                    showsAllPeerMessages: route.scope == .all
                )
            } else {
                presentationState.showInitialMegrumPlusPrompt()
            }
        }
    }

    private var content: some View {
        ScrollViewReader { proxy in
            MeguriMessageList(
                messages: messages,
                viewerID: appState.viewer?.id,
                isLoading: appState.isLoadingMeguriMessages,
                canReadIncomingMessages: canUseMeguriMessages,
                peerAvatarID: peerAvatarID,
                peerAvatarURL: peerAvatarURL,
                peerFallback: peerTitle,
                onOpenPremium: openMegrumPlus,
                onOpenPeerProfile: { onOpenUserProfile(route.peerID) },
                onOpenImage: { url in
                    photoPresentationState.selectRemoteImage(url)
                },
                onReply: { message in
                    let isMine = message.senderID == appState.viewer?.id
                    replyTarget = ChatReplyTarget(
                        messageID: message.id,
                        senderID: message.senderID,
                        senderName: isMine
                            ? (appState.viewer?.displayName).nilIfBlank ?? "自分"
                            : peerTitle,
                        avatarID: isMine ? nil : peerAvatarID,
                        avatarURL: isMine ? appState.viewer?.avatarURL : peerAvatarURL,
                        initial: String(
                            (isMine
                                ? (appState.viewer?.displayName).nilIfBlank ?? "自分"
                                : peerTitle
                            ).prefix(1)
                        ).uppercased(),
                        body: ChatReplyQuoteFormatter.copyText(of: message.body ?? ""),
                        imageURL: message.imageURL
                    )
                },
                onReport: { message in
                    reportTargetMessage = message
                },
                onJumpToMessage: { messageID in
                    withAnimation(.snappy(duration: 0.3)) {
                        proxy.scrollTo(messageID, anchor: .center)
                    }
                }
            )
            .onChange(of: messages.count) { _, _ in
                guard let lastID = messages.last?.id else {
                    return
                }
                withAnimation(.snappy(duration: 0.24)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
            // iter1226.460：開いた瞬間から最新メッセージが見える位置で表示する（アニメなし）。
            .onAppear {
                guard let lastID = messages.last?.id else {
                    return
                }
                proxy.scrollTo(lastID, anchor: .bottom)
                DispatchQueue.main.async {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if let replyTarget {
                    ChatReplyComposerPreview(target: replyTarget) {
                        self.replyTarget = nil
                    }
                }
                messageInputBar
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
                            targetUserID: message.senderID,
                            reason: .harassment,
                            note: "めぐりメッセージの通報: \(ChatReplyQuoteFormatter.preview(of: message.body ?? ""))"
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
    }

    private var messageInputBar: some View {
        MeguriMessageInput(
            text: $presentationState.draft,
            isSending: appState.sendingMeguriMessageRecipientID == route.peerID,
            canUseCamera: canUseCamera,
            onOpenCamera: openCamera,
            onOpenPhotoLibrary: openPhotoLibrary
        ) { sendMessage() }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func sendMessage() {
        guard canUseMeguriMessages else {
            presentationState.showMegrumPlusPrompt()
            return
        }
        let outgoingBody: String
        if let replyTarget {
            outgoingBody = ChatReplyQuoteFormatter.compose(reply: replyTarget, body: presentationState.draft)
        } else {
            outgoingBody = presentationState.draft
        }
        let attachesGroomContext = shouldAttachGroomContext
        Task {
            // sourceGroomPostID は会話のグルーピングキーなので常に付ける。
            // 文脈カード（owner / 画像）は最初のグルーム返信だけに付ける。
            let sent = await appState.sendMeguriMessage(
                recipientID: route.peerID,
                body: outgoingBody,
                sourceGroomPostID: routeSourceGroomPostID,
                sourceGroomOwnerID: attachesGroomContext ? routeSourceGroomOwnerID : nil,
                sourceGroomImageURL: attachesGroomContext ? routeSourceGroomImageURL : nil
            )
            presentationState.clearDraftAfterSend(sent)
            if sent {
                replyTarget = nil
            }
        }
    }

    /// グルーム文脈カード（「あなたのグルームに返信しました」等）は、その会話の
    /// 最初のグルーム返信にだけ付ける。すでに同じグルームの文脈カード付き
    /// メッセージが会話にあれば、以降（返信含む）は通常メッセージとして送る。
    private var shouldAttachGroomContext: Bool {
        guard let sourceGroomPostID = routeSourceGroomPostID else {
            return false
        }
        guard replyTarget == nil else {
            return false
        }
        return !messages.contains {
            $0.sourceGroomPostID == sourceGroomPostID && $0.sourceGroomImageURL != nil
        }
    }

    private func openMegrumPlus() {
        presentationState.showMegrumPlus()
    }

    private func openCamera() {
        guard canUseMeguriMessages else {
            presentationState.showMegrumPlusPrompt()
            return
        }
        photoPresentationState.isShowingCamera = true
    }

    private func openPhotoLibrary() {
        guard canUseMeguriMessages else {
            presentationState.showMegrumPlusPrompt()
            return
        }
        photoPresentationState.isShowingPhotoLibraryPicker = true
    }

    private func handleSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await addPhoto(from: item)
        }
    }

    private func handleCapturedImage(_ imageData: Data) {
        Task {
            await addPhoto(data: imageData, imageContentType: "image/jpeg")
        }
    }

    private func addPhoto(from item: PhotosPickerItem) async {
        defer {
            photoPresentationState.clearSelectedPhotoItem()
        }
        guard canUseMeguriMessages else {
            presentationState.showMegrumPlusPrompt()
            return
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }
        let upload = normalizedChatPhotoUpload(from: data)
        await addPhoto(data: upload.data, imageContentType: upload.contentType)
    }

    private func addPhoto(data: Data, imageContentType: String) async {
        guard canUseMeguriMessages else {
            presentationState.showMegrumPlusPrompt()
            return
        }
        let attachesGroomContext = shouldAttachGroomContext
        _ = await appState.sendMeguriPhotoMessage(
            recipientID: route.peerID,
            imageData: data,
            imageContentType: imageContentType,
            sourceGroomPostID: routeSourceGroomPostID,
            sourceGroomOwnerID: attachesGroomContext ? routeSourceGroomOwnerID : nil,
            sourceGroomImageURL: attachesGroomContext ? routeSourceGroomImageURL : nil
        )
    }

    private var canUseCamera: Bool {
#if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
#else
        false
#endif
    }

    private var peerTitle: String {
        peerIdentity.displayName
    }

    private var peerIdentity: MeguriProfileIdentity {
        appState.meguriIdentity(
            for: route.peerID,
            fallbackName: peerFallbackName,
            fallbackHandle: peerFallbackHandle
        )
    }

    private var peerFallbackName: String? {
        for message in messages {
            if message.senderID == route.peerID {
                return displayName(name: message.senderDisplayName, handle: message.senderHandle)
            }
            if message.recipientID == route.peerID {
                return displayName(name: message.recipientDisplayName, handle: message.recipientHandle)
            }
        }
        return nil
    }

    private var peerFallbackHandle: String? {
        for message in messages {
            if message.senderID == route.peerID, let handle = message.senderHandle?.nilIfBlank {
                return handle
            }
            if message.recipientID == route.peerID, let handle = message.recipientHandle?.nilIfBlank {
                return handle
            }
        }
        return nil
    }

    private var peerAvatarID: String? {
        peerIdentity.avatarID
    }

    private var peerAvatarURL: URL? {
        peerIdentity.avatarURL
    }

    private var routeSourceGroomPostID: UUID? {
        switch route.scope {
        case .all:
            nil
        case .conversation(let sourceGroomPostID):
            sourceGroomPostID
        }
    }

    private var routeSourceGroomOwnerID: UUID? {
        messages.last(where: { $0.sourceGroomPostID == routeSourceGroomPostID })?.sourceGroomOwnerID
    }

    private var routeSourceGroomImageURL: URL? {
        messages.last(where: { $0.sourceGroomPostID == routeSourceGroomPostID })?.sourceGroomImageURL
    }

    private func displayName(name: String?, handle: String?) -> String {
        if let name, !name.isEmpty {
            return name
        }
        if let handle, !handle.isEmpty {
            return "@\(handle)"
        }
        return "めぐりメッセージ"
    }

    private var moderationTarget: PublicProfileModerationTarget {
        PublicProfileModerationTarget(userID: route.peerID, displayName: peerTitle)
    }
}
