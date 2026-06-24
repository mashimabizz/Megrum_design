#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import MegrumDesign
import SwiftUI

struct AuthVisualFeedback: Equatable {
    enum Style {
        case error
        case success
        case info
    }

    var message: String
    var style: Style
}

struct AuthChoiceScreen: View {
    let mode: AuthScreenMode
    #if canImport(AuthenticationServices)
    var onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    var onAppleCompletion: (Result<ASAuthorization, Error>) -> Void
    #endif
    var onGoogle: () -> Void
    var onEmail: () -> Void
    var onSwitch: () -> Void

    private var isSignIn: Bool { mode == .signIn }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: isSignIn ? 156 : 106)

            AuthBrandLockup(showIconTile: !isSignIn)

            if !isSignIn {
                VStack(spacing: 9) {
                    Text("Megrumをはじめる")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("アカウントを作成")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .padding(.top, 96)
            }

            VStack(spacing: 18) {
                appleProviderButton
                AuthProviderButton(
                    title: isSignIn ? "Googleでログイン" : "Googleで登録",
                    icon: .google,
                    filled: true,
                    action: onGoogle
                )
                AuthProviderButton(
                    title: isSignIn ? "メールアドレスでログイン" : "メールアドレスで登録",
                    icon: .mail,
                    filled: false,
                    action: onEmail
                )
            }
            .padding(.top, isSignIn ? 132 : 34)

            Button(action: onSwitch) {
                HStack(spacing: 6) {
                    Text(isSignIn ? "はじめての方は" : "すでにアカウントをお持ちの方は")
                        .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                    Text(isSignIn ? "新規登録" : "ログイン")
                        .fontWeight(.black)
                        .foregroundStyle(MegrumTheme.lavender)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.plain)
            .padding(.top, 54)

            if !isSignIn {
                Spacer(minLength: 102)
                Text("登録すると 利用規約・プライバシーポリシー に\n同意したことになります")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity)
        .authVisualBackground()
    }

    @ViewBuilder
    private var appleProviderButton: some View {
        #if canImport(AuthenticationServices)
        ZStack {
            AuthProviderButton(
                title: isSignIn ? "Appleでログイン" : "Appleで登録",
                icon: .apple,
                filled: true,
                action: {}
            )
            SignInWithAppleButton(.continue, onRequest: onAppleRequest, onCompletion: onAppleCompletion)
                .signInWithAppleButtonStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .opacity(0.015)
                .accessibilityLabel(isSignIn ? "Appleでログイン" : "Appleで登録")
        }
        #else
        AuthProviderButton(
            title: isSignIn ? "Appleでログイン" : "Appleで登録",
            icon: .apple,
            filled: true,
            action: {}
        )
        #endif
    }
}

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

                Text("登録すると利用規約・プライバシーポリシーに同意したことになります")
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
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
