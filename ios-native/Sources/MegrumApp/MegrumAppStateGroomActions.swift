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
}
