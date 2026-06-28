#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import MegrumDesign
import SwiftUI

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
            Spacer(minLength: 132)

            AuthBrandLockup(style: .iconAboveWordmark)

            VStack(spacing: 18) {
                #if canImport(AuthenticationServices)
                AuthAppleProviderButton(
                    isSignIn: isSignIn,
                    onRequest: onAppleRequest,
                    onCompletion: onAppleCompletion
                )
                #else
                AuthAppleProviderButton(isSignIn: isSignIn)
                #endif
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
            .padding(.top, 62)

            AuthChoiceModeSwitchButton(isSignIn: isSignIn, action: onSwitch)
                .padding(.top, 44)

            if !isSignIn {
                Spacer(minLength: 72)
                AuthLegalConsentNotice(fontSize: 13)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity)
        .authVisualBackground()
    }
}

private struct AuthAppleProviderButton: View {
    var isSignIn: Bool
    #if canImport(AuthenticationServices)
    var onRequest: (ASAuthorizationAppleIDRequest) -> Void
    var onCompletion: (Result<ASAuthorization, Error>) -> Void
    #endif

    @ViewBuilder
    var body: some View {
        #if canImport(AuthenticationServices)
        ZStack {
            AuthProviderButton(
                title: isSignIn ? "Appleでログイン" : "Appleで登録",
                icon: .apple,
                filled: true,
                action: {}
            )
            SignInWithAppleButton(.continue, onRequest: onRequest, onCompletion: onCompletion)
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

private struct AuthChoiceModeSwitchButton: View {
    var isSignIn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
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
    }
}
