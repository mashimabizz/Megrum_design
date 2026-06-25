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
    var profile: UserProfile?
    var subtitle: String
    var commentBody: String?

    private var displayName: String {
        profile?.displayName.nilIfBlank
            ?? profile?.handle.nilIfBlank
            ?? "ユーザー"
    }

    private var handleText: String? {
        profile?.handle.nilIfBlank.map { "@\($0)" }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GroomArchiveUserAvatar(profile: profile, fallback: displayName)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
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
    var profile: UserProfile?
    var fallback: String

    var body: some View {
        AsyncImage(url: profile?.avatarURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Text(String(fallback.prefix(1)))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 42, height: 42)
        .background(MegrumTheme.lavender, in: Circle())
        .clipShape(Circle())
    }
}
