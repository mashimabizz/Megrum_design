import Foundation
import MegrumCore

struct UserRow: Decodable, Sendable {
    static let select = "id,handle,display_name,avatar_url,gender,primary_area,age,payment_methods,payment_note,account_status"
    static let legacySelect = "id,handle,display_name,avatar_url,gender,primary_area,account_status"

    var id: UUID
    var handle: String?
    var displayName: String?
    var avatarUrl: URL?
    var gender: UserGender?
    var primaryArea: String?
    var age: Int?
    var paymentMethods: [UserPaymentMethod]?
    var paymentNote: String?
    var accountStatus: String?

    var profile: UserProfile {
        UserProfile(
            id: id,
            handle: handle ?? "unknown",
            displayName: displayName ?? handle ?? "Megrum",
            avatarURL: avatarUrl,
            gender: gender,
            prefecture: primaryArea,
            age: age,
            paymentMethods: paymentMethods ?? [],
            paymentNote: paymentNote,
            accountStatus: AccountStatus(rawValue: accountStatus ?? "") ?? .active
        )
    }
}

struct UserPaymentSummaryUpdatePayload: Encodable, Sendable {
    var paymentMethods: [UserPaymentMethod]
    var paymentNote: String?
}

struct UserProfileUpdatePayload: Encodable, Sendable {
    var displayName: String
    var primaryArea: String?
    var accountStatus: String
}

struct UserOwnProfileUpdatePayload: Encodable, Sendable {
    var handle: String
    var displayName: String
    var avatarUrl: URL?
    var shouldEncodeAvatarUrl: Bool
    var gender: UserGender?
    var primaryArea: String?
    var paymentMethods: [UserPaymentMethod]

    enum CodingKeys: String, CodingKey {
        case handle
        case displayName
        case avatarUrl
        case gender
        case primaryArea
        case paymentMethods
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(handle, forKey: .handle)
        try container.encode(displayName, forKey: .displayName)
        if shouldEncodeAvatarUrl {
            if let avatarUrl {
                try container.encode(avatarUrl, forKey: .avatarUrl)
            } else {
                try container.encodeNil(forKey: .avatarUrl)
            }
        }
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(primaryArea, forKey: .primaryArea)
        try container.encode(paymentMethods, forKey: .paymentMethods)
    }
}
