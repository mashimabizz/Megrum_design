import MegrumDesign
import SwiftUI

/// メールでログイン／登録（iter1226.406 刷新）：
/// 入力欄は上ラベル＋淡い塗り、主CTAは共通グラデボタン、入力が揃うまで非活性。
/// 縦積みだったリンク類はテキストリンクに整理し、ボタンの数を実質2つに減らす。
struct AuthEmailScreen: View {
    let mode: AuthScreenMode
    @Binding var email: String
    @Binding var password: String
    var isLoading: Bool
    var feedback: AuthVisualFeedback?
    var onSubmit: () -> Void
    var onPasswordReset: () -> Void
    var onBackToProvider: () -> Void
    var onSwitch: () -> Void

    private var isSignIn: Bool { mode == .signIn }

    /// リアルタイムバリデーション：形式が揃うまで主CTAを非活性にする。
    private var canSubmit: Bool {
        if isSignIn {
            return MegrumAuthInputValidator.signInValidationMessage(email: email, password: password) == nil
        }
        return MegrumAuthInputValidator.signUpValidationMessage(email: email, password: password, handle: nil) == nil
    }

    var body: some View {
        VStack(spacing: 0) {
            AuthTopBar(title: isSignIn ? "メールでログイン" : "メールで登録", onBack: onBackToProvider)

            Spacer(minLength: 44)

            AuthBrandLockup(style: .wordmarkOnly, wordmarkWidth: 132)
                .padding(.bottom, 40)

            VStack(spacing: 16) {
                AuthInputRow(
                    title: "メールアドレス",
                    text: $email,
                    kind: .email
                )

                VStack(alignment: .trailing, spacing: 10) {
                    AuthInputRow(
                        title: "パスワード",
                        text: $password,
                        kind: .password
                    )

                    if isSignIn {
                        Button("パスワードを忘れた場合", action: onPasswordReset)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    } else {
                        Text("8文字以上で入力してください")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let feedback {
                AuthVisualFeedbackRow(feedback: feedback)
                    .padding(.top, 14)
            }

            AuthPrimaryActionButton(
                title: isSignIn ? "ログインする" : "新規登録する",
                isLoading: isLoading,
                isDisabled: !canSubmit,
                action: onSubmit
            )
            .padding(.top, 28)

            Button(isSignIn ? "Apple / Googleでログインに戻る" : "Apple / Googleで登録に戻る", action: onBackToProvider)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.top, 24)

            Spacer(minLength: 48)

            Button(action: onSwitch) {
                HStack(spacing: 6) {
                    Text(isSignIn ? "はじめての方は" : "すでにアカウントをお持ちの方は")
                        .foregroundStyle(MegrumTheme.muted)
                    Text(isSignIn ? "新規登録" : "ログイン")
                        .fontWeight(.bold)
                        .foregroundStyle(MegrumTheme.lavender)
                }
                .font(.system(size: 15, weight: .medium, design: .rounded))
            }
            .buttonStyle(.plain)

            if !isSignIn {
                AuthLegalConsentNotice(fontSize: 11.5)
                    .padding(.top, 20)
            }

            Spacer(minLength: 36)
        }
        .padding(.horizontal, 28)
    }
}
