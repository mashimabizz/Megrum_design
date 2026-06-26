import Foundation
import MegrumCore
import MegrumData

public extension SupabaseMegrumRepository {
    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        try await proposalClient.createProposal(senderID: viewerID, input: input)
    }

    func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        try await proposalClient.agreeProposal(
            userID: viewerID,
            proposalID: proposalID,
            acceptedExchangeMethod: acceptedExchangeMethod
        )
    }

    func rejectProposal(proposalID: UUID) async throws -> TradeProposal {
        try await proposalClient.rejectProposal(userID: viewerID, proposalID: proposalID)
    }

    func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        try await proposalClient.addEvidencePhoto(userID: viewerID, input: input)
    }

    func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        try await proposalClient.loadEvidencePhotos(proposalID: proposalID)
    }

    func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        try await proposalClient.deleteEvidencePhoto(userID: viewerID, proposalID: proposalID, photoID: photoID)
    }

    func approveTradeEvidence(proposalID: UUID, photoID: UUID? = nil) async throws -> TradeProposal {
        try await proposalClient.approveEvidence(userID: viewerID, proposalID: proposalID, photoID: photoID)
    }

    func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        try await proposalClient.submitEvaluation(userID: viewerID, input: input)
    }

    func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        try await disputeClient.createDispute(userID: viewerID, input: input)
    }

    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        try await messageClient.loadMessages(proposalID: proposalID, limit: limit)
    }

    func loadProposalReadState(proposalID: UUID, userID: UUID) async throws -> ProposalReadState? {
        try await messageClient.loadProposalReadState(proposalID: proposalID, userID: userID)
    }

    func markProposalMessagesRead(proposalID: UUID, userID: UUID, lastReadAt: Date) async throws -> ProposalReadState? {
        try await messageClient.markProposalMessagesRead(
            proposalID: proposalID,
            userID: userID,
            lastReadAt: lastReadAt
        )
    }

    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        try await messageClient.sendTextMessage(senderID: viewerID, input: input)
    }

    func sendPhotoMessage(_ input: TradePhotoMessageCreateInput) async throws -> TradeMessage {
        let result = try await chatPhotoStorage.uploadPhoto(input)
        var message = try await messageClient.sendPhotoMessage(
            senderID: viewerID,
            proposalID: input.proposalID,
            photoURL: result.signedURL,
            body: input.body,
            messageType: input.messageType,
            storagePath: result.upload.path,
            storageBucket: SupabaseChatPhotoStorage.bucket
        )
        if let localPhotoURL = try? await PreviewTradePhotoLocalStore.shared.storeChatPhoto(input) {
            message.photoURL = localPhotoURL
        }
        return message
    }

    func sendSystemMessage(proposalID: UUID, body: String) async throws -> TradeMessage {
        try await messageClient.sendSystemMessage(senderID: viewerID, proposalID: proposalID, body: body)
    }

    func sendLateNoticeMessage(
        proposalID: UUID,
        lateMinutes: Int,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendLateNoticeMessage(
            senderID: viewerID,
            proposalID: proposalID,
            lateMinutes: lateMinutes,
            reason: reason,
            note: note
        )
    }

    func sendCancelRequestMessage(
        proposalID: UUID,
        reason: String,
        note: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendCancelRequestMessage(
            senderID: viewerID,
            proposalID: proposalID,
            reason: reason,
            note: note
        )
    }

    func approveTradeCancel(proposalID: UUID) async throws -> (proposal: TradeProposal, message: TradeMessage) {
        let proposal = try await proposalClient.approveCancel(userID: viewerID, proposalID: proposalID)
        let message = try await messageClient.sendCancelApprovedMessage(
            senderID: viewerID,
            proposalID: proposalID
        )
        return (proposal, message)
    }

    func sendLocationMessage(
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String,
        body: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendLocationMessage(
            senderID: viewerID,
            proposalID: proposalID,
            latitude: latitude,
            longitude: longitude,
            label: label,
            body: body
        )
    }

    func sendArrivalStatusMessage(
        proposalID: UUID,
        status: TradeArrivalStatus,
        body: String?
    ) async throws -> TradeMessage {
        try await messageClient.sendArrivalStatusMessage(
            senderID: viewerID,
            proposalID: proposalID,
            status: status,
            body: body
        )
    }
}
