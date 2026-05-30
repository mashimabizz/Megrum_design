import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsGrid: View {
    var items: [GoodsItem]
    var columns: Int = 3

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 16) {
            ForEach(items) { item in
                GoodsTile(item: item)
            }
        }
    }
}

struct GoodsTile: View {
    var item: GoodsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tileGradient)
                .aspectRatio(0.78, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    if let tag = item.tags.first {
                        Text("# \(tag.name)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(MegrumTheme.ink)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.86), in: Capsule())
                            .padding(8)
                    }
                }
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.74))
                }
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 5)

            Text(item.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private var tileGradient: LinearGradient {
        LinearGradient(
            colors: [
                MegrumTheme.sky.opacity(0.62),
                MegrumTheme.lavender.opacity(0.72),
                MegrumTheme.pink.opacity(0.54)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
