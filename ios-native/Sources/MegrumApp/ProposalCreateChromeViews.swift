import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalFlowScreenHeader: View {
    var title: String
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
                Text("PROPOSAL")
                    .font(.system(size: ProposalFlowHeaderMetrics.kickerFontSize, weight: .black, design: .rounded))
                    .tracking(ProposalFlowHeaderMetrics.kickerTracking)
                    .foregroundStyle(MegrumTheme.lavender)
                Text(title)
                    .font(.system(size: ProposalFlowHeaderMetrics.titleFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            Spacer(minLength: 12)
        }
    }
}

struct ProposalConfirmNoticeCard: View {
    var title: String
    var text: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

            Text(text)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.lavender.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.64), lineWidth: 1)
        }
    }
}

struct ProposalStepHeader: View {
    @Binding var selectedStep: ProposalCreateStep
    var steps: [ProposalCreateStep]
    var configuration: ProposalCreateConfiguration
    var senderCount: Int
    var receiverCount: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(steps) { step in
                Button {
                    if canJump(to: step) {
                        withAnimation(.snappy) {
                            selectedStep = step
                        }
                    }
                } label: {
                    HStack(spacing: ProposalSectionTabsMetrics.tabGap) {
                        Text(tabTitle(for: step))
                            .font(.system(size: ProposalSectionTabsMetrics.labelFontSize, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(badgeText(for: step))
                            .font(.system(size: ProposalSectionTabsMetrics.countFontSize, weight: .black, design: .rounded))
                            .foregroundStyle(badgeColor(for: step))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        selectedStep == step
                            ? MegrumTheme.ink
                            : MegrumTheme.ink.opacity(0.55)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: ProposalSectionTabsMetrics.minTabHeight)
                    .padding(.horizontal, ProposalSectionTabsMetrics.tabHorizontalPadding)
                    .padding(.vertical, ProposalSectionTabsMetrics.tabVerticalPadding)
                    .background(
                        selectedStep == step ? AnyShapeStyle(Color.white.opacity(0.92)) : AnyShapeStyle(Color.clear),
                        in: Capsule()
                    )
                    .overlay {
                        if selectedStep == step {
                            Capsule()
                                .stroke(Color.white.opacity(0.92), lineWidth: 1)
                        }
                    }
                    .shadow(
                        color: selectedStep == step ? MegrumTheme.ink.opacity(0.13) : .clear,
                        radius: 12,
                        x: 0,
                        y: 5
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canJump(to: step))
                .opacity(canJump(to: step) ? 1 : 0.62)
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

    private func badgeText(for step: ProposalCreateStep) -> String {
        switch step {
        case .give:
            senderCount > 0 ? "\(senderCount)" : "!"
        case .receive:
            receiverCount > 0 ? "\(receiverCount)" : "!"
        case .meetup:
            configuration.targetStatus == nil ? "!" : "OK"
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

struct ProposalFlowBottomBar: View {
    var selectedStep: ProposalCreateStep
    var configuration: ProposalCreateConfiguration
    var meetupHasTimeDraft: Bool
    var isCreating: Bool
    var isInline = false
    var onPrimary: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrimary) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryTitle)
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: ProposalFlowBottomBarMetrics.buttonMinHeight)
                .background(
                    MegrumTheme.lavender,
                    in: RoundedRectangle(cornerRadius: ProposalFlowBottomBarMetrics.buttonCornerRadius, style: .continuous)
                )
                .shadow(color: MegrumTheme.lavender.opacity(canUsePrimary ? 0.28 : 0), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canUsePrimary)
            .opacity(canUsePrimary ? 1 : 0.48)
        }
        .padding(.horizontal, isInline ? 0 : ProposalFlowBottomBarMetrics.horizontalPadding)
        .padding(.top, isInline ? ProposalFlowBottomBarMetrics.inlineTopPadding : ProposalFlowBottomBarMetrics.topPadding)
        .padding(.bottom, isInline ? ProposalFlowBottomBarMetrics.inlineBottomPadding : ProposalFlowBottomBarMetrics.bottomPadding)
        .background(background)
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

    @ViewBuilder
    private var background: some View {
        if isInline {
            Color.clear
        } else {
            MegrumTheme.canvas.ignoresSafeArea(edges: .bottom)
        }
    }
}
