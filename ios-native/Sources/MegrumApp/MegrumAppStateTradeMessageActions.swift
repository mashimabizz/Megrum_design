import Foundation
import MegrumCore

extension MegrumAppState {
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
}
