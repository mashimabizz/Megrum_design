import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeExchangePreferenceCardPicker: View {
    @Binding var selection: HomeExchangePreference
    var onSelect: (HomeExchangePreference) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(HomeExchangePreference.allCases) { preference in
                HomeExchangePreferenceCard(
                    preference: preference,
                    isSelected: selection == preference
                ) {
                    onSelect(preference)
                }
            }
        }
    }
}

private struct HomeExchangePreferenceCard: View {
    var preference: HomeExchangePreference
    var isSelected: Bool
    var action: () -> Void

    // iter1226.416 刷新：左上の空ラジオを廃止し、選択＝ラベンダー枠＋淡い塗り＋右上チェックに。
    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: preference.iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(preference.iconTint)
                    .frame(width: 34, height: 34)
                    .background(preference.iconTint.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                Text(preference.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                isSelected ? MegrumTheme.lavender.opacity(0.08) : Color.white.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(MegrumTheme.lavender, in: Circle())
                        .offset(x: 6, y: -6)
                }
            }
            .shadow(color: MegrumTheme.ink.opacity(isSelected ? 0.06 : 0.03), radius: isSelected ? 14 : 8, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preference.displayName)、\(isSelected ? "選択中" : "未選択")")
    }
}

private extension HomeExchangePreference {
    var iconName: String {
        switch self {
        case .local:
            "mappin.circle.fill"
        case .mail:
            "shippingbox.fill"
        case .both:
            "arrow.left.arrow.right.circle.fill"
        }
    }

    var iconTint: Color {
        switch self {
        case .local:
            MegrumTheme.lavender
        case .mail:
            MegrumTheme.pink
        case .both:
            MegrumTheme.lavender.opacity(0.82)
        }
    }
}
