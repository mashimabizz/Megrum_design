import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalPaymentOptionRow: View {
    var option: ProposalPaymentOption
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.72), lineWidth: 2.2)
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Circle()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 18, height: 18)
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(iconTint.opacity(0.13))
                    Image(systemName: iconName)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(iconTint)
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    if let subtitle = option.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch option.kind {
        case .method(.bankTransfer):
            "building.columns"
        case .method(.paypay):
            "p.square.fill"
        case .method(.cashExchange):
            "banknote"
        case .method(.other), .other:
            "ellipsis.message"
        case .discussion:
            "bubble.left.and.bubble.right"
        }
    }

    private var iconTint: Color {
        switch option.kind {
        case .method(.bankTransfer):
            MegrumTheme.sky
        case .method(.paypay):
            MegrumTheme.conditionExact
        case .method(.cashExchange):
            MegrumTheme.ok
        case .method(.other), .other, .discussion:
            MegrumTheme.pink
        }
    }
}
