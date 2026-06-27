import MegrumDesign
import SwiftUI

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

    var body: some View {
        VStack(spacing: 0) {
            AuthTopBar(title: isSignIn ? "メールでログイン" : "メールで登録", onBack: onBackToProvider)

            Spacer(minLength: isSignIn ? 22 : 36)

            AuthBrandLockup(compact: true)
                .padding(.bottom, isSignIn ? 38 : 44)

            if !isSignIn {
                Text("メールアドレスで登録")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .frame(maxWidth: .infinity)
            }

            AuthEmailCredentialFields(email: $email, password: $password)
                .padding(.top, isSignIn ? 36 : 50)

            if let feedback {
                AuthVisualFeedbackRow(feedback: feedback)
                    .padding(.top, 14)
            }

            AuthPrimaryActionButton(
                title: isSignIn ? "ログインする" : "新規登録する",
                isLoading: isLoading,
                action: onSubmit
            )
            .padding(.top, isSignIn ? 44 : 56)

            if isSignIn {
                Button("パスワードを忘れた場合", action: onPasswordReset)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.top, 30)

                Button("Apple / Googleでログインに戻る", action: onBackToProvider)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity)
                    .frame(height: 66)
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(MegrumTheme.lavender.opacity(0.72), lineWidth: 1.2)
                    }
                    .padding(.top, 46)
            } else {
                Button("Apple / Googleで登録に戻る", action: onBackToProvider)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.top, 38)
                Divider()
                    .padding(.top, 46)
                Button(action: onSwitch) {
                    HStack(spacing: 7) {
                        Text("すでにアカウントをお持ちの方は")
                            .foregroundStyle(MegrumTheme.muted)
                        Text("ログイン")
                            .fontWeight(.black)
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.plain)
                .padding(.top, 31)

                AuthLegalConsentNotice(fontSize: 11.5)
                    .padding(.top, 44)
            }

            if isSignIn {
                Spacer(minLength: 88)
                Button(action: onSwitch) {
                    HStack(spacing: 7) {
                        Text("はじめての方は")
                            .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                        Text("新規登録")
                            .fontWeight(.black)
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 66)
                    .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 36)
        }
        .padding(.horizontal, 31)
        .authVisualBackground()
    }
}

private struct AuthEmailCredentialFields: View {
    @Binding var email: String
    @Binding var password: String

    var body: some View {
        VStack(spacing: 18) {
            AuthInputRow(
                title: "メールアドレス",
                systemImage: "envelope",
                text: $email,
                kind: .email
            )
            AuthInputRow(
                title: "パスワード",
                systemImage: "lock",
                text: $password,
                kind: .password
            )
        }
    }
}
