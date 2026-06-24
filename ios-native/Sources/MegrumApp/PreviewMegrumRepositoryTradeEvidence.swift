import Foundation
import MegrumCore

public extension PreviewMegrumRepository {
    func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == input.proposalID }
            ?? NativePreviewData.proposals.first
            ?? TradeProposal(
                id: input.proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: .agreed,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: URL(string: "https://example.com/evidence.jpg")!,
            evidenceTakenAt: .now,
            evidenceTakenBy: NativePreviewData.viewerID,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func approveTradeEvidence(proposalID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: [],
                evidencePhotoURL: URL(string: "https://example.com/evidence.jpg")!
            )
        let approvedBySender = proposal.isSender(NativePreviewData.viewerID) ? true : proposal.approvedBySender
        let approvedByReceiver = proposal.isSender(NativePreviewData.viewerID) ? proposal.approvedByReceiver : true
        return TradeProposal(
            id: proposal.id,
            senderID: proposal.senderID,
            receiverID: proposal.receiverID,
            status: approvedBySender && approvedByReceiver ? .completed : .agreed,
            exchangeMethod: proposal.exchangeMethod,
            senderGoodsIDs: proposal.senderGoodsIDs,
            receiverGoodsIDs: proposal.receiverGoodsIDs,
            conditionTags: proposal.conditionTags,
            cashOffer: proposal.cashOffer,
            cashAmount: proposal.cashAmount,
            cashAmountSide: proposal.cashAmountSide,
            agreedBySender: proposal.agreedBySender,
            agreedByReceiver: proposal.agreedByReceiver,
            evidencePhotoURL: proposal.evidencePhotoURL ?? URL(string: "https://example.com/evidence.jpg")!,
            evidenceTakenAt: proposal.evidenceTakenAt ?? .now,
            evidenceTakenBy: proposal.evidenceTakenBy ?? NativePreviewData.viewerID,
            approvedBySender: approvedBySender,
            approvedByReceiver: approvedByReceiver,
            completedAt: approvedBySender && approvedByReceiver ? .now : proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        [
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e101")!,
                proposalID: proposalID,
                photoURL: URL(string: "https://picsum.photos/seed/megrum-evidence-1/640/480")!,
                position: 1,
                takenAt: .now,
                takenBy: NativePreviewData.viewerID
            ),
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e102")!,
                proposalID: proposalID,
                photoURL: URL(string: "https://picsum.photos/seed/megrum-evidence-2/640/480")!,
                position: 2,
                takenAt: .now.addingTimeInterval(-120),
                takenBy: NativePreviewData.partnerID
            )
        ]
    }

    func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: []
            )
        return proposal
    }

    func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        UserEvaluation(
            id: UUID(),
            raterID: NativePreviewData.viewerID,
            raterHandle: NativePreviewData.viewer.handle,
            raterDisplayName: NativePreviewData.viewer.displayName,
            stars: input.stars,
            comment: input.comment
        )
    }

    func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        TradeDisputeTicket(
            id: UUID(),
            proposalID: input.proposalID,
            ticketNo: "DPT-260531-0001",
            status: "submitted"
        )
    }
}
