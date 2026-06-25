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

            AuthBrandLockup(compact: true)
                .padding(.bottom, 48)

            Image(systemName: "envelope")
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 84, height: 84)
                .background(MegrumTheme.lavender.opacity(0.08), in: Circle())
                .padding(.bottom, 42)

            Text("パスワードを再設定")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("登録メールアドレスを入力してください")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .padding(.top, 17)

            AuthInputRow(
                title: "メールアドレス",
                systemImage: "envelope",
                text: $email,
                kind: .email,
                onChange: onEmailChanged
            )
            .padding(.top, 48)

            if let feedback {
                AuthVisualFeedbackRow(feedback: feedback)
                    .padding(.top, 14)
            }

            AuthPrimaryActionButton(
                title: "再設定メールを送信",
                isLoading: isSending,
                action: onSend
            )
            .padding(.top, 40)

            Button("ログインに戻る", action: onLogin)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.top, 44)

            Spacer(minLength: 300)
        }
        .padding(.horizontal, 31)
        .authVisualBackground()
    }
}
