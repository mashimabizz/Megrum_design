import MegrumCore
import MegrumDesign
import SwiftUI

enum MeguriHomeUtilityLayout {
    static let tabBarClearance: CGFloat = 116

    static func bottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        safeAreaBottom + tabBarClearance
    }
}

enum MeguriHomeTopControlsLayout {
    static let minimumTopPadding: CGFloat = 58
    static let safeAreaGap: CGFloat = 10

    static func topPadding(safeAreaTop: CGFloat) -> CGFloat {
        max(minimumTopPadding, safeAreaTop + safeAreaGap)
    }
}

struct MeguriMapRecenterButton: View {
    var isRequesting: Bool
    var size: CGFloat = 48
    var iconSize: CGFloat = 18
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
                        .font(.system(size: iconSize, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            .frame(width: size, height: size)
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
                .frame(width: 46, height: 46)
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

struct MeguriMessageInboxButton: View {
    var unreadCount: Int
    var size: CGFloat = 48
    var iconSize: CGFloat = 18
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "message.fill")
                    .font(.system(size: iconSize, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(
                        LinearGradient(
                            colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.66), lineWidth: 1)
                    }
                    .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 16, y: 8)

                if unreadCount > 0 {
                    MeguriUnreadCountBadge(count: unreadCount, size: .homeInbox)
                        .offset(x: size >= 80 ? 8 : 14, y: size >= 80 ? -4 : -12)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard unreadCount > 0 else {
            return "めぐりメッセージを開く"
        }
        return "めぐりメッセージを開く、未読\(unreadCount)件"
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
        if notice.message.contains("チャットルーム") || notice.message.contains("投稿") {
            return "投稿できませんでした"
        }
        if notice.message.contains("読み込") {
            return "読み込めませんでした"
        }
        // 「現在地を確認中」の見出しに「許可されていません」を並べると矛盾するため、
        // 位置情報エラー系はエラーの見出しにする。
        if notice.message.contains("許可され") || notice.message.contains("オフ")
            || notice.message.contains("利用できません") || notice.message.contains("取得できません") {
            return "位置情報を確認できません"
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
