import MegrumCore
import MegrumDesign
import SwiftUI

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
