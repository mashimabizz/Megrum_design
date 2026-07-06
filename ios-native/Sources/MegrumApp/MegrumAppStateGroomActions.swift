import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    /// サーバーが返した「自分がいいね済みか」を likedGroomIDs へ反映する。
    /// 再起動後もいいね状態が復元されるように、取得した投稿分は上書きする。
    func syncLikedGroomIDs(with posts: [GroomPost]) {
        guard !posts.isEmpty else {
            return
        }
        likedGroomIDs.subtract(Set(posts.map(\.id)))
        likedGroomIDs.formUnion(GroomInteractionStateReducer.likedIDs(from: posts))
    }

    public func loadGroomMapPosts(
        latitude: Double? = nil,
        longitude: Double? = nil,
        radiusMeters: Int = 3_000,
        force: Bool = false
    ) async {
        let cacheKey = MeguriFeedCacheKey(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
        let hasCachedContent = !groomMapPosts.isEmpty
        guard force || groomMapCacheKey != cacheKey || !hasCachedContent else {
            return
        }
        guard !isGroomMapRequestInFlight else {
            return
        }

        let shouldShowLoading = !hasCachedContent
        isGroomMapRequestInFlight = true
        if shouldShowLoading {
            isLoadingGroomMap = true
        }
        errorMessage = nil
        defer {
            isGroomMapRequestInFlight = false
            if shouldShowLoading {
                isLoadingGroomMap = false
            }
        }
        do {
            let posts = try await repository.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters
            )
            groomMapPosts = posts
            syncLikedGroomIDs(with: posts)
            groomMapCacheKey = cacheKey
            await loadMeguriProfiles(userIDs: Set(posts.map(\.authorID)), reportsFailure: false)
        } catch {
            if !hasCachedContent {
                errorMessage = "グルームマップを読み込めませんでした"
            }
        }
    }

    /// めぐり地図のビューポート追加読み込み。表示範囲＋αのグルームとスレッドを
    /// 取得し、既存のピンへマージする（置き換えない）。読み込み中も地図操作は
    /// 止めない。失敗しても表示中の内容は変えない。
    public func loadMeguriMapViewport(
        latitude: Double,
        longitude: Double,
        radiusMeters: Int,
        prefecture: String?,
        scope: BoardThread.Audience
    ) async {
        guard !isLoadingMeguriViewport else {
            return
        }
        isLoadingMeguriViewport = true
        defer {
            isLoadingMeguriViewport = false
        }
        async let groomsTask = try? repository.loadGroomMapPosts(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
        async let threadsTask = try? repository.loadBoardThreads(
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope,
            allowsExtendedBoardAccess: subscriptionState.hasMeguriBoardExtendedAccess
        )
        let (loadedGrooms, loadedThreads) = await (groomsTask, threadsTask)

        if let loadedGrooms {
            groomMapPosts = Self.mergingByID(existing: groomMapPosts, incoming: loadedGrooms)
            syncLikedGroomIDs(with: loadedGrooms)
            await loadMeguriProfiles(userIDs: Set(loadedGrooms.map(\.authorID)), reportsFailure: false)
        }
        if let loadedThreads {
            threads = Self.mergingByID(existing: threads, incoming: loadedThreads)
        }
    }

    private static func mergingByID<Item: Identifiable>(existing: [Item], incoming: [Item]) -> [Item] {
        var merged = incoming
        var seen = Set(incoming.map(\.id))
        for item in existing where !seen.contains(item.id) {
            seen.insert(item.id)
            merged.append(item)
        }
        return merged
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
            syncLikedGroomIDs(with: archivedGrooms)
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

    public func loadGroomEngagement(postIDs: [UUID], reportsFailure: Bool = false) async {
        let postIDs = Array(Set(postIDs))
        guard !postIDs.isEmpty else {
            return
        }
        do {
            async let reactions = repository.loadGroomReactions(postIDs: postIDs)
            async let replies = repository.loadGroomReplies(postIDs: postIDs)
            let loadedReactions = try await reactions
            let loadedReplies = try await replies
            for postID in postIDs {
                groomReactionsByPostID[postID] = loadedReactions.filter { $0.groomPostID == postID }
                groomRepliesByPostID[postID] = []
            }
            groomRepliesByPostID = ReplyThreadStateReducer.mergingGroomReplies(
                loadedReplies,
                into: groomRepliesByPostID
            )
            await loadPublicProfilesForGroomArchive()
        } catch {
            if reportsFailure {
                errorMessage = "グルームの反応を読み込めませんでした"
            }
        }
    }

    public func createGroomPost(
        imageData: Data,
        imageContentType: String,
        caption: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        seriesName: String? = nil
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
                    longitude: longitude,
                    groupID: groupID,
                    characterID: characterID,
                    seriesName: seriesName
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

    /// 無料プランで、次の投稿によりアーカイブが10件を超えるか（＝現在すでに上限に達しているか）。
    public func groomArchiveWouldExceedFreeLimit() async -> Bool {
        guard !subscriptionState.hasUnlimitedGroomArchive else {
            return false
        }
        let archived = (try? await repository.loadOwnGroomArchive(
            limit: MegrumPlusLimits.freeGroomArchiveLimit + 1
        )) ?? []
        return archived.count >= MegrumPlusLimits.freeGroomArchiveLimit
    }

    /// 無料プランのアーカイブ上限（10件）を超えた分を、最も古いものから削除する。
    public func trimGroomArchiveToFreeLimitIfNeeded() async {
        guard !subscriptionState.hasUnlimitedGroomArchive else {
            return
        }
        guard let archived = try? await repository.loadOwnGroomArchive(limit: 100) else {
            return
        }
        let overflow = archived.count - MegrumPlusLimits.freeGroomArchiveLimit
        guard overflow > 0 else {
            return
        }
        let oldestFirst = archived.sorted { $0.createdAt < $1.createdAt }
        for groom in oldestFirst.prefix(overflow) {
            _ = await deleteOwnGroom(groom)
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
        guard viewer?.id != nil else {
            errorMessage = "ログイン状態を確認できません"
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
        // 自分のグルームの表示件数は reactions 一覧から数えるため、
        // 押した瞬間に +1/-1 されるようこちらも楽観更新する。
        let previousReactions = groomReactionsByPostID[postID]
        if didChange, let viewerID = viewer?.id {
            var reactions = groomReactionsByPostID[postID] ?? []
            if isLiked {
                if !reactions.contains(where: { $0.userID == viewerID }) {
                    reactions.insert(
                        GroomReaction(
                            groomPostID: postID,
                            userID: viewerID,
                            reactionType: "like",
                            createdAt: .now
                        ),
                        at: 0
                    )
                }
            } else {
                reactions.removeAll { $0.userID == viewerID }
            }
            groomReactionsByPostID[postID] = reactions
        }
        do {
            try await repository.setGroomLiked(postID: postID, isLiked: isLiked)
        } catch {
            likedGroomIDs = previousLikedIDs
            grooms = previousGrooms
            groomMapPosts = previousMapPosts
            ownGroomArchive = previousArchive
            groomReactionsByPostID[postID] = previousReactions
            errorMessage = "グルームのいいねを更新できませんでした"
        }
    }

    public func deleteOwnGroom(_ groom: GroomPost) async -> Bool {
        guard let viewerID = viewer?.id else {
            errorMessage = "ログイン状態を確認できません"
            return false
        }
        guard groom.authorID == viewerID else {
            errorMessage = "自分のグルームだけ削除できます"
            return false
        }
        guard deletingGroomPostID != groom.id else {
            return false
        }

        let previousGrooms = grooms
        let previousMapPosts = groomMapPosts
        let previousArchive = ownGroomArchive
        let previousReactions = groomReactionsByPostID
        let previousReplies = groomRepliesByPostID
        let previousViewedIDs = viewedGroomIDs
        let previousLikedIDs = likedGroomIDs

        deletingGroomPostID = groom.id
        errorMessage = nil
        grooms = GroomPostLocalMutation.removing(postID: groom.id, from: grooms)
        groomMapPosts = GroomPostLocalMutation.removing(postID: groom.id, from: groomMapPosts)
        ownGroomArchive = GroomPostLocalMutation.removing(postID: groom.id, from: ownGroomArchive)
        groomReactionsByPostID[groom.id] = nil
        groomRepliesByPostID[groom.id] = nil
        viewedGroomIDs.remove(groom.id)
        likedGroomIDs.remove(groom.id)

        do {
            try await repository.deleteGroomPost(postID: groom.id)
            deletingGroomPostID = nil
            return true
        } catch {
            grooms = previousGrooms
            groomMapPosts = previousMapPosts
            ownGroomArchive = previousArchive
            groomReactionsByPostID = previousReactions
            groomRepliesByPostID = previousReplies
            viewedGroomIDs = previousViewedIDs
            likedGroomIDs = previousLikedIDs
            deletingGroomPostID = nil
            errorMessage = "グルームを削除できませんでした"
            return false
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
        await loadMeguriProfiles(userIDs: userIDs, reportsFailure: false)
        for userID in userIDs where userID != viewer?.id && publicProfilesByUserID[userID] == nil {
            await loadPublicUserProfile(userID: userID, reportsFailure: false)
        }
    }

}
