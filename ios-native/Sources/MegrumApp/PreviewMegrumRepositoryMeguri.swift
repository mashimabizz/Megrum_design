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
            longitude: input.longitude ?? NativePreviewData.grooms.first?.longitude ?? 139.767125
        )
    }

    func markGroomViewed(postID: UUID) async throws {}

    func setGroomLiked(postID: UUID, isLiked: Bool) async throws {}

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

    func loadMeguriMessages() async throws -> [MeguriMessage] {
        NativePreviewData.meguriMessages
    }

    func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        MeguriMessage(
            id: UUID(),
            senderID: input.senderID,
            recipientID: input.recipientID,
            sourceGroomReplyID: input.sourceGroomReplyID,
            body: input.body
        )
    }

    func markMeguriMessagesRead(peerID: UUID, readAt: Date) async throws -> [MeguriMessage] {
        NativePreviewData.meguriMessages.compactMap { message in
            guard message.senderID == peerID, message.recipientID == NativePreviewData.viewerID, message.readAt == nil else {
                return nil
            }
            var next = message
            next.readAt = readAt
            return next
        }
    }

    func loadBoardThreads(latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardThread] {
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
            imagePaths: input.imagePaths
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
}
