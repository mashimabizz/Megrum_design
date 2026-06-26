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
        let photo = try await PreviewTradePhotoLocalStore.shared.storeEvidencePhoto(input, proposal: proposal)
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
            evidencePhotoURL: photo.photoURL,
            evidenceTakenAt: photo.takenAt,
            evidenceTakenBy: photo.takenBy,
            approvedBySender: proposal.approvedBySender,
            approvedByReceiver: proposal.approvedByReceiver,
            completedAt: proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func approveTradeEvidence(proposalID: UUID, photoID: UUID? = nil) async throws -> TradeProposal {
        _ = photoID
        let proposal = NativePreviewData.proposals.first { $0.id == proposalID }
            ?? TradeProposal(
                id: proposalID,
                senderID: NativePreviewData.viewerID,
                receiverID: NativePreviewData.partnerID,
                status: .agreed,
                exchangeMethod: .hand,
                senderGoodsIDs: [],
                receiverGoodsIDs: [],
                evidencePhotoURL: Self.previewEvidenceFallbackURL
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
            evidencePhotoURL: proposal.evidencePhotoURL ?? Self.previewEvidenceFallbackURL,
            evidenceTakenAt: proposal.evidenceTakenAt ?? .now,
            evidenceTakenBy: proposal.evidenceTakenBy ?? NativePreviewData.viewerID,
            approvedBySender: approvedBySender,
            approvedByReceiver: approvedByReceiver,
            completedAt: approvedBySender && approvedByReceiver ? .now : proposal.completedAt,
            createdAt: proposal.createdAt
        )
    }

    func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        let localPhotos = await PreviewTradePhotoLocalStore.shared.evidencePhotos(for: proposalID)
        if !localPhotos.isEmpty {
            return localPhotos
        }
        guard await PreviewTradePhotoLocalStore.shared.shouldIncludeSeedEvidence(for: proposalID) else {
            return []
        }
        let deletedIDs = await PreviewTradePhotoLocalStore.shared.deletedEvidencePhotoIDs(for: proposalID)
        return [
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e101")!,
                proposalID: proposalID,
                photoURL: NativePreviewData.testGoodsImageURL("aespa_ningning") ?? Self.previewEvidenceFallbackURL,
                position: 1,
                takenAt: .now,
                takenBy: NativePreviewData.viewerID,
                approvedBySender: true,
                approvedByReceiver: false
            ),
            TradeEvidencePhoto(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000e102")!,
                proposalID: proposalID,
                photoURL: NativePreviewData.testGoodsImageURL("twice_dahyun_1") ?? Self.previewEvidenceFallbackURL,
                position: 2,
                takenAt: .now.addingTimeInterval(-120),
                takenBy: NativePreviewData.partnerID,
                approvedBySender: false,
                approvedByReceiver: true
            )
        ].filter { !deletedIDs.contains($0.id) }
    }

    func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        await PreviewTradePhotoLocalStore.shared.deleteEvidencePhoto(proposalID: proposalID, photoID: photoID)
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
        var nextProposal = proposal
        nextProposal.evidencePhotoURL = nil
        nextProposal.evidenceTakenAt = nil
        nextProposal.evidenceTakenBy = nil
        return nextProposal
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

    private static var previewEvidenceFallbackURL: URL {
        NativePreviewData.testGoodsImageURL("bts_v")
            ?? URL(fileURLWithPath: "/tmp/megrum-preview-evidence-fallback.jpg")
    }
}
