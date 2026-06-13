import MegrumCore
import MegrumDesign
import SwiftUI

private struct HomeHeader: View {
    var viewer: UserProfile?
    var onOpenSettings: () -> Void

    var body: some View {
        HStack {
            Button(action: onOpenSettings) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MegrumTheme.lavender, MegrumTheme.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: HomeLayoutMetrics.fixedHeaderAvatarSize, height: HomeLayoutMetrics.fixedHeaderAvatarSize)
                    .overlay(
                        Text(initial)
                            .font(.system(size: HomeLayoutMetrics.fixedHeaderInitialFontSize, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("設定を開く")

            Spacer()

            Text("Megrum")
                .font(.system(size: HomeLayoutMetrics.fixedHeaderTitleFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Circle()
                .fill(Color.clear)
                .frame(width: HomeLayoutMetrics.fixedHeaderAvatarSize, height: HomeLayoutMetrics.fixedHeaderAvatarSize)
        }
    }

    private var initial: String {
        guard let first = viewer?.displayName.first else {
            return "M"
        }
        return String(first)
    }
}

private struct HomeGroomRail: View {
    var grooms: [GroomPost]
    var onOpen: (() -> Void)?

    private var displayGrooms: [HomeGroomRailEntry] {
        let mapped = grooms.prefix(4).enumerated().map { index, groom in
            HomeGroomRailEntry(
                id: groom.id,
                name: HomeGroomRailFallback.names.indices.contains(index) ? HomeGroomRailFallback.names[index] : "めぐ",
                imageURL: groom.imageURL,
                isViewed: index > 1
            )
        }
        if mapped.isEmpty {
            return HomeGroomRailFallback.entries
        }
        return Array((mapped + HomeGroomRailFallback.entries.dropFirst(mapped.count)).prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("グルーム")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 13) {
                    Button(action: { onOpen?() }) {
                        HomeGroomRailAddTile()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("グルームを追加")

                    ForEach(displayGrooms) { groom in
                        Button(action: { onOpen?() }) {
                            HomeGroomRailTile(entry: groom)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(groom.name)のグルームを見る")
                    }
                }
                .padding(.trailing, 18)
            }
        }
    }
}

private struct HomeGroomRailEntry: Identifiable, Equatable {
    var id: UUID
    var name: String
    var imageURL: URL?
    var isViewed: Bool
}

private enum HomeGroomRailFallback {
    static let names = ["みち", "きこ", "ゆい", "まい"]
    static let entries: [HomeGroomRailEntry] = names.enumerated().map { index, name in
        HomeGroomRailEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000008\(String(format: "%02d", index))")!,
            name: name,
            imageURL: nil,
            isViewed: index == 3
        )
    }
}

private struct HomeGroomRailAddTile: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.28))
                .background(MegrumTheme.lavender.opacity(0.08), in: Circle())
                .frame(width: 74, height: 74)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            Text("追加")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(width: 80)
    }
}

private struct HomeGroomRailTile: View {
    var entry: HomeGroomRailEntry

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(entry.isViewed ? Color.gray.opacity(0.28) : MegrumTheme.lavender, lineWidth: 2)
                .background(Color.white.opacity(0.92), in: Circle())
                .frame(width: 74, height: 74)
                .overlay {
                    if let imageURL = entry.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                HomeGroomRailInitial(name: entry.name)
                            }
                        }
                        .clipShape(Circle())
                        .padding(4)
                    } else {
                        HomeGroomRailInitial(name: entry.name)
                    }
                }
                .shadow(color: MegrumTheme.lavender.opacity(0.16), radius: 12, x: 0, y: 5)

            Text(entry.name)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

private struct HomeGroomRailInitial: View {
    var name: String

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [MegrumTheme.lavender.opacity(0.26), MegrumTheme.pink.opacity(0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(String(name.prefix(1)))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(4)
    }
}

private struct MatchSection<Items: RandomAccessCollection>: View where Items.Element == GoodsItem, Items.Index == Int {
    var shelfKind: HomeMatchShelfKind
    var title: String
    var count: Int
    var items: Items
    var isLoading: Bool
    var viewerID: UUID?
    var onSelectRelationRoute: (HomeRelationRoute) -> Void
    var onOpenOwnerProfile: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            if isLoading && items.isEmpty {
                GoodsGridSkeleton()
            } else {
                HomeCandidateGrid(
                    items: Array(items),
                    viewerID: viewerID,
                    shelfKind: shelfKind,
                    onOpenItem: { item in
                        switch HomeGoodsPanelRouteResolver.destination(for: shelfKind) {
                        case .relation(let matchType):
                            onSelectRelationRoute(
                                HomeRelationRoute(item: item, matchType: matchType)
                            )
                        }
                    }
                )
            }
        }
    }
}

