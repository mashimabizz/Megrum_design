import Foundation
import MegrumCore

public extension PreviewMegrumRepository {
    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        TradeProposal(
            id: UUID(),
            senderID: NativePreviewData.viewerID,
            receiverID: input.receiverID,
            status: input.status,
            exchangeMethod: input.exchangeMethod,
            senderGoodsIDs: input.senderGoodsIDs,
            receiverGoodsIDs: input.receiverGoodsIDs,
            conditionTags: input.conditionTags,
            cashOffer: input.cashOffer,
            cashAmount: input.cashAmount,
            cashAmountSide: input.cashAmountSide,
            agreedBySender: [.sent, .negotiating, .agreementOneSide, .agreed].contains(input.status),
            agreedByReceiver: input.status == .agreed,
            meetupCandidates: input.meetupCandidates.isEmpty ? input.meetup.map { [$0] } : input.meetupCandidates
        )
    }

    func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .sent,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        let resolvedExchangeMethod = try resolvedAcceptanceExchangeMethod(for: proposal, selectedMethod: acceptedExchangeMethod)
        let agreedBySender = proposal.isSender(NativePreviewData.viewerID) ? true : (proposal.agreedBySender || proposal.status == .sent)
        let agreedByReceiver = proposal.isSender(NativePreviewData.viewerID) ? proposal.agreedByReceiver : true
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: agreedBySender && agreedByReceiver ? .agreed : .agreementOneSide,
            exchangeMethod: resolvedExchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: agreedBySender,
            agreedByReceiver: agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func rejectProposal(proposalID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .sent,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .rejected,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func approveTradeCancel(proposalID: UUID) async throws -> (proposal: TradeProposal, message: TradeMessage) {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.partnerID,
                receiverID: NativePreviewData.viewerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        let cancelled = TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .cancelled,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL,
            evidenceTakenAt: proposal.evidenceTakenAt,
            evidenceTakenBy: proposal.evidenceTakenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
        let message = TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: NativePreviewData.viewerID,
            messageType: .system,
            body: "キャンセル申請に同意しました",
            meta: [
                "action": "cancel_approved",
                "approved_by": NativePreviewData.viewerID.uuidString.lowercased()
            ]
        )
        return (cancelled, message)
    }
}

private func resolvedAcceptanceExchangeMethod(
    for proposal: TradeProposal,
    selectedMethod: ExchangeMethod?
) throws -> ExchangeMethod {
    switch proposal.exchangeMethod {
    case .both:
        guard let selectedMethod, selectedMethod != .both else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return selectedMethod
    case .hand, .mail:
        if let selectedMethod, selectedMethod != proposal.exchangeMethod {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return proposal.exchangeMethod
    }
}
