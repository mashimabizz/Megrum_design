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
        switch replyContextScope {
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

    private var replyRows: [BoardReplyDisplay] {
        replies.enumerated().map { index, reply in
            let profile = profile(for: reply.authorID)
            let isMine = reply.authorID == appState.viewer?.id
            return BoardReplyDisplay(
                reply: reply,
                displayName: isMine ? "あなた" : profile?.displayName ?? fallbackParticipantName(index: index),
                avatarURL: profile?.avatarURL ?? fallbackGroomURL(index: index + 1),
                initial: profile?.displayName.first.map(String.init) ?? fallbackParticipantName(index: index).first.map(String.init) ?? "話",
                isMine: isMine,
                relativeTime: relativeTime(from: reply.createdAt)
            )
        }
    }

    private var participantAvatars: [BoardParticipantAvatar] {
        uniqueParticipantIDs.enumerated().map { index, id in
            let profile = profile(for: id)
            let isMine = id == appState.viewer?.id
            return BoardParticipantAvatar(
                id: id,
                avatarURL: profile?.avatarURL ?? fallbackGroomURL(index: index),
                initial: isMine ? "あ" : profile?.displayName.first.map(String.init) ?? fallbackParticipantName(index: index).first.map(String.init) ?? "話"
            )
        }
    }

    private var uniqueParticipantIDs: [UUID] {
        var seen = Set<UUID>()
        return ([thread.authorID] + replies.map(\.authorID)).filter { seen.insert($0).inserted }
    }

    var body: some View {
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
                                authorName: authorDisplayName,
                                authorAvatarURL: authorAvatarURL,
                                authorInitial: authorInitial,
                                authorRelativeTime: relativeTime(from: thread.createdAt),
                                replyCount: max(replies.count, appState.boardRepliesByThreadID[thread.id]?.count ?? replies.count),
                                participantAvatars: participantAvatars,
                                replies: replyRows,
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
                await MainActor.run {
                    scrollToLatest(proxy, animated: false)
                }
            }
        }
    }

    private var authorDisplayName: String {
        if thread.authorID == appState.viewer?.id {
            return appState.viewer?.displayName ?? "あなた"
        }
        return profile(for: thread.authorID)?.displayName ?? "miki"
    }

    private var authorAvatarURL: URL? {
        profile(for: thread.authorID)?.avatarURL ?? fallbackGroomURL(index: 0)
    }

    private var authorInitial: String {
        authorDisplayName.first.map(String.init) ?? "話"
    }

    private func profile(for userID: UUID) -> UserProfile? {
        if userID == appState.viewer?.id {
            return appState.viewer
        }
        return appState.publicProfilesByUserID[userID]?.profile
    }

    private func fallbackGroomURL(index: Int) -> URL? {
        guard !appState.grooms.isEmpty else { return nil }
        return appState.grooms[index % appState.grooms.count].imageURL
    }

    private func fallbackParticipantName(index: Int) -> String {
        ["yuna", "haru", "saku", "miki"][index % 4]
    }

    private func preloadParticipantProfiles() async {
        let viewerID = appState.viewer?.id
        for userID in uniqueParticipantIDs where userID != viewerID && appState.publicProfilesByUserID[userID] == nil {
            await appState.loadPublicUserProfile(userID: userID, reportsFailure: false)
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

    private func relativeTime(from date: Date) -> String {
        let elapsed = max(0, Date().timeIntervalSince(date))
        if elapsed < 60 {
            return "たった今"
        }
        if elapsed < 3_600 {
            return "\(Int(elapsed / 60))分前"
        }
        if elapsed < 86_400 {
            return "\(Int(elapsed / 3_600))時間前"
        }
        return date.formatted(date: .numeric, time: .omitted)
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
