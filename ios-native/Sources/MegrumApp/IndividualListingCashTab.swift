import MegrumDesign
import SwiftUI

struct IndividualListingCashTab: View {
    @Binding var pricingMode: IndividualListingCashPricingMode
    @Binding var amount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ForEach(IndividualListingCashPricingMode.allCases) { mode in
                    cashModeButton(mode)
                }
            }

            if pricingMode == .specifiedAmount {
                IndividualListingCashAmountCard(amount: $amount)
            }
        }
    }

    private func cashModeButton(_ mode: IndividualListingCashPricingMode) -> some View {
        let selected = pricingMode == mode
        return Button {
            MegrumHaptics.performSelectionChanged {
                withAnimation(.smooth(duration: 0.18)) {
                    pricingMode = mode
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: mode == .listPrice ? "tag.fill" : "yensign.circle.fill")
                        .font(.system(size: 16, weight: .black))
                    Text(mode.title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .lineLimit(1)
                }
                Text(mode == .listPrice ? "金額を固定せず定価扱い" : "具体的な金額を入力")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .foregroundStyle(selected ? .white.opacity(0.82) : MegrumTheme.muted)
            }
            .foregroundStyle(selected ? .white : MegrumTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .padding(.horizontal, 15)
            .background(
                selected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.94)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
