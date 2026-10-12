import MegrumDesign
import SwiftUI

/// 認証系の入力欄（iter1226.406 刷新）：
/// 左アイコンを廃止し「上ラベル＋淡い塗りフィールド」に。フォーカス時のみラベンダー枠が出る。
struct AuthInputRow: View {
    enum FieldKind {
        case email
        case password
    }

    var title: String
    @Binding var text: String
    var kind: FieldKind
    var onChange: (() -> Void)?
    @State private var presentationState = AuthInputRowPresentationState()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            HStack(spacing: 10) {
                Group {
                    if presentationState.usesSecureInput(for: kind) {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .focused($isFocused)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(kind == .email ? .emailAddress : .default)
                .textContentType(kind == .email ? .emailAddress : .password)
                #endif

                if kind == .password {
                    Button(action: togglePasswordVisibility) {
                        Image(systemName: presentationState.passwordVisibilityIconName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(MegrumTheme.muted.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(MegrumTheme.ink.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isFocused ? MegrumTheme.lavender.opacity(0.85) : .clear,
                        lineWidth: 1.5
                    )
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onTapGesture {
                isFocused = true
            }
        }
        .onChange(of: text) { _, _ in
            onChange?()
        }
    }

    private func togglePasswordVisibility() {
        presentationState.togglePasswordVisibility()
    }
}
