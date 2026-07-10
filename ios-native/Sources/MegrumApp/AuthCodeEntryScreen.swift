import MegrumDesign
import SwiftUI

/// メール確認コード（6桁）の入力画面（iter1226.418）。
/// 新規登録＝検証で即ログイン、パスワード再設定＝検証後に新パスワード設定へ。
struct AuthCodeEntryScreen: View {
    enum Purpose {
        case signUp
        case recovery

        var title: String {
            switch self {
            case .signUp:
                "メールアドレスの確認"
            case .recovery:
                "本人確認"
            }
        }

        var submitTitle: String {
            switch self {
            case .signUp:
                "認証して始める"
            case .recovery:
                "コードを確認"
            }
        }
    }

    let purpose: Purpose
    let email: String
    var isLoading: Bool
    var feedback: AuthVisualFeedback?
    var onSubmit: (String) -> Void
    var onResend: () -> Void
    var onBack: () -> Void

    @State private var code = ""
    @State private var didAutoSubmit = false
    @FocusState private var isCodeFieldFocused: Bool

    private let codeLength = MegrumAuthState.emailCodeLength

    var body: some View {
        VStack(spacing: 0) {
            AuthTopBar(title: purpose.title, onBack: onBack)

            Spacer(minLength: 44)

            VStack(spacing: 10) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 76, height: 76)
                    .background(MegrumTheme.lavender.opacity(0.08), in: Circle())

                Text("確認コードを入力")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text("\(email) に届いた\(codeLength)桁のコードを入力してください")
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            codeBoxes
                .padding(.top, 32)

            if let feedback {
                AuthVisualFeedbackRow(feedback: feedback)
                    .padding(.top, 14)
            }

            AuthPrimaryActionButton(
                title: purpose.submitTitle,
                isLoading: isLoading,
                isDisabled: !MegrumAuthState.isValidEmailCode(code),
                action: { onSubmit(code) }
            )
            .padding(.top, 28)

            Button("コードを再送する", action: onResend)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.top, 24)
                .disabled(isLoading)

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 28)
        .authVisualBackground()
        .onAppear {
            isCodeFieldFocused = true
        }
    }

    /// 6桁のコードボックス。実入力は透明TextField（.oneTimeCodeでメールからの自動入力にも対応）。
    private var codeBoxes: some View {
        ZStack {
            TextField("", text: $code)
                .focused($isCodeFieldFocused)
                #if os(iOS)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                #endif
                .opacity(0.02)
                .frame(width: 1, height: 1)
                .onChange(of: code) { _, value in
                    let normalized = String(MegrumAuthState.normalizedEmailCode(value).prefix(codeLength))
                    if normalized != value {
                        code = normalized
                    }
                    // 6桁揃ったら1回だけ自動送信（編集し直したら再度有効化）。
                    if normalized.count == codeLength, !didAutoSubmit {
                        didAutoSubmit = true
                        onSubmit(normalized)
                    } else if normalized.count < codeLength {
                        didAutoSubmit = false
                    }
                }

            HStack(spacing: 10) {
                ForEach(0..<codeLength, id: \.self) { index in
                    codeBox(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isCodeFieldFocused = true
            }
        }
    }

    private func codeBox(at index: Int) -> some View {
        let characters = Array(code)
        let digit = index < characters.count ? String(characters[index]) : ""
        let isActive = isCodeFieldFocused && index == min(code.count, codeLength - 1) && code.count < codeLength

        return Text(digit)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(width: 46, height: 56)
            .background(MegrumTheme.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isActive ? MegrumTheme.lavender.opacity(0.85) : .clear,
                        lineWidth: 1.5
                    )
            }
            .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

/// リカバリコード検証後の新パスワード設定画面（iter1226.418）。
struct AuthNewPasswordScreen: View {
    @Binding var password: String
    var isLoading: Bool
    var feedback: AuthVisualFeedback?
    var onSubmit: () -> Void
    var onBack: () -> Void

    private var canSubmit: Bool {
        MegrumAuthInputValidator.isValidSignUpPassword(password)
    }

    var body: some View {
        VStack(spacing: 0) {
            AuthTopBar(title: "新しいパスワード", onBack: onBack)

            Spacer(minLength: 44)

            VStack(spacing: 10) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 76, height: 76)
                    .background(MegrumTheme.lavender.opacity(0.08), in: Circle())

                Text("新しいパスワードを設定")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            VStack(alignment: .leading, spacing: 10) {
                AuthInputRow(
                    title: "新しいパスワード",
                    text: $password,
                    kind: .password
                )
                Text("8文字以上で入力してください")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
            .padding(.top, 32)

            if let feedback {
                AuthVisualFeedbackRow(feedback: feedback)
                    .padding(.top, 14)
            }

            AuthPrimaryActionButton(
                title: "パスワードを変更してログイン",
                isLoading: isLoading,
                isDisabled: !canSubmit,
                action: onSubmit
            )
            .padding(.top, 28)

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 28)
        .authVisualBackground()
    }
}
