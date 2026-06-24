import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardReplyDisplay: Identifiable {
    var id: UUID { reply.id }
    var reply: BoardReply
    var displayName: String
    var avatarURL: URL?
    var initial: String
    var isMine: Bool
    var relativeTime: String
}

struct BoardParticipantAvatar: Identifiable {
    var id: UUID
    var avatarURL: URL?
    var initial: String
}

struct BoardThreadDetailHeader: View {
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

struct BoardThreadDetailCard: View {
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

struct BoardReplyInput: View {
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