private struct HomeCandidateGrid: View {
    var items: [GoodsItem]
    var viewerID: UUID?
    var shelfKind: HomeMatchShelfKind
    var onOpenItem: (GoodsItem) -> Void

    var body: some View {
        LazyVGrid(
            columns: HomeCandidateGridMetrics.columns,
            alignment: .leading,
            spacing: HomeCandidateGridMetrics.spacing
        ) {
                ForEach(items) { item in
                    Button(action: { onOpenItem(item) }) {
                        HomeCandidateTile(
                            item: item,
                            shelfKind: shelfKind,
                            localMode: shelfKind == .matched && item.ownerID != viewerID
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.title)の関係図を開く")
                }
        }
    }
}

enum HomeLayoutMetrics {
    static let horizontalPadding: CGFloat = 18
    static let fixedHeaderTopPadding: CGFloat = 12
    static let fixedHeaderBottomPadding: CGFloat = 12
    static let fixedHeaderAvatarSize: CGFloat = 44
    static let fixedHeaderInitialFontSize: CGFloat = 20
    static let fixedHeaderTitleFontSize: CGFloat = 24
}

enum HomeCandidateGridMetrics {
    static let columnCount = 3
    static let spacing: CGFloat = 10
    static let cardHeightRatio: CGFloat = 1.34
    static let localAuraCornerRadius: CGFloat = 22
    static let localAuraOutset: CGFloat = 5
    static let localAuraShadowRadius: CGFloat = 18
    static let tagFontSize: CGFloat = 9
    static let tagHorizontalPadding: CGFloat = 6
    static let tagVerticalPadding: CGFloat = 3
    static let liveTopOffset: CGFloat = 31
    static let fakeImageGlowSize: CGFloat = 58
    static let fakeImageGlowOffsetX: CGFloat = 17
    static let fakeImageGlowOffsetY: CGFloat = -12
    static let fakeImageLetterFontSize: CGFloat = 32
    static let fakeImageLetterShadowRadius: CGFloat = 5
    static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: spacing, alignment: .top),
        count: columnCount
    )

    static func tileWidth(containerWidth: CGFloat) -> CGFloat {
        guard containerWidth > 0 else {
            return 0
        }
        return (containerWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    static func cardHeight(tileWidth: CGFloat) -> CGFloat {
        tileWidth * cardHeightRatio
    }
}

private struct HomeCandidateTile: View {
    var item: GoodsItem
    var shelfKind: HomeMatchShelfKind
    var localMode: Bool

    private var frameStyle: HomeCandidatePriorityFrameStyle {
        HomeCandidatePriorityFrameStyle.style(for: shelfKind)
    }

    var body: some View {
        ZStack {
            if localMode {
                RoundedRectangle(cornerRadius: HomeCandidateGridMetrics.localAuraCornerRadius, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.16))
                    .overlay {
                        RoundedRectangle(cornerRadius: HomeCandidateGridMetrics.localAuraCornerRadius, style: .continuous)
                            .stroke(MegrumTheme.lavender.opacity(0.52), lineWidth: 1)
                    }
                    .shadow(color: MegrumTheme.lavender.opacity(0.42), radius: HomeCandidateGridMetrics.localAuraShadowRadius, x: 0, y: 0)
                    .padding(-HomeCandidateGridMetrics.localAuraOutset)
            }

            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(HomeCandidateTileStyle.hue(for: item))
                .overlay {
                    ZStack {
                        if let imageURL = item.imageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    fallback
                                }
                            }
                        } else {
                            fallback
                        }

                        if let tagLine = HomeCandidateTileStyle.tagLine(for: item) {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text(tagLine)
                                        .font(.system(size: HomeCandidateGridMetrics.tagFontSize, weight: .black, design: .rounded))
                                        .foregroundStyle(MegrumTheme.ink.opacity(0.74))
                                        .lineLimit(1)
                                        .padding(.horizontal, HomeCandidateGridMetrics.tagHorizontalPadding)
                                        .padding(.vertical, HomeCandidateGridMetrics.tagVerticalPadding)
                                        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                Spacer()
                            }
                            .padding(.top, 6)
                            .padding(.trailing, 6)
                        }

                        if localMode {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("LIVE")
                                        .font(.system(size: HomeCandidateGridMetrics.tagFontSize, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, HomeCandidateGridMetrics.tagHorizontalPadding)
                                        .padding(.vertical, HomeCandidateGridMetrics.tagVerticalPadding)
                                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                                Spacer()
                            }
                            .padding(.top, HomeCandidateGridMetrics.liveTopOffset)
                            .padding(.trailing, 8)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(frameStyle.borderColor, lineWidth: frameStyle.borderWidth)
                }
                .shadow(color: frameStyle.shadowColor, radius: frameStyle.shadowRadius, x: frameStyle.shadowX, y: frameStyle.shadowY)
        }
        .aspectRatio(1 / HomeCandidateGridMetrics.cardHeightRatio, contentMode: .fit)
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(
                    width: HomeCandidateGridMetrics.fakeImageGlowSize,
                    height: HomeCandidateGridMetrics.fakeImageGlowSize
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(
                    x: HomeCandidateGridMetrics.fakeImageGlowOffsetX,
                    y: HomeCandidateGridMetrics.fakeImageGlowOffsetY
                )

            Text(HomeCandidateTileStyle.letter(for: item))
                .font(.system(size: HomeCandidateGridMetrics.fakeImageLetterFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(
                    color: MegrumTheme.ink.opacity(0.16),
                    radius: HomeCandidateGridMetrics.fakeImageLetterShadowRadius,
                    x: 0,
                    y: 2
                )
        }
    }
}

