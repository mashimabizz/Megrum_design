import Foundation
import MegrumCore
import MegrumData

public extension SupabaseMegrumRepository {
    func loadGrooms(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        try await groomClient.loadNearbyGrooms(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
    }

    func loadGroomMapPosts(latitude: Double?, longitude: Double?, radiusMeters: Int) async throws -> [GroomPost] {
        try await groomClient.loadGroomMapPosts(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
    }

    func loadOwnGroomArchive(limit: Int) async throws -> [GroomPost] {
        try await groomClient.loadOwnGroomArchive(userID: viewerID, limit: limit)
    }

    func loadGroomReactions(postIDs: [UUID]) async throws -> [GroomReaction] {
        try await groomClient.loadReactions(postIDs: postIDs)
    }

    func loadGroomReplies(postIDs: [UUID]) async throws -> [GroomReply] {
        try await groomClient.loadReplies(postIDs: postIDs)
    }

    func createGroomPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        try await groomClient.createPost(input)
    }

    func markGroomViewed(postID: UUID) async throws {
        try await groomClient.markViewed(userID: viewerID, postID: postID)
    }

    func setGroomLiked(postID: UUID, isLiked: Bool) async throws {
        try await groomClient.setLiked(userID: viewerID, postID: postID, isLiked: isLiked)
    }

    func reportGroom(_ input: GroomReportCreateInput) async throws -> GroomReportTicket {
        try await groomClient.reportPost(reporterID: viewerID, input: input)
    }

    func blockGroomUser(_ userID: UUID) async throws {
        try await groomClient.blockUser(blockerID: viewerID, blockedID: userID)
    }

    func sendGroomReply(_ input: GroomReplyCreateInput) async throws -> GroomReply {
        try await groomClient.sendReply(input)
    }

    func loadMeguriProfile(userID: UUID) async throws -> MeguriProfile? {
        try await meguriProfileClient.loadProfile(userID: userID)
    }

    func loadMeguriProfiles(userIDs: Set<UUID>) async throws -> [MeguriProfile] {
        try await meguriProfileClient.loadProfiles(userIDs: userIDs)
    }

    func saveMeguriProfile(_ input: MeguriProfileUpdateInput) async throws -> MeguriProfile {
        try await meguriProfileClient.saveProfile(input, userID: viewerID)
    }

    func loadMeguriMessages() async throws -> [MeguriMessage] {
        try await meguriMessageClient.loadMessages()
    }

    func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        try await meguriMessageClient.sendTextMessage(input)
    }

    func markMeguriMessagesRead(peerID: UUID, readAt: Date) async throws -> [MeguriMessage] {
        try await meguriMessageClient.markConversationRead(viewerID: viewerID, peerID: peerID, readAt: readAt)
    }

    func loadBoardThreads(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) async throws -> [BoardThread] {
        try await boardClient.loadThreads(
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope
        )
    }

    func loadBoardReplies(
        threadID: UUID,
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) async throws -> [BoardReply] {
        try await boardClient.loadReplies(
            threadID: threadID,
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope
        )
    }

    func sendBoardReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        try await boardClient.appendReply(input)
    }

    func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        try await boardClient.createThread(input)
    }
}
