import MegrumDesign
import SwiftUI

struct ProposalFlowBottomBar: View {
    var selectedStep: ProposalCreateStep
    var configuration: ProposalCreateConfiguration
    var meetupHasTimeDraft: Bool
    var isCreating: Bool
    var isInline = false
    var onPrimary: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProposalFlowBottomBarPrimaryButton(
                title: primaryTitle,
                isCreating: isCreating,
                isEnabled: canUsePrimary,
                action: onPrimary
            )
        }
        .padding(.horizontal, isInline ? 0 : ProposalFlowBottomBarMetrics.horizontalPadding)
        .padding(.top, isInline ? ProposalFlowBottomBarMetrics.inlineTopPadding : ProposalFlowBottomBarMetrics.topPadding)
        .padding(.bottom, isInline ? ProposalFlowBottomBarMetrics.inlineBottomPadding : ProposalFlowBottomBarMetrics.bottomPadding)
        .background(ProposalFlowBottomBarBackground(isInline: isInline))
    }

    private var canUsePrimary: Bool {
        configuration.canAdvance(from: selectedStep)
    }

    private var primaryTitle: String {
        ProposalCreateBottomBarCopy.primaryTitle(
            selectedStep: selectedStep,
            configuration: configuration,
            meetupHasTimeDraft: meetupHasTimeDraft
        )
    }
}

private struct ProposalFlowBottomBarPrimaryButton: View {
    var title: String
    var isCreating: Bool
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: ProposalFlowBottomBarMetrics.buttonMinHeight)
            .background(
                LinearGradient(
                    colors: [
                        MegrumTheme.lavender,
                        MegrumTheme.lavender.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: ProposalFlowBottomBarMetrics.buttonCornerRadius, style: .continuous)
            )
            .shadow(color: MegrumTheme.lavender.opacity(isEnabled ? 0.28 : 0), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.48)
    }
}

private struct ProposalFlowBottomBarBackground: View {
    var isInline: Bool

    var body: some View {
        if isInline {
            Color.clear
        } else {
            MegrumTheme.canvas.ignoresSafeArea(edges: .bottom)
        }
    }
}
