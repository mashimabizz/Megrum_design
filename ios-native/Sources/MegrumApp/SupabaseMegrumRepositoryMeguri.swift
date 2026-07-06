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

    func deleteGroomPost(postID: UUID) async throws {
        try await groomClient.deletePost(userID: viewerID, postID: postID)
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
        let uploadedAvatarURL = try await profilePhotoStorage.uploadIfNeeded(input.avatarUpload, userID: viewerID)
        let resolvedInput = MeguriProfileUpdateInput(
            displayName: input.displayName,
            avatarID: input.avatarID,
            avatarURL: uploadedAvatarURL ?? input.avatarURL,
            avatarUpload: nil,
            clearsAvatarURL: input.clearsAvatarURL && uploadedAvatarURL == nil,
            usesPublicProfile: input.usesPublicProfile
        )
        return try await meguriProfileClient.saveProfile(resolvedInput, userID: viewerID)
    }

    func loadMeguriMessages() async throws -> [MeguriMessage] {
        try await meguriMessageClient.loadMessages()
    }

    func sendMeguriMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        try await meguriMessageClient.sendTextMessage(input)
    }

    func sendMeguriPhotoMessage(_ input: MeguriPhotoMessageCreateInput) async throws -> MeguriMessage {
        let upload = try await meguriMessageMediaStorage.uploadPhoto(input)
        return try await meguriMessageClient.sendImageMessage(
            senderID: input.senderID,
            recipientID: input.recipientID,
            sourceGroomReplyID: input.sourceGroomReplyID,
            sourceGroomPostID: input.sourceGroomPostID,
            sourceGroomOwnerID: input.sourceGroomOwnerID,
            sourceGroomImageURL: input.sourceGroomImageURL,
            imagePath: upload.path,
            body: input.body
        )
    }

    func markMeguriMessagesRead(peerID: UUID, sourceGroomPostID: UUID?, includesAllSources: Bool, readAt: Date) async throws -> [MeguriMessage] {
        try await meguriMessageClient.markConversationRead(
            viewerID: viewerID,
            peerID: peerID,
            sourceGroomPostID: sourceGroomPostID,
            includesAllSources: includesAllSources,
            readAt: readAt
        )
    }

    func loadBoardThreads(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience,
        allowsExtendedBoardAccess: Bool
    ) async throws -> [BoardThread] {
        try await boardClient.loadThreads(
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope,
            allowsExtendedBoardAccess: allowsExtendedBoardAccess
        )
    }

    func loadBoardReplyPreviews(threadIDs: [UUID]) async throws -> [UUID: [String]] {
        try await boardClient.loadReplyPreviews(threadIDs: threadIDs)
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

    func setBoardThreadReaction(threadID: UUID, reaction: BoardMessageReaction?) async throws {
        try await boardClient.setThreadReaction(threadID: threadID, reaction: reaction)
    }

    func setBoardReplyReaction(replyID: UUID, reaction: BoardMessageReaction?) async throws {
        try await boardClient.setReplyReaction(replyID: replyID, reaction: reaction)
    }

    func reportBoardThread(threadID: UUID, reason: String) async throws {
        try await boardClient.reportThread(threadID: threadID, reason: reason)
    }

    func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        try await boardClient.createThread(input)
    }
}
