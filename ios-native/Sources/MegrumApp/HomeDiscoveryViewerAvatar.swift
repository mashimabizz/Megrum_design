import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryViewerAvatar: View {
    var viewer: UserProfile?

    private var avatarURL: URL? {
        viewer?.avatarURL
    }

    private var initial: String {
        guard let first = viewer?.displayName.first else {
            return "M"
        }
        return String(first)
    }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                HomeDiscoveryViewerAvatarImageLayer(
                    avatarURL: avatarURL,
                    initial: initial
                )
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.82), lineWidth: 1.4)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.18), radius: 10, y: 5)
    }
}

private struct HomeDiscoveryViewerAvatarImageLayer: View {
    var avatarURL: URL?
    var initial: String

    var body: some View {
        if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    HomeDiscoveryViewerAvatarFallbackInitial(initial: initial)
                }
            }
            .clipShape(Circle())
        } else {
            HomeDiscoveryViewerAvatarFallbackInitial(initial: initial)
        }
    }
}

private struct HomeDiscoveryViewerAvatarFallbackInitial: View {
    var initial: String

    var body: some View {
        Text(initial)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
    }
}
