import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCreateActiveContent<GiveContent: View, ReceiveContent: View, MeetupContent: View, ShippingContent: View, PaymentContent: View, ConfirmContent: View>: View {
    @Binding var selectedStep: ProposalCreateStep
    @Binding var exchangeMethod: ExchangeMethod
    var selectionTabs: [ProposalCreateStep]
    var configuration: ProposalCreateConfiguration
    var senderCount: Int
    var receiverCount: Int
    var contentSpacing: CGFloat
    var horizontalContentPadding: CGFloat
    var usesInlineBottomBar: Bool
    var meetupHasTimeDraft: Bool
    var isCreating: Bool
    var onBack: () -> Void
    var onPrimary: () -> Void
    private var giveContent: () -> GiveContent
    private var receiveContent: () -> ReceiveContent
    private var meetupContent: () -> MeetupContent
    private var shippingContent: () -> ShippingContent
    private var paymentContent: () -> PaymentContent
    private var confirmContent: () -> ConfirmContent

    init(
        selectedStep: Binding<ProposalCreateStep>,
        exchangeMethod: Binding<ExchangeMethod>,
        selectionTabs: [ProposalCreateStep],
        configuration: ProposalCreateConfiguration,
        senderCount: Int,
        receiverCount: Int,
        contentSpacing: CGFloat,
        horizontalContentPadding: CGFloat,
        usesInlineBottomBar: Bool,
        meetupHasTimeDraft: Bool,
        isCreating: Bool,
        onBack: @escaping () -> Void,
        onPrimary: @escaping () -> Void,
        @ViewBuilder giveContent: @escaping () -> GiveContent,
        @ViewBuilder receiveContent: @escaping () -> ReceiveContent,
        @ViewBuilder meetupContent: @escaping () -> MeetupContent,
        @ViewBuilder shippingContent: @escaping () -> ShippingContent,
        @ViewBuilder paymentContent: @escaping () -> PaymentContent,
        @ViewBuilder confirmContent: @escaping () -> ConfirmContent
    ) {
        _selectedStep = selectedStep
        _exchangeMethod = exchangeMethod
        self.selectionTabs = selectionTabs
        self.configuration = configuration
        self.senderCount = senderCount
        self.receiverCount = receiverCount
        self.contentSpacing = contentSpacing
        self.horizontalContentPadding = horizontalContentPadding
        self.usesInlineBottomBar = usesInlineBottomBar
        self.meetupHasTimeDraft = meetupHasTimeDraft
        self.isCreating = isCreating
        self.onBack = onBack
        self.onPrimary = onPrimary
        self.giveContent = giveContent
        self.receiveContent = receiveContent
        self.meetupContent = meetupContent
        self.shippingContent = shippingContent
        self.paymentContent = paymentContent
        self.confirmContent = confirmContent
    }

    private func selectStepFromPill(_ step: ProposalCreateStep) {
        let order: [ProposalCreateStep] = [.give, .receive, .conditions]
        guard let targetIndex = order.firstIndex(of: step),
              let currentIndex = order.firstIndex(of: selectedStep)
        else {
            return
        }
        if targetIndex <= currentIndex {
            selectedStep = step
            return
        }
        // 先のステップへは、間のステップの前提を満たしている時だけ進める。
        let priorSteps = order.prefix(targetIndex)
        guard priorSteps.allSatisfy({ configuration.canAdvance(from: $0) }) else {
            return
        }
        selectedStep = step
    }

    var body: some View {
        VStack(spacing: 0) {
            ProposalFlowScreenHeader(
                title: ProposalFlowScreenCopy.title(for: selectedStep),
                showsKicker: ProposalFlowScreenCopy.showsHeaderKicker(for: selectedStep),
                onBack: onBack
            )
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // 個別募集エディタと同じ進捗ピル（送信確認では出さない）。
            if selectedStep != .payment && selectedStep != .confirm {
                ProposalStepProgressPill(step: selectedStep, onSelectStep: selectStepFromPill)
                    .padding(.bottom, 8)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    // 個別募集エディタ準拠：ステップ大見出し（1/3〜3/3）。
                    // 交換手段の選択は 3/3「交換条件」内へ移動した（iter1226.344）。
                    if selectedStep != .payment && selectedStep != .confirm {
                        ProposalStepProgressTitle(step: selectedStep)
                    }

                    ProposalCreateActiveStepContent(
                        selectedStep: selectedStep,
                        configuration: configuration,
                        meetupHasTimeDraft: meetupHasTimeDraft,
                        usesInlineBottomBar: usesInlineBottomBar,
                        isCreating: isCreating,
                        onPrimary: onPrimary,
                        giveContent: giveContent,
                        receiveContent: receiveContent,
                        meetupContent: meetupContent,
                        shippingContent: shippingContent,
                        paymentContent: paymentContent,
                        confirmContent: confirmContent
                    )
                }
                .padding(.horizontal, horizontalContentPadding)
                .padding(.top, 10)
                .padding(.bottom, usesInlineBottomBar ? 20 : 104)
            }
        }
    }
}

