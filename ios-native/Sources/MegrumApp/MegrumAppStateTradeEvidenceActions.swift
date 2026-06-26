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
            let previousPhotos = evidencePhotosByProposalID[proposalID]
            let systemMessageBody = TradeEvidenceSystemMessage.body(
                actorDisplayName: viewer?.displayName,
                actorHandle: viewer?.handle
            )
            let input = TradeEvidenceCreateInput(
                proposalID: proposalID,
                imageData: imageData,
                imageContentType: imageContentType,
                systemMessageBody: systemMessageBody
            )
            let proposal = try await repository.addTradeEvidence(input)
            replaceProposal(proposal)
            await appendLocalEvidencePhotoIfPossible(
                input: input,
                proposal: proposal,
                previousPhotos: previousPhotos
            )
            addingEvidenceProposalID = nil
            await loadTradeEvidencePhotos(proposal: proposal, reportsFailure: false)
            await loadMessages(proposalID: proposalID)
            appendLocalEvidenceNoticeIfNeeded(proposalID: proposalID, body: systemMessageBody)
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
        let previousPhotos = evidencePhotosByProposalID[proposal.id]
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
            if let existingPhotos = previousPhotos, !existingPhotos.isEmpty {
                evidencePhotosByProposalID[proposal.id] = existingPhotos
            }
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

        let previousProposal = proposals.first { $0.id == proposalID }
        let hadCachedPhotos = evidencePhotosByProposalID.keys.contains(proposalID)
        let previousCachedPhotos = evidencePhotosByProposalID[proposalID]
        let previousDisplayPhotos = previousCachedPhotos
            ?? previousProposal.map {
                TradeEvidencePhotoStateReducer.photos(
                    for: $0,
                    in: evidencePhotosByProposalID,
                    viewerID: viewer?.id
                )
            }
            ?? []

        deletingEvidencePhotoID = photoID
        errorMessage = nil
        evidencePhotosByProposalID[proposalID] = previousDisplayPhotos.filter { $0.id != photoID }
        do {
            let proposal = try await repository.deleteTradeEvidencePhoto(proposalID: proposalID, photoID: photoID)
            replaceProposal(proposal)
            deletingEvidencePhotoID = nil
            return true
        } catch {
            if let previousProposal {
                replaceProposal(previousProposal)
            }
            if hadCachedPhotos {
                evidencePhotosByProposalID[proposalID] = previousCachedPhotos
            } else {
                evidencePhotosByProposalID.removeValue(forKey: proposalID)
            }
            errorMessage = "証跡写真を削除できませんでした"
            deletingEvidencePhotoID = nil
            return false
        }
    }

    public func approveTradeEvidence(proposalID: UUID, photoID: UUID? = nil) async -> Bool {
        guard approvingEvidenceProposalID != proposalID else {
            return false
        }

        approvingEvidenceProposalID = proposalID
        errorMessage = nil
        let previousProposal = proposals.first { $0.id == proposalID }
        if photoID == nil, let optimisticProposal = previousProposal?.markingEvidenceApproved(by: viewer?.id) {
            replaceProposal(optimisticProposal)
        }
        let previousEvidencePhotos = evidencePhotosByProposalID[proposalID]
        if let viewerID = viewer?.id {
            evidencePhotosByProposalID[proposalID] = (previousEvidencePhotos ?? []).map { photo in
                guard photoID == nil || photo.id == photoID else {
                    return photo
                }
                return photo.markingApproved(by: viewerID, in: previousProposal)
            }
        }
        do {
            let proposal = try await repository.approveTradeEvidence(proposalID: proposalID, photoID: photoID)
            replaceProposal(proposal)
            approvingEvidenceProposalID = nil
            await loadTradeEvidencePhotos(proposal: proposal, reportsFailure: false)
            await loadMessages(proposalID: proposalID)
            appendLocalCompletionNoticeIfNeeded(proposal: proposal)
            return true
        } catch {
            if let previousProposal {
                replaceProposal(previousProposal)
            }
            if let previousEvidencePhotos {
                evidencePhotosByProposalID[proposalID] = previousEvidencePhotos
            }
            errorMessage = "証跡を承認できませんでした"
            approvingEvidenceProposalID = nil
            return false
        }
    }

    private func appendLocalEvidenceNoticeIfNeeded(proposalID: UUID, body: String) {
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
            body: body,
            meta: ["action": TradeEvidenceSystemMessage.action]
        )
        messagesByProposalID = TradeMessageStateReducer.appendingMessage(
            message,
            to: messagesByProposalID,
            proposalID: proposalID
        )
    }

    private func appendLocalCompletionNoticeIfNeeded(proposal: TradeProposal) {
        guard proposal.status == .completed, let viewerID = viewer?.id else {
            return
        }
        let messages = messagesByProposalID[proposal.id] ?? []
        let alreadyHasCompletionNotice = messages.contains(where: TradeCompletionSystemMessage.isCompletionNotice)
        guard !alreadyHasCompletionNotice else {
            return
        }
        let message = TradeMessage(
            id: UUID(),
            proposalID: proposal.id,
            senderID: viewerID,
            messageType: .system,
            body: TradeCompletionSystemMessage.body,
            meta: ["action": TradeCompletionSystemMessage.action]
        )
        messagesByProposalID = TradeMessageStateReducer.appendingMessage(
            message,
            to: messagesByProposalID,
            proposalID: proposal.id
        )
    }

    private func appendLocalEvidencePhotoIfPossible(
        input: TradeEvidenceCreateInput,
        proposal: TradeProposal,
        previousPhotos: [TradeEvidencePhoto]?
    ) async {
        guard let viewerID = viewer?.id else {
            return
        }
        if let loadedPhotos = try? await repository.loadTradeEvidencePhotos(proposalID: input.proposalID),
           !loadedPhotos.isEmpty {
            evidencePhotosByProposalID[input.proposalID] = loadedPhotos.sorted { $0.position < $1.position }
            return
        }
        let existing = previousPhotos ?? evidencePhotosByProposalID[input.proposalID] ?? []
        let nextPosition = (existing.map(\.position).max() ?? 0) + 1
        guard let localPhoto = try? await PreviewTradePhotoLocalStore.shared.storeEvidencePhoto(
            input,
            proposal: proposal,
            uploaderID: viewerID,
            position: nextPosition
        ) else {
            return
        }
        var next = evidencePhotosByProposalID[input.proposalID] ?? existing
        if !next.contains(where: { $0.position == localPhoto.position && $0.takenBy == localPhoto.takenBy })
            && !next.contains(where: { $0.photoURL == localPhoto.photoURL }) {
            next.append(localPhoto)
        }
        evidencePhotosByProposalID[input.proposalID] = next.sorted { $0.position < $1.position }
    }
}

private extension TradeProposal {
    func markingEvidenceApproved(by userID: UUID?) -> TradeProposal? {
        guard let userID, isParticipant(userID) else {
            return nil
        }

        var next = self
        if isSender(userID) {
            next.approvedBySender = true
        } else {
            next.approvedByReceiver = true
        }

        if next.status == .agreed, next.approvedBySender, next.approvedByReceiver {
            next.status = .completed
            next.completedAt = next.completedAt ?? .now
        }
        return next
    }
}

private extension TradeEvidencePhoto {
    func markingApproved(by userID: UUID, in proposal: TradeProposal?) -> TradeEvidencePhoto {
        guard let proposal, proposal.isParticipant(userID) else {
            return self
        }
        var next = self
        if proposal.isSender(userID) {
            next.approvedBySender = true
        } else {
            next.approvedByReceiver = true
        }
        return next
    }
}
