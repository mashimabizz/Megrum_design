import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMapRecenterButton: View {
    var isRequesting: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isRequesting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MegrumTheme.lavender)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            .frame(width: 48, height: 48)
            .background(.regularMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.66), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("現在地へ移動")
    }
}

struct MeguriGroomArchiveButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.66), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("グルームアーカイブを開く")
    }
}

struct MeguriHomeNoticeCard: View {
    var notice: MegrumLocationNotice
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 48, height: 48)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Text(notice.message)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(14)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: MegrumTheme.ink.opacity(0.09), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        if notice.message.contains("掲示板") || notice.message.contains("投稿") {
            return "投稿できませんでした"
        }
        if notice.message.contains("読み込") {
            return "読み込めませんでした"
        }
        return "現在地を確認中"
    }
}

struct MeguriNoticeBanner: View {
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct MeguriAvatarCircle: View {
    var profile: UserProfile?
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.16))
            .frame(width: size, height: size)
            .overlay {
                if let avatarURL = profile?.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Text(profile?.displayName.first.map(String.init) ?? "M")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Text(profile?.displayName.first.map(String.init) ?? "M")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            .overlay(Circle().stroke(MegrumTheme.lavender.opacity(0.78), lineWidth: 2))
    }
}
