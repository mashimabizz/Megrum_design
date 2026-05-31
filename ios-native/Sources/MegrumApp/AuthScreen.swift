#if canImport(AuthenticationServices)
import AuthenticationServices
import CryptoKit
#endif
#if canImport(UIKit)
import UIKit
#endif
import MegrumDesign
import SwiftUI

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

@MainActor
public struct AuthScreen: View {
    @ObservedObject private var authState: MegrumAuthState
    @State private var mode: AuthScreenMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var handle = ""
    @State private var isShowingPasswordResetSheet = false
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

    public init(authState: MegrumAuthState) {
        self.authState = authState
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    modePicker
                    form
                    actionArea
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 42)
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
        .onChange(of: mode) { _, _ in
            clearFeedback()
            focusedField = nil
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
        .sheet(isPresented: $isShowingPasswordResetSheet) {
            PasswordResetSheet(
                email: $passwordResetEmail,
                isSending: authState.isLoading,
                errorMessage: hasSubmittedPasswordReset ? (passwordResetInputErrorMessage ?? authState.errorMessage) : nil,
                successMessage: hasSubmittedPasswordReset ? authState.passwordResetMessage : nil,
                onEmailChanged: {
                    hasSubmittedPasswordReset = false
                    passwordResetInputErrorMessage = nil
                    authState.clearFeedback()
                }
            ) {
                await sendPasswordReset()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Megrum")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(mode == .signIn ? "おかえりなさい" : "まずはアカウントを作成します")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modePicker: some View {
        Picker("認証方法", selection: $mode) {
            ForEach(AuthScreenMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var form: some View {
        VStack(spacing: 16) {
            emailField
            passwordField

            if mode == .signUp {
                handleField
            }
        }
        .disabled(authState.isLoading)
        .animation(.easeInOut(duration: 0.12), value: authState.isLoading)
    }

    @ViewBuilder
    private var emailField: some View {
        #if os(iOS)
        TextField("メールアドレス", text: $email)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .password
            }
            .megrumTextFieldStyle()
        #else
        TextField("メールアドレス", text: $email)
            .focused($focusedField, equals: .email)
            .onSubmit {
                focusedField = .password
            }
            .megrumTextFieldStyle()
        #endif
    }

    @ViewBuilder
    private var passwordField: some View {
        #if os(iOS)
        SecureField("パスワード", text: $password)
            .textContentType(mode == .signIn ? .password : .newPassword)
            .focused($focusedField, equals: .password)
            .submitLabel(mode == .signIn ? .go : .next)
            .onSubmit {
                if mode == .signIn {
                    Task { await submit() }
                } else {
                    focusedField = .handle
                }
            }
            .megrumTextFieldStyle()
        #else
        SecureField("パスワード", text: $password)
            .focused($focusedField, equals: .password)
            .onSubmit {
                if mode == .signIn {
                    Task { await submit() }
                } else {
                    focusedField = .handle
                }
            }
            .megrumTextFieldStyle()
        #endif
    }

    @ViewBuilder
    private var handleField: some View {
        #if os(iOS)
        TextField("ユーザーID（任意）", text: $handle)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.username)
            .focused($focusedField, equals: .handle)
            .submitLabel(.go)
            .onSubmit {
                Task { await submit() }
            }
            .megrumTextFieldStyle()
        #else
        TextField("ユーザーID（任意）", text: $handle)
            .focused($focusedField, equals: .handle)
            .onSubmit {
                Task { await submit() }
            }
            .megrumTextFieldStyle()
        #endif
    }

    private var actionArea: some View {
        VStack(spacing: 14) {
            if !authState.isConfigured {
                infoLabel("ログイン機能を使うにはSupabase設定が必要です。画面確認だけならプレビューで入れます")
            }

            if let inputErrorMessage {
                errorLabel(inputErrorMessage)
            } else if let errorMessage = authState.errorMessage {
                errorLabel(errorMessage)
            } else if let identityProviderError {
                errorLabel(identityProviderError)
            } else if let successMessage = authState.successMessage {
                successLabel(successMessage)
            } else if let passwordResetMessage = authState.passwordResetMessage {
                successLabel(passwordResetMessage)
            }

            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 10) {
                    if authState.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(mode == .signIn ? "メールアドレスでログイン" : "メールアドレスで登録")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .tint(MegrumTheme.lavender)
            .disabled(authState.isLoading)

            if mode == .signIn {
                Button("パスワードを忘れた場合") {
                    openPasswordResetSheet()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .disabled(authState.isLoading)
            }

            appleSignInButton

            if !authState.isConfigured {
                Button("画面だけプレビューする") {
                    authState.enterPreview()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 18))
                .frame(maxWidth: .infinity)
                .disabled(authState.isLoading)
            }
        }
    }

    private func errorLabel(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    private func successLabel(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ok)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(MegrumTheme.ok.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private func infoLabel(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(MegrumTheme.sky.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var appleSignInButton: some View {
        #if canImport(AuthenticationServices)
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(MegrumTheme.muted.opacity(0.18))
                    .frame(height: 1)
                Text("または")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Rectangle()
                    .fill(MegrumTheme.muted.opacity(0.18))
                    .frame(height: 1)
            }

            SignInWithAppleButton(.continue) { request in
                let nonce = AppleSignInNonce.make()
                appleSignInNonce = nonce
                identityProviderError = nil
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleSignInNonce.sha256(nonce)
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .disabled(authState.isLoading || !authState.isConfigured)
            .accessibilityLabel("Appleで続ける")

            googleSignInButton
        }
        #endif
    }

    @ViewBuilder
    private var googleSignInButton: some View {
        #if canImport(AuthenticationServices) && canImport(UIKit)
        Button {
            startGoogleSignIn()
        } label: {
            HStack(spacing: 10) {
                Text("G")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(MegrumTheme.ink)
                    .background(Color.white, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(MegrumTheme.muted.opacity(0.22), lineWidth: 1)
                    )
                Text("Googleで続ける")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .tint(MegrumTheme.ink)
        .disabled(authState.isLoading || !authState.isConfigured)
        .accessibilityLabel("Googleで続ける")
        #endif
    }

    private func openPasswordResetSheet() {
        passwordResetEmail = MegrumAuthInputValidator.normalizedEmail(email)
        hasSubmittedPasswordReset = false
        passwordResetInputErrorMessage = nil
        inputErrorMessage = nil
        identityProviderError = nil
        authState.clearFeedback()
        focusedField = nil
        isShowingPasswordResetSheet = true
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

    private var validationMessage: String? {
        switch mode {
        case .signIn:
            MegrumAuthInputValidator.signInValidationMessage(email: email, password: password)
        case .signUp:
            MegrumAuthInputValidator.signUpValidationMessage(email: email, password: password, handle: handle)
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

private struct PasswordResetSheet: View {
    @Binding var email: String
    var isSending: Bool
    var errorMessage: String?
    var successMessage: String?
    var onEmailChanged: () -> Void
    var onSend: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    emailField
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    }
                }

                if let successMessage {
                    Section {
                        Text(successMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ok)
                    }
                }
            }
            .navigationTitle("パスワード再設定")
            .megrumInlineNavigationTitle()
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(successMessage == nil ? "キャンセル" : "閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if successMessage == nil {
                        Button {
                            Task {
                                await onSend()
                            }
                        } label: {
                            if isSending {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("送信")
                            }
                        }
                        .disabled(isSending)
                    }
                }
                #if os(iOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") {
                        isEmailFocused = false
                    }
                }
                #endif
            }
            .onAppear {
                if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    isEmailFocused = true
                }
            }
            .onChange(of: email) { _, _ in
                onEmailChanged()
            }
        }
    }

    @ViewBuilder
    private var emailField: some View {
        #if os(iOS)
        TextField("メールアドレス", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .focused($isEmailFocused)
            .submitLabel(.send)
            .onSubmit {
                Task {
                    await onSend()
                }
            }
        #else
        TextField("メールアドレス", text: $email)
            .focused($isEmailFocused)
            .onSubmit {
                Task {
                    await onSend()
                }
            }
        #endif
    }
}

#if canImport(AuthenticationServices)
private extension AuthScreen {
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

private enum AppleSignInNonce {
    static func make() -> String {
        "\(UUID().uuidString).\(UUID().uuidString)"
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func displayName(from components: PersonNameComponents?) -> String? {
        guard let components else {
            return nil
        }
        let value = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

#if canImport(UIKit)
private final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
#endif
#endif
