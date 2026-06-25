import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeExchangeMailConditionsCard: View {
    @Binding var shippingFee: IndividualListingShippingFeeDraft
    @Binding var shippingDays: IndividualListingShippingDaysDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("郵送交換の条件")
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 8)

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
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.92), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.09), radius: 18, y: 10)
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
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 7) {
                ForEach(values) { value in
                    Button {
                        selection = value
                    } label: {
                        Text(segmentTitle(for: value))
                            .font(.caption.weight(.black))
                            .foregroundStyle(selection == value ? .white : MegrumTheme.ink.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                selection == value ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.05),
                                in: Capsule()
                            )
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
