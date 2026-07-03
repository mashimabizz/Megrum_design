import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardThreadDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var thread: BoardThread
    var selectedPrefecture: String?
    var coordinate: MegrumLocationCoordinate?
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.megrumSlidePresentationDismiss) private var slideDismiss
    @State private var replyComposerState = BoardThreadReplyComposerState()
    @State private var isShowingReportConfirmation = false

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
            meguriProfilesByUserID: appState.meguriProfilesByUserID,
            grooms: appState.grooms
        )
        .makePresentation()
    }

    var body: some View {
        let presentation = detailPresentation

        ScrollViewReader { proxy in
            ZStack {
                MegrumTheme.canvas
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    BoardThreadDetailHeader(
                        title: currentThread.title,
                        onClose: close,
                        onReport: { isShowingReportConfirmation = true }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    ScrollView(showsIndicators: false) {
                        BoardThreadChatTimeline(
                            messages: presentation.chatMessages,
                            isLoadingReplies: appState.loadingBoardRepliesThreadID == currentThread.id,
                            missingReplyContextMessage: missingReplyContextMessage,
                            onReact: react(to:reaction:)
                        )
                        .padding(.top, 14)

                        Color.clear
                            .frame(height: 1)
                            .id(BoardThreadScrollAnchor.bottom)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .padding(.bottom, 92)
                }
            }
            .safeAreaInset(edge: .bottom) {
                BoardReplyInput(
                    text: $replyComposerState.draftReply,
                    isSending: appState.sendingBoardReplyThreadID == currentThread.id,
                    isDisabled: missingReplyContextMessage != nil
                ) {
                    sendReply(proxy: proxy)
                }
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
                await appState.loadBoardReplies(
                    threadID: currentThread.id,
                    latitude: coordinate?.latitude,
                    longitude: coordinate?.longitude,
                    prefecture: selectedPrefecture,
                    scope: replyContextScope
                )
                await preloadParticipantProfiles()
                await preloadParticipantMeguriProfiles()
                await MainActor.run {
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

    private func preloadParticipantMeguriProfiles() async {
        await appState.loadMeguriProfiles(
            userIDs: Set(([currentThread.authorID] + replies.map(\.authorID))),
            reportsFailure: false
        )
    }

    private func sendReply(proxy: ScrollViewProxy) {
        guard let replyBody = replyComposerState.replyBodyForSubmission(
            isSending: appState.sendingBoardReplyThreadID == currentThread.id
        ) else {
            return
        }

        Task {
            let sent = await appState.sendBoardReply(
                threadID: currentThread.id,
                body: replyBody,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude,
                prefecture: selectedPrefecture,
                scope: replyContextScope
            )
            if sent {
                await MainActor.run {
                    replyComposerState.clearDraftAfterSend(succeeded: sent)
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
