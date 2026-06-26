import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDetailPinnedSummaryArea: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var latestDisputeSummary: TradeDisputeSummary?
    var tradeSummaryLine: String
    var requestedGoods: [GoodsItem]
    var offeredGoods: [GoodsItem]
    var requestedGoodsCount: Int
    var offeredGoodsCount: Int
    var partnerPaymentMethods: [UserPaymentMethod]
    var partnerPaymentNote: String?
    var viewerPaymentMethods: [UserPaymentMethod]
    var viewerPaymentNote: String?
    var viewerHasCounterProposal: Bool
    var isMessageComposerFocused: Bool
    var isResponding: Bool
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onOpenMailingInfo: () -> Void
    var onOpenPaymentInfo: () -> Void
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    @State private var detailRoute: TradeSummaryDetailRoute?
    @State private var selectedExchangeMethod: ExchangeMethod?
    @State private var selectedPaymentOptionID: String?

    private var isInitialSenderWaitingForPartner: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.status == .sent && proposal.isSender(viewerID)
    }

    private var responsePresentation: TradeProposalResponsePresentation {
        TradeProposalResponsePresentation(
            proposal: proposal,
            viewerID: viewerID,
            proposedPaymentMethods: partnerPaymentMethods,
            proposedPaymentOtherNote: partnerPaymentNote,
            availablePaymentMethods: viewerPaymentMethods,
            availablePaymentOtherNote: viewerPaymentNote,
            viewerHasCounterProposal: viewerHasCounterProposal
        )
    }

    private var proposalSummaryLabel: String {
        isInitialSenderWaitingForPartner ? "送った打診" : "届いた打診"
    }

    var body: some View {
        VStack(spacing: 8) {
            disputeBannerSection

            if !responsePresentation.showsResponseControls {
                TradeIncomingProposalSummaryCard(
                    label: proposalSummaryLabel,
                    summary: tradeSummaryLine,
                    action: {
                        detailRoute = .tradeContent
                    }
                )
            }

            if showsAgreementDisclosureActions {
                TradeAgreementDisclosureActionsCard(
                    showsMailingInfo: supportsMailExchange,
                    showsPaymentInfo: showsPaymentInfo,
                    onOpenMailingInfo: onOpenMailingInfo,
                    onOpenPaymentInfo: onOpenPaymentInfo
                )
            } else {
                proposalResponseSection
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.56))
        .sheet(item: $detailRoute) { route in
            TradeSummaryDetailSheet(
                route: route,
                proposal: proposal,
                requestedGoods: requestedGoods,
                offeredGoods: offeredGoods,
                requestedGoodsCount: requestedGoodsCount,
                offeredGoodsCount: offeredGoodsCount
            )
        }
    }

    private var showsAgreementDisclosureActions: Bool {
        (proposal.status == .agreed || proposal.status == .completed)
            && (supportsMailExchange || showsPaymentInfo)
    }

    private var supportsMailExchange: Bool {
        proposal.exchangeMethod == .mail || proposal.exchangeMethod == .both
    }

    private var showsPaymentInfo: Bool {
        proposal.cashOffer || !partnerPaymentMethods.isEmpty || partnerPaymentNote.nilIfBlank != nil
    }

    @ViewBuilder
    private var disputeBannerSection: some View {
        if let latestDisputeSummary {
            TradeDisputeBanner(summary: latestDisputeSummary) {
                onOpenDispute(latestDisputeSummary)
            }
        }
    }

    @ViewBuilder
    private var proposalResponseSection: some View {
        if responsePresentation.showsResponseControls {
            TradeIncomingProposalResponseCard(
                presentation: responsePresentation,
                selectedExchangeMethod: $selectedExchangeMethod,
                selectedPaymentOptionID: $selectedPaymentOptionID,
                isCondensedForKeyboard: isMessageComposerFocused,
                isResponding: isResponding,
                onAgree: {
                    onAgree(
                        responsePresentation.needsExchangeMethodSelection
                            ? selectedExchangeMethod ?? responsePresentation.defaultSelectedExchangeMethod
                            : nil
                    )
                },
                onReject: onReject,
                onCounterProposal: onCounterProposal
            )
        }
    }
}