struct HomeCandidatePriorityFrameStyle: Equatable {
    var borderColor: Color
    var borderWidth: CGFloat
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowX: CGFloat
    var shadowY: CGFloat

    static func style(for shelfKind: HomeMatchShelfKind) -> HomeCandidatePriorityFrameStyle {
        switch shelfKind {
        case .matched:
            return HomeCandidatePriorityFrameStyle(
                borderColor: MegrumTheme.lavender.opacity(HomeCandidatePriorityFrameMetrics.bothBorderOpacity),
                borderWidth: HomeCandidatePriorityFrameMetrics.bothBorderWidth,
                shadowColor: MegrumTheme.lavender.opacity(HomeCandidatePriorityFrameMetrics.bothShadowOpacity),
                shadowRadius: HomeCandidatePriorityFrameMetrics.bothShadowRadius,
                shadowX: 0,
                shadowY: HomeCandidatePriorityFrameMetrics.bothShadowY
            )
        case .possible:
            return HomeCandidatePriorityFrameStyle(
                borderColor: MegrumTheme.sky.opacity(HomeCandidatePriorityFrameMetrics.oneSideBorderOpacity),
                borderWidth: HomeCandidatePriorityFrameMetrics.oneSideBorderWidth,
                shadowColor: MegrumTheme.sky.opacity(HomeCandidatePriorityFrameMetrics.oneSideShadowOpacity),
                shadowRadius: HomeCandidatePriorityFrameMetrics.oneSideShadowRadius,
                shadowX: 0,
                shadowY: HomeCandidatePriorityFrameMetrics.oneSideShadowY
            )
        }
    }
}

enum HomeCandidatePriorityFrameMetrics {
    static let bothBorderWidth: CGFloat = 2
    static let bothBorderOpacity: CGFloat = 0.72
    static let bothShadowOpacity: CGFloat = 0.22
    static let bothShadowRadius: CGFloat = 16
    static let bothShadowY: CGFloat = 8
    static let oneSideBorderWidth: CGFloat = 1.5
    static let oneSideBorderOpacity: CGFloat = 0.78
    static let oneSideShadowOpacity: CGFloat = 0.18
    static let oneSideShadowRadius: CGFloat = 12
    static let oneSideShadowY: CGFloat = 7
}

enum HomeCandidateTileStyle {
    static func tagLine(for item: GoodsItem) -> String? {
        let tags = item.tags.prefix(2).map { "# \($0.name)" }
        guard !tags.isEmpty else {
            return nil
        }
        return tags.joined(separator: " ")
    }

    static func letter(for item: GoodsItem) -> String {
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.contains("スア") {
            return "S"
        }
        if title.contains("サナ") {
            return "S"
        }
        if title.contains("ニンニン") {
            return "N"
        }
        if title.contains("ジョンウ") {
            return "J"
        }
        if title.contains("カリナ") {
            return "K"
        }
        return title.first.map { String($0) } ?? "?"
    }

    static func hue(for item: GoodsItem) -> Color {
        switch letter(for: item) {
        case "S":
            return MegrumTheme.lavender.opacity(0.34)
        case "K":
            return MegrumTheme.pink.opacity(0.34)
        case "J":
            return MegrumTheme.sky.opacity(0.34)
        case "N":
            return MegrumTheme.pink.opacity(0.28)
        default:
            switch abs(item.id.hashValue) % 4 {
            case 0:
                return MegrumTheme.lavender.opacity(0.34)
            case 1:
                return MegrumTheme.pink.opacity(0.34)
            case 2:
                return MegrumTheme.sky.opacity(0.34)
            default:
                return Color(red: 0.80, green: 0.87, blue: 1.0).opacity(0.62)
            }
        }
    }
}

private struct GoodsGridSkeleton: View {
    var body: some View {
        LazyVGrid(
            columns: HomeCandidateGridMetrics.columns,
            alignment: .leading,
            spacing: HomeCandidateGridMetrics.spacing
        ) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.76), lineWidth: 1)
                    )
                    .aspectRatio(1 / HomeCandidateGridMetrics.cardHeightRatio, contentMode: .fit)
                    .redacted(reason: .placeholder)
            }
        }
    }
}
