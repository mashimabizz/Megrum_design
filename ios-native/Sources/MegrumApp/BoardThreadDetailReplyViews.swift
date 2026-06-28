import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardThreadReplyRow: View {
    var display: BoardReplyDisplay

    var body: some View {
        if display.isMine {
            BoardThreadMineReply(display: display)
        } else {
            HStack(alignment: .top, spacing: 10) {
                BoardThreadDetailAvatar(
                    avatarID: display.avatarID,
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

struct BoardThreadDetailAvatarStack: View {
    var avatars: [BoardParticipantAvatar]

    var body: some View {
        HStack(spacing: -7) {
            ForEach(avatars.prefix(5)) { avatar in
                BoardThreadDetailAvatar(
                    avatarID: avatar.avatarID,
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

struct BoardThreadDetailAvatar: View {
    var avatarID: String?
    var imageURL: URL?
    var initial: String
    var size: CGFloat

    var body: some View {
        if let avatarID, !avatarID.isBlank {
            BoardAnonymousAvatar(
                option: BoardAnonymousAvatarOption.option(id: avatarID),
                size: size
            )
        } else {
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
    }

    private var fallbackInitial: some View {
        Text(initial)
            .font(.system(size: size * 0.38, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
    }
}
