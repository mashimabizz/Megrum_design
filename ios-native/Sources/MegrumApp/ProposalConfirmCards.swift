import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCardSection<Content: View>: View {
    var title: String
    var rightText: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProposalCardSectionHeader(title: title, rightText: rightText)
            content
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
    }
}

private struct ProposalCardSectionHeader: View {
    var title: String
    var rightText: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer(minLength: 0)
            if let rightText, !rightText.isEmpty {
                Text(rightText)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

struct ProposalConfirmMeetupConditionsCard: View {
    var summaryText: String

    var body: some View {
        ProposalConfirmDetailCard(
            iconSystemName: "mappin.circle.fill",
            iconColor: MegrumTheme.lavender,
            title: "現地交換の条件"
        ) {
            ForEach(ProposalConfirmLocalRows(summaryText: summaryText).rows) { row in
                ProposalConfirmDetailRow(title: row.title, value: row.value)
            }
        }
    }
}

struct ProposalConfirmConditionTextCard: View {
    var title: String
    var value: String

    var body: some View {
        ProposalConfirmDetailCard(
            iconSystemName: "box.truck.fill",
            iconColor: MegrumTheme.conditionExact,
            title: title
        ) {
            ForEach(ProposalConfirmShippingRows(summaryText: value).rows) { row in
                ProposalConfirmDetailRow(title: row.title, value: row.value)
            }
        }
    }
}

struct ProposalConfirmPaymentConditionsCard: View {
    var paymentSummaryText: String

    var body: some View {
        ProposalConfirmPlainCard {
            HStack(spacing: 14) {
                ProposalConfirmRoundIcon(
                    systemName: "yensign",
                    color: MegrumTheme.sky
                )

                Text("支払方法")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer(minLength: 12)

                Text(paymentSummaryText)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
    }
}

struct ProposalConfirmMethodCard: View {
    var exchangeMethod: ExchangeMethod
    var mailingAddress: MailingAddress?
    var isLoadingMailingAddress: Bool
    var onOpenAddressSettings: () -> Void

    var body: some View {
        ProposalConfirmPlainCard {
            HStack(spacing: 10) {
                ProposalConfirmRoundIcon(
                    systemName: "arrow.left.arrow.right",
                    color: MegrumTheme.lavender
                )

                Text("受け渡し方法")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    if exchangeMethod == .hand || exchangeMethod == .both {
                        ProposalConfirmPill(title: "現地交換", tint: MegrumTheme.lavender)
                    }
                    if exchangeMethod == .mail || exchangeMethod == .both {
                        ProposalConfirmPill(title: "郵送交換", tint: MegrumTheme.conditionExact)
                    }
                }
                .layoutPriority(1)
            }
        }
    }

}

struct ProposalConfirmMessageCard: View {
    @Binding var message: String
    var messageLimit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("メッセージ（任意）")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text("\(message.count) / \(messageLimit)")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            TextField("よろしくお願いします", text: $message, axis: .vertical)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(minHeight: 86, alignment: .topLeading)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(MegrumTheme.ink.opacity(0.18), lineWidth: 1)
                }
        }
    }
}
