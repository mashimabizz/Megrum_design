import MegrumDesign
import SwiftUI

/// ログイン後の設定画面から使うパスワード再設定フロー（iter1226.419）。
/// 確認コード入力 → 新パスワード設定 を1枚のシートで完結させる。
struct PasswordResetCodeFlowSheet: View {
    @ObservedObject var authState: MegrumAuthState
    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case code
        case newPassword
    }

    @State private var step: Step = .code
    @State private var newPassword = ""

    var body: some View {
        Group {
            switch step {
            case .code:
                AuthCodeEntryScreen(
                    purpose: .recovery,
                    email: authState.pendingRecoveryCodeEmail ?? "",
                    isLoading: authState.isLoading,
                    feedback: feedback,
                    onSubmit: { code in
                        Task {
                            if await authState.verifyRecoveryCode(code) {
                                newPassword = ""
                                step = .newPassword
                            }
                        }
                    },
                    onResend: {
                        Task {
                            await authState.resendPendingEmailCode(purpose: .recovery)
                        }
                    },
                    onBack: closeFlow
                )
            case .newPassword:
                AuthNewPasswordScreen(
                    password: $newPassword,
                    isLoading: authState.isLoading,
                    feedback: feedback,
                    onSubmit: {
                        Task {
                            if await authState.completePasswordReset(newPassword: newPassword) {
                                dismiss()
                            }
                        }
                    },
                    onBack: { step = .code }
                )
            }
        }
        .interactiveDismissDisabled(step == .newPassword)
    }

    private var feedback: AuthVisualFeedback? {
        if let errorMessage = authState.errorMessage {
            return AuthVisualFeedback(message: errorMessage, style: .error)
        }
        if let successMessage = authState.successMessage {
            return AuthVisualFeedback(message: successMessage, style: .success)
        }
        return nil
    }

    private func closeFlow() {
        authState.cancelPendingEmailCode(purpose: .recovery)
        dismiss()
    }
}
