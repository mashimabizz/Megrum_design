import MegrumDesign
import SwiftUI

struct ProposalFlowBottomBar: View {
    var selectedStep: ProposalCreateStep
    var configuration: ProposalCreateConfiguration
    var meetupHasTimeDraft: Bool
    var isCreating: Bool
    var isInline = false
    var onPrimary: () -> Void

    var onBack: (() -> Void)?

    var body: some View {
        HStack(spacing: 15) {
            // 個別募集エディタ準拠：1/3以外は「戻る」を併置（iter1226.345）。
            if let onBack, selectedStep != .give {
                IndividualListingEditorBackBottomBarButton(action: onBack)
            }
            ProposalFlowBottomBarPrimaryButton(
                title: primaryTitle,
                isCreating: isCreating,
                isEnabled: canUsePrimary,
                action: onPrimary
            )
        }
        .padding(.horizontal, isInline ? 0 : 20)
        .padding(.top, isInline ? ProposalFlowBottomBarMetrics.inlineTopPadding : 12)
        .padding(.bottom, isInline ? ProposalFlowBottomBarMetrics.inlineBottomPadding : 14)
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
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
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
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.sky],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.46)
    }
}

private struct ProposalFlowBottomBarBackground: View {
    var isInline: Bool

    var body: some View {
        if isInline {
            Color.clear
        } else {
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous)
                .fill(.white.opacity(0.92))
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
