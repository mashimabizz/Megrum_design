import SwiftUI

extension AuthScreen {
    var mode: AuthScreenMode { route.mode }

    var feedbackMessage: AuthVisualFeedback? {
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

    var passwordResetFeedbackMessage: AuthVisualFeedback? {
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

    var validationMessage: String? {
        switch mode {
        case .signIn:
            MegrumAuthInputValidator.signInValidationMessage(email: email, password: password)
        case .signUp:
            MegrumAuthInputValidator.signUpValidationMessage(email: email, password: password, handle: handle)
        }
    }
}
