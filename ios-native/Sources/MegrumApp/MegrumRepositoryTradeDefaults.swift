import Foundation
import MegrumCore

public extension MegrumRepository {
    func createProposal(_ input: ProposalCreateInput) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func reviseProposal(proposalID: UUID, input: ProposalCreateInput) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func rejectProposal(proposalID: UUID) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func approveTradeCancel(proposalID: UUID) async throws -> (proposal: TradeProposal, message: TradeMessage) {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func addTradeEvidence(_ input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadTradeEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        []
    }

    func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func approveTradeEvidence(proposalID: UUID, photoID: UUID? = nil) async throws -> TradeProposal {
        _ = photoID
        throw MegrumRepositoryError.unsupportedMutation
    }

    func submitTradeEvaluation(_ input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func fileTradeDispute(_ input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        []
    }

    func loadProposalReadState(proposalID: UUID, userID: UUID) async throws -> ProposalReadState? {
        nil
    }

    func markProposalMessagesRead(proposalID: UUID, userID: UUID, lastReadAt: Date) async throws -> ProposalReadState? {
        nil
    }

    func sendMessage(_ input: TradeMessageCreateInput) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendPhotoMessage(_ input: TradePhotoMessageCreateInput) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendSystemMessage(proposalID: UUID, body: String) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendLateNoticeMessage(proposalID: UUID, lateMinutes: Int, reason: String, note: String?) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendCancelRequestMessage(proposalID: UUID, reason: String, note: String?) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendLocationMessage(proposalID: UUID, latitude: Double, longitude: Double, label: String, body: String?) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendArrivalStatusMessage(proposalID: UUID, status: TradeArrivalStatus, body: String?) async throws -> TradeMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        []
    }

    func loadPersonalSchedules(startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        []
    }

    func loadProfileSchedules(userID: UUID, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        []
    }

    func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        throw MegrumRepositoryError.unsupportedMutation
    }
}
