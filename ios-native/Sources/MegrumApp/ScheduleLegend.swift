import MegrumDesign
import SwiftUI

struct ScheduleLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem(title: "あなた", color: MegrumTheme.lavender)
            legendItem(title: "相手", color: MegrumTheme.sky)
            Spacer()
        }
        .font(.system(size: 13, weight: .heavy, design: .rounded))
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text(title)
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}
