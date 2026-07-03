import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct BlockedUsersScreen: View {
    @ObservedObject var appState: MegrumAppState
    var context: BlockedUsersContext = .exchange
    @State private var presentationState = BlockedUsersPresentationState()

    var body: some View {
        BlockedUsersContent(
            context: context,
            users: appState.blockedUsers,
            isLoading: appState.isLoadingBlockedUsers,
            unblockingUserID: appState.unblockingUserID,
            onRequestUnblock: requestUnblock
        )
        .navigationTitle(context.navigationTitle)
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadBlockedUsers()
        }
        .refreshable {
            await appState.loadBlockedUsers()
        }
        .confirmationDialog("ブロックを解除しますか？", isPresented: $presentationState.isShowingUnblockDialog, titleVisibility: .visible) {
            if let user = presentationState.userPendingUnblock {
                Button("解除", role: .destructive) {
                    Task {
                        _ = await appState.unblockUser(user.userID)
                        presentationState.clearPendingUnblock()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let user = presentationState.userPendingUnblock {
                Text(context.unblockConfirmationMessage(for: user.displayName))
            }
        }
    }

    private func requestUnblock(_ user: BlockedUser) {
        presentationState.requestUnblock(user)
    }
}
