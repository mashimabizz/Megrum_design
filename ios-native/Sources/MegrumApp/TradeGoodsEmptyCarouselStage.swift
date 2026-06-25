import MegrumDesign
import SwiftUI

struct TradeGoodsEmptyCarouselStage: View {
    var title: String
    var accentColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(accentColor.opacity(0.10))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.badge.questionmark")
                        .font(.system(size: 22, weight: .bold))
                    Text(title)
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                }
                .foregroundStyle(accentColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(accentColor.opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
            .accessibilityLabel(title)
    }
}
