import MegrumDesign
import SwiftUI

struct GoodsSharePromptThumbnail: View {
    var url: URL?

    var body: some View {
        Group {
            if let url {
                GoodsRemoteImage(url: url, cornerRadius: 29, placeholderIconSize: 22)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            MegrumTheme.lavender.opacity(0.26),
                            MegrumTheme.pink.opacity(0.20),
                            MegrumTheme.sky.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.90))
                }
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
