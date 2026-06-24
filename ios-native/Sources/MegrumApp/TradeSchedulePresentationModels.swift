import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeScheduleCalendarMode: String, CaseIterable, Identifiable {
    case fiveDays
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fiveDays:
            "週"
        case .month:
            "月"
        }
    }
}

enum TradePreviewThumbnailStyle {
    static func glyph(for item: GoodsItem) -> String {
        if item.title.contains("スア") {
            return "S"
        }
        if item.title.contains("ニンニン") {
            return "N"
        }
        if item.title.contains("ジョンウ") {
            return "J"
        }
        if item.title.contains("カリナ") {
            return "K"
        }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func hue(for item: GoodsItem) -> Color {
        switch abs(item.id.hashValue) % 3 {
        case 0:
            return MegrumTheme.lavender.opacity(0.62)
        case 1:
            return MegrumTheme.sky.opacity(0.72)
        default:
            return MegrumTheme.pink.opacity(0.62)
        }
    }
}
