import MegrumDesign
import SwiftUI

struct GoodsSharePostTileView: View {
    var tile: GoodsSharePostImageTile

    var body: some View {
        ZStack {
            GoodsSharePostTileArtwork(data: tile.imageData)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white, lineWidth: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 16, y: 8)
    }
}
