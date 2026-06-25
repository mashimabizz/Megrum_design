import MegrumCore
import SwiftUI

struct TradeGoodsFallbackArtwork: View {
    var item: GoodsItem

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white.opacity(0.88))

            Text(TradePreviewThumbnailStyle.glyph(for: item))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
        }
    }
}
