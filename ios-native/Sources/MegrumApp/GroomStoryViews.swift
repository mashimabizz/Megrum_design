import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomFeedOrdering {
    static func sorted(
        _ grooms: [GroomPost],
        viewerID: UUID?,
        viewedIDs: Set<UUID>
    ) -> [GroomPost] {
        grooms
            .filter { $0.authorID != viewerID }
            .sorted { lhs, rhs in
                let lhsViewed = viewedIDs.contains(lhs.id)
                let rhsViewed = viewedIDs.contains(rhs.id)
                if lhsViewed != rhsViewed {
                    return !lhsViewed && rhsViewed
                }
                return lhs.createdAt > rhs.createdAt
            }
    }
}

struct GroomStrip: View {
    var grooms: [GroomPost]
    var viewer: UserProfile?
    var publicProfilesByUserID: [UUID: PublicUserProfile]
    var viewedGroomIDs: Set<UUID>
    var isCreating: Bool
    var onAdd: () -> Void
    var onSelect: (GroomPost) -> Void

    private var displayGrooms: [GroomPost] {
        GroomFeedOrdering.sorted(grooms, viewerID: viewer?.id, viewedIDs: viewedGroomIDs)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 22) {
                GroomMyStoryTile(
                    viewer: viewer,
                    isLoading: isCreating,
                    onAdd: onAdd
                )

                if displayGrooms.isEmpty {
                    GroomEmptyStoryHint()
                }

                ForEach(displayGrooms) { groom in
                    Button {
                        onSelect(groom)
                    } label: {
                        GroomStoryTile(
                            groom: groom,
                            profile: publicProfilesByUserID[groom.authorID]?.profile,
                            isRead: viewedGroomIDs.contains(groom.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(groomStoryName(for: groom))のグルーム")
                    .id(groom.id)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func groomStoryName(for groom: GroomPost) -> String {
        if let profile = publicProfilesByUserID[groom.authorID]?.profile {
            return profile.handle.nilIfBlank ?? profile.displayName.nilIfBlank ?? "グルーム"
        }
        return "グルーム"
    }
}

private struct GroomMyStoryTile: View {
    var viewer: UserProfile?
    var isLoading: Bool
    var onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    GroomAvatarCircle(
                        avatarURL: viewer?.avatarURL,
                        fallbackText: viewer?.displayName.nilIfBlank ?? viewer?.handle.nilIfBlank ?? "Me",
                        size: 82,
                        backgroundOpacity: 0.92
                    )
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    }
                    .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 10, y: 5)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 30, height: 30)
                            .background(MegrumTheme.ink, in: Circle())
                            .offset(x: 2, y: 2)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(MegrumTheme.ink, in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            }
                            .offset(x: 3, y: 3)
                    }
                }

                Text("グルーム")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .frame(width: 88)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("グルームを追加")
    }
}

private struct GroomStoryTile: View {
    var groom: GroomPost
    var profile: UserProfile?
    var isRead: Bool

    private var displayName: String {
        profile?.handle.nilIfBlank ?? profile?.displayName.nilIfBlank ?? "めぐり"
    }

    private var fallbackText: String {
        profile?.displayName.nilIfBlank ?? profile?.handle.nilIfBlank ?? "?"
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                GroomStoryRing(isRead: isRead, size: 86)
                GroomAvatarCircle(
                    avatarURL: profile?.avatarURL,
                    fallbackText: fallbackText,
                    size: 74,
                    backgroundOpacity: isRead ? 0.72 : 0.96
                )
                .opacity(isRead ? 0.72 : 1)
            }
            .shadow(color: isRead ? .clear : MegrumTheme.pink.opacity(0.15), radius: 10, y: 5)

            Text(displayName)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(isRead ? MegrumTheme.muted : MegrumTheme.ink)
                .lineLimit(1)
                .frame(width: 88)
        }
    }
}

private struct GroomStoryRing: View {
    var isRead: Bool
    var size: CGFloat

    var body: some View {
        Circle()
            .stroke(
                isRead
                    ? AnyShapeStyle(MegrumTheme.muted.opacity(0.22))
                    : AnyShapeStyle(
                        AngularGradient(
                            colors: [
                                Color(red: 1.0, green: 0.07, blue: 0.45),
                                Color(red: 0.82, green: 0.03, blue: 0.88),
                                Color(red: 1.0, green: 0.50, blue: 0.0),
                                Color(red: 1.0, green: 0.07, blue: 0.45)
                            ],
                            center: .center
                        )
                    ),
                lineWidth: isRead ? 2 : 5
            )
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.9), lineWidth: 2)
                    .padding(5)
            }
    }
}

private struct GroomAvatarCircle: View {
    var avatarURL: URL?
    var fallbackText: String
    var size: CGFloat
    var backgroundOpacity: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(backgroundOpacity),
                            MegrumTheme.sky.opacity(backgroundOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .contentShape(Circle())
    }

    private var fallbackAvatar: some View {
        Text(String(fallbackText.prefix(1)).uppercased())
            .font(.system(size: size * 0.36, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.4), radius: 6)
    }
}

private struct GroomEmptyStoryHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("近くのグルームはまだありません")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)

            Text("追加すると、近くの人にだけ届きます。")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .frame(width: 178, height: 82, alignment: .leading)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
