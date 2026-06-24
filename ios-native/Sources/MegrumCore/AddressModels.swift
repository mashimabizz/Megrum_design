import Foundation

public struct MailingAddress: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { userID }
    public var userID: UUID
    public var recipientName: String
    public var postalCode: String
    public var prefecture: String
    public var city: String
    public var line1: String
    public var line2: String?
    public var phoneNumber: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        userID: UUID,
        recipientName: String,
        postalCode: String,
        prefecture: String,
        city: String,
        line1: String,
        line2: String? = nil,
        phoneNumber: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userID = userID
        self.recipientName = recipientName
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.city = city
        self.line1 = line1
        self.line2 = line2
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isReady: Bool {
        [
            recipientName,
            postalCode,
            prefecture,
            city,
            line1
        ].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } && postalCode.count == 7
    }

    public var formattedPostalCode: String {
        guard postalCode.count > 3 else {
            return postalCode.isEmpty ? "" : "〒\(postalCode)"
        }
        let prefix = postalCode.prefix(3)
        let suffix = postalCode.dropFirst(3)
        return "〒\(prefix)-\(suffix)"
    }

    public var summary: String {
        [formattedPostalCode, "\(prefecture)\(city)\(line1)"]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

public struct PostalCodeAddress: Codable, Hashable, Sendable {
    public var postalCode: String
    public var prefecture: String
    public var city: String
    public var town: String

    public init(
        postalCode: String,
        prefecture: String,
        city: String,
        town: String
    ) {
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.city = city
        self.town = town
    }

    public var line1Suggestion: String {
        town
    }
}
