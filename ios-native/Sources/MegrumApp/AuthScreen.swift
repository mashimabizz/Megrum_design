#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import MegrumDesign
import SwiftUI

@MainActor
public struct AuthScreen: View {
    @ObservedObject var authState: MegrumAuthState
    @State var route: AuthFlowRoute
    @State var inputState = AuthScreenInputState()
    @State var appleSignInNonce: String?
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
                        email: $inputState.email,
                        password: $inputState.password,
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
                        email: $inputState.email,
                        password: $inputState.password,
                        isLoading: authState.isLoading,
                        feedback: feedbackMessage,
                        onSubmit: submitFromButton,
                        onPasswordReset: { setRoute(.passwordReset) },
                        onBackToProvider: { setRoute(.signUpChoice) },
                        onSwitch: { setRoute(.signInEmail) }
                    )
                case .passwordReset:
                    AuthPasswordResetScreen(
                        email: $inputState.passwordResetEmail,
                        isSending: authState.isLoading,
                        feedback: passwordResetFeedbackMessage,
                        onEmailChanged: handlePasswordResetEmailChanged,
                        onSend: sendPasswordResetFromButton,
                        onBack: { setRoute(.signInEmail) },
                        onLogin: { setRoute(.signInEmail) }
                    )
                case .signUpCode:
                    AuthCodeEntryScreen(
                        purpose: .signUp,
                        email: authState.pendingSignUpCodeEmail ?? inputState.email,
                        isLoading: authState.isLoading,
                        feedback: feedbackMessage,
                        onSubmit: verifySignUpCodeFromButton,
                        onResend: { resendEmailCodeFromButton(purpose: .signUp) },
                        onBack: {
                            authState.cancelPendingEmailCode(purpose: .signUp)
                            setRoute(.signUpEmail)
                        }
                    )
                case .recoveryCode:
                    AuthCodeEntryScreen(
                        purpose: .recovery,
                        email: authState.pendingRecoveryCodeEmail ?? inputState.passwordResetEmail,
                        isLoading: authState.isLoading,
                        feedback: passwordResetFeedbackMessage,
                        onSubmit: verifyRecoveryCodeFromButton,
                        onResend: { resendEmailCodeFromButton(purpose: .recovery) },
                        onBack: {
                            authState.cancelPendingEmailCode(purpose: .recovery)
                            setRoute(.passwordReset)
                        }
                    )
                case .newPassword:
                    AuthNewPasswordScreen(
                        password: $inputState.password,
                        isLoading: authState.isLoading,
                        feedback: passwordResetFeedbackMessage,
                        onSubmit: completeNewPasswordFromButton,
                        onBack: {
                            authState.cancelPendingEmailCode(purpose: .recovery)
                            setRoute(.passwordReset)
                        }
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
        .onChange(of: inputState.email) { _, _ in
            clearFeedback()
        }
        .onChange(of: inputState.password) { _, _ in
            clearFeedback()
        }
        .onChange(of: inputState.handle) { _, _ in
            clearFeedback()
        }
    }

    enum Field {
        case email
        case password
        case handle
    }
}
