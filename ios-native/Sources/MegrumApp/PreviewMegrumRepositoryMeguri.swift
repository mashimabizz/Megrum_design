import Foundation
import MegrumCore

public extension PreviewMegrumRepository {
    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        NativePreviewData.grooms
    }

    func loadOwnGroomArchive(limit: Int) async throws -> [GroomPost] {
        Array(
            NativePreviewData.grooms
                .filter { $0.authorID == NativePreviewData.viewerID }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(max(1, limit))
        )
    }

    func loadGroomReactions(postIDs: [UUID]) async throws -> [GroomReaction] {
        postIDs.flatMap { NativePreviewData.groomReactions[$0] ?? [] }
    }

    func loadGroomReplies(postIDs: [UUID]) async throws -> [GroomReply] {
        postIDs.flatMap { NativePreviewData.groomReplies[$0] ?? [] }
    }

    func createGroomPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        GroomPost(
            id: UUID(),
            authorID: NativePreviewData.viewerID,
            imageURL: URL(string: "https://example.com/native-groom-preview.jpg")!,
            latitude: input.latitude ?? NativePreviewData.grooms.first?.latitude ?? 35.681236,
            longitude: input.longitude ?? NativePreviewData.grooms.first?.longitude ?? 139.767125,
            groupID: input.groupID,
            characterID: input.characterID,
            seriesName: input.seriesName
        )
    }

    func deleteGroomPost(postID: UUID) async throws {}

    func markGroomViewed(postID: UUID) async throws {}

    func setGroomLiked(postID: UUID, isLiked: Bool) async throws {}

    func reportGroom(_ input: GroomReportCreateInput) async throws -> GroomReportTicket {
        GroomReportTicket(
            id: UUID(),
            groomPostID: input.groomPostID,
            reportedUserID: input.reportedUserID,
            reason: input.reason
        )
    }

    func blockGroomUser(_ userID: UUID) async throws {}

    func sendGroomReply(_ input: GroomReplyCreateInput) async throws -> GroomReply {
        GroomReply(
            id: UUID(),
            groomPostID: input.groomPostID,
            senderID: input.senderID,
            recipientID: input.recipientID,
            body: input.body,
            groomImageURL: input.groomImageURL
        )
    }

    func loadMeguriProfile(userID: UUID) async throws -> MeguriProfile? {
        previewMeguriProfile(userID: userID)
    }

    func loadMeguriProfiles(userIDs: Set<UUID>) async throws -> [MeguriProfile] {
        userIDs.compactMap(previewMeguriProfile(userID:))
    }

    func saveMeguriProfile(_ input: MeguriProfileUpdateInput) async throws -> MeguriProfile {
        MeguriProfile(
            userID: NativePreviewData.viewerID,
            displayName: input.displayName,
            avatarID: input.avatarID,
            avatarURL: previewMeguriAvatarURL(from: input),
            usesPublicProfile: input.usesPublicProfile,
            lastChangedAt: .now
        )
    }

    func loadMeguriMessages() async throws -> [MeguriMessage] {
        NativePreviewData.meguriMessages
    }

    func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        MeguriMessage(
            id: UUID(),
            senderID: input.senderID,
            recipientID: input.recipientID,
            sourceGroomReplyID: input.sourceGroomReplyID,
            sourceGroomPostID: input.sourceGroomPostID,
            sourceGroomOwnerID: input.sourceGroomOwnerID,
            sourceGroomImageURL: input.sourceGroomImageURL,
            body: input.body
        )
    }

    func sendMeguriPhotoMessage(_ input: MeguriPhotoMessageCreateInput) async throws -> MeguriMessage {
        let photoURL = try await PreviewMeguriMessageMediaStore.shared.storePhoto(input)
        return MeguriMessage(
            id: UUID(),
            senderID: input.senderID,
            recipientID: input.recipientID,
            sourceGroomReplyID: input.sourceGroomReplyID,
            sourceGroomPostID: input.sourceGroomPostID,
            sourceGroomOwnerID: input.sourceGroomOwnerID,
            sourceGroomImageURL: input.sourceGroomImageURL,
            messageType: .image,
            body: input.body,
            imageURL: photoURL,
            imagePath: photoURL.lastPathComponent
        )
    }

    func markMeguriMessagesRead(peerID: UUID, sourceGroomPostID: UUID?, includesAllSources: Bool, readAt: Date) async throws -> [MeguriMessage] {
        NativePreviewData.meguriMessages.compactMap { message in
            guard
                message.senderID == peerID,
                message.recipientID == NativePreviewData.viewerID,
                includesAllSources || message.sourceGroomPostID == sourceGroomPostID,
                message.readAt == nil
            else {
                return nil
            }
            var next = message
            next.readAt = readAt
            return next
        }
    }

    func loadBoardThreads(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience,
        allowsExtendedBoardAccess: Bool
    ) async throws -> [BoardThread] {
        NativePreviewData.threads.filter { thread in
            switch scope {
            case .nearby3km:
                return thread.audience == .nearby3km
            case .samePrefecture:
                return thread.audience == .samePrefecture && (thread.prefecture == prefecture || prefecture == nil)
            case .sameSpot, .global:
                return thread.audience == scope
            }
        }
    }

    func loadBoardReplies(threadID: UUID, latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardReply] {
        NativePreviewData.boardReplies[threadID] ?? []
    }

    func sendBoardReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        BoardReply(
            id: UUID(),
            threadID: input.threadID,
            authorID: NativePreviewData.viewerID,
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func setBoardThreadReaction(threadID: UUID, reaction: BoardMessageReaction?) async throws {}

    func setBoardReplyReaction(replyID: UUID, reaction: BoardMessageReaction?) async throws {}

    func reportBoardThread(threadID: UUID, reason: String) async throws {}

    func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        let imageURLs = previewBoardThreadImageURLs(from: input)
        return BoardThread(
            id: UUID(),
            authorID: NativePreviewData.viewerID,
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines),
            audience: input.audience,
            latitude: input.latitude,
            longitude: input.longitude,
            prefecture: input.prefecture,
            imageURLs: imageURLs,
            imagePaths: input.imagePaths,
            groupID: input.groupID,
            characterID: input.characterID,
            seriesName: input.seriesName,
            anonymousDisplayName: input.anonymousDisplayName,
            anonymousAvatarID: input.anonymousAvatarID
        )
    }

    private func previewBoardThreadImageURLs(from input: BoardThreadCreateInput) -> [URL] {
        var urls = input.imagePaths.compactMap(URL.init(string:))
        if let thumbnailURL = previewBoardThreadThumbnailURL(from: input.thumbnailUpload) {
            urls.insert(thumbnailURL, at: 0)
        }
        return urls
    }

    private func previewBoardThreadThumbnailURL(from upload: GoodsPhotoUpload?) -> URL? {
        guard let upload else {
            return nil
        }
        let fileExtension = upload.contentType.lowercased().contains("png") ? "png" : "jpg"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("megrum-board-thumbnail-\(UUID().uuidString).\(fileExtension)")
        do {
            try upload.data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func previewMeguriProfile(userID: UUID) -> MeguriProfile? {
        if userID == NativePreviewData.viewerID {
            return MeguriProfile(
                userID: userID,
                displayName: "みちめぐり",
                avatarID: "avatar_1",
                avatarURL: nil,
                usesPublicProfile: false,
                lastChangedAt: Date(timeIntervalSince1970: 1_766_000_000)
            )
        }
        if userID == NativePreviewData.partnerID {
            return MeguriProfile(
                userID: userID,
                displayName: "まくはり民",
                avatarID: "avatar_3",
                avatarURL: nil,
                usesPublicProfile: true,
                lastChangedAt: Date(timeIntervalSince1970: 1_766_100_000)
            )
        }
        return MeguriProfile(
            userID: userID,
            displayName: "めぐりさん",
            avatarID: "avatar_2",
            avatarURL: nil,
            usesPublicProfile: false,
            lastChangedAt: Date(timeIntervalSince1970: 1_766_200_000)
        )
    }

    private func previewMeguriAvatarURL(from input: MeguriProfileUpdateInput) -> URL? {
        if let upload = input.avatarUpload {
            let fileExtension = upload.contentType.lowercased().contains("png") ? "png" : "jpg"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("megrum-meguri-profile-avatar-\(UUID().uuidString).\(fileExtension)")
            do {
                try upload.data.write(to: url, options: .atomic)
                return url
            } catch {
                return input.avatarURL
            }
        }
        if input.clearsAvatarURL {
            return nil
        }
        return input.avatarURL
    }
}
