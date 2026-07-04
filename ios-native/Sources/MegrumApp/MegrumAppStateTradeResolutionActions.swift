import Foundation
import MegrumCore

extension MegrumAppState {
    public func submitTradeEvaluation(proposalID: UUID, stars: Int, comment: String?) async -> Bool {
        guard submittingEvaluationProposalID != proposalID else {
            return false
        }

        submittingEvaluationProposalID = proposalID
        errorMessage = nil
        do {
            let body = TradeEvaluationSystemMessage.body(
                actorDisplayName: viewer?.displayName,
                actorHandle: viewer?.handle
            )
            let evaluation = try await repository.submitTradeEvaluation(
                TradeEvaluationCreateInput(
                    proposalID: proposalID,
                    stars: stars,
                    comment: comment,
                    systemMessageBody: body,
                    raterDisplayName: viewer?.displayName,
                    raterHandle: viewer?.handle
                )
            )
            submittingEvaluationProposalID = nil
            appendLocalEvaluationNoticeIfNeeded(proposalID: proposalID, body: body, evaluation: evaluation)
            return true
        } catch {
            errorMessage = "評価を送信できませんでした"
            submittingEvaluationProposalID = nil
            return false
        }
    }

    private func appendLocalEvaluationNoticeIfNeeded(
        proposalID: UUID,
        body: String,
        evaluation: UserEvaluation
    ) {
        guard let viewerID = viewer?.id else {
            return
        }
        let messages = messagesByProposalID[proposalID] ?? []
        let alreadyHasViewerEvaluationNotice = messages.contains { message in
            TradeEvaluationSystemMessage.isEvaluationNotice(message)
                && TradeEvaluationSystemMessage.raterID(for: message) == viewerID
        }
        guard !alreadyHasViewerEvaluationNotice else {
            return
        }

        var meta: [String: String] = [
            "action": TradeEvaluationSystemMessage.action,
            "stars": "\(evaluation.stars)",
            "rater_id": viewerID.uuidString.lowercased(),
            "rater_display_name": evaluation.raterDisplayName,
            "rater_handle": evaluation.raterHandle
        ]
        if let comment = evaluation.comment?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank {
            meta["comment"] = comment
        }
        let message = TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: viewerID,
            messageType: .system,
            body: body,
            meta: meta
        )
        messagesByProposalID = TradeMessageStateReducer.appendingMessage(
            message,
            to: messagesByProposalID,
            proposalID: proposalID
        )
    }

    public func fileTradeDispute(
        proposalID: UUID,
        category: TradeDisputeCategory,
        factMemo: String
    ) async -> Bool {
        let trimmed = MegrumAppStateInputNormalizer.trimmedText(factMemo)
        guard !trimmed.isEmpty else {
            errorMessage = "申告内容を入力してください"
            return false
        }
        guard filingDisputeProposalID != proposalID else {
            return false
        }

        filingDisputeProposalID = proposalID
        errorMessage = nil
        do {
            _ = try await repository.fileTradeDispute(
                TradeDisputeCreateInput(
                    proposalID: proposalID,
                    category: category,
                    factMemo: trimmed
                )
            )
            filingDisputeProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "申告を送信できませんでした"
            filingDisputeProposalID = nil
            return false
        }
    }
}
