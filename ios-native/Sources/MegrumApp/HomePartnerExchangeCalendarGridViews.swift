import MegrumDesign
import SwiftUI

struct HomePartnerExchangeCalendarDayCell: View {
    var day: HomePartnerExchangeCalendarDay
    var detail: HomeExchangeLocalDateDetail?
    var isMarked: Bool
    var isFocused: Bool
    var color: Color
    var selectionColor: Color
    var connection: HomeExchangeCalendarSelectionConnection
    var showsTrailingDivider: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(day.dayNumber)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isMarked ? Color.white : color)

                if isMarked {
                    Text(prefectureLabel)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(selectionColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(isFocused ? 0.96 : 0.86), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(selectionBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isMarked)
        .overlay(alignment: .trailing) {
            if showsTrailingDivider {
                Rectangle()
                    .fill(MegrumTheme.ink.opacity(0.06))
                    .frame(width: 1)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isMarked ? [.isButton, .isSelected] : [])
    }

    private var selectionBackground: some View {
        Group {
            if isMarked {
                HomePartnerExchangeCalendarSelectionBackgroundShape(connection: connection)
                    .fill(selectionColor.opacity(day.isInDisplayedMonth ? (isFocused ? 0.98 : 0.72) : 0.24))
                    .overlay {
                        if isFocused {
                            HomePartnerExchangeCalendarSelectionBackgroundShape(connection: connection)
                                .stroke(Color.white.opacity(0.94), lineWidth: 2)
                        }
                    }
                    .padding(.leading, connection.connectsFromPrevious ? 0 : 5)
                    .padding(.trailing, connection.connectsToNext ? 0 : 5)
                    .padding(.vertical, 4)
            }
        }
    }

    private var accessibilityLabel: String {
        "\(day.monthNumber)月\(day.dayNumber)日、\(isMarked ? "現地交換可能" : "予定なし")、\(prefectureLabel)"
    }

    private var prefectureLabel: String {
        detail?.prefecture.nilIfBlank.map(HomePartnerExchangePrefecturePresentation.shortName) ?? "場所"
    }
}

private struct HomePartnerExchangeCalendarSelectionBackgroundShape: Shape {
    var connection: HomeExchangeCalendarSelectionConnection

    func path(in rect: CGRect) -> Path {
        let radius = min(11, rect.width / 2, rect.height / 2)
        let topLeft = connection.connectsFromPrevious ? 0 : radius
        let bottomLeft = connection.connectsFromPrevious ? 0 : radius
        let topRight = connection.connectsToNext ? 0 : radius
        let bottomRight = connection.connectsToNext ? 0 : radius

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        if topRight > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + topRight),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        if bottomRight > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        }
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        if bottomLeft > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        if topLeft > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + topLeft, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }
        path.closeSubpath()
        return path
    }
}

struct HomePartnerExchangeCalendarLegendEntry: Identifiable {
    var title: String
    var color: Color

    var id: String { title }
}
