import MegrumDesign
import SwiftUI

struct MapGlassHeader: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(.regularMaterial, in: Capsule())

            Spacer()

            Color.clear
                .frame(width: 42, height: 42)
        }
    }
}

struct MapStatusBadge: View {
    var message: String
    var isLoading: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(MegrumTheme.lavender)
            } else {
                Image(systemName: "location")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            Text(message)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 38)
        .background(.regularMaterial, in: Capsule())
    }
}
