import Foundation
import MegrumData
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
            viewerEvaluatedProposalIDs.insert(proposalID)
            persistViewerEvaluatedProposalIDsIfPossible()
            appendLocalEvaluationNoticeIfNeeded(proposalID: proposalID, body: body, evaluation: evaluation)
            return true
        } catch SupabaseProposalClientError.alreadyEvaluated {
            // iter1226.423：すでに評価済み＝完了扱いにして画面を閉じる（以前は汎用エラーで詰まっていた）。
            submittingEvaluationProposalID = nil
            viewerEvaluatedProposalIDs.insert(proposalID)
            persistViewerEvaluatedProposalIDsIfPossible()
            return true
        } catch {
            errorMessage = Self.tradeEvaluationErrorMessage(from: error)
            submittingEvaluationProposalID = nil
            return false
        }
    }

    /// 自分の評価済み proposal ID をサーバーから取得する。
    /// 失敗時は現状維持（メッセージ由来の判定にフォールバック）。
    /// iter1226.423：評価失敗の原因を出す（サーバー詳細を併記）。
    static func tradeEvaluationErrorMessage(from error: Error) -> String {
        if error as? SupabaseProposalClientError == .invalidStatus {
            return "この取引はまだ評価できません（取引完了後に評価できます）"
        }
        if let restError = error as? SupabaseRESTError, let message = restError.serverMessage {
            return "評価を送信できませんでした（\(message)）"
        }
        return "評価を送信できませんでした"
    }

    public func loadViewerEvaluatedProposalIDs() async {
        do {
            // ローカル保存分（直近の送信）はサーバー反映前でも保持する。
            viewerEvaluatedProposalIDs.formUnion(try await repository.loadViewerEvaluatedProposalIDs())
            persistViewerEvaluatedProposalIDsIfPossible()
        } catch {
            #if DEBUG
            MegrumAppLogger.general.debug("Megrum evaluated proposal ids load failed: \(String(describing: error), privacy: .public)")
            #endif
        }
    }

    func persistViewerEvaluatedProposalIDsIfPossible() {
        guard let viewerID = viewer?.id else {
            return
        }
        ViewerEvaluatedProposalStore.save(viewerEvaluatedProposalIDs, viewerID: viewerID)
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
