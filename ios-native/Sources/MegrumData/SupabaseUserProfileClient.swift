import Foundation
import MegrumCore

public final class SupabaseUserProfileClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadProfile(userID: UUID) async throws -> PublicUserProfile? {
        let rows: [PublicUserProfileRow] = try await client.rpcRows(
            function: "get_public_user_profile_for_viewer",
            payload: PublicUserProfilePayload(userID: userID)
        )
        return rows.first?.profile
    }

    public func loadEvaluations(userID: UUID, limit: Int = 50) async throws -> [UserEvaluation] {
        let rows: [UserEvaluationRow] = try await client.rpcRows(
            function: "list_user_evaluations_for_profile",
            payload: UserEvaluationListPayload(userID: userID, limit: limit)
        )
        return rows.map(\.evaluation)
    }

    public func makeLoadProfileRequest(userID: UUID) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "get_public_user_profile_for_viewer",
            payload: PublicUserProfilePayload(userID: userID)
        )
    }

    public func makeLoadEvaluationsRequest(userID: UUID, limit: Int = 50) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_user_evaluations_for_profile",
            payload: UserEvaluationListPayload(userID: userID, limit: limit)
        )
    }
}

private struct PublicUserProfilePayload: Encodable, Sendable {
    var pUserId: UUID

    init(userID: UUID) {
        self.pUserId = userID
    }
}

private struct UserEvaluationListPayload: Encodable, Sendable {
    var pUserId: UUID
    var pLimit: Int

    init(userID: UUID, limit: Int) {
        self.pUserId = userID
        self.pLimit = max(1, min(limit, 100))
    }
}

private struct PublicUserProfileRow: Decodable, Sendable {
    var id: UUID
    var handle: String?
    var displayName: String?
    var bio: String?
    var avatarUrl: URL?
    var primaryArea: String?
    var gender: UserGender?
    var age: Int?
    var accountStatus: String?
    var averageStars: Double?
    var evaluationCount: Int?
    var completedTradeCount: Int?

    var profile: PublicUserProfile {
        PublicUserProfile(
            profile: UserProfile(
                id: id,
                handle: handle ?? "unknown",
                displayName: displayName ?? handle ?? "Megrum",
                bio: bio,
                avatarURL: avatarUrl,
                gender: gender,
                prefecture: primaryArea,
                age: age,
                accountStatus: AccountStatus(rawValue: accountStatus ?? "") ?? .active
            ),
            averageStars: averageStars,
            evaluationCount: evaluationCount ?? 0,
            completedTradeCount: completedTradeCount ?? 0
        )
    }
}

private struct UserEvaluationRow: Decodable, Sendable {
    var id: UUID
    var raterId: UUID
    var raterHandle: String?
    var raterDisplayName: String?
    var raterAvatarUrl: URL?
    var stars: Int
    var comment: String?
    var createdAt: Date?

    var evaluation: UserEvaluation {
        UserEvaluation(
            id: id,
            raterID: raterId,
            raterHandle: raterHandle ?? "unknown",
            raterDisplayName: raterDisplayName ?? raterHandle ?? "Megrum",
            raterAvatarURL: raterAvatarUrl,
            stars: stars,
            comment: comment,
            createdAt: createdAt ?? .now
        )
    }
}
