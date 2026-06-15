import Foundation
import MegrumCore
import MegrumData

struct SupabaseInitialSnapshotLoader: Sendable {
    static let defaultGroomRadiusMeters = 1_000

    private let accountProfilePersistence: SupabaseAccountProfilePersistence
    private let ownedGoodsPersistence: SupabaseOwnedGoodsPersistence
    private let listingClient: SupabaseListingClient
    private let proposalClient: SupabaseProposalClient
    private let groomClient: SupabaseGroomClient
    private let boardClient: SupabaseBoardClient
    private let userID: UUID

    init(
        accountProfilePersistence: SupabaseAccountProfilePersistence,
        ownedGoodsPersistence: SupabaseOwnedGoodsPersistence,
        listingClient: SupabaseListingClient,
        proposalClient: SupabaseProposalClient,
        groomClient: SupabaseGroomClient,
        boardClient: SupabaseBoardClient,
        userID: UUID
    ) {
        self.accountProfilePersistence = accountProfilePersistence
        self.ownedGoodsPersistence = ownedGoodsPersistence
        self.listingClient = listingClient
        self.proposalClient = proposalClient
        self.groomClient = groomClient
        self.boardClient = boardClient
        self.userID = userID
    }

    func loadSnapshot() async throws -> MegrumAppSnapshot {
        let viewer = try await accountProfilePersistence.loadViewer()
        async let inventory = Self.bestEffortInitialSection([]) {
            try await ownedGoodsPersistence.loadTradeGoods()
        }
        async let wishes = Self.bestEffortInitialSection([]) {
            try await ownedGoodsPersistence.loadWishes()
        }
        async let listings = Self.bestEffortInitialSection([]) {
            try await listingClient.loadListings(userID: userID)
        }
        async let proposals = Self.bestEffortInitialSection([]) {
            try await proposalClient.loadProposals(viewerID: userID)
        }
        async let grooms = Self.bestEffortInitialSection([]) {
            try await groomClient.loadNearbyGrooms(
                latitude: nil,
                longitude: nil,
                radiusMeters: Self.defaultGroomRadiusMeters
            )
        }
        async let threads = Self.bestEffortInitialSection([]) {
            try await boardClient.loadThreads(
                latitude: nil,
                longitude: nil,
                prefecture: viewer.prefecture,
                scope: Self.boardScope(for: viewer)
            )
        }

        return MegrumAppSnapshot(
            viewer: viewer,
            inventory: await inventory,
            wishes: await wishes,
            listings: await listings,
            proposals: await proposals,
            grooms: await grooms,
            threads: await threads
        )
    }

    static func boardScope(for viewer: UserProfile) -> BoardThread.Audience {
        viewer.prefecture == nil ? .nearby3km : .samePrefecture
    }

    static func bestEffortInitialSection<Value>(
        _ fallback: Value,
        operation: () async throws -> Value
    ) async -> Value {
        do {
            return try await operation()
        } catch {
            #if DEBUG
            print("Megrum initial section failed: \(error)")
            #endif
            return fallback
        }
    }
}
