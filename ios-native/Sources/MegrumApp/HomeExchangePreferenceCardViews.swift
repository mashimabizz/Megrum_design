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

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 7) {
                    Image(systemName: preference.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(preference.iconTint)
                        .frame(width: 32, height: 32)
                        .background(preference.iconTint.opacity(0.13), in: Circle())
                        .accessibilityHidden(true)

                    Text(preference.displayName)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.62))

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                isSelected ? Color.white.opacity(0.82) : Color.white.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                        lineWidth: isSelected ? 1.7 : 1
                    )
            }
            .shadow(color: MegrumTheme.ink.opacity(isSelected ? 0.08 : 0.035), radius: isSelected ? 18 : 10, y: 8)
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
