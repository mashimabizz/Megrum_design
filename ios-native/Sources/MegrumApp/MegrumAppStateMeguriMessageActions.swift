import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    public func loadMeguriMessages(reportsFailure: Bool = true) async {
        guard !isLoadingMeguriMessages else {
            return
        }

        isLoadingMeguriMessages = true
        if reportsFailure {
            errorMessage = nil
        }
        do {
            let loadedMessages = try await repository.loadMeguriMessages()
            meguriMessages = loadedMessages
            let participantIDs = Set(loadedMessages.flatMap { [$0.senderID, $0.recipientID] })
            await loadMeguriProfiles(
                userIDs: participantIDs,
                reportsFailure: false
            )
            await loadPublicProfilesForMeguriIdentities(userIDs: participantIDs)
        } catch {
            if reportsFailure {
                errorMessage = "めぐりメッセージを読み込めませんでした"
            }
        }
        isLoadingMeguriMessages = false
    }

    private func loadPublicProfilesForMeguriIdentities(userIDs: Set<UUID>) async {
        for userID in userIDs
        where userID != viewer?.id
            && meguriProfile(for: userID)?.usesPublicProfile == true
            && publicProfilesByUserID[userID] == nil {
            await loadPublicUserProfile(userID: userID, reportsFailure: false)
        }
    }

    public func sendMeguriMessage(
        recipientID: UUID,
        body: String,
        sourceGroomReplyID: UUID? = nil,
        sourceGroomPostID: UUID? = nil,
        sourceGroomOwnerID: UUID? = nil,
        sourceGroomImageURL: URL? = nil
    ) async -> Bool {
        let trimmed = MegrumAppStateInputNormalizer.trimmedText(body)
        guard !trimmed.isEmpty else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを確認してから送信してください"
            return false
        }
        guard viewer.id != recipientID else {
            errorMessage = "自分には送信できません"
            return false
        }
        guard subscriptionState.hasMeguriMessageAccess else {
            errorMessage = "\(SubscriptionCatalog.currentPremiumDisplayName)でめぐり内のメッセージのやり取りができます"
            return false
        }
        guard sendingMeguriMessageRecipientID != recipientID else {
            return false
        }

        sendingMeguriMessageRecipientID = recipientID
        errorMessage = nil
        do {
            let message = try await repository.sendMeguriMessage(
                MeguriMessageCreateInput(
                    senderID: viewer.id,
                    recipientID: recipientID,
                    sourceGroomReplyID: sourceGroomReplyID,
                    sourceGroomPostID: sourceGroomPostID,
                    sourceGroomOwnerID: sourceGroomOwnerID,
                    sourceGroomImageURL: sourceGroomImageURL,
                    body: trimmed
                )
            )
            meguriMessages = MeguriMessageReadStateReducer.appendingSentMessage(
                message,
                to: meguriMessages
            )
            await loadMeguriProfiles(userIDs: [recipientID], reportsFailure: false)
            sendingMeguriMessageRecipientID = nil
            return true
        } catch {
            errorMessage = "めぐりメッセージを送信できませんでした"
            sendingMeguriMessageRecipientID = nil
            return false
        }
    }

    public func sendMeguriPhotoMessage(
        recipientID: UUID,
        imageData: Data,
        imageContentType: String,
        sourceGroomReplyID: UUID? = nil,
        sourceGroomPostID: UUID? = nil,
        sourceGroomOwnerID: UUID? = nil,
        sourceGroomImageURL: URL? = nil,
        body: String? = nil
    ) async -> Bool {
        guard !imageData.isEmpty else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを確認してから送信してください"
            return false
        }
        guard viewer.id != recipientID else {
            errorMessage = "自分には送信できません"
            return false
        }
        guard subscriptionState.hasMeguriMessageAccess else {
            errorMessage = "\(SubscriptionCatalog.currentPremiumDisplayName)でめぐり内のメッセージのやり取りができます"
            return false
        }
        guard sendingMeguriMessageRecipientID != recipientID else {
            return false
        }

        sendingMeguriMessageRecipientID = recipientID
        errorMessage = nil
        do {
            let message = try await repository.sendMeguriPhotoMessage(
                MeguriPhotoMessageCreateInput(
                    senderID: viewer.id,
                    recipientID: recipientID,
                    sourceGroomReplyID: sourceGroomReplyID,
                    sourceGroomPostID: sourceGroomPostID,
                    sourceGroomOwnerID: sourceGroomOwnerID,
                    sourceGroomImageURL: sourceGroomImageURL,
                    imageData: imageData,
                    imageContentType: imageContentType,
                    body: body
                )
            )
            meguriMessages = MeguriMessageReadStateReducer.appendingSentMessage(
                message,
                to: meguriMessages
            )
            await loadMeguriProfiles(userIDs: [recipientID], reportsFailure: false)
            sendingMeguriMessageRecipientID = nil
            return true
        } catch {
            errorMessage = "写真をめぐりメッセージへ送信できませんでした"
            sendingMeguriMessageRecipientID = nil
            return false
        }
    }

    public func markMeguriMessagesRead(
        peerID: UUID,
        sourceGroomPostID: UUID? = nil,
        showsAllPeerMessages: Bool = false
    ) async {
        guard let viewer else {
            return
        }

        let conversationKey = MeguriMessageConversationKey(
            peerID: peerID,
            sourceGroomPostID: sourceGroomPostID
        )
        let targetMessages = showsAllPeerMessages
            ? meguriMessages(with: peerID)
            : meguriMessages(in: conversationKey)

        let readAt = Date()
        let previous = meguriMessages
        if showsAllPeerMessages {
            guard targetMessages.contains(where: {
                $0.senderID == peerID && $0.recipientID == viewer.id && $0.readAt == nil
            }) else {
                return
            }
            meguriMessages = meguriMessages.map { message in
                guard
                    message.senderID == peerID,
                    message.recipientID == viewer.id,
                    message.readAt == nil
                else {
                    return message
                }
                var next = message
                next.readAt = readAt
                return next
            }
        } else {
            guard MeguriMessageReadStateReducer.hasUnreadIncomingMessages(
                targetMessages,
                conversationKey: conversationKey,
                viewerID: viewer.id
            ) else {
                return
            }
            meguriMessages = MeguriMessageReadStateReducer.markIncomingMessagesRead(
                meguriMessages,
                conversationKey: conversationKey,
                viewerID: viewer.id,
                readAt: readAt
            )
        }

        do {
            let updated = try await repository.markMeguriMessagesRead(
                peerID: peerID,
                sourceGroomPostID: sourceGroomPostID,
                includesAllSources: showsAllPeerMessages,
                readAt: readAt
            )
            meguriMessages = MeguriMessageReadStateReducer.mergingUpdated(
                meguriMessages,
                updated: updated
            )
        } catch {
            meguriMessages = previous
            errorMessage = "めぐりメッセージを既読にできませんでした"
        }
    }
}