private struct TradeIncomingProposalSummaryCard: View {
    var label: String
    var summary: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 15, weight: .black))
                    Text(label)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 118, height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityHint("個別募集の詳細を開きます")

            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(width: 1, height: 48)

            Text(summary)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)

            Button(action: action) {
                Text("詳細")
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 54, height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityHint("個別募集の詳細を開きます")
        }
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct TradeIncomingProposalResponseCard: View {
    var presentation: TradeProposalResponsePresentation
    @Binding var selectedExchangeMethod: ExchangeMethod?
    @Binding var selectedPaymentOptionID: String?
    var isCondensedForKeyboard: Bool
    var isResponding: Bool
    var onAgree: () -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void

    private var effectiveExchangeMethod: ExchangeMethod? {
        selectedExchangeMethod ?? presentation.defaultSelectedExchangeMethod
    }

    private var effectivePaymentOptionID: String? {
        selectedPaymentOptionID ?? presentation.defaultPaymentOptionID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let responseHeaderText = presentation.responseHeaderText, !isCondensedForKeyboard {
                Text(responseHeaderText)
                    .font(.system(size: presentation.viewerHasCounterProposal ? 13.5 : 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if presentation.needsExchangeMethodSelection {
                TradeResponseMethodSelector(
                    presentation: presentation,
                    selectedExchangeMethod: $selectedExchangeMethod,
                    effectiveExchangeMethod: effectiveExchangeMethod
                )
            }

            if presentation.showsPaymentSelector {
                TradeResponsePaymentSelector(
                    presentation: presentation,
                    selectedPaymentOptionID: $selectedPaymentOptionID,
                    effectivePaymentOptionID: effectivePaymentOptionID
                )
            }

            actionButtons
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.05), radius: 14, x: 0, y: 8)
        .animation(.snappy(duration: 0.18), value: isCondensedForKeyboard)
        .onAppear {
            if selectedExchangeMethod == nil {
                selectedExchangeMethod = presentation.defaultSelectedExchangeMethod
            }
            if selectedPaymentOptionID == nil {
                selectedPaymentOptionID = presentation.defaultPaymentOptionID
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if presentation.showsPrimaryAgreeAction {
                    primaryActionButton
                }
                counterProposalButton
            }

            Button(action: onReject) {
                Text("見送る")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
            }
            .buttonStyle(.plain)
            .disabled(isResponding || !presentation.canReject)
        }
    }

    private var primaryActionButton: some View {
        Button(action: onAgree) {
            HStack(spacing: 7) {
                if isResponding {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: primaryActionImageName)
                        .font(.system(size: 13.5, weight: .black))
                }
                Text(presentation.primaryActionTitle(selectedExchangeMethod: effectiveExchangeMethod))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .font(.system(size: 13.6, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isResponding || !presentation.canAgree)
    }

    private var counterProposalButton: some View {
        Button(action: onCounterProposal) {
            Label("条件を変えて再打診", systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 13.4, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.38), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isResponding || !presentation.canCounterProposal)
    }

    private var primaryActionImageName: String {
        switch effectiveExchangeMethod {
        case .mail:
            "shippingbox.fill"
        case .hand:
            "mappin.circle.fill"
        case .both, nil:
            "checkmark.circle.fill"
        }
    }
}

private struct TradeResponseMethodSelector: View {
    var presentation: TradeProposalResponsePresentation
    @Binding var selectedExchangeMethod: ExchangeMethod?
    var effectiveExchangeMethod: ExchangeMethod?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                methodCard(.hand)
                methodCard(.mail)
            }
        }
    }

    private func methodCard(_ method: ExchangeMethod) -> some View {
        let isSelected = effectiveExchangeMethod == method
        return Button {
            selectedExchangeMethod = method
        } label: {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 3) {
                    Image(systemName: method == .hand ? "mappin.circle.fill" : "truck.box.fill")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(method == .hand ? MegrumTheme.lavender : MegrumTheme.pink)
                        .frame(width: 41, height: 41)
                        .background((method == .hand ? MegrumTheme.lavender : MegrumTheme.pink).opacity(0.13), in: Circle())

                    Text(method.displayName)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(detailText(for: method))
                        .font(.system(size: 11.4, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.74)
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Image(systemName: isSelected ? "record.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.6))
                    Spacer()
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(isSelected ? MegrumTheme.lavender.opacity(0.06) : .white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(method.displayName)を選択")
    }

    private func detailText(for method: ExchangeMethod) -> String {
        switch method {
        case .hand:
            presentation.localExchangeDetailText
        case .mail:
            presentation.mailExchangeDetailText
        case .both:
            method.displayName
        }
    }
}

private struct TradeResponsePaymentSelector: View {
    var presentation: TradeProposalResponsePresentation
    @Binding var selectedPaymentOptionID: String?
    var effectivePaymentOptionID: String?

    var body: some View {
        Menu {
            ForEach(presentation.paymentMenuOptions) { option in
                Button {
                    selectedPaymentOptionID = option.id
                } label: {
                    Label(
                        option.title,
                        systemImage: option.id == effectivePaymentOptionID ? "checkmark" : "circle"
                    )
                }
            }
        } label: {
            row
        }
        .buttonStyle(.plain)
    }

    private var row: some View {
        HStack(spacing: 8) {
            Image(systemName: "yensign.circle.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
            Text("支払方法")
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer(minLength: 8)
            Text(presentation.paymentOptionTitle(for: effectivePaymentOptionID))
                .font(.system(size: 13.4, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Image(systemName: "chevron.down")
                .font(.system(size: 10.5, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.1), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
