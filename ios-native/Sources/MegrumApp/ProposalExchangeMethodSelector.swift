import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalExchangeMethodSelector: View {
    @Binding var exchangeMethod: ExchangeMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("交換手段")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 0) {
                ForEach(ExchangeMethod.allCases) { method in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            exchangeMethod = method
                        }
                    } label: {
                        Text(method.displayName)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(exchangeMethod == method ? .white : MegrumTheme.ink.opacity(0.48))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                exchangeMethod == method ? MegrumTheme.lavender : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(exchangeMethod == method ? .isSelected : [])
                }
            }
            .padding(3)
            .background(MegrumTheme.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
        }
    }
}
