import SwiftUI

extension AuthScreen {
    var mode: AuthScreenMode { route.mode }

    var feedbackMessage: AuthVisualFeedback? {
        if !authState.isConfigured {
            return nil
        }
        if let inputErrorMessage = inputState.inputErrorMessage {
            return AuthVisualFeedback(message: inputErrorMessage, style: .error)
        }
        if let errorMessage = authState.errorMessage {
            return AuthVisualFeedback(message: errorMessage, style: .error)
        }
        if let identityProviderError = inputState.identityProviderError {
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

    var passwordResetFeedbackMessage: AuthVisualFeedback? {
        guard inputState.hasSubmittedPasswordReset else {
            return nil
        }
        if let passwordResetInputErrorMessage = inputState.passwordResetInputErrorMessage {
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

    var validationMessage: String? {
        inputState.validationMessage(mode: mode)
    }
}
