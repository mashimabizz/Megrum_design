import MegrumCore
import MegrumDesign
import SwiftUI

struct BlockedUsersContent: View {
    var users: [BlockedUser]
    var isLoading: Bool
    var unblockingUserID: UUID?
    var onRequestUnblock: (BlockedUser) -> Void

    var body: some View {
        List {
            Section {
                if isLoading {
                    BlockedUsersLoadingRow()
                } else if users.isEmpty {
                    BlockedUsersEmptyRow()
                } else {
                    ForEach(users) { user in
                        BlockedUserRow(
                            user: user,
                            isUnblocking: unblockingUserID == user.userID,
                            onUnblock: {
                                onRequestUnblock(user)
                            }
                        )
                    }
                }
            } header: {
                Text("\(users.count)人")
            }
        }
    }
}

private struct BlockedUsersLoadingRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("読み込んでいます")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private struct BlockedUsersEmptyRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ブロック中のユーザーはいません")
                .font(.headline.weight(.bold))
            Text("必要になった時は、プロフィールやチャットルームのメニューから追加できます。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 8)
    }
}

private struct BlockedUserRow: View {
    var user: BlockedUser
    var isUnblocking: Bool
    var onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BlockedUserAvatar(
                avatarURL: user.avatarURL,
                displayName: user.displayName
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.ink)
                Text("@\(user.handle)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                Text(blockedAtText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.85))
            }

            Spacer(minLength: 8)

            BlockedUserUnblockButton(
                isUnblocking: isUnblocking,
                onUnblock: onUnblock
            )
        }
        .padding(.vertical, 8)
    }

    private var blockedAtText: String {
        guard let blockedAt = user.blockedAt else {
            return "ブロック中"
        }
        return blockedAt.formatted(.dateTime.month().day()) + "からブロック中"
    }
}

private struct BlockedUserAvatar: View {
    var avatarURL: URL?
    var displayName: String

    @ViewBuilder
    var body: some View {
        if let avatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                BlockedUserAvatarPlaceholder(displayName: displayName)
            }
            .frame(width: 46, height: 46)
            .clipShape(Circle())
        } else {
            BlockedUserAvatarPlaceholder(displayName: displayName)
        }
    }
}

private struct BlockedUserUnblockButton: View {
    var isUnblocking: Bool
    var onUnblock: () -> Void

    var body: some View {
        Button(action: onUnblock) {
            if isUnblocking {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("解除")
                    .font(.subheadline.weight(.bold))
            }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .disabled(isUnblocking)
    }
}

private struct BlockedUserAvatarPlaceholder: View {
    var displayName: String

    var body: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: 46, height: 46)
            .overlay {
                Text(String(displayName.prefix(1)))
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }
}
