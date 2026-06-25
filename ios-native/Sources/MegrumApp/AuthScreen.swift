#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import MegrumDesign
import SwiftUI

@MainActor
public struct AuthScreen: View {
    @ObservedObject var authState: MegrumAuthState
    @State var route: AuthFlowRoute
    @State var email = ""
    @State var password = ""
    @State var handle = ""
    @State var passwordResetEmail = ""
    @State var hasSubmittedPasswordReset = false
    @State var passwordResetInputErrorMessage: String?
    @State var appleSignInNonce: String?
    @State var identityProviderError: String?
    @State var inputErrorMessage: String?
    #if canImport(AuthenticationServices) && canImport(UIKit)
    @State var googleOAuthSession: ASWebAuthenticationSession?
    #endif
    @FocusState var focusedField: Field?

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

    enum Field {
        case email
        case password
        case handle
    }
}
