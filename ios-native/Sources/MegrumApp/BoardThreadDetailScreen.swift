import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardThreadDetailScreen: View {
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
        if thread.isClosed {
            return "このチャットルームは終了しています"
        }
        return switch replyContextScope {
        case .nearby3km:
            coordinate == nil ? "この話題への返信には現在地が必要です" : nil
        case .samePrefecture:
            selectedPrefecture.nilIfBlank == nil
                && (appState.viewer?.prefecture).nilIfBlank == nil
                ? "この話題への返信には都道府県設定が必要です"
                : nil
        case .sameSpot, .global:
            nil
        }
    }

    private var detailPresentation: BoardThreadDetailPresentation {
        BoardThreadDetailPresentationBuilder(
            thread: thread,
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
                    BoardThreadDetailHeader {
                        dismiss()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            BoardThreadDetailCard(
                                thread: thread,
                                authorName: presentation.authorName,
                                authorAvatarURL: presentation.authorAvatarURL,
                                authorAvatarID: presentation.authorAvatarID,
                                authorInitial: presentation.authorInitial,
                                authorRelativeTime: presentation.authorRelativeTime,
                                replyCount: max(thread.effectiveReplyCount, replies.count, appState.boardRepliesByThreadID[thread.id]?.count ?? replies.count),
                                participantAvatars: presentation.participantAvatars,
                                replies: presentation.replies,
                                isLoadingReplies: appState.loadingBoardRepliesThreadID == thread.id,
                                missingReplyContextMessage: missingReplyContextMessage
                            )
                            .padding(.horizontal, 12)
                            .padding(.top, 14)

                            Color.clear
                                .frame(height: 1)
                                .id(BoardThreadScrollAnchor.bottom)
                        }
                        .padding(.bottom, 92)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .safeAreaInset(edge: .bottom) {
                BoardReplyInput(
                    text: $draftReply,
                    isSending: appState.sendingBoardReplyThreadID == thread.id,
                    isDisabled: missingReplyContextMessage != nil
                ) {
                    sendReply(proxy: proxy)
                }
            }
            .boardThreadDetailNavigationChromeHidden()
            .onChange(of: replies.count) { _, _ in
                scrollToLatest(proxy)
            }
            .task {
                await appState.loadBoardReplies(
                    threadID: thread.id,
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

    private func preloadParticipantProfiles() async {
        let viewerID = appState.viewer?.id
        guard thread.anonymousDisplayName?.isBlank != false && thread.anonymousAvatarID?.isBlank != false else {
            return
        }
        if thread.authorID != viewerID && appState.publicProfilesByUserID[thread.authorID] == nil {
            await appState.loadPublicUserProfile(userID: thread.authorID, reportsFailure: false)
        }
    }

    private func preloadParticipantMeguriProfiles() async {
        await appState.loadMeguriProfiles(
            userIDs: Set(([thread.authorID] + replies.map(\.authorID))),
            reportsFailure: false
        )
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
