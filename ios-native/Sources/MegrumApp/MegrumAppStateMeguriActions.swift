import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    public func loadMeguriFeed(
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) async {
        guard !isLoadingMeguri else {
            return
        }

        let selectedPrefecture = boardPrefecture(explicitPrefecture: prefecture)
        isLoadingMeguri = true
        errorMessage = nil
        do {
            async let loadedGrooms = repository.loadGrooms(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: 1_000
            )
            async let loadedThreads = repository.loadBoardThreads(
                latitude: latitude,
                longitude: longitude,
                prefecture: selectedPrefecture,
                scope: scope
            )
            grooms = try await loadedGrooms
            threads = try await loadedThreads
        } catch {
            errorMessage = "めぐりを読み込めませんでした"
        }
        isLoadingMeguri = false
    }

    private func boardPrefecture(explicitPrefecture: String?) -> String? {
        MegrumAppStateInputNormalizer.prefecture(explicitPrefecture)
            ?? MegrumAppStateInputNormalizer.prefecture(viewer?.prefecture)
    }

    public func loadGroomMapPosts(
        latitude: Double? = nil,
        longitude: Double? = nil,
        radiusMeters: Int = 3_000
    ) async {
        guard !isLoadingGroomMap else {
            return
        }

        isLoadingGroomMap = true
        errorMessage = nil
        do {
            groomMapPosts = try await repository.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters
            )
        } catch {
            errorMessage = "グルームマップを読み込めませんでした"
        }
        isLoadingGroomMap = false
    }

    public func loadGroomArchive(limit: Int = 120) async {
        guard !isLoadingGroomArchive else {
            return
        }
        guard viewer != nil else {
            errorMessage = "プロフィールを読み込んでから確認してください"
            return
        }

        isLoadingGroomArchive = true
        errorMessage = nil
        do {
            let archivedGrooms = try await repository.loadOwnGroomArchive(limit: limit)
            let postIDs = archivedGrooms.map(\.id)
            async let reactions = repository.loadGroomReactions(postIDs: postIDs)
            async let replies = repository.loadGroomReplies(postIDs: postIDs)

            ownGroomArchive = GroomArchiveOrdering.sorted(archivedGrooms)
            groomReactionsByPostID = Dictionary(grouping: try await reactions, by: \.groomPostID)
            groomRepliesByPostID = ReplyThreadStateReducer.mergingGroomReplies(
                try await replies,
                into: groomRepliesByPostID
            )
            await loadPublicProfilesForGroomArchive()
        } catch {
            errorMessage = "グルームアーカイブを読み込めませんでした"
        }
        isLoadingGroomArchive = false
    }

    public func createGroomPost(
        imageData: Data,
        imageContentType: String,
        caption: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async -> Bool {
        guard !isCreatingGroomPost else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを読み込んでから投稿してください"
            return false
        }
        guard !imageData.isEmpty else {
            errorMessage = "投稿する画像を選択してください"
            return false
        }
        guard let latitude, let longitude else {
            errorMessage = "現在地を確認してから投稿してください"
            return false
        }

        isCreatingGroomPost = true
        errorMessage = nil
        do {
            let post = try await repository.createGroomPost(
                GroomPostCreateInput(
                    authorID: viewer.id,
                    imageData: imageData,
                    imageContentType: imageContentType,
                    caption: caption,
                    latitude: latitude,
                    longitude: longitude
                )
            )
            grooms = MeguriFeedStateReducer.upsertingGroomPost(post, into: grooms)
            groomMapPosts = MeguriFeedStateReducer.upsertingGroomPost(post, into: groomMapPosts)
            isCreatingGroomPost = false
            return true
        } catch {
            errorMessage = "グルームを投稿できませんでした"
            isCreatingGroomPost = false
            return false
        }
    }

    public func markGroomViewed(_ postID: UUID) async {
        viewedGroomIDs = GroomInteractionStateReducer.markingViewed(
            postID: postID,
            in: viewedGroomIDs
        )
        do {
            try await repository.markGroomViewed(postID: postID)
        } catch {
            errorMessage = "グルームの閲覧状態を更新できませんでした"
        }
    }

    public func setGroomLiked(_ postID: UUID, isLiked: Bool) async {
        let previousLikedIDs = likedGroomIDs
        likedGroomIDs = GroomInteractionStateReducer.settingLiked(
            postID: postID,
            isLiked: isLiked,
            in: likedGroomIDs
        )
        do {
            try await repository.setGroomLiked(postID: postID, isLiked: isLiked)
        } catch {
            likedGroomIDs = previousLikedIDs
            errorMessage = "グルームのいいねを更新できませんでした"
        }
    }

    public func sendGroomReply(
        postID: UUID,
        recipientID: UUID,
        body: String,
        groomImageURL: URL?
    ) async -> Bool {
        let trimmed = MegrumAppStateInputNormalizer.trimmedText(body)
        guard !trimmed.isEmpty else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを確認してから返信してください"
            return false
        }
        guard viewer.id != recipientID else {
            errorMessage = "自分のグルームには返信できません"
            return false
        }
        guard sendingGroomReplyPostID != postID else {
            return false
        }

        sendingGroomReplyPostID = postID
        errorMessage = nil
        do {
            let reply = try await repository.sendGroomReply(
                GroomReplyCreateInput(
                    groomPostID: postID,
                    senderID: viewer.id,
                    recipientID: recipientID,
                    body: trimmed,
                    groomImageURL: groomImageURL
                )
            )
            groomRepliesByPostID = ReplyThreadStateReducer.appendingGroomReply(
                reply,
                to: groomRepliesByPostID,
                postID: postID
            )
            sendingGroomReplyPostID = nil
            return true
        } catch {
            errorMessage = "グルームに返信できませんでした"
            sendingGroomReplyPostID = nil
            return false
        }
    }

    private func loadPublicProfilesForGroomArchive() async {
        let userIDs = Set(
            groomReactionsByPostID.values.flatMap { reactions in
                reactions.map(\.userID)
            } + groomRepliesByPostID.values.flatMap { replies in
                replies.map(\.senderID)
            }
        )
        for userID in userIDs where userID != viewer?.id && publicProfilesByUserID[userID] == nil {
            await loadPublicUserProfile(userID: userID, reportsFailure: false)
        }
    }

    public func loadMeguriMessages() async {
        guard !isLoadingMeguriMessages else {
            return
        }

        isLoadingMeguriMessages = true
        errorMessage = nil
        do {
            meguriMessages = try await repository.loadMeguriMessages()
        } catch {
            errorMessage = "めぐりメッセージを読み込めませんでした"
        }
        isLoadingMeguriMessages = false
    }

    public func sendMeguriMessage(
        recipientID: UUID,
        body: String,
        sourceGroomReplyID: UUID? = nil
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
                    body: trimmed
                )
            )
            meguriMessages = MeguriMessageReadStateReducer.appendingSentMessage(
                message,
                to: meguriMessages
            )
            sendingMeguriMessageRecipientID = nil
            return true
        } catch {
            errorMessage = "めぐりメッセージを送信できませんでした"
            sendingMeguriMessageRecipientID = nil
            return false
        }
    }

    public func markMeguriMessagesRead(peerID: UUID) async {
        guard let viewer else {
            return
        }

        guard MeguriMessageReadStateReducer.hasUnreadIncomingMessages(
            meguriMessages,
            peerID: peerID,
            viewerID: viewer.id
        ) else {
            return
        }

        let readAt = Date()
        let previous = meguriMessages
        meguriMessages = MeguriMessageReadStateReducer.markIncomingMessagesRead(
            meguriMessages,
            peerID: peerID,
            viewerID: viewer.id,
            readAt: readAt
        )

        do {
            let updated = try await repository.markMeguriMessagesRead(peerID: peerID, readAt: readAt)
            meguriMessages = MeguriMessageReadStateReducer.mergingUpdated(
                meguriMessages,
                updated: updated
            )
        } catch {
            meguriMessages = previous
            errorMessage = "めぐりメッセージを既読にできませんでした"
        }
    }

    public func loadBoardReplies(
        threadID: UUID,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) async {
        guard loadingBoardRepliesThreadID != threadID else {
            return
        }

        let selectedPrefecture = boardPrefecture(explicitPrefecture: prefecture)
        loadingBoardRepliesThreadID = threadID
        errorMessage = nil
        do {
            let replies = try await repository.loadBoardReplies(
                threadID: threadID,
                latitude: latitude,
                longitude: longitude,
                prefecture: selectedPrefecture,
                scope: scope
            )
            boardRepliesByThreadID = ReplyThreadStateReducer.replacingBoardReplies(
                in: boardRepliesByThreadID,
                threadID: threadID,
                replies: replies
            )
        } catch {
            errorMessage = "掲示板の返信を読み込めませんでした"
        }
        loadingBoardRepliesThreadID = nil
    }

    public func sendBoardReply(
        threadID: UUID,
        body: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) async -> Bool {
        let trimmed = MegrumAppStateInputNormalizer.trimmedText(body)
        guard !trimmed.isEmpty else {
            return false
        }
        guard sendingBoardReplyThreadID != threadID else {
            return false
        }

        let selectedPrefecture = boardPrefecture(explicitPrefecture: prefecture)
        sendingBoardReplyThreadID = threadID
        errorMessage = nil
        do {
            let reply = try await repository.sendBoardReply(
                BoardReplyCreateInput(
                    threadID: threadID,
                    body: trimmed,
                    latitude: latitude,
                    longitude: longitude,
                    prefecture: selectedPrefecture,
                    scope: scope
                )
            )
            boardRepliesByThreadID = ReplyThreadStateReducer.appendingBoardReply(
                reply,
                to: boardRepliesByThreadID,
                threadID: threadID
            )
            sendingBoardReplyThreadID = nil
            return true
        } catch {
            errorMessage = "掲示板に返信できませんでした"
            sendingBoardReplyThreadID = nil
            return false
        }
    }

    public func createBoardThread(
        title: String,
        body: String,
        scope: BoardThread.Audience = .nearby3km,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        thumbnailUpload: GoodsPhotoUpload? = nil
    ) async -> Bool {
        await createBoardThreadRecord(
            title: title,
            body: body,
            scope: scope,
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            thumbnailUpload: thumbnailUpload
        ) != nil
    }

    public func createBoardThreadRecord(
        title: String,
        body: String,
        scope: BoardThread.Audience = .nearby3km,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        thumbnailUpload: GoodsPhotoUpload? = nil
    ) async -> BoardThread? {
        guard !isCreatingBoardThread else {
            return nil
        }
        guard let viewer else {
            errorMessage = "プロフィールを読み込んでから投稿してください"
            return nil
        }

        let trimmedTitle = MegrumAppStateInputNormalizer.trimmedText(title)
        let trimmedBody = MegrumAppStateInputNormalizer.trimmedText(body)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "タイトルを入力してください"
            return nil
        }
        guard !trimmedBody.isEmpty else {
            errorMessage = "本文を入力してください"
            return nil
        }

        let normalizedPrefecture = boardPrefecture(explicitPrefecture: prefecture)
        switch scope {
        case .nearby3km:
            guard latitude != nil, longitude != nil else {
                errorMessage = "現在地と都道府県を確認してから投稿してください"
                return nil
            }
        case .samePrefecture:
            guard normalizedPrefecture != nil else {
                errorMessage = "プロフィールの都道府県を設定してください"
                return nil
            }
        case .sameSpot, .global:
            errorMessage = "この公開範囲はまだ作成できません"
            return nil
        }

        isCreatingBoardThread = true
        errorMessage = nil
        do {
            let created = try await repository.createBoardThread(
                BoardThreadCreateInput(
                    authorID: viewer.id,
                    title: trimmedTitle,
                    body: trimmedBody,
                    audience: scope,
                    latitude: latitude,
                    longitude: longitude,
                    prefecture: normalizedPrefecture,
                    thumbnailUpload: thumbnailUpload
                )
            )
            threads = MeguriFeedStateReducer.upsertingBoardThread(created, into: threads)
            isCreatingBoardThread = false
            return created
        } catch {
            errorMessage = "掲示板を作成できませんでした"
            isCreatingBoardThread = false
            return nil
        }
    }
}
