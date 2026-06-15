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

private struct BoardReplyDisplay: Identifiable {
    var id: UUID { reply.id }
    var reply: BoardReply
    var displayName: String
    var avatarURL: URL?
    var initial: String
    var isMine: Bool
    var relativeTime: String
}

private struct BoardParticipantAvatar: Identifiable {
    var id: UUID
    var avatarURL: URL?
    var initial: String
}

private struct BoardThreadDetailHeader: View {
    var onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("話題")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 44, height: 44, alignment: .trailing)
        }
    }
}

private struct BoardThreadDetailCard: View {
    var thread: BoardThread
    var authorName: String
    var authorAvatarURL: URL?
    var authorInitial: String
    var authorRelativeTime: String
    var replyCount: Int
    var participantAvatars: [BoardParticipantAvatar]
    var replies: [BoardReplyDisplay]
    var isLoadingReplies: Bool
    var missingReplyContextMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(thread.detailTagTitle)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 13)
                .frame(height: 23)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender.opacity(0.20), MegrumTheme.lavender.opacity(0.07)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )

            Text(thread.title)
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            HStack(alignment: .top, spacing: 12) {
                BoardThreadDetailAvatar(
                    imageURL: authorAvatarURL,
                    initial: authorInitial,
                    size: 42
                )

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 12) {
                        Text(authorName)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                        Text(authorRelativeTime)
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Text(thread.body)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .center) {
                BoardThreadDetailAvatarStack(avatars: participantAvatars)

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                        Text("\(replyCount)")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)

                    Text("話題への返信数")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Divider()
                .background(MegrumTheme.ink.opacity(0.09))

            if let missingReplyContextMessage {
                MeguriNoticeBanner(message: missingReplyContextMessage)
            }

            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(MegrumTheme.muted)
                Text("この話題に参加している人")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            VStack(spacing: 7) {
                ForEach(replies) { reply in
                    BoardThreadReplyRow(display: reply)
                }

                if isLoadingReplies {
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
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
        }
    }
}

private struct BoardThreadReplyRow: View {
    var display: BoardReplyDisplay

    var body: some View {
        if display.isMine {
            BoardThreadMineReply(display: display)
        } else {
            HStack(alignment: .top, spacing: 10) {
                BoardThreadDetailAvatar(
                    imageURL: display.avatarURL,
                    initial: display.initial,
                    size: 36
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(display.displayName)
                            .font(.system(size: 13.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(display.relativeTime)
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        Spacer()
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Text(display.reply.status == .deleted ? "削除済みです" : display.reply.body)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
                        }

                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                        Text(display.relativeTime)
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .frame(height: 20)
                    .background(.white.opacity(0.92), in: Capsule())
                    .overlay(Capsule().strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1))
                }
            }
        }
    }
}

private struct BoardThreadMineReply: View {
    var display: BoardReplyDisplay

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("あなた")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(display.relativeTime)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Text(display.reply.status == .deleted ? "削除済みです" : display.reply.body)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(.white.opacity(0.76), in: Capsule())
                    .overlay(Capsule().strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1))
            }
            .padding(9)
            .frame(width: 268)
            .background(MegrumTheme.lavender.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle")
                Text(display.relativeTime)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct BoardReplyInput: View {
    @Binding var text: String
    var isSending: Bool
    var isDisabled = false
    var onSend: () -> Void

    private var canSend: Bool {
        !text.isBlank && !isSending && !isDisabled
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            Image(systemName: "camera")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            TextField("この話題に返信する", text: $text, axis: .vertical)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1...3)
                .submitLabel(.send)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 40)
                .background(.white.opacity(0.94), in: Capsule())
                .overlay(Capsule().strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1))
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
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(MegrumTheme.lavender, in: Circle())
                .shadow(color: MegrumTheme.lavender.opacity(0.34), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.45)
        }
        .foregroundStyle(MegrumTheme.lavender)
        .padding(.horizontal, 20)
        .frame(height: 68)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 18, y: -5)
        .opacity(isDisabled ? 0.62 : 1)
    }
}

private struct BoardThreadDetailAvatarStack: View {
    var avatars: [BoardParticipantAvatar]

    var body: some View {
        HStack(spacing: -7) {
            ForEach(avatars.prefix(5)) { avatar in
                BoardThreadDetailAvatar(
                    imageURL: avatar.avatarURL,
                    initial: avatar.initial,
                    size: 28
                )
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
            }

            if avatars.count > 5 {
                Text("+\(avatars.count - 5)")
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 38, height: 38)
                    .background(MegrumTheme.lavender.opacity(0.09), in: Circle())
            }
        }
    }
}

private struct BoardThreadDetailAvatar: View {
    var imageURL: URL?
    var initial: String
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.14))
            .frame(width: size, height: size)
            .overlay {
                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallbackInitial
                        default:
                            ProgressView()
                                .tint(MegrumTheme.lavender)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackInitial
                }
            }
            .clipShape(Circle())
    }

    private var fallbackInitial: some View {
        Text(initial)
            .font(.system(size: size * 0.38, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
    }
}

private extension BoardThread {
    var detailTagTitle: String {
        if title.contains("物販") {
            return "LE SSERAFIM"
        }
        if audience == .samePrefecture, let prefecture {
            return prefecture
        }
        return "同じ現場"
    }
}
