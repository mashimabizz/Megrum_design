#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import SwiftUI

extension AuthScreen {
    func startGoogleSignInFromChoice() {
        #if canImport(AuthenticationServices) && canImport(UIKit)
        startGoogleSignIn()
        #else
        inputState.identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
        #endif
    }

    #if canImport(AuthenticationServices) && canImport(UIKit)
    func startGoogleSignIn() {
        focusedField = nil
        clearFeedback()

        guard let callbackScheme = authState.oauthCallbackScheme else {
            inputState.identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
            return
        }

        do {
            let authorizeURL = try authState.googleOAuthAuthorizeURL()
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                Task { @MainActor in
                    googleOAuthSession = nil
                    if let sessionError = error as? ASWebAuthenticationSessionError,
                       sessionError.code == .canceledLogin {
                        return
                    }
                    guard let callbackURL else {
                        inputState.identityProviderError = "Googleでのログインに失敗しました。もう一度お試しください"
                        return
                    }
                    let handled = await authState.handleOpenURL(callbackURL)
                    if !handled, authState.errorMessage == nil {
                        inputState.identityProviderError = "Googleログイン情報を取得できませんでした。もう一度お試しください"
                    }
                }
            }
            session.presentationContextProvider = OAuthPresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            googleOAuthSession = session
            if !session.start() {
                googleOAuthSession = nil
                inputState.identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
            }
        } catch {
            inputState.identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
        }
    }
    #endif
}

#if canImport(AuthenticationServices)
extension AuthScreen {
    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.make()
        appleSignInNonce = nonce
        inputState.identityProviderError = nil
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInNonce.sha256(nonce)
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = appleSignInNonce,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                inputState.identityProviderError = "Appleログイン情報を取得できませんでした。もう一度お試しください"
                appleSignInNonce = nil
                return
            }

            appleSignInNonce = nil
            let fullName = AppleSignInNonce.displayName(from: credential.fullName)
            Task {
                await authState.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName)
            }
        case let .failure(error):
            appleSignInNonce = nil
            if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
                return
            }
            inputState.identityProviderError = "Appleでのログインに失敗しました。もう一度お試しください"
        }
    }
}
#endif
