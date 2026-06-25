import MegrumDesign
import SwiftUI

struct AuthInputRow: View {
    enum FieldKind {
        case email
        case password
    }

    var title: String
    var systemImage: String
    @Binding var text: String
    var kind: FieldKind
    var onChange: (() -> Void)?
    @State private var showsPassword = false

    var body: some View {
        HStack(spacing: 19) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 31)

            Group {
                if kind == .password && !showsPassword {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(kind == .email ? .emailAddress : .default)
            .textContentType(kind == .email ? .emailAddress : .password)
            #endif

            if kind == .password {
                Button(action: togglePasswordVisibility) {
                    Image(systemName: showsPassword ? "eye.slash" : "eye")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.78))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 70)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.13), lineWidth: 1)
        }
        .onChange(of: text) { _, _ in
            onChange?()
        }
    }

    private func togglePasswordVisibility() {
        showsPassword.toggle()
    }
}
