import MegrumDesign
import SwiftUI

struct GoodsSharePostImageView: View {
    static let canvasSize = CGSize(width: 1_200, height: 1_500)

    var title: String
    var tiles: [GoodsSharePostImageTile]

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 18),
        count: 5
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            Text(title)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(tiles) { tile in
                    GoodsSharePostTileView(tile: tile)
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Spacer(minLength: 0)
                Image("MegrumBrandIcon", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                Image("MegrumWordmark", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170)
            }
        }
        .padding(.horizontal, 72)
        .padding(.top, 78)
        .padding(.bottom, 62)
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
        .background(.white)
        .accessibilityHidden(true)
    }
}
