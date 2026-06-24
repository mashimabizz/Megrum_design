import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCardSection<Content: View>: View {
    var title: String
    var rightText: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

struct ProposalConfirmSummary: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var senderCashAmount: Int? = nil
    var receiverCashAmount: Int? = nil
    var methodTitle: String
    var meetupSummary: String
    var conditionTags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProposalExchangePreviewRow(
                senderGoods: senderGoods,
                receiverGoods: receiverGoods,
                senderCashAmount: senderCashAmount,
                receiverCashAmount: receiverCashAmount
            )
            ProposalSummaryRow(title: "交換方法", value: methodTitle)
            ProposalSummaryRow(title: "待ち合わせ", value: meetupSummary)
            if !conditionTags.isEmpty {
                ProposalSummaryRow(title: "条件タグ", value: conditionTags.joined(separator: " / "))
            }
        }
        .padding(16)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.68), lineWidth: 1)
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

private struct ProposalConfirmPlainCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(14)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
        }
    }
}

private struct ProposalConfirmRoundIcon: View {
    var systemName: String
    var color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.14), in: Circle())
    }
}

private struct ProposalConfirmDetailCard<Content: View>: View {
    var iconSystemName: String
    var iconColor: Color
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                ProposalConfirmRoundIcon(systemName: iconSystemName, color: iconColor)
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
            }
            .padding(.bottom, 12)

            content
        }
        .padding(14)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
        }
    }
}

private struct ProposalConfirmDetailRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                .frame(width: 78, alignment: .leading)
            Spacer(minLength: 8)
            Text(value.isEmpty ? "未設定" : value)
                .font(.system(size: 13.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(height: 1)
        }
    }
}

private struct ProposalConfirmPill: View {
    var title: String
    var tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11.5, weight: .black, design: .rounded))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .allowsTightening(true)
            .padding(.horizontal, 7)
            .frame(height: 30)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ProposalConfirmRowItem: Identifiable {
    var title: String
    var value: String

    var id: String { "\(title):\(value)" }
}

private struct ProposalConfirmLocalRows {
    var summaryText: String

    var rows: [ProposalConfirmRowItem] {
        [
            ProposalConfirmRowItem(title: "都道府県", value: prefecture),
            ProposalConfirmRowItem(title: "メモ", value: memo),
            ProposalConfirmRowItem(title: "日程", value: schedule)
        ]
    }

    private var parts: [String] {
        normalizedParts(from: summaryText)
    }

    private var prefecture: String {
        parts.first ?? "未設定"
    }

    private var memo: String {
        guard parts.count >= 3 else {
            return ""
        }
        return parts[1]
    }

    private var schedule: String {
        if parts.count >= 3 {
            return parts[2]
        }
        if parts.count == 2 {
            return parts[1]
        }
        return "未設定"
    }
}

private struct ProposalConfirmShippingRows {
    var summaryText: String

    var rows: [ProposalConfirmRowItem] {
        [
            ProposalConfirmRowItem(title: "送料", value: fee),
            ProposalConfirmRowItem(title: "発送目安", value: days)
        ]
    }

    private var parts: [String] {
        normalizedParts(from: summaryText)
    }

    private var fee: String {
        cleanedValue(parts.first, prefixes: ["送料"])
    }

    private var days: String {
        cleanedValue(parts.dropFirst().first, prefixes: ["発送", "発送目安"])
    }
}

private func normalizedParts(from text: String) -> [String] {
    text
        .components(separatedBy: " / ")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty && $0 != "未設定" && $0 != "対象外" }
}

private func cleanedValue(_ value: String?, prefixes: [String]) -> String {
    guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty
    else {
        return "未設定"
    }
    for prefix in prefixes {
        if value.hasPrefix(prefix) {
            value = String(value.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    return value.isEmpty ? "未設定" : value
}

private struct ProposalSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(width: 92, alignment: .leading)
            Text(value.isEmpty ? "未選択" : value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}
