import MegrumDesign
import SwiftUI

struct TradeDisputeBanner: View {
    var summary: TradeDisputeSummary
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(MegrumTheme.pink, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.bannerTitle)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(summary.bannerBody)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(.top, 10)
            }
            .padding(15)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(MegrumTheme.pink.opacity(0.42), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(summary.bannerTitle)。\(summary.bannerBody)。詳細を見る")
    }
}
