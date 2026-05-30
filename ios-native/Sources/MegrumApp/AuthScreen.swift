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
    }

    @ViewBuilder
    private var emailField: some View {
        #if os(iOS)
        TextField("メールアドレス", text: $email)
            .textInputAutocapitalization(.never)
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
            if let errorMessage = authState.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
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
            .disabled(authState.isLoading || !canSubmit)

            if !authState.isConfigured {
                Button("画面だけプレビューする") {
                    authState.enterPreview()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 18))
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var canSubmit: Bool {
        let hasEmail = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if mode == .signIn {
            return hasEmail && !password.isEmpty
        }
        return hasEmail && password.count >= 8
    }

    private func submit() async {
        focusedField = nil
        switch mode {
        case .signIn:
            await authState.signIn(email: email, password: password)
        case .signUp:
            await authState.signUp(email: email, password: password, handle: handle)
        }
    }

    private enum Field {
        case email
        case password
        case handle
    }
}

private extension View {
    func megrumTextFieldStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.58), lineWidth: 1)
            }
    }
}
