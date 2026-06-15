import Foundation
import MegrumCore
import MegrumData

struct SupabasePublicProfilePersistence: Sendable {
    private let userProfileClient: SupabaseUserProfileClient
    private let oshiClient: SupabaseOshiClient

    init(
        userProfileClient: SupabaseUserProfileClient,
        oshiClient: SupabaseOshiClient
    ) {
        self.userProfileClient = userProfileClient
        self.oshiClient = oshiClient
    }

    func loadProfile(userID: UUID) async throws -> PublicUserProfile? {
        guard let profile = try await userProfileClient.loadProfile(userID: userID) else {
            return nil
        }
        let selections = (try? await oshiClient.loadUserSelections(userID: userID)) ?? []
        return Self.profile(profile, withOshiSelections: selections)
    }

    func loadEvaluations(userID: UUID, limit: Int) async throws -> [UserEvaluation] {
        try await userProfileClient.loadEvaluations(userID: userID, limit: limit)
    }

    static func profile(
        _ profile: PublicUserProfile,
        withOshiSelections selections: [UserOshiSelection]
    ) -> PublicUserProfile {
        var enrichedProfile = profile
        enrichedProfile.oshiTags = PublicOshiTag.makeTags(from: selections)
        return enrichedProfile
    }
}
