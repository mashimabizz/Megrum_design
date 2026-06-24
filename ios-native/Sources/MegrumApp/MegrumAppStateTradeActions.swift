import Foundation
import MegrumCore

extension MegrumAppState {
    public func createProposal(_ input: ProposalCreateInput) async -> Bool {
        guard !isCreatingProposal else {
            return false
        }
        let senderHasSelection = !input.senderGoodsIDs.isEmpty || input.cashAmountSide == .sender
        let receiverHasSelection = !input.receiverGoodsIDs.isEmpty || input.cashAmountSide == .receiver
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

    public func submitTradeEvaluation(proposalID: UUID, stars: Int, comment: String?) async -> Bool {
        guard submittingEvaluationProposalID != proposalID else {
            return false
        }

        submittingEvaluationProposalID = proposalID
        errorMessage = nil
        do {
            _ = try await repository.submitTradeEvaluation(
                TradeEvaluationCreateInput(
                    proposalID: proposalID,
                    stars: stars,
                    comment: comment
                )
            )
            submittingEvaluationProposalID = nil
            return true
        } catch {
            errorMessage = "評価を送信できませんでした"
            submittingEvaluationProposalID = nil
            return false
        }
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

    public func loadMessages(proposalID: UUID, limit: Int = 80) async {
        guard loadingMessagesProposalID != proposalID else {
            return
        }
        loadingMessagesProposalID = proposalID
        errorMessage = nil
        do {
            let messages = try await repository.loadMessages(proposalID: proposalID, limit: limit)
            messagesByProposalID = TradeMessageStateReducer.replacingMessages(
                in: messagesByProposalID,
                proposalID: proposalID,
                messages: messages
            )
            await refreshPartnerReadState(proposalID: proposalID)
            await markProposalRead(proposalID: proposalID, messages: messages)
        } catch {
            errorMessage = "メッセージを読み込めませんでした"
        }
        loadingMessagesProposalID = nil
    }

    public func markProposalRead(proposalID: UUID) async {
        await markProposalRead(proposalID: proposalID, messages: messagesByProposalID[proposalID] ?? [])
    }

    public func sendMessage(proposalID: UUID, body: String) async -> Bool {
        let trimmed = MegrumAppStateInputNormalizer.trimmedText(body)
        guard !trimmed.isEmpty else {
            return false
        }

        return await sendTradeMessage(
            proposalID: proposalID,
            failureMessage: "メッセージを送信できませんでした",
            marksReadAfterSend: true
        ) {
            try await repository.sendMessage(
                TradeMessageCreateInput(proposalID: proposalID, body: trimmed)
            )
        }
    }

    public func sendPhotoMessage(
        proposalID: UUID,
        imageData: Data,
        imageContentType: String,
        messageType: TradeMessageType = .photo,
        body: String? = nil
    ) async -> Bool {
        guard [.photo, .outfitPhoto].contains(messageType), !imageData.isEmpty else {
            return false
        }

        return await sendTradeMessage(
            proposalID: proposalID,
            failureMessage: "写真を取引チャットへ送信できませんでした",
            marksReadAfterSend: true
        ) {
            try await repository.sendPhotoMessage(
                TradePhotoMessageCreateInput(
                    proposalID: proposalID,
                    imageData: imageData,
                    imageContentType: imageContentType,
                    messageType: messageType,
                    body: body
                )
            )
        }
    }

    public func sendSystemMessage(proposalID: UUID, body: String) async -> Bool {
        let trimmed = MegrumAppStateInputNormalizer.trimmedText(body)
        guard !trimmed.isEmpty else {
            return false
        }

        return await sendTradeMessage(
            proposalID: proposalID,
            failureMessage: "取引チャットへ送信できませんでした"
        ) {
            try await repository.sendSystemMessage(proposalID: proposalID, body: trimmed)
        }
    }

    public func sendLateNoticeMessage(
        proposalID: UUID,
        lateMinutes: Int,
        reason: String,
        note: String? = nil
    ) async -> Bool {
        let normalizedReason = MegrumAppStateInputNormalizer.trimmedText(reason)
        guard !normalizedReason.isEmpty else {
            return false
        }

        return await sendTradeMessage(
            proposalID: proposalID,
            failureMessage: "遅刻連絡を送信できませんでした"
        ) {
            try await repository.sendLateNoticeMessage(
                proposalID: proposalID,
                lateMinutes: lateMinutes,
                reason: normalizedReason,
                note: note
            )
        }
    }

    public func sendCancelRequestMessage(
        proposalID: UUID,
        reason: String,
        note: String? = nil
    ) async -> Bool {
        let normalizedReason = MegrumAppStateInputNormalizer.trimmedText(reason)
        guard !normalizedReason.isEmpty else {
            return false
        }

        return await sendTradeMessage(
            proposalID: proposalID,
            failureMessage: "キャンセル申請を送信できませんでした"
        ) {
            try await repository.sendCancelRequestMessage(
                proposalID: proposalID,
                reason: normalizedReason,
                note: note
            )
        }
    }

    public func sendLocationMessage(
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String,
        body: String? = nil
    ) async -> Bool {
        let normalizedLabel = MegrumAppStateInputNormalizer.trimmedText(label)
        guard !normalizedLabel.isEmpty else {
            return false
        }

        return await sendTradeMessage(
            proposalID: proposalID,
            failureMessage: "現在地を共有できませんでした"
        ) {
            try await repository.sendLocationMessage(
                proposalID: proposalID,
                latitude: latitude,
                longitude: longitude,
                label: normalizedLabel,
                body: body
            )
        }
    }

    public func sendArrivalStatusMessage(
        proposalID: UUID,
        status: TradeArrivalStatus,
        body: String? = nil
    ) async -> Bool {
        return await sendTradeMessage(
            proposalID: proposalID,
            failureMessage: "到着ステータスを送信できませんでした"
        ) {
            try await repository.sendArrivalStatusMessage(
                proposalID: proposalID,
                status: status,
                body: body
            )
        }
    }

    private func refreshPartnerReadState(proposalID: UUID) async {
        guard
            let viewerID = viewer?.id,
            let proposal = proposals.first(where: { $0.id == proposalID }),
            let partnerID = proposal.partnerID(for: viewerID)
        else {
            partnerReadAtByProposalID = TradeMessageStateReducer.settingReadAt(
                in: partnerReadAtByProposalID,
                proposalID: proposalID,
                readAt: nil
            )
            return
        }

        do {
            let readState = try await repository.loadProposalReadState(
                proposalID: proposalID,
                userID: partnerID
            )
            partnerReadAtByProposalID = TradeMessageStateReducer.settingReadAt(
                in: partnerReadAtByProposalID,
                proposalID: proposalID,
                readAt: readState?.lastReadAt
            )
        } catch {
            partnerReadAtByProposalID = TradeMessageStateReducer.settingReadAt(
                in: partnerReadAtByProposalID,
                proposalID: proposalID,
                readAt: nil
            )
        }
    }

    private func markProposalRead(proposalID: UUID, messages: [TradeMessage]) async {
        guard
            let viewerID = viewer?.id,
            let proposal = proposals.first(where: { $0.id == proposalID })
        else {
            return
        }
        let latestReadAt = TradeMessageStateReducer.latestReadAt(
            for: proposal,
            proposalID: proposalID,
            messages: messages
        )
        viewerReadAtByProposalID = TradeMessageStateReducer.settingReadAt(
            in: viewerReadAtByProposalID,
            proposalID: proposalID,
            readAt: latestReadAt
        )

        do {
            let readState = try await repository.markProposalMessagesRead(
                proposalID: proposalID,
                userID: viewerID,
                lastReadAt: latestReadAt
            )
            viewerReadAtByProposalID = TradeMessageStateReducer.settingReadAt(
                in: viewerReadAtByProposalID,
                proposalID: proposalID,
                readAt: TradeMessageStateReducer.resolvedReadAt(
                    from: readState,
                    fallback: latestReadAt
                )
            )
        } catch {
            return
        }
    }

    private func sendTradeMessage(
        proposalID: UUID,
        failureMessage: String,
        marksReadAfterSend: Bool = false,
        operation: () async throws -> TradeMessage
    ) async -> Bool {
        guard sendingMessageProposalID != proposalID else {
            return false
        }

        sendingMessageProposalID = proposalID
        errorMessage = nil
        do {
            let message = try await operation()
            messagesByProposalID = TradeMessageStateReducer.appendingMessage(
                message,
                to: messagesByProposalID,
                proposalID: proposalID
            )
            if marksReadAfterSend {
                await markProposalRead(
                    proposalID: proposalID,
                    messages: messagesByProposalID[proposalID] ?? [message]
                )
            }
            sendingMessageProposalID = nil
            return true
        } catch {
            errorMessage = failureMessage
            sendingMessageProposalID = nil
            return false
        }
    }

    private func replaceProposal(_ proposal: TradeProposal) {
        proposals = TradeProposalStateReducer.replacingOrPrepending(proposal, in: proposals)
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
