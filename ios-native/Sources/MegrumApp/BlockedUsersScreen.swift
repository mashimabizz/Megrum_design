import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
/// 設定の「ブロックしたユーザー」：グッズ交換／めぐりを2タブで表示する。
/// ブロックは現状アプリ共通（同一テーブル）のため、両タブの内容は同じ
/// リストになるが、導線と文言をコンテキストごとに分けている。
struct BlockedUsersTabbedScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var selectedContext: BlockedUsersContext = .exchange

    var body: some View {
        VStack(spacing: 0) {
            Picker("表示", selection: $selectedContext) {
                Text("グッズ交換").tag(BlockedUsersContext.exchange)
                Text("めぐり").tag(BlockedUsersContext.meguri)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)

            BlockedUsersScreen(
                appState: appState,
                context: selectedContext,
                navigationTitleText: "ブロックしたユーザー"
            )
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}

struct BlockedUsersScreen: View {
    @ObservedObject var appState: MegrumAppState
    var context: BlockedUsersContext = .exchange
    var navigationTitleText: String? = nil
    @State private var presentationState = BlockedUsersPresentationState()

    var body: some View {
        BlockedUsersContent(
            context: context,
            users: appState.blockedUsers,
            isLoading: appState.isLoadingBlockedUsers,
            unblockingUserID: appState.unblockingUserID,
            onRequestUnblock: requestUnblock
        )
        .navigationTitle(navigationTitleText ?? context.navigationTitle)
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
