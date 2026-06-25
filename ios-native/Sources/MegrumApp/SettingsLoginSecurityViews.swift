import MegrumDesign
import SwiftUI

@MainActor
struct LoginSecuritySettingsScreen: View {
    @ObservedObject var authState: MegrumAuthState
    var isSigningOut: Bool
    var accountSummary: SettingsAccountSummary
    var onSignOut: () async -> Void

    @FocusState private var focusedField: Field?
    @State private var resetEmail = ""
    @State private var resetInputErrorMessage: String?

    private var summary: LoginSecuritySummary {
        LoginSecuritySummary(
            authSession: authState.session,
            isAuthenticated: authState.isAuthenticated,
            isAuthConfigured: authState.isConfigured,
            accountSummary: accountSummary
        )
    }

    var body: some View {
        List {
            LoginSecurityStatusSection(summary: summary)
            Section {
                resetEmailField

                Button {
                    Task { await sendPasswordReset() }
                } label: {
                    HStack(spacing: 8) {
                        if authState.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("再設定メールを送る")
                    }
                }
                .disabled(authState.isLoading)

                if let resetInputErrorMessage {
                    SecurityFeedbackRow(message: resetInputErrorMessage, style: .error)
                } else if let errorMessage = authState.errorMessage {
                    SecurityFeedbackRow(message: errorMessage, style: .error)
                } else if let successMessage = authState.passwordResetMessage ?? authState.successMessage {
                    SecurityFeedbackRow(message: successMessage, style: .success)
                }
            } header: {
                Text("パスワード再設定")
            } footer: {
                Text("メール/パスワードでログインしている場合は、登録メールへ再設定リンクを送れます。")
            }

            LoginSecuritySignOutSection(
                isSigningOut: isSigningOut,
                onTap: startSignOut
            )
        }
        .navigationTitle("ログインとセキュリティ")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") {
                    focusedField = nil
                }
            }
            #endif
        }
        .onAppear {
            prefillResetEmailIfNeeded()
        }
        .onChange(of: authState.session?.user.email) { _, _ in
            prefillResetEmailIfNeeded()
        }
        .onChange(of: resetEmail) { _, _ in
            resetInputErrorMessage = nil
            authState.clearFeedback()
        }
    }

    @ViewBuilder
    private var resetEmailField: some View {
        #if os(iOS)
        TextField("ログインメール", text: $resetEmail)
            .focused($focusedField, equals: .resetEmail)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .submitLabel(.send)
            .onSubmit {
                Task { await sendPasswordReset() }
            }
        #else
        TextField("ログインメール", text: $resetEmail)
            .focused($focusedField, equals: .resetEmail)
            .textContentType(.emailAddress)
            .onSubmit {
                Task { await sendPasswordReset() }
            }
        #endif
    }

    private func sendPasswordReset() async {
        focusedField = nil
        resetInputErrorMessage = nil
        let normalizedEmail = MegrumAuthInputValidator.normalizedEmail(resetEmail)
        if let validationMessage = MegrumAuthInputValidator.passwordResetValidationMessage(email: normalizedEmail) {
            authState.clearFeedback()
            resetInputErrorMessage = validationMessage
            return
        }

        _ = await authState.sendPasswordReset(email: normalizedEmail)
    }

    private func startSignOut() {
        Task {
            focusedField = nil
            await onSignOut()
        }
    }

    private func prefillResetEmailIfNeeded() {
        guard resetEmail.isBlank else {
            return
        }
        resetEmail = summary.resetEmailPrefill
    }

    private enum Field {
        case resetEmail
    }
}

private struct SecurityFeedbackRow: View {
    enum Style {
        case error
        case success
    }

    var message: String
    var style: Style

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .accessibilityLabel(message)
    }

    private var foregroundColor: Color {
        switch style {
        case .error:
            Color(red: 0.851, green: 0.51, blue: 0.42)
        case .success:
            MegrumTheme.ok
        }
    }
}
