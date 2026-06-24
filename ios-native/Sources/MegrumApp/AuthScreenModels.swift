public enum AuthScreenMode: String, CaseIterable, Identifiable {
    case signIn
    case signUp

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .signIn:
            "ログイン"
        case .signUp:
            "新規登録"
        }
    }
}

enum AuthFlowRoute: Equatable {
    case signInChoice
    case signUpChoice
    case signInEmail
    case signUpEmail
    case passwordReset

    init(visualQAInitialScreen: VisualQAInitialScreen?) {
        switch visualQAInitialScreen {
        case .authSignUp:
            self = .signUpChoice
        case .authEmailSignIn:
            self = .signInEmail
        case .authEmailSignUp:
            self = .signUpEmail
        case .authPasswordReset:
            self = .passwordReset
        default:
            self = .signInChoice
        }
    }

    var mode: AuthScreenMode {
        switch self {
        case .signUpChoice, .signUpEmail:
            .signUp
        case .signInChoice, .signInEmail, .passwordReset:
            .signIn
        }
    }
}
