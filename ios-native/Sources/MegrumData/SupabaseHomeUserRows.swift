import Foundation

public struct SupabaseHomeUserRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var handle: String?
    public var displayName: String?
    public var primaryArea: String?
    public var avatarUrl: String?
    public var gender: String?
    public var age: Int?
    public var paymentMethods: [String]
    public var paymentNote: String?
    public var paymentBankNames: [String]
    public var isTestAccount: Bool?
    public var averageStars: Double?
    public var evaluationCount: Int?
    public var completedTradeCount: Int?

    enum CodingKeys: CodingKey {
        case id
        case handle
        case displayName
        case primaryArea
        case avatarUrl
        case gender
        case age
        case paymentMethods
        case paymentNote
        case paymentBankNames
        case isTestAccount
        case averageStars
        case evaluationCount
        case completedTradeCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.handle = try container.decodeIfPresent(String.self, forKey: .handle)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.primaryArea = try container.decodeIfPresent(String.self, forKey: .primaryArea)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.age = try container.decodeIfPresent(Int.self, forKey: .age)
        self.paymentMethods = try container.decodeIfPresent([String].self, forKey: .paymentMethods) ?? []
        self.paymentNote = try container.decodeIfPresent(String.self, forKey: .paymentNote)
        self.paymentBankNames = try container.decodeIfPresent([String].self, forKey: .paymentBankNames) ?? []
        self.isTestAccount = try container.decodeIfPresent(Bool.self, forKey: .isTestAccount)
        self.averageStars = try container.decodeIfPresent(Double.self, forKey: .averageStars)
        self.evaluationCount = try container.decodeIfPresent(Int.self, forKey: .evaluationCount)
        self.completedTradeCount = try container.decodeIfPresent(Int.self, forKey: .completedTradeCount)
    }
}

public struct SupabaseHomeNotificationIDRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
}

public struct SupabaseMegrumPlusUserIDRow: Decodable, Equatable, Sendable, Identifiable {
    public var userID: UUID

    public var id: UUID { userID }

    enum CodingKeys: String, CodingKey {
        case userID = "userId"
    }
}

extension SupabaseHomeUserRow {
    static let select = "id,handle,display_name,primary_area,avatar_url,gender,age,payment_methods,payment_note,payment_bank_names,is_test_account"
    static let legacySelect = "id,handle,display_name,primary_area,avatar_url,gender"
}

extension SupabaseHomeNotificationIDRow {
    static let select = "id"
}

struct MegrumPlusUserIDsPayload: Encodable, Sendable {
    var userIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case userIDs = "p_user_ids"
    }

    init(userIDs: [UUID]) {
        self.userIDs = userIDs
    }
}
