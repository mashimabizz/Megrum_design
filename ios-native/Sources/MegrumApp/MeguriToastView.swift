import MegrumDesign
import SwiftUI

struct MeguriToastView: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(MegrumTheme.ink.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 18, y: 8)
            .padding(.horizontal, 28)
            .accessibilityLabel(message)
    }
}
