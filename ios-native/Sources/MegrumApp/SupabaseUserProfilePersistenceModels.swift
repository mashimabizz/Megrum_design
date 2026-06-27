import Foundation
import MegrumCore

struct UserRow: Decodable, Sendable {
    static let select = "id,handle,display_name,bio,avatar_url,gender,primary_area,birth_date,age,payment_methods,payment_note,account_status"
    static let paymentSummarySelect = "id,handle,display_name,avatar_url,gender,primary_area,age,payment_methods,payment_note,account_status"
    static let legacySelect = "id,handle,display_name,avatar_url,gender,primary_area,account_status"

    var id: UUID
    var handle: String?
    var displayName: String?
    var bio: String?
    var avatarUrl: URL?
    var gender: UserGender?
    var primaryArea: String?
    var birthDate: String?
    var age: Int?
    var paymentMethods: [UserPaymentMethod]?
    var paymentNote: String?
    var accountStatus: String?

    var profile: UserProfile {
        UserProfile(
            id: id,
            handle: handle ?? "unknown",
            displayName: displayName ?? handle ?? "Megrum",
            bio: bio,
            avatarURL: avatarUrl,
            gender: gender,
            prefecture: primaryArea,
            birthDate: ProfileBirthDateCodec.date(from: birthDate),
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
    var handle: String
    var displayName: String
    var gender: UserGender?
    var primaryArea: String?
    var birthDate: String?
    var age: Int?
    var accountStatus: String
}

struct UserProfileAccountSetupUpsertPayload: Encodable, Sendable {
    var id: UUID
    var handle: String
    var displayName: String
    var gender: UserGender?
    var primaryArea: String?
    var birthDate: String?
    var age: Int?
    var accountStatus: String
}

struct UserProfileAccountSetupLegacyUpsertPayload: Encodable, Sendable {
    var id: UUID
    var handle: String
    var displayName: String
    var gender: UserGender?
    var primaryArea: String?
    var accountStatus: String
}

struct UserOwnProfileUpdatePayload: Encodable, Sendable {
    var handle: String
    var displayName: String
    var bio: String?
    var avatarUrl: URL?
    var shouldEncodeAvatarUrl: Bool
    var gender: UserGender?
    var primaryArea: String?
    var birthDate: String?
    var age: Int?
    var paymentMethods: [UserPaymentMethod]

    enum CodingKeys: String, CodingKey {
        case handle
        case displayName
        case bio
        case avatarUrl
        case gender
        case primaryArea
        case birthDate
        case age
        case paymentMethods
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(handle, forKey: .handle)
        try container.encode(displayName, forKey: .displayName)
        if let bio {
            try container.encode(bio, forKey: .bio)
        } else {
            try container.encodeNil(forKey: .bio)
        }
        if shouldEncodeAvatarUrl {
            if let avatarUrl {
                try container.encode(avatarUrl, forKey: .avatarUrl)
            } else {
                try container.encodeNil(forKey: .avatarUrl)
            }
        }
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(primaryArea, forKey: .primaryArea)
        try container.encodeIfPresent(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encode(paymentMethods, forKey: .paymentMethods)
    }
}

struct UserOwnProfileLegacyUpdatePayload: Encodable, Sendable {
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

struct AccountDeletionRequestPayload: Encodable, Sendable {
    var reasons: [String]
    var note: String?
}

struct AccountDeletionRequestRow: Decodable, Sendable {
    var userId: UUID
    var accountStatus: String
    var deletionRequestedAt: Date?
    var deletionScheduledAt: Date?
}
