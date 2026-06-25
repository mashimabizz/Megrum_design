import MegrumDesign
import SwiftUI

struct ProposalStepHeader: View {
    @Binding var selectedStep: ProposalCreateStep
    var steps: [ProposalCreateStep]
    var configuration: ProposalCreateConfiguration
    var senderCount: Int
    var receiverCount: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(steps) { step in
                let isEnabled = canJump(to: step)
                ProposalStepHeaderTab(
                    title: tabTitle(for: step),
                    badge: badgeText(for: step),
                    badgeColor: badgeColor(for: step),
                    isSelected: selectedStep == step,
                    isEnabled: isEnabled
                ) {
                    guard isEnabled else {
                        return
                    }
                    withAnimation(.snappy) {
                        selectedStep = step
                    }
                }
            }
        }
        .padding(ProposalSectionTabsMetrics.containerPadding)
        .background(Color.white.opacity(0.58), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private func badgeText(for step: ProposalCreateStep) -> String? {
        switch step {
        case .give:
            senderCount > 0 ? "\(senderCount)" : "!"
        case .receive:
            receiverCount > 0 ? "\(receiverCount)" : "!"
        case .meetup:
            configuration.targetStatus == nil ? "!" : nil
        case .shipping:
            nil
        case .payment:
            configuration.requiresPaymentSelection && !configuration.hasSelectedPaymentMethod ? "!" : nil
        case .confirm:
            configuration.canSubmit ? "OK" : "!"
        }
    }

    private func badgeColor(for step: ProposalCreateStep) -> Color {
        switch step {
        case .give:
            senderCount > 0 ? MegrumTheme.lavender : MegrumTheme.muted
        case .receive:
            receiverCount > 0 ? MegrumTheme.sky : MegrumTheme.muted
        case .meetup:
            configuration.targetStatus == nil ? MegrumTheme.muted : MegrumTheme.lavender
        case .shipping:
            MegrumTheme.sky
        case .payment:
            configuration.hasSelectedPaymentMethod ? MegrumTheme.lavender : MegrumTheme.muted
        case .confirm:
            configuration.canSubmit ? MegrumTheme.lavender : MegrumTheme.muted
        }
    }

    private func tabTitle(for step: ProposalCreateStep) -> String {
        switch step {
        case .give:
            "私が出す"
        case .receive:
            "受け取る"
        case .meetup:
            "待ち合わせ"
        case .shipping:
            "送料"
        case .payment:
            "支払"
        case .confirm:
            "確認"
        }
    }

    private func canJump(to step: ProposalCreateStep) -> Bool {
        guard let targetIndex = steps.firstIndex(of: step) else {
            return false
        }
        let priorSteps = steps.prefix(targetIndex)
        return priorSteps.allSatisfy { configuration.canAdvance(from: $0) }
    }
}
