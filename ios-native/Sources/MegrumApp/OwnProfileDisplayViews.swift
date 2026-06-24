import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct OwnProfilePageHeader: View {
    var onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.86), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("戻る")

            Spacer()

            Text("プロフィール")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Color.clear
                .frame(width: 38, height: 38)
                .accessibilityHidden(true)
        }
    }
}

struct OwnProfileAvatarImage: View {
    var avatarURL: URL?
    var localData: Data?
    var initial: String
    var size: CGFloat

    var body: some View {
        ZStack {
            avatarContent
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.85), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        .accessibilityLabel("プロフィール画像")
    }

    @ViewBuilder
    private var avatarContent: some View {
#if canImport(UIKit)
        if let localData, let image = UIImage(data: localData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            remoteAvatar(url: avatarURL)
        } else {
            fallbackAvatar
        }
#elseif canImport(AppKit)
        if let localData, let image = NSImage(data: localData) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            remoteAvatar(url: avatarURL)
        } else {
            fallbackAvatar
        }
#else
        if let avatarURL {
            remoteAvatar(url: avatarURL)
        } else {
            fallbackAvatar
        }
#endif
    }

    private func remoteAvatar(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                fallbackAvatar
            }
        }
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.sky],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initial)
                .font(.system(size: size * 0.44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
