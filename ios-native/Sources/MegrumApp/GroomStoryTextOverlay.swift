import MegrumDesign
import SwiftUI

enum GroomStoryTextColor: String, CaseIterable, Identifiable {
    case white
    case black
    case lavender
    case pink
    case yellow
    case green
    case blue

    var id: String {
        rawValue
    }

    var color: Color {
        switch self {
        case .white:
            Color.white
        case .black:
            Color.black
        case .lavender:
            MegrumTheme.lavender
        case .pink:
            MegrumTheme.pink
        case .yellow:
            Color(red: 1.00, green: 0.86, blue: 0.20)
        case .green:
            Color(red: 0.24, green: 0.82, blue: 0.45)
        case .blue:
            Color(red: 0.25, green: 0.44, blue: 1.00)
        }
    }

    var accessibilityName: String {
        switch self {
        case .white:
            "白"
        case .black:
            "黒"
        case .lavender:
            "ラベンダー"
        case .pink:
            "ピンク"
        case .yellow:
            "黄色"
        case .green:
            "緑"
        case .blue:
            "青"
        }
    }

    var shadowColor: Color {
        self == .black ? .white.opacity(0.36) : .black.opacity(0.42)
    }
}

struct GroomStoryTextOverlay: Identifiable, Equatable {
    var id: UUID
    var text: String
    var normalizedPosition: CGPoint
    var color: GroomStoryTextColor
    var scale: CGFloat
    var rotationDegrees: Double

    init(
        id: UUID = UUID(),
        text: String,
        normalizedPosition: CGPoint,
        color: GroomStoryTextColor = .white,
        scale: CGFloat = 1,
        rotationDegrees: Double = 0
    ) {
        self.id = id
        self.text = text
        self.normalizedPosition = normalizedPosition.groomStoryClamped
        self.color = color
        self.scale = min(max(scale, 0.55), 2.6)
        self.rotationDegrees = rotationDegrees
    }
}

extension CGPoint {
    var groomStoryClamped: CGPoint {
        CGPoint(
            x: min(max(x, 0.08), 0.92),
            y: min(max(y, 0.08), 0.90)
        )
    }
}
