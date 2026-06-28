import Foundation
import MegrumCore

extension SupabaseGroomClient {
    public func makeLoadNearbyGroomsRequest(
        latitude: Double?,
        longitude: Double?,
        radiusMeters: Int = 1_000
    ) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_groom_feed_nearby",
            payload: GroomFeedPayload(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                maxRadiusMeters: Self.maxFeedRadiusMeters,
                minRadiusMeters: Self.minRadiusMeters
            )
        )
    }

    public func makeLoadGroomMapPostsRequest(
        latitude: Double?,
        longitude: Double?,
        radiusMeters: Int = 3_000
    ) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_groom_feed_nearby",
            payload: GroomFeedPayload(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                maxRadiusMeters: Self.maxMapRadiusMeters,
                minRadiusMeters: Self.minRadiusMeters
            )
        )
    }

    public func makeLoadOwnGroomArchiveRequest(userID: UUID, limit: Int = 120) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_posts",
            queryItems: [URLQueryItem(name: "select", value: GroomFeedRow.select)]
                + ownGroomArchiveQueryItems(userID: userID, limit: limit)
        )
    }

    public func makeLoadReactionsRequest(postIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_reactions",
            queryItems: [URLQueryItem(name: "select", value: GroomReactionRow.select)]
                + engagementQueryItems(postIDs: postIDs, order: "created_at.desc") + [
                    URLQueryItem(name: "reaction_type", value: "eq.like")
                ]
        )
    }

    public func makeLoadRepliesRequest(postIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_replies",
            queryItems: [URLQueryItem(name: "select", value: GroomReplyRow.select)]
                + engagementQueryItems(postIDs: postIDs, order: "created_at.desc")
        )
    }

    public func makeCreatePostRequest(_ input: GroomPostCreateInput, imagePath: String) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "groom_posts",
            values: [GroomPostInsertPayload(input: input, imagePath: imagePath)],
            select: GroomFeedRow.select
        )
    }

    public func makeMarkViewedRequest(userID: UUID, postID: UUID) throws -> URLRequest {
        try client.makeUpsertRequest(
            into: "groom_views",
            values: [GroomViewPayload(groomPostID: postID, userID: userID)],
            onConflict: "groom_post_id,user_id"
        )
    }

    public func makeSetLikedRequest(userID _: UUID, postID: UUID, isLiked: Bool) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "set_groom_like_for_viewer",
            payload: GroomLikeTogglePayload(pPostID: postID, pIsLiked: isLiked)
        )
    }

    public func makeReportPostRequest(reporterID: UUID, input: GroomReportCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "groom_reports",
            values: [GroomReportPayload(reporterID: reporterID, input: input)],
            select: GroomReportRow.select
        )
    }

    public func makeBlockUserRequest(blockerID: UUID, blockedID: UUID) throws -> URLRequest {
        try client.makeUpsertRequest(
            into: "groom_user_blocks",
            values: [GroomBlockPayload(blockedID: blockedID, blockerID: blockerID)],
            select: "blocked_id",
            onConflict: "blocker_id,blocked_id"
        )
    }

    public func makeSendReplyRequest(_ input: GroomReplyCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "groom_replies",
            values: [GroomReplyPayload(input: input)],
            select: GroomReplyRow.select
        )
    }

    public func makeGroomReplyMeguriMessageRequest(reply: GroomReply) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "meguri_messages",
            values: [GroomReplyMeguriMessagePayload(reply: reply)],
            select: "id"
        )
    }
}
