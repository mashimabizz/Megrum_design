import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeExchangeMailConditionsCard: View {
    @Binding var shippingFee: IndividualListingShippingFeeDraft
    @Binding var shippingDays: IndividualListingShippingDaysDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("郵送交換の条件")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 2)

            VStack(spacing: 14) {
                HomeExchangeMailConditionSegmentRow(
                    title: "送料の負担",
                    selection: $shippingFee,
                    values: IndividualListingShippingFeeDraft.selectableCases
                )
                Divider().overlay(MegrumTheme.ink.opacity(0.08))
                HomeExchangeMailConditionSegmentRow(
                    title: "発送目安",
                    selection: $shippingDays,
                    values: IndividualListingShippingDaysDraft.allCases
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.black.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.03), radius: 14, y: 7)
        }
    }
}

private struct HomeExchangeMailConditionSegmentRow<Value: Identifiable & Equatable>: View where Value.ID == String {
    var title: String
    @Binding var selection: Value
    var values: [Value]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            HStack(spacing: 7) {
                ForEach(values) { value in
                    Button {
                        selection = value
                    } label: {
                        Text(segmentTitle(for: value))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(selection == value ? .white : MegrumTheme.ink.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background {
                                if selection == value {
                                    Capsule().fill(MegrumTheme.primaryGradient)
                                } else {
                                    Capsule().fill(MegrumTheme.ink.opacity(0.045))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == value ? .isSelected : [])
                }
            }
        }
    }

    private func segmentTitle(for value: Value) -> String {
        if let shippingFee = value as? IndividualListingShippingFeeDraft {
            return shippingFee.title
        }
        if let shippingDays = value as? IndividualListingShippingDaysDraft {
            return shippingDays.title
        }
        return value.id
    }
}
