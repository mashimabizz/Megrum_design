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
