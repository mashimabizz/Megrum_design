import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct BlockedUsersScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var userPendingUnblock: BlockedUser?
    @State private var isShowingUnblockDialog = false

    var body: some View {
        List {
            Section {
                if appState.isLoadingBlockedUsers {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("読み込んでいます")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                } else if appState.blockedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ブロック中のユーザーはいません")
                            .font(.headline.weight(.bold))
                        Text("必要になった時は、プロフィールや掲示板のメニューから追加できます。")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(appState.blockedUsers) { user in
                        BlockedUserRow(
                            user: user,
                            isUnblocking: appState.unblockingUserID == user.userID,
                            onUnblock: {
                                userPendingUnblock = user
                                isShowingUnblockDialog = true
                            }
                        )
                    }
                }
            } header: {
                Text("\(appState.blockedUsers.count)人")
            }
        }
        .navigationTitle("ブロックした人")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadBlockedUsers()
        }
        .refreshable {
            await appState.loadBlockedUsers()
        }
        .confirmationDialog("ブロックを解除しますか？", isPresented: $isShowingUnblockDialog, titleVisibility: .visible) {
            if let user = userPendingUnblock {
                Button("解除", role: .destructive) {
                    Task {
                        _ = await appState.unblockUser(user.userID)
                        userPendingUnblock = nil
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let user = userPendingUnblock {
                Text("\(user.displayName)さんをブロックした人から外します。")
            }
        }
    }
}

private struct BlockedUserRow: View {
    var user: BlockedUser
    var isUnblocking: Bool
    var onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            avatar

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

            Button {
                onUnblock()
            } label: {
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
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarURL = user.avatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: 46, height: 46)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: 46, height: 46)
            .overlay {
                Text(String(user.displayName.prefix(1)))
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }

    private var blockedAtText: String {
        guard let blockedAt = user.blockedAt else {
            return "ブロック中"
        }
        return blockedAt.formatted(.dateTime.month().day()) + "からブロック中"
    }
}
