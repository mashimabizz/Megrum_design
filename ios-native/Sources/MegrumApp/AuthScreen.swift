#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import MegrumDesign
import SwiftUI

@MainActor
public struct AuthScreen: View {
    @ObservedObject private var authState: MegrumAuthState
    @State private var route: AuthFlowRoute
    @State private var email = ""
    @State private var password = ""
    @State private var handle = ""
    @State private var passwordResetEmail = ""
    @State private var hasSubmittedPasswordReset = false
    @State private var passwordResetInputErrorMessage: String?
    @State private var appleSignInNonce: String?
    @State private var identityProviderError: String?
    @State private var inputErrorMessage: String?
    #if canImport(AuthenticationServices) && canImport(UIKit)
    @State private var googleOAuthSession: ASWebAuthenticationSession?
    #endif
    @FocusState private var focusedField: Field?

    private var mode: AuthScreenMode { route.mode }

    private var feedbackMessage: AuthVisualFeedback? {
        if !authState.isConfigured {
            return nil
        }
        if let inputErrorMessage {
            return AuthVisualFeedback(message: inputErrorMessage, style: .error)
        }
        if let errorMessage = authState.errorMessage {
            return AuthVisualFeedback(message: errorMessage, style: .error)
        }
        if let identityProviderError {
            return AuthVisualFeedback(message: identityProviderError, style: .error)
        }
        if let successMessage = authState.successMessage {
            return AuthVisualFeedback(message: successMessage, style: .success)
        }
        if let passwordResetMessage = authState.passwordResetMessage {
            return AuthVisualFeedback(message: passwordResetMessage, style: .success)
        }
        return nil
    }

    private var passwordResetFeedbackMessage: AuthVisualFeedback? {
        guard hasSubmittedPasswordReset else {
            return nil
        }
        if let passwordResetInputErrorMessage {
            return AuthVisualFeedback(message: passwordResetInputErrorMessage, style: .error)
        }
        if let errorMessage = authState.errorMessage {
            return AuthVisualFeedback(message: errorMessage, style: .error)
        }
        if let passwordResetMessage = authState.passwordResetMessage {
            return AuthVisualFeedback(message: passwordResetMessage, style: .success)
        }
        return nil
    }

    private var validationMessage: String? {
        switch mode {
        case .signIn:
            MegrumAuthInputValidator.signInValidationMessage(email: email, password: password)
        case .signUp:
            MegrumAuthInputValidator.signUpValidationMessage(email: email, password: password, handle: handle)
        }
    }

    public init(authState: MegrumAuthState) {
        self.authState = authState
        let route = AuthFlowRoute.signInChoice
        self._route = State(initialValue: route)
    }

