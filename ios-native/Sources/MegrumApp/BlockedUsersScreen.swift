import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct BlockedUsersScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var userPendingUnblock: BlockedUser?
    @State private var isShowingUnblockDialog = false

    var body: some View {
        BlockedUsersContent(
            users: appState.blockedUsers,
            isLoading: appState.isLoadingBlockedUsers,
            unblockingUserID: appState.unblockingUserID,
            onRequestUnblock: requestUnblock
        )
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

    private func requestUnblock(_ user: BlockedUser) {
        userPendingUnblock = user
        isShowingUnblockDialog = true
    }
}
