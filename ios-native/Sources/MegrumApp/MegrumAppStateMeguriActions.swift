import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    public func loadMeguriFeed(
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km,
        force: Bool = false
    ) async {
        let selectedPrefecture = boardPrefecture(explicitPrefecture: prefecture)
        let allowsExtendedBoardAccess = subscriptionState.hasMeguriBoardExtendedAccess
        let cacheKey = MeguriFeedCacheKey(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: 1_000,
            prefecture: selectedPrefecture,
            scope: scope,
            allowsExtendedBoardAccess: allowsExtendedBoardAccess
        )
        let hasCachedContent = !grooms.isEmpty || !threads.isEmpty
        guard force || meguriFeedCacheKey != cacheKey || !hasCachedContent else {
            return
        }
        guard !isMeguriFeedRequestInFlight else {
            return
        }

        if let latitude, let longitude {
            // 圏内通知が有効な場合だけ、基準位置を最新のめぐり閲覧地点に更新する。
            Task {
                await updatePushNotificationLocationIfNeeded(latitude: latitude, longitude: longitude)
            }
        }

        let shouldShowLoading = !hasCachedContent
        isMeguriFeedRequestInFlight = true
        if shouldShowLoading {
            isLoadingMeguri = true
        }
        errorMessage = nil
        defer {
            isMeguriFeedRequestInFlight = false
            if shouldShowLoading {
                isLoadingMeguri = false
            }
        }
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
                scope: scope,
                allowsExtendedBoardAccess: allowsExtendedBoardAccess
            )
            let nextGrooms = try await loadedGrooms
            let nextThreads = try await loadedThreads
            grooms = nextGrooms
            syncLikedGroomIDs(with: nextGrooms)
            threads = nextThreads
            meguriFeedCacheKey = cacheKey
            await loadMeguriProfiles(
                userIDs: Set(nextGrooms.map(\.authorID) + nextThreads.map(\.authorID)),
                reportsFailure: false
            )
        } catch {
            if !hasCachedContent {
                errorMessage = "めぐりを読み込めませんでした"
            }
        }
    }

    private func boardPrefecture(explicitPrefecture: String?) -> String? {
        MegrumAppStateInputNormalizer.prefecture(explicitPrefecture)
            ?? MegrumAppStateInputNormalizer.prefecture(viewer?.prefecture)
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
            errorMessage = "チャットルームの返信を読み込めませんでした"
        }
        loadingBoardRepliesThreadID = nil
    }

    public func sendBoardReply(
        threadID: UUID,
        body: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km,
        anonymousDisplayName: String? = nil,
        anonymousAvatarID: String? = nil
    ) async -> Bool {
        let trimmed = MegrumAppStateInputNormalizer.trimmedText(body)
        guard !trimmed.isEmpty else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを確認してから送信してください"
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
                    authorID: viewer.id,
                    body: trimmed,
                    latitude: latitude,
                    longitude: longitude,
                    prefecture: selectedPrefecture,
                    scope: scope,
                    anonymousDisplayName: anonymousDisplayName,
                    anonymousAvatarID: anonymousAvatarID
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
            errorMessage = "チャットルームに返信できませんでした"
            sendingBoardReplyThreadID = nil
            return false
        }
    }

    public func sendBoardPhotoReply(
        threadID: UUID,
        imageData: Data,
        imageContentType: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km,
        anonymousDisplayName: String? = nil,
        anonymousAvatarID: String? = nil
    ) async -> Bool {
        guard !imageData.isEmpty else {
            return false
        }
        guard let viewer else {
            errorMessage = "プロフィールを確認してから送信してください"
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
                    authorID: viewer.id,
                    body: "",
                    latitude: latitude,
                    longitude: longitude,
                    prefecture: selectedPrefecture,
                    scope: scope,
                    imageUpload: GoodsPhotoUpload(data: imageData, contentType: imageContentType),
                    anonymousDisplayName: anonymousDisplayName,
                    anonymousAvatarID: anonymousAvatarID
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
            errorMessage = "写真をチャットルームに送信できませんでした"
            sendingBoardReplyThreadID = nil
            return false
        }
    }

    public func setBoardThreadReaction(threadID: UUID, reaction: BoardMessageReaction?) async {
        let previousThreads = threads
        threads = ReplyThreadStateReducer.settingBoardThreadReaction(
            reaction,
            threadID: threadID,
            in: threads
        )
        errorMessage = nil
        do {
            try await repository.setBoardThreadReaction(threadID: threadID, reaction: reaction)
        } catch {
            threads = previousThreads
            errorMessage = "リアクションを更新できませんでした"
        }
    }

    public func setBoardReplyReaction(replyID: UUID, reaction: BoardMessageReaction?) async {
        let previousReplies = boardRepliesByThreadID
        boardRepliesByThreadID = ReplyThreadStateReducer.settingBoardReplyReaction(
            reaction,
            replyID: replyID,
            in: boardRepliesByThreadID
        )
        errorMessage = nil
        do {
            try await repository.setBoardReplyReaction(replyID: replyID, reaction: reaction)
        } catch {
            boardRepliesByThreadID = previousReplies
            errorMessage = "リアクションを更新できませんでした"
        }
    }

    public func reportBoardThread(_ threadID: UUID, reason: String = "user_report") async -> Bool {
        guard reportingBoardThreadID != threadID else {
            return false
        }
        reportingBoardThreadID = threadID
        errorMessage = nil
        defer {
            reportingBoardThreadID = nil
        }
        do {
            try await repository.reportBoardThread(threadID: threadID, reason: reason)
            return true
        } catch {
            errorMessage = "チャットルームを通報できませんでした"
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
        thumbnailUpload: GoodsPhotoUpload? = nil,
        anonymousDisplayName: String? = nil,
        anonymousAvatarID: String? = nil,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        seriesName: String? = nil
    ) async -> Bool {
        await createBoardThreadRecord(
            title: title,
            body: body,
            scope: scope,
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            thumbnailUpload: thumbnailUpload,
            anonymousDisplayName: anonymousDisplayName,
            anonymousAvatarID: anonymousAvatarID,
            groupID: groupID,
            characterID: characterID,
            seriesName: seriesName
        ) != nil
    }

    public func createBoardThreadRecord(
        title: String,
        body: String,
        scope: BoardThread.Audience = .nearby3km,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        thumbnailUpload: GoodsPhotoUpload? = nil,
        anonymousDisplayName: String? = nil,
        anonymousAvatarID: String? = nil,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        seriesName: String? = nil
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
        let creationPrefecture = normalizedPrefecture ?? (scope == .nearby3km ? "未設定" : nil)
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
                    prefecture: creationPrefecture,
                    thumbnailUpload: thumbnailUpload,
                    anonymousDisplayName: MegrumAppStateInputNormalizer.optionalText(anonymousDisplayName),
                    anonymousAvatarID: MegrumAppStateInputNormalizer.optionalText(anonymousAvatarID),
                    groupID: groupID,
                    characterID: characterID,
                    seriesName: MegrumAppStateInputNormalizer.optionalText(seriesName)
                )
            )
            threads = MeguriFeedStateReducer.upsertingBoardThread(created, into: threads)
            isCreatingBoardThread = false
            return created
        } catch {
            errorMessage = "チャットルームを作成できませんでした"
            isCreatingBoardThread = false
            return nil
        }
    }

    /// ホームの「近くのチャットルーム」と一覧用。圏外も一覧に出すため拡張アクセスで取得し、
    /// 開閉はクライアントの MeguriAccessPolicy.canOpenBoard で判定する（無料×圏外はロック表示）。iter1226.421。
    public func loadHomeNearbyBoardThreads(latitude: Double, longitude: Double) async {
        let prefecture = MegrumAppStateInputNormalizer.prefecture(viewer?.prefecture)
        guard let threads = try? await repository.loadBoardThreads(
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: .nearby3km,
            allowsExtendedBoardAccess: true
        ) else {
            return
        }
        let sorted = threads.sorted { $0.latestActivityAt > $1.latestActivityAt }
        // iter1226.423：署名URLは取得のたびに変わるため、実質同じ内容なら公開値を触らない
        //（ホームを開くたびに行が作り直されてサムネイルが更新される問題の防止）。
        if !Self.homeNearbyBoardContentEquals(homeNearbyBoardThreads, sorted) {
            homeNearbyBoardThreads = sorted
        }
        await loadBoardReplyPreviews(threadIDs: Array(sorted.prefix(30).map(\.id)))
    }

    /// 署名つき画像URLなどの揮発値を除いた実内容の比較。
    static func homeNearbyBoardContentEquals(_ lhs: [BoardThread], _ rhs: [BoardThread]) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        return zip(lhs, rhs).allSatisfy { a, b in
            a.id == b.id
                && a.title == b.title
                && a.body == b.body
                && a.seriesName == b.seriesName
                && a.latestActivityAt == b.latestActivityAt
                && a.replyCount == b.replyCount
                && a.status == b.status
                && (a.imagePaths ?? []) == (b.imagePaths ?? [])
        }
    }

    /// 地図に見えているチャットルームの最新メッセージを吹き出し用に読み込む。
    /// 読み込み済みスレッドはスキップし、失敗しても致命扱いにしない。
    public func loadBoardReplyPreviews(threadIDs: [UUID]) async {
        let missing = threadIDs.filter { boardReplyPreviewsByThreadID[$0] == nil }
        guard !missing.isEmpty else {
            return
        }
        guard let previews = try? await repository.loadBoardReplyPreviews(threadIDs: missing) else {
            return
        }
        for threadID in missing {
            let bodies = (previews[threadID] ?? [])
                .map { ChatReplyQuoteFormatter.copyText(of: $0) }
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            boardReplyPreviewsByThreadID[threadID] = bodies
        }
    }
}
