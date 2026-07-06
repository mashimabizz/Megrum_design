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
    @State private var presentationState = TradeDetailPinnedSummaryPresentationState()

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
                    offeredGoods: offeredGoods,
                    requestedGoods: requestedGoods,
                    offeredGoodsCount: offeredGoodsCount,
                    requestedGoodsCount: requestedGoodsCount,
                    action: {
                        presentationState.openTradeContentDetails()
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
        .sheet(item: $presentationState.detailRoute) { route in
            TradeSummaryDetailSheet(
                route: route,
                proposal: proposal,
                viewerID: viewerID,
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
                selectedExchangeMethod: $presentationState.selectedExchangeMethod,
                selectedPaymentOptionID: $presentationState.selectedPaymentOptionID,
                isCondensedForKeyboard: isMessageComposerFocused,
                isResponding: isResponding,
                onAgree: {
                    onAgree(presentationState.agreementExchangeMethod(for: responsePresentation))
                },
                onReject: onReject,
                onCounterProposal: onCounterProposal
            )
        }
    }
}