private struct ProposalCreateActiveStepContent<GiveContent: View, ReceiveContent: View, MeetupContent: View, ShippingContent: View, PaymentContent: View, ConfirmContent: View>: View {
    var selectedStep: ProposalCreateStep
    var configuration: ProposalCreateConfiguration
    var meetupHasTimeDraft: Bool
    var usesInlineBottomBar: Bool
    var isCreating: Bool
    var onPrimary: () -> Void
    private var giveContent: () -> GiveContent
    private var receiveContent: () -> ReceiveContent
    private var meetupContent: () -> MeetupContent
    private var shippingContent: () -> ShippingContent
    private var paymentContent: () -> PaymentContent
    private var confirmContent: () -> ConfirmContent

    init(
        selectedStep: ProposalCreateStep,
        configuration: ProposalCreateConfiguration,
        meetupHasTimeDraft: Bool,
        usesInlineBottomBar: Bool,
        isCreating: Bool,
        onPrimary: @escaping () -> Void,
        @ViewBuilder giveContent: @escaping () -> GiveContent,
        @ViewBuilder receiveContent: @escaping () -> ReceiveContent,
        @ViewBuilder meetupContent: @escaping () -> MeetupContent,
        @ViewBuilder shippingContent: @escaping () -> ShippingContent,
        @ViewBuilder paymentContent: @escaping () -> PaymentContent,
        @ViewBuilder confirmContent: @escaping () -> ConfirmContent
    ) {
        self.selectedStep = selectedStep
        self.configuration = configuration
        self.meetupHasTimeDraft = meetupHasTimeDraft
        self.usesInlineBottomBar = usesInlineBottomBar
        self.isCreating = isCreating
        self.onPrimary = onPrimary
        self.giveContent = giveContent
        self.receiveContent = receiveContent
        self.meetupContent = meetupContent
        self.shippingContent = shippingContent
        self.paymentContent = paymentContent
        self.confirmContent = confirmContent
    }

    @ViewBuilder
    var body: some View {
        switch selectedStep {
        case .give:
            giveContent()
        case .receive:
            receiveContent()
        case .conditions, .meetup:
            // .conditions は結合ステップ（呼び出し側が meetupContent スロットで渡す）。
            meetupContent()
        case .shipping:
            shippingContent()
        case .payment:
            paymentContent()
        case .confirm:
            confirmContent()
            if usesInlineBottomBar {
                ProposalFlowBottomBar(
                    selectedStep: selectedStep,
                    configuration: configuration,
                    meetupHasTimeDraft: meetupHasTimeDraft,
                    isCreating: isCreating,
                    isInline: true,
                    onPrimary: onPrimary
                )
            }
        }
    }
}
