import SwiftUI

struct LoginSecurityStatusSection: View {
    var summary: LoginSecuritySummary

    var body: some View {
        Section {
            SettingsValueRow(title: "認証状態", value: summary.authStatusText)
            SettingsValueRow(title: "ログインメール", value: summary.emailText)
            SettingsValueRow(title: "認証ユーザーID", value: summary.authUserIDText, isMonospaced: true)
            SettingsValueRow(title: "プロフィールID", value: summary.profileUserIDText, isMonospaced: true)
            SettingsValueRow(title: "接続状態", value: summary.authConfigurationText)
            SettingsValueRow(title: "アカウント状態", value: summary.accountStatusText)
        } header: {
            Text("現在の状態")
        }
    }
}

struct LoginSecuritySignOutSection: View {
    var isSigningOut: Bool
    var onTap: () -> Void

    var body: some View {
        Section {
            SettingsSignOutButtonRow(
                isSigningOut: isSigningOut,
                onTap: onTap
            )
        } footer: {
            Text("ログアウトすると、この端末のセッションを外してログイン/新規登録画面に戻ります。")
        }
    }
}
