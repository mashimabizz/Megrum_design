import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeAgreementDisclosureRoute: String, Identifiable {
    case mailingAddress
    case paymentInfo

    var id: String { rawValue }
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

            if supportsMailExchange {
                TradeAgreementTimelineActionRow(
                    title: "郵送先が公開されました",
                    actionTitle: "見る",
                    isAvailable: true,
                    unavailableTitle: "",
                    action: onOpenMailingInfo
                )

                if showsPaymentInfo {
                    timelineDot
                }
            }

            if showsPaymentInfo {
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

    private var supportsMailExchange: Bool {
        proposal.exchangeMethod == .mail || proposal.exchangeMethod == .both
    }

    private var showsPaymentInfo: Bool {
        proposal.cashOffer || !partnerPaymentMethods.isEmpty || partnerPaymentNote.nilIfBlank != nil
    }

    private var showsAgreementDetails: Bool {
        supportsMailExchange || showsPaymentInfo
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