    init(authState: MegrumAuthState, visualQAInitialScreen: VisualQAInitialScreen?) {
        self.authState = authState
        let route = AuthFlowRoute(visualQAInitialScreen: visualQAInitialScreen)
        self._route = State(initialValue: route)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                switch route {
                case .signInChoice:
                    AuthChoiceScreen(
                        mode: .signIn,
                        onAppleRequest: prepareAppleSignIn,
                        onAppleCompletion: handleAppleSignIn,
                        onGoogle: startGoogleSignInFromChoice,
                        onEmail: { setRoute(.signInEmail) },
                        onSwitch: { setRoute(.signUpChoice) }
                    )
                case .signUpChoice:
                    AuthChoiceScreen(
                        mode: .signUp,
                        onAppleRequest: prepareAppleSignIn,
                        onAppleCompletion: handleAppleSignIn,
                        onGoogle: startGoogleSignInFromChoice,
                        onEmail: { setRoute(.signUpEmail) },
                        onSwitch: { setRoute(.signInChoice) }
                    )
                case .signInEmail:
                    AuthEmailScreen(
                        mode: .signIn,
                        email: $email,
                        password: $password,
                        isLoading: authState.isLoading,
                        feedback: feedbackMessage,
                        onSubmit: submitFromButton,
                        onPasswordReset: { setRoute(.passwordReset) },
                        onBackToProvider: { setRoute(.signInChoice) },
                        onSwitch: { setRoute(.signUpEmail) }
                    )
                case .signUpEmail:
                    AuthEmailScreen(
                        mode: .signUp,
                        email: $email,
                        password: $password,
                        isLoading: authState.isLoading,
                        feedback: feedbackMessage,
                        onSubmit: submitFromButton,
                        onPasswordReset: { setRoute(.passwordReset) },
                        onBackToProvider: { setRoute(.signUpChoice) },
                        onSwitch: { setRoute(.signInEmail) }
                    )
                case .passwordReset:
                    AuthPasswordResetScreen(
                        email: $passwordResetEmail,
                        isSending: authState.isLoading,
                        feedback: passwordResetFeedbackMessage,
                        onEmailChanged: handlePasswordResetEmailChanged,
                        onSend: sendPasswordResetFromButton,
                        onBack: { setRoute(.signInEmail) },
                        onLogin: { setRoute(.signInEmail) }
                    )
                }
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .background(
                MegrumTheme.canvas
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusedField = nil
                    }
            )
            #if os(iOS)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") {
                        focusedField = nil
                    }
                }
            }
            #endif
        }
        .onChange(of: email) { _, _ in
            clearFeedback()
        }
        .onChange(of: password) { _, _ in
            clearFeedback()
        }
        .onChange(of: handle) { _, _ in
            clearFeedback()
        }
    }

    private func setRoute(_ nextRoute: AuthFlowRoute) {
        route = nextRoute
        if nextRoute == .passwordReset {
            passwordResetEmail = MegrumAuthInputValidator.normalizedEmail(email)
            hasSubmittedPasswordReset = false
            passwordResetInputErrorMessage = nil
        }
        clearFeedback()
        focusedField = nil
    }

    private func submitFromButton() {
        Task { await submit() }
    }

    private func sendPasswordResetFromButton() {
        Task { await sendPasswordReset() }
    }

    private func handlePasswordResetEmailChanged() {
        hasSubmittedPasswordReset = false
        passwordResetInputErrorMessage = nil
        authState.clearFeedback()
    }

    private func startGoogleSignInFromChoice() {
        #if canImport(AuthenticationServices) && canImport(UIKit)
        startGoogleSignIn()
        #else
        identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
        #endif
    }

    private func sendPasswordReset() async {
        hasSubmittedPasswordReset = true
        let normalizedEmail = MegrumAuthInputValidator.normalizedEmail(passwordResetEmail)
        identityProviderError = nil
        inputErrorMessage = nil
        passwordResetInputErrorMessage = nil
        if let validationMessage = MegrumAuthInputValidator.passwordResetValidationMessage(email: normalizedEmail) {
            authState.clearFeedback()
            passwordResetInputErrorMessage = validationMessage
            return
        }

        email = normalizedEmail
        let sent = await authState.sendPasswordReset(email: normalizedEmail)
        if sent {
            focusedField = nil
        }
    }

    private func submit() async {
        focusedField = nil
        identityProviderError = nil
        email = MegrumAuthInputValidator.normalizedEmail(email)
        if mode == .signUp {
            handle = MegrumAuthInputValidator.normalizedHandle(handle) ?? ""
        }
        inputErrorMessage = validationMessage
        guard inputErrorMessage == nil else {
            authState.clearFeedback()
            return
        }

        switch mode {
        case .signIn:
            await authState.signIn(email: email, password: password)
        case .signUp:
            await authState.signUp(email: email, password: password, handle: handle)
        }
    }

    private func clearFeedback() {
        inputErrorMessage = nil
        identityProviderError = nil
        authState.clearFeedback()
    }

    #if canImport(AuthenticationServices) && canImport(UIKit)
    private func startGoogleSignIn() {
        focusedField = nil
        clearFeedback()

        guard let callbackScheme = authState.oauthCallbackScheme else {
            identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
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
                        identityProviderError = "Googleでのログインに失敗しました。もう一度お試しください"
                        return
                    }
                    let handled = await authState.handleOpenURL(callbackURL)
                    if !handled, authState.errorMessage == nil {
                        identityProviderError = "Googleログイン情報を取得できませんでした。もう一度お試しください"
                    }
                }
            }
            session.presentationContextProvider = OAuthPresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            googleOAuthSession = session
            if !session.start() {
                googleOAuthSession = nil
                identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
            }
        } catch {
            identityProviderError = "Googleログインを開始できませんでした。もう一度お試しください"
        }
    }
    #endif

    private enum Field {
        case email
        case password
        case handle
    }
}

#if canImport(AuthenticationServices)
private extension AuthScreen {
    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.make()
        appleSignInNonce = nonce
        identityProviderError = nil
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
                identityProviderError = "Appleログイン情報を取得できませんでした。もう一度お試しください"
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
            identityProviderError = "Appleでのログインに失敗しました。もう一度お試しください"
        }
    }
}

#endif
