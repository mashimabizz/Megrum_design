import MegrumDesign
import SwiftUI

struct ProfileVisualGrid: View {
    var items: [ProfileVisualGridItem]
    var onSelect: ((ProfileVisualGridItem) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

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
            LazyVGrid(columns: columns, spacing: 8) {
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
        RoundedRectangle(cornerRadius: 6, style: .continuous)
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
                if item.showsMatchTags {
                    VStack(alignment: .trailing, spacing: 4) {
                        ProfileVisualConditionTag(text: "グッズ条件◎", color: MegrumTheme.lavender)
                        ProfileVisualConditionTag(text: "交換条件▲", color: MegrumTheme.pink)
                    }
                    .padding(6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct ProfileVisualConditionTag: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
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
