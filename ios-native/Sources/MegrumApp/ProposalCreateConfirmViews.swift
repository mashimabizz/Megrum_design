import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalConfirmStepView: View {
    var requiresMeetupBeforeSubmit: Bool
    var requiresShippingBeforeSubmit: Bool
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var senderCashAmount: Int?
    var receiverCashAmount: Int?
    var exchangeMethod: ExchangeMethod
    var mailingAddress: MailingAddress?
    var isLoadingMailingAddress: Bool
    var meetupInputs: [ProposalMeetupInput]
    var meetupSummaryText: String
    var shippingSummaryText: String
    var selectedPaymentSummaryText: String?
    @Binding var message: String
    var messageLimit: Int
    @Binding var shareSchedule: Bool
    var errorMessage: String?
    var onOpenAddressSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProposalExchangePreviewRow(
                senderGoods: senderGoods,
                receiverGoods: receiverGoods,
                senderCashAmount: senderCashAmount,
                receiverCashAmount: receiverCashAmount
            )

            Text("交換条件")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.top, 4)

            ProposalConfirmMethodCard(
                exchangeMethod: exchangeMethod,
                mailingAddress: mailingAddress,
                isLoadingMailingAddress: isLoadingMailingAddress,
                onOpenAddressSettings: onOpenAddressSettings
            )

            if showsLocalConditions {
                ProposalConfirmMeetupConditionsCard(summaryText: meetupSummaryText)
            }

            if showsShippingConditions {
                ProposalConfirmConditionTextCard(
                    title: "郵送交換の条件",
                    value: shippingSummaryText
                )
            }

            if let selectedPaymentSummaryText {
                ProposalConfirmPaymentConditionsCard(
                    paymentSummaryText: selectedPaymentSummaryText
                )
            }

            ProposalConfirmMessageCard(
                message: $message,
                messageLimit: messageLimit
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var showsLocalConditions: Bool {
        exchangeMethod == .hand || exchangeMethod == .both
    }

    private var showsShippingConditions: Bool {
        exchangeMethod == .mail || exchangeMethod == .both
    }
}
