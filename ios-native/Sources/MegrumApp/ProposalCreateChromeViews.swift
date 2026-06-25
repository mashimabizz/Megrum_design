import MegrumDesign
import SwiftUI

struct ProposalFlowScreenHeader: View {
    var title: String
    var showsKicker = true
    var onBack: () -> Void

    var body: some View {
        HStack(spacing: ProposalFlowHeaderMetrics.horizontalSpacing) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: ProposalFlowHeaderMetrics.backChevronSize, weight: .black))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(
                        width: ProposalFlowHeaderMetrics.backButtonSize,
                        height: ProposalFlowHeaderMetrics.backButtonSize
                    )
                    .background(.regularMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.66), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("戻る")

            VStack(alignment: .leading, spacing: 3) {
                if showsKicker {
                    Text("PROPOSAL")
                        .font(.system(size: ProposalFlowHeaderMetrics.kickerFontSize, weight: .black, design: .rounded))
                        .tracking(ProposalFlowHeaderMetrics.kickerTracking)
                        .foregroundStyle(MegrumTheme.lavender)
                }
                Text(title)
                    .font(.system(size: ProposalFlowHeaderMetrics.titleFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            Spacer(minLength: 12)
        }
    }
}
