import Foundation
import MegrumCore
import MegrumData

extension MegrumAppState {
    public func createProposal(_ input: ProposalCreateInput) async -> Bool {
        guard !isCreatingProposal else {
            return false
        }
        let cashSide = resolvedCashSide(for: input)
        let senderHasSelection = !input.senderGoodsIDs.isEmpty || cashSide == .sender
        let receiverHasSelection = !input.receiverGoodsIDs.isEmpty || cashSide == .receiver
        guard senderHasSelection && receiverHasSelection else {
            errorMessage = "提示物を選択してください"
            return false
        }
        guard !(input.cashAmountSide == nil && input.cashAmount != nil) else {
            errorMessage = "金額指定の対象を確認してください"
            return false
        }

        isCreatingProposal = true
        errorMessage = nil
        do {
            let proposal = try await repository.createProposal(input)
            proposals = TradeProposalStateReducer.prependingCreatedProposal(
                proposal,
                to: proposals
            )
            isCreatingProposal = false
            return true
        } catch {
            errorMessage = "打診を作成できませんでした"
            isCreatingProposal = false
            return false
        }
    }

    public func reviseProposal(proposalID: UUID, input: ProposalCreateInput) async -> Bool {
        guard !isCreatingProposal else {
            return false
        }
        let cashSide = resolvedCashSide(for: input)
        let senderHasSelection = !input.senderGoodsIDs.isEmpty || cashSide == .sender
        let receiverHasSelection = !input.receiverGoodsIDs.isEmpty || cashSide == .receiver
        guard senderHasSelection && receiverHasSelection else {
            errorMessage = "提示物を選択してください"
            return false
        }
        guard !(input.cashAmountSide == nil && input.cashAmount != nil) else {
            errorMessage = "金額指定の対象を確認してください"
            return false
        }

        isCreatingProposal = true
        errorMessage = nil
        do {
            let proposal = try await repository.reviseProposal(proposalID: proposalID, input: input)
            replaceProposal(proposal)
            isCreatingProposal = false
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = Self.proposalReviseErrorMessage(from: error)
            isCreatingProposal = false
            return false
        }
    }

    /// iter1226.423：再打診失敗の原因を闇落ちさせない（待ち合わせ必須は専用文言）。
    static func proposalReviseErrorMessage(from error: Error) -> String {
        if let restError = error as? SupabaseRESTError,
           let message = restError.serverMessage {
            if message.contains("meetup_required") {
                return "手渡し交換は待ち合わせ（日時・場所）の設定が必要です。待ち合わせを設定してから送信してください"
            }
            return "打診を更新できませんでした（\(message)）"
        }
        return "打診を更新できませんでした"
    }

    public func agreeProposal(proposalID: UUID, acceptedExchangeMethod: ExchangeMethod? = nil) async -> Bool {
        guard respondingProposalID != proposalID else {
            return false
        }

        respondingProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.agreeProposal(
                proposalID: proposalID,
                acceptedExchangeMethod: acceptedExchangeMethod
            )
            replaceProposal(proposal)
            respondingProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "打診を承諾できませんでした"
            respondingProposalID = nil
            return false
        }
    }

    /// 成立前の打診を取り下げる（サーバーから物理削除し、ローカルからも消す）。
    public func withdrawProposal(proposalID: UUID) async -> Bool {
        errorMessage = nil
        do {
            try await repository.withdrawProposalBeforeAgreement(proposalID: proposalID)
            proposals.removeAll { $0.id == proposalID }
            messagesByProposalID[proposalID] = nil
            viewerReadAtByProposalID[proposalID] = nil
            partnerReadAtByProposalID[proposalID] = nil
            return true
        } catch {
            errorMessage = (error as? SupabaseRESTError)?.serverMessage ?? "打診を取り下げられませんでした"
            return false
        }
    }

    public func rejectProposal(proposalID: UUID) async -> Bool {
        guard respondingProposalID != proposalID else {
            return false
        }

        respondingProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.rejectProposal(proposalID: proposalID)
            replaceProposal(proposal)
            respondingProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "打診を断れませんでした"
            respondingProposalID = nil
            return false
        }
    }

    public func approveTradeCancel(proposalID: UUID) async -> Bool {
        guard respondingProposalID != proposalID else {
            return false
        }

        respondingProposalID = proposalID
        errorMessage = nil
        do {
            let result = try await repository.approveTradeCancel(proposalID: proposalID)
            replaceProposal(result.proposal)
            messagesByProposalID = TradeMessageStateReducer.appendingMessage(
                result.message,
                to: messagesByProposalID,
                proposalID: proposalID
            )
            respondingProposalID = nil
            return true
        } catch {
            errorMessage = "キャンセル申請に同意できませんでした"
            respondingProposalID = nil
            return false
        }
    }

    private func resolvedCashSide(for input: ProposalCreateInput) -> ProposalCashSide? {
        if let cashAmountSide = input.cashAmountSide {
            return cashAmountSide
        }
        guard input.cashOffer else {
            return nil
        }
        if input.senderGoodsIDs.isEmpty, !input.receiverGoodsIDs.isEmpty {
            return .sender
        }
        if input.receiverGoodsIDs.isEmpty, !input.senderGoodsIDs.isEmpty {
            return .receiver
        }
        return nil
    }
}
