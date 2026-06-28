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
