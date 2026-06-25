import MegrumDesign
import SwiftUI

struct TradeRotatingGoodsTable: View {
    var accentColor: Color
    var rotation: Double

    var body: some View {
        ZStack {
            Ellipse()
                .fill(accentColor.opacity(0.14))
                .blur(radius: 5)
                .offset(y: 7)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.96),
                            accentColor.opacity(0.24),
                            MegrumTheme.sky.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.78),
                            accentColor.opacity(0.20),
                            accentColor.opacity(0.02)
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 56
                    )
                )
                .scaleEffect(x: 0.82, y: 0.54)

            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    Capsule()
                        .fill(tableHighlightColor(for: index))
                        .frame(width: index.isMultiple(of: 2) ? 30 : 19, height: 2.8)
                        .offset(x: index.isMultiple(of: 2) ? 48 : 40)
                        .rotationEffect(.degrees(Double(index) * 36))
                }
            }
            .rotationEffect(.degrees(rotation))
            .clipShape(Ellipse())

            Capsule()
                .fill(.white.opacity(0.62))
                .frame(width: 82, height: 4)
                .blur(radius: 0.4)
                .offset(y: 14)

            Ellipse()
                .strokeBorder(.white.opacity(0.84), lineWidth: 1.4)

            Ellipse()
                .strokeBorder(accentColor.opacity(0.30), lineWidth: 4.4)
                .scaleEffect(x: 0.88, y: 0.66)
                .blur(radius: 0.8)
        }
        .shadow(color: accentColor.opacity(0.20), radius: 13, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .accessibilityHidden(true)
    }

    private func tableHighlightColor(for index: Int) -> Color {
        if index.isMultiple(of: 2) {
            return accentColor.opacity(0.46)
        }
        return MegrumTheme.sky.opacity(0.34)
    }
}
