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

private struct AuthTopBar: View {
    var title: String
    var onBack: () -> Void

    var body: some View {
        ZStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 29, weight: .medium))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .padding(.top, 30)
        .frame(height: 76)
    }
}

private struct AuthBrandLockup: View {
    var compact = false
    var showIconTile = false

    var body: some View {
        VStack(spacing: showIconTile ? 66 : 0) {
            if compact {
                HStack(spacing: 15) {
                    AuthRibbonMark()
                        .frame(width: 36, height: 34)
                    Text("Megrum")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            } else {
                Text("Megrum")
                    .font(.system(size: 45, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if showIconTile {
                ZStack {
                    AuthSparkleDecor()
                    Text("Mg")
                        .font(.system(size: 29, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(
                            LinearGradient(
                                colors: [
                                    MegrumTheme.lavender,
                                    MegrumTheme.sky.opacity(0.62),
                                    MegrumTheme.pink.opacity(0.74)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 21, style: .continuous)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            if !compact && !showIconTile {
                AuthRibbonMark()
                    .frame(width: 74, height: 70)
                    .offset(y: -70)
            }
        }
    }
}

private struct AuthRibbonMark: View {
    var body: some View {
        HStack(spacing: -6) {
            Capsule()
                .fill(AuthVisualStyle.primaryGradient)
                .rotationEffect(.degrees(27))
            Capsule()
                .fill(AuthVisualStyle.primaryGradient)
                .rotationEffect(.degrees(-27))
        }
    }
}

private struct AuthSparkleDecor: View {
    var body: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.38))
                .offset(x: -108, y: -7)
            Circle()
                .fill(MegrumTheme.pink.opacity(0.38))
                .frame(width: 8, height: 8)
                .offset(x: -48, y: 60)
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.34))
                .frame(width: 8, height: 8)
                .offset(x: 112, y: -51)
            Image(systemName: "sparkle")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.32))
                .offset(x: 122, y: 48)
        }
    }
}

private struct AuthProviderButton: View {
    enum ProviderIcon {
        case apple
        case google
        case mail
    }

    var title: String
    var icon: ProviderIcon
    var filled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 27) {
                iconView
                    .frame(width: 30, height: 30)
                Text(title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(icon == .mail ? MegrumTheme.lavender : MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(filled ? .white.opacity(0.94) : .clear, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(icon == .mail ? MegrumTheme.lavender.opacity(0.82) : Color.clear, lineWidth: 1.2)
            }
            .shadow(color: filled ? MegrumTheme.ink.opacity(0.08) : .clear, radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .apple:
            Image(systemName: "apple.logo")
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.black)
        case .google:
            Text("G")
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .yellow, .green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .mail:
            Image(systemName: "envelope")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct AuthPrimaryActionButton: View {
    var title: String
    var isLoading: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(AuthVisualStyle.primaryGradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

private struct AuthInputRow: View {
    enum FieldKind {
        case email
        case password
    }

    var title: String
    var systemImage: String
    @Binding var text: String
    var kind: FieldKind
    var onChange: (() -> Void)?
    @State private var showsPassword = false

    var body: some View {
        HStack(spacing: 19) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 31)

            Group {
                if kind == .password && !showsPassword {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(kind == .email ? .emailAddress : .default)
            .textContentType(kind == .email ? .emailAddress : .password)
            #endif

            if kind == .password {
                Button(action: togglePasswordVisibility) {
                    Image(systemName: showsPassword ? "eye.slash" : "eye")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.78))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 70)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.13), lineWidth: 1)
        }
        .onChange(of: text) { _, _ in
            onChange?()
        }
    }

    private func togglePasswordVisibility() {
        showsPassword.toggle()
    }
}

private struct AuthVisualFeedbackRow: View {
    var feedback: AuthVisualFeedback

    var body: some View {
        Text(feedback.message)
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(foreground.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var foreground: Color {
        switch feedback.style {
        case .error:
            Color(red: 0.851, green: 0.35, blue: 0.42)
        case .success:
            MegrumTheme.ok
        case .info:
            MegrumTheme.muted
        }
    }
}

private enum AuthVisualStyle {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.lavender, Color(red: 0.50, green: 0.40, blue: 0.86)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private extension View {
    func authVisualBackground() -> some View {
        self
            .background(
                ZStack {
                    MegrumTheme.canvas
                    RadialGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(0.15),
                            .clear
                        ],
                        center: .top,
                        startRadius: 40,
                        endRadius: 430
                    )
                }
                .ignoresSafeArea()
            )
    }
}
