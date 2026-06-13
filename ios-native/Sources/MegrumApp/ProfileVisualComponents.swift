import MegrumDesign
import SwiftUI

enum ProfileVisualTab: String, CaseIterable, Identifiable {
    case goods = "譲"
    case listings = "個別募集"
    case wish = "Wish"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .goods:
            "bag"
        case .listings:
            "bookmark"
        case .wish:
            "heart"
        }
    }
}

struct ProfileVisualGridItem: Identifiable, Hashable {
    var id: UUID
    var title: String
    var imageURL: URL?
    var showsMatchTags: Bool

    init(id: UUID, title: String, imageURL: URL?, showsMatchTags: Bool = false) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.showsMatchTags = showsMatchTags
    }
}

struct ProfileVisualHero: View {
    var displayName: String
    var handle: String
    var bio: String
    var avatarURL: URL?
    var tradeCount: String
    var ratingText: String
    var chips: [String]
    var actionTitle: String
    var isPrimaryAction: Bool = false
    var onAction: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            HStack(alignment: .top, spacing: 22) {
                ProfileVisualAvatar(url: avatarURL, fallback: displayName, size: 116)

                VStack(alignment: .leading, spacing: 9) {
                    Text(displayName)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                    Text("@\(handle)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text(bio)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                        .lineLimit(2)

                    HStack(spacing: 18) {
                        ProfileVisualStat(title: "取引", value: tradeCount, accent: false)
                        Divider()
                            .frame(height: 32)
                        ProfileVisualStat(title: "評価", value: ratingText, accent: true)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(chips.prefix(5).enumerated()), id: \.offset) { index, chip in
                            Text(chip)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(chipColor(index))
                                .padding(.horizontal, 18)
                                .frame(height: 44)
                                .background(chipColor(index).opacity(0.14), in: Capsule())
                                .overlay {
                                    Capsule().stroke(chipColor(index).opacity(0.20), lineWidth: 1)
                                }
                        }
                    }
                }
            }

            Button(action: onAction) {
                Text(actionTitle)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(isPrimaryAction ? .white : MegrumTheme.lavender)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        isPrimaryAction ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.74)),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MegrumTheme.lavender.opacity(0.78), lineWidth: isPrimaryAction ? 0 : 1.2)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private func chipColor(_ index: Int) -> Color {
        switch index % 3 {
        case 0:
            MegrumTheme.lavender
        case 1:
            MegrumTheme.sky
        default:
            MegrumTheme.pink
        }
    }
}

private struct ProfileVisualStat: View {
    var title: String
    var value: String
    var accent: Bool

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.62))
            HStack(spacing: 4) {
                if accent {
                    Image(systemName: "star.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Color.orange)
                }
                Text(value)
                    .font(.system(size: 21, weight: .regular, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }
        }
        .frame(minWidth: 52)
    }
}

struct ProfileVisualTabs: View {
    @Binding var selection: ProfileVisualTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileVisualTab.allCases) { tab in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selection == tab ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.62))
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(selection == tab ? MegrumTheme.lavender : .clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(.white.opacity(0.76))
    }
}

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

struct ProfileVisualAvatar: View {
    var url: URL?
    var fallback: String
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: size, height: size)
            .overlay {
                if let url {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackText
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackText
                }
            }
    }

    private var fallbackText: some View {
        Text(fallback.first.map(String.init) ?? "M")
            .font(.system(size: size * 0.33, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
    }
}
