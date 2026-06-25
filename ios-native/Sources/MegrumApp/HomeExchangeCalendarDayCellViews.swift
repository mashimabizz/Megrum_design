import MegrumDesign
import SwiftUI

struct HomeExchangeCalendarDayCell: View {
    var day: HomeExchangeCalendarDay
    var detail: HomeExchangeLocalDateDetail?
    var isSelected: Bool
    var color: Color
    var selectionColor: Color
    var selectionConnection: HomeExchangeCalendarSelectionConnection
    var showsTrailingDivider: Bool
    var action: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            Text("\(day.dayNumber)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? Color.white : color)

            if isSelected {
                if let prefectureLabel {
                    Text(prefectureLabel)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(selectionColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.88), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(selectionBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .overlay(alignment: .trailing) {
            if showsTrailingDivider {
                Rectangle()
                    .fill(MegrumTheme.ink.opacity(0.06))
                    .frame(width: 1)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction {
            action()
        }
    }

    private var selectionBackground: some View {
        Group {
            if isSelected {
                HomeExchangeCalendarSelectionBackgroundShape(connection: selectionConnection)
                    .fill(selectionColor.opacity(day.isInDisplayedMonth ? 0.90 : 0.26))
                    .padding(.leading, selectionConnection.connectsFromPrevious ? 0 : 5)
                    .padding(.trailing, selectionConnection.connectsToNext ? 0 : 5)
                    .padding(.vertical, 4)
            }
        }
    }

    private var accessibilityLabel: String {
        "\(day.monthNumber)月\(day.dayNumber)日、\(isSelected ? "選択中" : "未選択")、\(prefectureLabel ?? "都道府県未設定")"
    }

    private var prefectureLabel: String? {
        detail?.prefecture.nilIfBlank.map(HomeExchangePrefecturePresentation.shortName)
    }
}

struct HomeExchangeCalendarSelectionConnection: Equatable, Sendable {
    var connectsFromPrevious = false
    var connectsToNext = false

    static let isolated = HomeExchangeCalendarSelectionConnection()
}

private struct HomeExchangeCalendarSelectionBackgroundShape: Shape {
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
