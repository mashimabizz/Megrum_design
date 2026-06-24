import MegrumDesign
import SwiftUI

struct AuthTopBar: View {
    var title: String
    var onBack: () -> Void

    var body: some View {
        ZStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 29, weight: .medium))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .padding(.top, 30)
        .frame(height: 76)
    }
}

struct AuthBrandLockup: View {
    var compact = false
    var showIconTile = false

    var body: some View {
        VStack(spacing: showIconTile ? 66 : 0) {
            if compact {
                HStack(spacing: 15) {
                    AuthRibbonMark()
                        .frame(width: 36, height: 34)
                    Text("Megrum")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            } else {
                Text("Megrum")
                    .font(.system(size: 45, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if showIconTile {
                ZStack {
                    AuthSparkleDecor()
                    Text("Mg")
                        .font(.system(size: 29, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(
                            LinearGradient(
                                colors: [
                                    MegrumTheme.lavender,
                                    MegrumTheme.sky.opacity(0.62),
                                    MegrumTheme.pink.opacity(0.74)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 21, style: .continuous)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            if !compact && !showIconTile {
                AuthRibbonMark()
                    .frame(width: 74, height: 70)
                    .offset(y: -70)
            }
        }
    }
}

private struct AuthRibbonMark: View {
    var body: some View {
        HStack(spacing: -6) {
            Capsule()
                .fill(AuthVisualStyle.primaryGradient)
                .rotationEffect(.degrees(27))
            Capsule()
                .fill(AuthVisualStyle.primaryGradient)
                .rotationEffect(.degrees(-27))
        }
    }
}

private struct AuthSparkleDecor: View {
    var body: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.38))
                .offset(x: -108, y: -7)
            Circle()
                .fill(MegrumTheme.pink.opacity(0.38))
                .frame(width: 8, height: 8)
                .offset(x: -48, y: 60)
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.34))
                .frame(width: 8, height: 8)
                .offset(x: 112, y: -51)
            Image(systemName: "sparkle")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.32))
                .offset(x: 122, y: 48)
        }
    }
}

struct AuthProviderButton: View {
    enum ProviderIcon {
        case apple
        case google
        case mail
    }

    var title: String
    var icon: ProviderIcon
    var filled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 27) {
                iconView
                    .frame(width: 30, height: 30)
                Text(title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(icon == .mail ? MegrumTheme.lavender : MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(filled ? .white.opacity(0.94) : .clear, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(icon == .mail ? MegrumTheme.lavender.opacity(0.82) : Color.clear, lineWidth: 1.2)
            }
            .shadow(color: filled ? MegrumTheme.ink.opacity(0.08) : .clear, radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .apple:
            Image(systemName: "apple.logo")
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.black)
        case .google:
            Text("G")
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .yellow, .green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .mail:
            Image(systemName: "envelope")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

struct AuthPrimaryActionButton: View {
    var title: String
    var isLoading: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(AuthVisualStyle.primaryGradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }
}

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

struct AuthVisualFeedbackRow: View {
    var feedback: AuthVisualFeedback

    var body: some View {
        Text(feedback.message)
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(foreground.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var foreground: Color {
        switch feedback.style {
        case .error:
            Color(red: 0.851, green: 0.35, blue: 0.42)
        case .success:
            MegrumTheme.ok
        case .info:
            MegrumTheme.muted
        }
    }
}

private enum AuthVisualStyle {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.lavender, Color(red: 0.50, green: 0.40, blue: 0.86)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func authVisualBackground() -> some View {
        self
            .background(
                ZStack {
                    MegrumTheme.canvas
                    RadialGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(0.15),
                            .clear
                        ],
                        center: .top,
                        startRadius: 40,
                        endRadius: 430
                    )
                }
                .ignoresSafeArea()
            )
    }
}
