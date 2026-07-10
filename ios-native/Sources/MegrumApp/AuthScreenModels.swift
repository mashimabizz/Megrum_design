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
    /// 新規登録の確認コード入力（iter1226.418）。
    case signUpCode
    /// パスワード再設定の確認コード入力（iter1226.418）。
    case recoveryCode
    /// リカバリ検証後の新パスワード設定（iter1226.418）。
    case newPassword

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
        case .authSignUpCode:
            self = .signUpCode
        case .authRecoveryCode:
            self = .recoveryCode
        case .authNewPassword:
            self = .newPassword
        default:
            self = .signInChoice
        }
    }

    var mode: AuthScreenMode {
        switch self {
        case .signUpChoice, .signUpEmail, .signUpCode:
            .signUp
        case .signInChoice, .signInEmail, .passwordReset, .recoveryCode, .newPassword:
            .signIn
        }
    }
}
