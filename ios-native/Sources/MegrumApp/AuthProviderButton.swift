import MegrumDesign
import SwiftUI

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
                AuthProviderIconView(icon: icon)
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
}

private struct AuthProviderIconView: View {
    var icon: AuthProviderButton.ProviderIcon

    @ViewBuilder
    var body: some View {
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
