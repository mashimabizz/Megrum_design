import Foundation
import MegrumCore

public final class SupabaseEntitlementClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadSubscriptionState(userID: UUID) async throws -> UserSubscriptionState {
        let rows: [UserEntitlementRow] = try await client.fetchRows(
            from: "user_entitlements",
            select: Self.entitlementSelectFields,
            queryItems: entitlementQueryItems(userID: userID)
        )
        return UserSubscriptionState(
            entitlements: rows.compactMap(\.entitlement),
            loadedAt: Date()
        )
    }

    public func makeLoadEntitlementsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/user_entitlements",
            queryItems: [URLQueryItem(name: "select", value: Self.entitlementSelectFields)] + entitlementQueryItems(userID: userID)
        )
    }

    private static let entitlementSelectFields = "feature_key,active,source,granted_at,expires_at,updated_at"

    private func entitlementQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "feature_key", value: "in.(premium,meguri_plus)")
        ]
    }
}

private struct UserEntitlementRow: Decodable, Sendable {
    var featureKey: String
    var active: Bool
    var source: String
    var grantedAt: Date?
    var expiresAt: Date?
    var updatedAt: Date?

    var entitlement: UserEntitlement? {
        guard let key = UserEntitlementKey(rawValue: featureKey) else {
            return nil
        }
        return UserEntitlement(
            key: key,
            isActive: active,
            source: UserEntitlementSource(rawValue: source) ?? .system,
            grantedAt: grantedAt,
            expiresAt: expiresAt,
            updatedAt: updatedAt
        )
    }
}
