import Foundation
import MegrumCore

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
            errorMessage = "打診を更新できませんでした"
            isCreatingProposal = false
            return false
        }
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
