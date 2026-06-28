import MegrumDesign
import SwiftUI

struct GoodsSharePostTileArtwork: View {
    var data: Data?

    var body: some View {
        if let data, let image = PlatformShareImage(data: data) {
            image
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        MegrumTheme.lavender.opacity(0.22),
                        MegrumTheme.pink.opacity(0.18),
                        MegrumTheme.sky.opacity(0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "photo")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
            }
        }
    }
}
