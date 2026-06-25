import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeGoodsArtwork: View {
    var item: GoodsItem
    var accentColor: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    accentColor.opacity(0.42),
                    MegrumTheme.sky.opacity(0.25),
                    .white.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                            .tint(accentColor)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        TradeGoodsFallbackArtwork(item: item)
                    @unknown default:
                        TradeGoodsFallbackArtwork(item: item)
                    }
                }
            } else {
                TradeGoodsFallbackArtwork(item: item)
            }
        }
        .clipped()
    }
}
