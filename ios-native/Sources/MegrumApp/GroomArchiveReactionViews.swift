import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveReactionSection<Content: View>: View {
    var title: String
    var systemImage: String
    var emptyText: String
    var isEmpty: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if isEmpty {
                Text(emptyText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                content
            }
        }
    }
}

struct GroomArchiveUserReactionRow: View {
    var userID: UUID
    var identity: MeguriProfileIdentity
    var subtitle: String
    var commentBody: String?
    var onOpenProfile: (() -> Void)?
    var onMessage: (() -> Void)?

    private var displayName: String {
        identity.displayName
    }

    private var handleText: String? {
        identity.handle?.nilIfBlank.map { "@\($0)" }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { onOpenProfile?() }) {
                GroomArchiveUserAvatar(
                    avatarID: identity.avatarID,
                    avatarURL: identity.avatarURL,
                    fallback: displayName
                )
            }
            .buttonStyle(.plain)
            .disabled(onOpenProfile == nil)
            .accessibilityLabel("\(displayName)のプロフィールを開く")

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Button(action: { onOpenProfile?() }) {
                        Text(displayName)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                    }
                    .buttonStyle(.plain)
                    .disabled(onOpenProfile == nil)
                    if let handleText {
                        Text(handleText)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }
                Text(subtitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                if let commentBody, !commentBody.isBlank {
                    Text(commentBody)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            if let onMessage {
                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 44, height: 44)
                        .background(MegrumTheme.lavender.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(displayName)にメッセージを送る")
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.10), lineWidth: 1)
        }
    }
}

struct GroomArchiveUserAvatar: View {
    var avatarID: String?
    var avatarURL: URL?
    var fallback: String

    var body: some View {
        MeguriProfileAvatarView(
            avatarID: avatarID,
            avatarURL: avatarURL,
            fallback: fallback,
            size: 42
        )
    }
}
