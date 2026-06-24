import Foundation
import MegrumCore

extension TradeDetailScreen {
    var messages: [TradeMessage] {
        appState.messages(for: proposal.id)
    }

    var currentProposal: TradeProposal {
        appState.proposals.first { $0.id == proposal.id } ?? proposal
    }

    var goodsByID: [UUID: GoodsItem] {
        TradeGoodsLookup.build(
            inventory: appState.inventory,
            homeMatchedItems: appState.homeMatchedItems,
            homePossibleItems: appState.homePossibleItems,
            wishes: appState.wishes,
            publicTradeGoodsByUserID: appState.publicTradeGoodsByUserID
        )
    }

    var latestDisputeSummary: TradeDisputeSummary? {
        messages
            .compactMap(TradeDisputeSummary.init(message:))
            .max { $0.submittedAt < $1.submittedAt }
    }

    var chatInputAvailability: TradeChatInputAvailability {
        TradeChatInputAvailability(proposal: currentProposal)
    }

    var isChatInputVisible: Bool {
        guard let viewerID else {
            return false
        }
        return currentProposal.isParticipant(viewerID) && chatInputAvailability.canSendMessages
    }

    var messageInputContext: TradeMessageInputContext {
        TradeMessageInputContext(
            isSending: appState.sendingMessageProposalID == proposal.id,
            canUseCamera: canUseCamera,
            proposalStatus: currentProposal.status,
            supportsHandExchange: supportsHandExchange,
            showsCounterProposal: currentProposal.canCreateCounterProposal(from: viewerID)
        )
    }

    var supportsHandExchange: Bool {
        currentProposal.exchangeMethod == .hand || currentProposal.exchangeMethod == .both
    }

    var evaluationPromptState: TradeEvaluationPromptState {
        TradeEvaluationPromptState(
            proposal: currentProposal,
            viewerID: viewerID,
            messages: messages,
            localSubmission: didSubmitEvaluation
        )
    }

    var viewerID: UUID? {
        appState.viewer?.id
    }

    var partnerID: UUID? {
        viewerID.flatMap { currentProposal.partnerID(for: $0) }
    }

    var partnerProfile: UserProfile? {
        partnerID.flatMap { appState.publicProfilesByUserID[$0]?.profile }
    }

    var heroPresentation: TradeDetailHeroPresentation {
        TradeDetailHeroPresentation(
            proposal: currentProposal,
            viewerID: viewerID,
            profilesByUserID: appState.publicProfilesByUserID
        )
    }

    var offeredGoodsIDs: [UUID] {
        viewerID.flatMap { currentProposal.goodsOffered(by: $0) } ?? currentProposal.senderGoodsIDs
    }

    var requestedGoodsIDs: [UUID] {
        viewerID.flatMap { currentProposal.goodsRequested(by: $0) } ?? currentProposal.receiverGoodsIDs
    }

    var requestedGoods: [GoodsItem] {
        tradeItems(for: requestedGoodsIDs)
    }

    var offeredGoods: [GoodsItem] {
        tradeItems(for: offeredGoodsIDs)
    }

    var paymentSummaryText: String? {
        guard currentProposal.cashOffer else {
            return nil
        }
        return UserPaymentMethod.displayText(
            for: partnerProfile?.paymentMethods ?? [],
            otherNote: partnerProfile?.paymentNote,
            emptyText: "未設定"
        )
    }
}
