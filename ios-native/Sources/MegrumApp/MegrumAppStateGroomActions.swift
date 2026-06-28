import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
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
            let posts = try await repository.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters
            )
            groomMapPosts = posts
            await loadMeguriProfiles(userIDs: Set(posts.map(\.authorID)), reportsFailure: false)
        } catch {
            errorMessage = "グルームマップを読み込めませんでした"
        }
        isLoadingGroomMap = false
    }

    public func loadGroomArchive(limit: Int = MegrumPlusLimits.defaultGroomArchivePageLimit) async {
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
            let effectiveLimit = MegrumPlusAccessPolicy.groomArchiveRequestLimit(
                requestedLimit: limit,
                subscriptionState: subscriptionState
            )
            let archivedGrooms = try await repository.loadOwnGroomArchive(limit: effectiveLimit)
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
        guard let viewerID = viewer?.id else {
            errorMessage = "ログイン状態を確認できません"
            return
        }
        if groomPostForGroomAction(postID)?.authorID == viewerID {
            errorMessage = "自分のグルームにはいいねできません"
            return
        }

        let previousLikedIDs = likedGroomIDs
        let previousGrooms = grooms
        let previousMapPosts = groomMapPosts
        let previousArchive = ownGroomArchive
        let didChange = likedGroomIDs.contains(postID) != isLiked
        likedGroomIDs = GroomInteractionStateReducer.settingLiked(
            postID: postID,
            isLiked: isLiked,
            in: likedGroomIDs
        )
        grooms = GroomPostLocalMutation.settingLiked(
            postID: postID,
            isLiked: isLiked,
            adjustsCount: didChange,
            in: grooms
        )
        groomMapPosts = GroomPostLocalMutation.settingLiked(
            postID: postID,
            isLiked: isLiked,
            adjustsCount: didChange,
            in: groomMapPosts
        )
        ownGroomArchive = GroomPostLocalMutation.settingLiked(
            postID: postID,
            isLiked: isLiked,
            adjustsCount: didChange,
            in: ownGroomArchive
        )
        do {
            try await repository.setGroomLiked(postID: postID, isLiked: isLiked)
        } catch {
            likedGroomIDs = previousLikedIDs
            grooms = previousGrooms
            groomMapPosts = previousMapPosts
            ownGroomArchive = previousArchive
            errorMessage = "グルームのいいねを更新できませんでした"
        }
    }

    public func reportGroom(
        _ groom: GroomPost,
        reason: GroomReportReason = .other,
        note: String? = nil
    ) async -> Bool {
        guard let viewerID = viewer?.id else {
            errorMessage = "ログイン状態を確認できません"
            return false
        }
        guard viewerID != groom.authorID else {
            errorMessage = "自分のグルームは通報できません"
            return false
        }
        guard reportingGroomPostID != groom.id else {
            return false
        }

        reportingGroomPostID = groom.id
        errorMessage = nil
        do {
            _ = try await repository.reportGroom(
                GroomReportCreateInput(
                    groomPostID: groom.id,
                    reportedUserID: groom.authorID,
                    reason: reason,
                    note: note
                )
            )
            reportingGroomPostID = nil
            return true
        } catch {
            errorMessage = "グルームを通報できませんでした"
            reportingGroomPostID = nil
            return false
        }
    }

    public func blockGroomAuthor(_ groom: GroomPost) async -> Bool {
        guard let viewerID = viewer?.id else {
            errorMessage = "ログイン状態を確認できません"
            return false
        }
        guard viewerID != groom.authorID else {
            errorMessage = "自分をブロックできません"
            return false
        }
        guard blockingGroomUserID != groom.authorID else {
            return false
        }

        blockingGroomUserID = groom.authorID
        errorMessage = nil
        do {
            try await repository.blockGroomUser(groom.authorID)
            grooms = GroomPostLocalMutation.removing(authorID: groom.authorID, from: grooms)
            groomMapPosts = GroomPostLocalMutation.removing(authorID: groom.authorID, from: groomMapPosts)
            ownGroomArchive = GroomPostLocalMutation.removing(authorID: groom.authorID, from: ownGroomArchive)
            blockingGroomUserID = nil
            return true
        } catch {
            errorMessage = "ユーザーをブロックできませんでした"
            blockingGroomUserID = nil
            return false
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
            let message = GroomReplyMeguriMessageMapper.sentMessage(from: reply, viewer: viewer)
            meguriMessages = MeguriMessageReadStateReducer.appendingSentMessage(
                message,
                to: meguriMessages
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

    private func groomPostForGroomAction(_ postID: UUID) -> GroomPost? {
        GroomPostLocalMutation.firstPost(
            id: postID,
            in: grooms,
            groomMapPosts,
            ownGroomArchive
        )
    }
}
