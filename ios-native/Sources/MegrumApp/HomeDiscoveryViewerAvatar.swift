import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryViewerAvatar: View {
    var viewer: UserProfile?

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
                if let avatarURL = viewer?.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackInitial
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackInitial
                }
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.82), lineWidth: 1.4)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.18), radius: 10, y: 5)
    }

    private var fallbackInitial: some View {
        Text(initial)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
    }

    private var initial: String {
        guard let first = viewer?.displayName.first else {
            return "M"
        }
        return String(first)
    }
}
