import MegrumDesign
import SwiftUI

struct HomeMutualMatchEmptyStateView: View {
    var presentation: HomeMutualMatchEmptyStatePresentation
    var onCreateListing: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("相互マッチを増やす", systemImage: "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)

            VStack(alignment: .leading, spacing: 7) {
                Text(presentation.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(presentation.message)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onCreateListing) {
                Label(presentation.buttonTitle, systemImage: "plus.circle.fill")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityHint("個別募集の作成画面を開きます。")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.10), radius: 16, x: 0, y: 10)
    }
}
