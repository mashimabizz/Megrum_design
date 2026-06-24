import MegrumDesign
import SwiftUI

@MainActor
struct AppDrawerScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenNotificationDestination: (MegrumTab) -> Void
    var onSignOut: () async -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                NavigationLink {
                    OwnProfileScreen(appState: appState)
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "プロフィール",
                        subtitle: "自分の表示を確認",
                        systemImage: "person.crop.circle"
                    )
                }

                notificationLink

                NavigationLink {
                    AddressSettingsScreen(appState: appState)
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "住所設定",
                        subtitle: "取引に使う住所",
                        systemImage: "shippingbox"
                    )
                }

                NavigationLink {
                    BlockedUsersScreen(appState: appState)
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "ブロックした人",
                        subtitle: "一覧と解除",
                        systemImage: "person.crop.circle.badge.xmark"
                    )
                }

                NavigationLink {
                    SettingsScreen(
                        appState: appState,
                        onOpenNotificationDestination: { tab in
                            dismiss()
                            onOpenNotificationDestination(tab)
                        },
                        onSignOut: onSignOut
                    )
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "設定",
                        subtitle: "通知・住所・ブロック",
                        systemImage: "gearshape"
                    )
                }
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await onSignOut()
                        dismiss()
                    }
                } label: {
                    Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("メニュー")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            if appState.notifications.isEmpty {
                await appState.loadNotifications()
            }
        }
    }

    @ViewBuilder
    private var notificationLink: some View {
        let link = NavigationLink {
            NotificationCenterScreen(appState: appState) { tab in
                dismiss()
                onOpenNotificationDestination(tab)
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text("通知")
                        .font(.body.weight(.semibold))
                    Text(notificationStatusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MegrumTheme.muted)
                }
            } icon: {
                Image(systemName: "bell")
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }

        if appState.unreadNotificationCount > 0 {
            link.badge(appState.unreadNotificationCount)
        } else {
            link
        }
    }

    private var notificationStatusText: String {
        guard !appState.notifications.isEmpty else {
            return "未読なし"
        }
        if appState.unreadNotificationCount > 0 {
            return "未読 \(appState.unreadNotificationCount)件"
        }
        return "すべて既読"
    }
}

private struct AppDrawerScreenRouteLabel: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}
