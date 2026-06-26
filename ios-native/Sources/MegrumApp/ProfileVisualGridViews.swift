import MegrumDesign
import SwiftUI

enum ProfileVisualGridLayout {
    static let columnCount = 4
    static let spacing: CGFloat = 8
    static let cornerRadius: CGFloat = 6
}

struct ProfileVisualGrid: View {
    var items: [ProfileVisualGridItem]
    var onSelect: ((ProfileVisualGridItem) -> Void)?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: ProfileVisualGridLayout.spacing),
        count: ProfileVisualGridLayout.columnCount
    )

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView(
                "表示できるグッズはありません",
                systemImage: "photo.on.rectangle",
                description: Text("登録された内容がここに表示されます")
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 42)
        } else {
            LazyVGrid(columns: columns, spacing: ProfileVisualGridLayout.spacing) {
                ForEach(items) { item in
                    if let onSelect {
                        Button {
                            onSelect(item)
                        } label: {
                            ProfileVisualGridTile(item: item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ProfileVisualGridTile(item: item)
                    }
                }
            }
        }
    }
}

private struct ProfileVisualGridTile: View {
    var item: ProfileVisualGridItem

    var body: some View {
        RoundedRectangle(cornerRadius: ProfileVisualGridLayout.cornerRadius, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.10))
            .aspectRatio(0.74, contentMode: .fit)
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case let .success(image):
                            GeometryReader { proxy in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
                        default:
                            ProfileVisualGridFallback(title: item.title)
                        }
                    }
                } else {
                    ProfileVisualGridFallback(title: item.title)
                }
            }
            .overlay(alignment: .topTrailing) {
                GoodsCollectionTagPlate(text: GoodsTileCollectionCardStyle.tagLine(for: item.tags))
            }
            .overlay(alignment: .bottomTrailing) {
                if item.quantity > 1 {
                    GoodsQuantityBadge(quantity: item.quantity)
                        .padding(6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: ProfileVisualGridLayout.cornerRadius, style: .continuous))
    }
}

private struct ProfileVisualGridFallback: View {
    var title: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.72), MegrumTheme.sky.opacity(0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(title.first.map(String.init) ?? "M")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
