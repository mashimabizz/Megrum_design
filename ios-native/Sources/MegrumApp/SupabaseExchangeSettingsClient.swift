import Foundation
import MegrumData

final class SupabaseExchangeSettingsClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    init(client: SupabaseRESTClient) {
        self.client = client
    }

    func loadSettings(userID: UUID) async throws -> HomeDefaultExchangeSettings? {
        let rows: [UserExchangeSettingsRow] = try await client.fetchRows(
            from: "user_exchange_settings",
            select: Self.selectFields,
            queryItems: settingsQueryItems(userID: userID)
        )
        return rows.first?.settings
    }

    func upsertSettings(_ settings: HomeDefaultExchangeSettings, userID: UUID) async throws -> HomeDefaultExchangeSettings {
        let rows: [UserExchangeSettingsRow] = try await client.upsertRows(
            into: "user_exchange_settings",
            values: [UserExchangeSettingsPayload(settings: settings, userID: userID)],
            select: Self.selectFields,
            onConflict: "user_id"
        )
        return rows.first?.settings ?? settings
    }

    private static let selectFields = [
        "user_id",
        "preference",
        "local_prefecture",
        "local_date_keys",
        "local_date_details",
        "mail_shipping_fee",
        "mail_shipping_days",
        "created_at",
        "updated_at"
    ].joined(separator: ",")

    private func settingsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }
}

private struct UserExchangeSettingsPayload: Encodable, Sendable {
    var userId: UUID
    var preference: String
    var localPrefecture: String?
    var localDateKeys: [String]
    var localDateDetails: [String: HomeExchangeLocalDateDetail]
    var mailShippingFee: String
    var mailShippingDays: String

    init(settings: HomeDefaultExchangeSettings, userID: UUID) {
        self.userId = userID
        self.preference = settings.preference.rawValue
        self.localPrefecture = settings.localPrefecture.nilIfBlank
        self.localDateKeys = settings.localDateKeys
        self.localDateDetails = settings.localDateDetails
        self.mailShippingFee = settings.mailShippingFee.rawValue
        self.mailShippingDays = settings.mailShippingDays.rawValue
    }
}

private struct UserExchangeSettingsRow: Decodable, Sendable {
    var userId: UUID
    var preference: String
    var localPrefecture: String?
    var localDateKeys: [String]?
    var localDateDetails: [String: HomeExchangeLocalDateDetail]?
    var mailShippingFee: String?
    var mailShippingDays: String?
    var createdAt: Date?
    var updatedAt: Date?

    var settings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preference: HomeExchangePreference(rawValue: preference) ?? .both,
            localPrefecture: localPrefecture ?? "",
            localDateKeys: localDateKeys ?? [],
            localDateDetails: localDateDetails ?? [:],
            mailShippingFee: IndividualListingShippingFeeDraft(rawValue: mailShippingFee ?? "") ?? .negotiate,
            mailShippingDays: IndividualListingShippingDaysDraft(rawValue: mailShippingDays ?? "") ?? .twoToFourDays
        )
    }
}
