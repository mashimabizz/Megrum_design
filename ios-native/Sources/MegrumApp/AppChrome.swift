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
                notificationLink

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
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("設定")
                                .font(.body.weight(.semibold))
                            Text("通知・住所・ブロック")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
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

extension View {
    @ViewBuilder
    func megrumHiddenNavigationBar() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func megrumInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    func megrumTextFieldStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.58), lineWidth: 1)
            }
    }
}
