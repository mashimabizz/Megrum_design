import Foundation
import MegrumDesign
import SwiftUI

struct BoardThreadDetailPostHeader: View {
    var detailTagTitle: String
    var title: String
    var threadBody: String
    var authorName: String
    var authorAvatarURL: URL?
    var authorInitial: String
    var authorRelativeTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detailTagTitle)
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

            Text(title)
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

                    Text(threadBody)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct BoardThreadDetailReplySummary: View {
    var replyCount: Int
    var participantAvatars: [BoardParticipantAvatar]

    var body: some View {
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
    }
}

struct BoardThreadDetailParticipantsHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .foregroundStyle(MegrumTheme.muted)

            Text("この話題に参加している人")
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
    }
}

struct BoardThreadDetailRepliesSection: View {
    var replies: [BoardReplyDisplay]
    var isLoadingReplies: Bool

    var body: some View {
        VStack(spacing: 7) {
            ForEach(replies) { reply in
                BoardThreadReplyRow(display: reply)
            }

            if isLoadingReplies {
                BoardThreadDetailRepliesLoadingRow()
            } else if replies.isEmpty {
                BoardThreadDetailRepliesEmptyRow()
            }
        }
    }
}

struct BoardThreadDetailRepliesLoadingRow: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)

            Text("返信を読み込み中")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

struct BoardThreadDetailRepliesEmptyRow: View {
    var body: some View {
        Text("まだ返信はありません")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}
