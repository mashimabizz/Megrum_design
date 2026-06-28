import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeAgreementDisclosureSheet: View {
    var route: TradeAgreementDisclosureRoute
    var proposal: TradeProposal
    var partnerHandle: String
    var partnerMailingAddress: TradeMailingAddressSnapshot?
    var partnerPaymentMethods: [UserPaymentMethod]
    var partnerPaymentNote: String?
    var partnerPaymentSettings: TradePaymentSettingsSnapshot?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(routeTitle)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var routeTitle: String {
        switch route {
        case .mailingAddress:
            "郵送先"
        case .paymentInfo:
            "支払い情報"
        }
    }

    private var routeIconName: String {
        switch route {
        case .mailingAddress:
            "shippingbox.fill"
        case .paymentInfo:
            "yensign.circle.fill"
        }
    }

    private var supportsMailExchange: Bool {
        proposal.exchangeMethod == .mail || proposal.exchangeMethod == .both
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(routeTitle, systemImage: routeIconName)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("@\(partnerHandle) から成立後に公開された情報です。")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .mailingAddress:
            mailingAddressContent
        case .paymentInfo:
            paymentInfoContent
        }
    }

    private var mailingAddressContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if supportsMailExchange {
                if let partnerMailingAddress {
                    TradeAgreementDisclosureInfoRow(title: "宛名", value: partnerMailingAddress.recipientName)
                    TradeAgreementDisclosureInfoRow(title: "郵便番号", value: partnerMailingAddress.formattedPostalCode)
                    TradeAgreementDisclosureInfoRow(title: "住所", value: partnerMailingAddress.addressLine)
                    TradeAgreementDisclosureInfoRow(title: "電話番号", value: partnerMailingAddress.phoneNumberText)
                } else {
                    TradeAgreementDisclosureInfoRow(title: "ステータス", value: "公開待ち")
                    Text("成立時の郵送先スナップショットがまだ取得できていません。")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ContentUnavailableView(
                    "郵送先は不要です",
                    systemImage: "mappin.and.ellipse",
                    description: Text("この取引は現地交換のため、郵送先の開示はありません。")
                )
            }
        }
        .tradeAgreementDisclosureCardStyle()
    }

    private var paymentInfoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            TradeAgreementDisclosureInfoRow(
                title: "支払い方法",
                value: UserPaymentMethod.displayText(
                    for: partnerPaymentMethods,
                    otherNote: partnerPaymentNote,
                    emptyText: proposal.cashOffer ? "未設定" : "支払いなし"
                )
            )

            if partnerPaymentMethods.contains(.bankTransfer) {
                if let partnerPaymentSettings, partnerPaymentSettings.hasBankTransferDetails {
                    TradeAgreementDisclosureInfoRow(title: "銀行名", value: partnerPaymentSettings.bankName)
                    TradeAgreementDisclosureInfoRow(title: "支店名", value: partnerPaymentSettings.bankBranchName)
                    TradeAgreementDisclosureInfoRow(title: "口座種別", value: partnerPaymentSettings.bankAccountType)
                    TradeAgreementDisclosureInfoRow(title: "口座番号", value: partnerPaymentSettings.bankAccountNumber)
                    TradeAgreementDisclosureInfoRow(title: "口座名義", value: partnerPaymentSettings.bankAccountHolder)
                } else {
                    TradeAgreementDisclosureInfoRow(title: "振込先", value: "未取得")
                    Text("成立時の支払い情報スナップショットがまだ取得できていません。")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if !proposal.cashOffer {
                Text("この取引は物々交換として成立しているため、支払い情報は不要です。")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else if partnerPaymentMethods.isEmpty {
                Text("相手の支払い情報はまだ取得できていません。")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tradeAgreementDisclosureCardStyle()
    }
}

private struct TradeAgreementDisclosureInfoRow: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    func tradeAgreementDisclosureCardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
            }
    }
}
