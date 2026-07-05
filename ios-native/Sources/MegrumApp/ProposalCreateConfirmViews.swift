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

                ProposalConfirmAddressCard(
                    mailingAddress: mailingAddress,
                    isLoading: isLoadingMailingAddress,
                    onOpenAddressSettings: onOpenAddressSettings
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


/// 郵送交換の確認画面に出す住所カード。未登録なら登録を促し、登録するまで打診は送信できない。
struct ProposalConfirmAddressCard: View {
    var mailingAddress: MailingAddress?
    var isLoading: Bool
    var onOpenAddressSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("郵送先の住所")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 4)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let mailingAddress {
                VStack(alignment: .leading, spacing: 3) {
                    Text("〒\(mailingAddress.postalCode) \(mailingAddress.prefecture)\(mailingAddress.city)")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                    Text(mailingAddress.line1 + (mailingAddress.line2.map { " \($0)" } ?? ""))
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                    Text(mailingAddress.recipientName)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Text("住所は双方の合意後に相手へ表示されます。")
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            } else if !isLoading {
                Text("郵送交換には住所の登録が必要です。登録するまで打診は送信できません。")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.conditionExact)

                Button(action: onOpenAddressSettings) {
                    Text("住所を登録する")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    mailingAddress == nil && !isLoading ? MegrumTheme.conditionExact.opacity(0.45) : MegrumTheme.ink.opacity(0.08),
                    lineWidth: 1
                )
        }
    }
}
