import Foundation
import MegrumCore

public extension MegrumRepository {
    func loadHomeLocalModeSettings(now: Date) async throws -> HomeLocalActivitySettings? {
        nil
    }

    func saveHomeLocalModeSettings(_ settings: HomeLocalActivitySettings, now: Date) async throws -> HomeLocalActivitySettings {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        []
    }

    func loadGroomMapPosts(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        try await loadGrooms(latitude: latitude, longitude: longitude, radiusMeters: radiusMeters)
    }

    func loadOwnGroomArchive(limit: Int) async throws -> [GroomPost] {
        []
    }

    func loadGroomReactions(postIDs: [UUID]) async throws -> [GroomReaction] {
        []
    }

    func loadGroomReplies(postIDs: [UUID]) async throws -> [GroomReply] {
        []
    }

    func createGroomPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func deleteGroomPost(postID: UUID) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

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
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadMeguriMessages() async throws -> [MeguriMessage] {
        []
    }

    func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendMeguriPhotoMessage(_ input: MeguriPhotoMessageCreateInput) async throws -> MeguriMessage {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func markMeguriMessagesRead(peerID: UUID, sourceGroomPostID: UUID?, includesAllSources: Bool, readAt: Date) async throws -> [MeguriMessage] {
        []
    }

    func loadBoardThreads(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience,
        allowsExtendedBoardAccess: Bool
    ) async throws -> [BoardThread] {
        []
    }

    func loadBoardReplies(threadID: UUID, latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) async throws -> [BoardReply] {
        []
    }

    func sendBoardReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func setBoardThreadReaction(threadID: UUID, reaction: BoardMessageReaction?) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func setBoardReplyReaction(replyID: UUID, reaction: BoardMessageReaction?) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func reportBoardThread(threadID: UUID, reason: String) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        throw MegrumRepositoryError.unsupportedMutation
    }
}
