import MegrumDesign
import SwiftUI

struct AdBannerSlot: View {
    var placement: AdPlacement
    var displayContext: AdDisplayContext
    var configuration: AdRuntimeConfiguration = .current()

    private var decision: AdDisplayDecision {
        AdDisplayPolicy.decision(
            for: placement,
            context: displayContext,
            configuration: configuration
        )
    }

    var body: some View {
        if decision.isAllowed, decision.usesPlaceholder {
            AdBannerPlaceholder(placement: placement)
        }
    }
}

private struct AdBannerPlaceholder: View {
    var placement: AdPlacement

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("広告枠", systemImage: "megaphone")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.72))

            Text("\(placement.screenID) / \(placement.format.rawValue)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("広告枠")
        .accessibilityHint("広告SDK導入後にバナー広告を表示する場所です")
    }
}
