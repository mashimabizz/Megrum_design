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

            ScrollView {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    if selectedStep != .payment && selectedStep != .confirm {
                        ProposalExchangeMethodSelector(
                            exchangeMethod: $exchangeMethod
                        )

                        ProposalStepHeader(
                            selectedStep: $selectedStep,
                            steps: selectionTabs,
                            configuration: configuration,
                            senderCount: senderCount,
                            receiverCount: receiverCount
                        )
                    }

                    stepContent
                }
                .padding(.horizontal, horizontalContentPadding)
                .padding(.top, 10)
                .padding(.bottom, usesInlineBottomBar ? 20 : 104)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch selectedStep {
        case .give:
            giveContent()
        case .receive:
            receiveContent()
        case .meetup:
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
