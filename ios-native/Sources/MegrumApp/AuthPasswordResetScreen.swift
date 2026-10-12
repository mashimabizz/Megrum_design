import MegrumDesign
import SwiftUI

struct AuthPasswordResetScreen: View {
    @Binding var email: String
    var isSending: Bool
    var feedback: AuthVisualFeedback?
    var onEmailChanged: () -> Void
    var onSend: () -> Void
    var onBack: () -> Void
    var onLogin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AuthTopBar(title: "パスワード再設定", onBack: onBack)

            Spacer(minLength: 54)

            AuthBrandLockup(style: .compactIconAndWordmark, wordmarkWidth: 124)
                .padding(.bottom, 48)

            AuthPasswordResetIntro()

            AuthInputRow(
                title: "メールアドレス",
                text: $email,
                kind: .email,
                onChange: onEmailChanged
            )
            .padding(.top, 48)

            if let feedback {
                AuthVisualFeedbackRow(feedback: feedback)
                    .padding(.top, 14)
            }

            AuthPasswordResetActions(
                isSending: isSending,
                onSend: onSend,
                onLogin: onLogin
            )

            Spacer(minLength: 300)
        }
        .padding(.horizontal, 31)
    }
}

private struct AuthPasswordResetIntro: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "envelope")
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 84, height: 84)
                .background(MegrumTheme.lavender.opacity(0.08), in: Circle())
                .padding(.bottom, 42)

            Text("パスワードを再設定")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("登録メールアドレスを入力してください")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .padding(.top, 12)
        }
    }
}

private struct AuthPasswordResetActions: View {
    var isSending: Bool
    var onSend: () -> Void
    var onLogin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AuthPrimaryActionButton(
                title: "再設定メールを送信",
                isLoading: isSending,
                action: onSend
            )
            .padding(.top, 40)

            Button("ログインに戻る", action: onLogin)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.top, 44)
        }
    }
}
