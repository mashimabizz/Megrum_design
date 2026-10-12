import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeAgreementDisclosureRoute: String, Identifiable {
    case mailingAddress
    case paymentInfo

    var id: String { rawValue }
}

/// 成立後の情報開示（郵送先/支払い情報）を、閲覧者の役割で出し分ける判定。iter1226.381。
/// 郵送でグッズを送る側だけが相手の郵送先を、金額を支払う側だけが相手の支払い先を見る。
/// 郵送ぶつぶつ交換なら双方がグッズを送るので双方に郵送先が出る。
struct TradeAgreementDisclosureVisibility {
    var showsMailingInfo: Bool
    var showsPaymentInfo: Bool

    var showsAny: Bool { showsMailingInfo || showsPaymentInfo }

    init(proposal: TradeProposal, viewerID: UUID?) {
        let viewerIsSender = viewerID.map { proposal.isSender($0) } ?? false
        let supportsMail = proposal.exchangeMethod == .mail || proposal.exchangeMethod == .both
        // 自分側の提示グッズがある＝相手にグッズを送る側。その側だけ相手の郵送先を知る必要がある。
        let viewerGivesGoods = viewerIsSender
            ? !proposal.senderGoodsIDs.isEmpty
            : !proposal.receiverGoodsIDs.isEmpty
        showsMailingInfo = supportsMail && viewerGivesGoods

        // 金額を支払う側だけ相手の支払い先を知る必要がある。支払い側不明時は従来通り（安全側）表示。
        let hasCash = proposal.cashOffer || (proposal.cashAmount ?? 0) > 0
        if !hasCash {
            showsPaymentInfo = false
        } else if let side = proposal.cashAmountSide {
            showsPaymentInfo = viewerIsSender ? side == .sender : side == .receiver
        } else {
            showsPaymentInfo = true
        }
    }
}

struct TradeAgreementDisclosureActionsCard: View {
    var showsMailingInfo: Bool
    var showsPaymentInfo: Bool
    var onOpenMailingInfo: () -> Void
    var onOpenPaymentInfo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if showsMailingInfo {
                TradeAgreementDisclosureButton(
                    title: "郵送先",
                    systemImage: "lock.fill",
                    action: onOpenMailingInfo
                )
            }
            if showsPaymentInfo {
                TradeAgreementDisclosureButton(
                    title: "支払い情報",
                    systemImage: "yensign.circle.fill",
                    action: onOpenPaymentInfo
                )
            }
        }
        .padding(10)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct TradeAgreementDisclosureButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityHint("成立後に公開された\(title)を確認します")
    }
}

struct TradeAgreementSystemTimeline: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var partnerPaymentMethods: [UserPaymentMethod]
    var partnerPaymentNote: String?
    var partnerMailingAddress: TradeMailingAddressSnapshot?
    var partnerPaymentSettings: TradePaymentSettingsSnapshot?
    var onOpenMailingInfo: () -> Void
    var onOpenPaymentInfo: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Label(agreementTitle, systemImage: "sparkles")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)

            if showsAgreementDetails {
                timelineDot
            }

            if disclosure.showsMailingInfo {
                TradeAgreementTimelineActionRow(
                    title: "郵送先が公開されました",
                    actionTitle: "見る",
                    isAvailable: true,
                    unavailableTitle: "",
                    action: onOpenMailingInfo
                )

                if disclosure.showsPaymentInfo {
                    timelineDot
                }
            }

            if disclosure.showsPaymentInfo {
                TradeAgreementTimelineActionRow(
                    title: "支払い情報が公開されました",
                    actionTitle: "見る",
                    isAvailable: true,
                    unavailableTitle: "",
                    action: onOpenPaymentInfo
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .accessibilityElement(children: .contain)
    }

    private var agreementTitle: String {
        "\(proposal.exchangeMethod.displayName)で取引が成立しました"
    }

    private var disclosure: TradeAgreementDisclosureVisibility {
        TradeAgreementDisclosureVisibility(proposal: proposal, viewerID: viewerID)
    }

    private var showsAgreementDetails: Bool {
        disclosure.showsAny
    }

    private var timelineDot: some View {
        Circle()
            .fill(MegrumTheme.muted.opacity(0.32))
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }
}

private struct TradeAgreementTimelineActionRow: View {
    var title: String
    var actionTitle: String
    var isAvailable: Bool
    var unavailableTitle: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(isAvailable ? title : unavailableTitle)
                .font(.system(size: 13.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)

            if isAvailable {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
