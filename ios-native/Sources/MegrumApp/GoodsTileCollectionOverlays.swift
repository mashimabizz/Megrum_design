import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsSelectionBadge: View {
    var isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? MegrumTheme.lavender : Color.white.opacity(0.82))
                .frame(width: 25, height: 25)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.92), lineWidth: 1.5)
                )
                .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 5, y: 2)

            Image(systemName: isSelected ? "checkmark" : "circle")
                .font(.system(size: isSelected ? 12 : 10, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : MegrumTheme.lavender)
        }
        .accessibilityHidden(true)
    }
}

struct GoodsCollectionFallback: View {
    var item: GoodsItem

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                GoodsTileCollectionCardStyle.hue(for: item)

                Circle()
                    .fill(.white.opacity(GoodsTileCollectionCardMetrics.shineOpacity))
                    .frame(
                        width: GoodsTileCollectionCardMetrics.shineSize,
                        height: GoodsTileCollectionCardMetrics.shineSize
                    )
                    .position(
                        x: proxy.size.width + GoodsTileCollectionCardMetrics.shineCenterXOffset,
                        y: GoodsTileCollectionCardMetrics.shineCenterY
                    )

                Text(GoodsTileCollectionCardStyle.glyph(for: item))
                    .font(.system(
                        size: GoodsTileCollectionCardMetrics.glyphFontSize,
                        weight: .black,
                        design: .rounded
                    ))
                    .foregroundStyle(.white)
                    .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 5, y: 2)
            }
        }
        .accessibilityHidden(true)
    }
}

struct GoodsCollectionTagPlate: View {
    var text: String
    var foregroundColor: Color = MegrumTheme.ink

    var body: some View {
        GeometryReader { proxy in
            GoodsTagTextPill(
                text: text,
                fontSize: GoodsTileCollectionCardMetrics.tagFontSize,
                horizontalPadding: GoodsTileCollectionCardMetrics.tagHorizontalPadding,
                verticalPadding: GoodsTileCollectionCardMetrics.tagVerticalPadding,
                foregroundColor: foregroundColor
            )
            .frame(maxWidth: proxy.size.width * GoodsTileCollectionCardMetrics.tagMaxWidthRatio, alignment: .trailing)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(GoodsTileCollectionCardMetrics.tagInset)
        }
        .accessibilityHidden(true)
    }
}
