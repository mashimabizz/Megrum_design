import MegrumDesign
import SwiftUI

struct HomeExchangePreferenceRow: View {
    var preference: HomeExchangePreference
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.6))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preference.displayName)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(preference.detailText)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                isSelected ? MegrumTheme.lavender.opacity(0.12) : .white,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? MegrumTheme.lavender.opacity(0.45) : MegrumTheme.ink.opacity(0.08),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preference.displayName)、\(isSelected ? "選択中" : "未選択")")
    }
}
