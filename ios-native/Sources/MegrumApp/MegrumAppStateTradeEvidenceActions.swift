import Foundation
import MegrumCore

extension MegrumAppState {
    public func addTradeEvidence(proposalID: UUID, imageData: Data, imageContentType: String) async -> Bool {
        guard addingEvidenceProposalID != proposalID else {
            return false
        }
        guard !imageData.isEmpty else {
            errorMessage = "証跡に使う写真を選択してください"
            return false
        }

        addingEvidenceProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.addTradeEvidence(
                TradeEvidenceCreateInput(
                    proposalID: proposalID,
                    imageData: imageData,
                    imageContentType: imageContentType
                )
            )
            replaceProposal(proposal)
            addingEvidenceProposalID = nil
            await loadTradeEvidencePhotos(proposal: proposal, reportsFailure: false)
            await loadMessages(proposalID: proposalID)
            appendLocalEvidenceNoticeIfNeeded(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "証跡写真を追加できませんでした"
            addingEvidenceProposalID = nil
            return false
        }
    }

    public func loadTradeEvidencePhotos(proposal: TradeProposal, reportsFailure: Bool = true) async {
        guard loadingEvidencePhotosProposalID != proposal.id else {
            return
        }

        loadingEvidencePhotosProposalID = proposal.id
        do {
            let photos = try await repository.loadTradeEvidencePhotos(proposalID: proposal.id)
            evidencePhotosByProposalID = TradeEvidencePhotoStateReducer.replacingLoadedPhotos(
                in: evidencePhotosByProposalID,
                proposal: proposal,
                loadedPhotos: photos,
                viewerID: viewer?.id
            )
        } catch {
            evidencePhotosByProposalID = TradeEvidencePhotoStateReducer.replacingLoadedPhotos(
                in: evidencePhotosByProposalID,
                proposal: proposal,
                loadedPhotos: [],
                viewerID: viewer?.id
            )
            if reportsFailure {
                errorMessage = "証跡写真を読み込めませんでした"
            }
        }
        loadingEvidencePhotosProposalID = nil
    }

    public func deleteTradeEvidencePhoto(proposalID: UUID, photoID: UUID) async -> Bool {
        guard deletingEvidencePhotoID != photoID else {
            return false
        }

        deletingEvidencePhotoID = photoID
        errorMessage = nil
        do {
            let proposal = try await repository.deleteTradeEvidencePhoto(proposalID: proposalID, photoID: photoID)
            replaceProposal(proposal)
            deletingEvidencePhotoID = nil
            await loadTradeEvidencePhotos(proposal: proposal, reportsFailure: false)
            return true
        } catch {
            errorMessage = "証跡写真を削除できませんでした"
            deletingEvidencePhotoID = nil
            return false
        }
    }

    public func approveTradeEvidence(proposalID: UUID) async -> Bool {
        guard approvingEvidenceProposalID != proposalID else {
            return false
        }

        approvingEvidenceProposalID = proposalID
        errorMessage = nil
        do {
            let proposal = try await repository.approveTradeEvidence(proposalID: proposalID)
            replaceProposal(proposal)
            approvingEvidenceProposalID = nil
            await loadMessages(proposalID: proposalID)
            return true
        } catch {
            errorMessage = "証跡を承認できませんでした"
            approvingEvidenceProposalID = nil
            return false
        }
    }

    private func appendLocalEvidenceNoticeIfNeeded(proposalID: UUID) {
        guard let viewerID = viewer?.id else {
            return
        }
        let messages = messagesByProposalID[proposalID] ?? []
        let alreadyHasViewerEvidenceNotice = messages.contains { message in
            message.senderID == viewerID && TradeEvidenceSystemMessage.isEvidenceNotice(message)
        }
        guard !alreadyHasViewerEvidenceNotice else {
            return
        }
        let message = TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: viewerID,
            messageType: .system,
            body: "取引証跡が追加されました",
            meta: ["action": TradeEvidenceSystemMessage.action]
        )
        messagesByProposalID = TradeMessageStateReducer.appendingMessage(
            message,
            to: messagesByProposalID,
            proposalID: proposalID
        )
    }
}
