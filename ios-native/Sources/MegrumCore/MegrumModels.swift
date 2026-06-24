import Foundation

public enum ExchangeMethod: String, Codable, Sendable, CaseIterable, Identifiable {
    case hand
    case mail
    case both

    public var id: String { rawValue }

    public init?(exchangeTypeValue: String?) {
        switch exchangeTypeValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "hand", "local", "in_person":
            self = .hand
        case "mail", "postal", "shipping":
            self = .mail
        case "both", "any":
            self = .both
        default:
            return nil
        }
    }

    public var displayName: String {
        switch self {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地交換・郵送OK"
        }
    }
}

public enum ProposalStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case draft
    case sent
    case negotiating
    case agreementOneSide = "agreement_one_side"
    case agreed
    case rejected
    case expired
    case cancelled
    case completed

    public var id: String { rawValue }
}

public enum MatchBucket: String, Codable, Sendable, CaseIterable, Identifiable {
    case matched
    case possible
    case noMatch = "no_match"

    public var id: String { rawValue }
}

public enum AccountStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case registered
    case verified
    case onboarding
    case active
    case suspended
    case deletionRequested = "deletion_requested"
    case deleted

    public var id: String { rawValue }

    public var requiresSetup: Bool {
        switch self {
        case .registered, .verified, .onboarding:
            true
        case .active, .suspended, .deletionRequested, .deleted:
            false
        }
    }
}

public enum UserGender: String, Codable, Sendable, CaseIterable, Identifiable {
    case female
    case male
    case other
    case noAnswer = "no_answer"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .female:
            "女性"
        case .male:
            "男性"
        case .other:
            "その他"
        case .noAnswer:
            "回答しない"
        }
    }
}

public enum UserPaymentMethod: String, Codable, Sendable, CaseIterable, Identifiable {
    case bankTransfer = "bank_transfer"
    case paypay
    case cashExchange = "cash_exchange"
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bankTransfer:
            "銀行振込"
        case .paypay:
            "PayPay"
        case .cashExchange:
            "現金交換"
        case .other:
            "その他"
        }
    }

    public var isHomeConditionTarget: Bool {
        switch self {
        case .bankTransfer, .paypay, .cashExchange:
            true
        case .other:
            false
        }
    }

    public static func normalized(_ methods: [UserPaymentMethod]) -> [UserPaymentMethod] {
        UserPaymentMethod.allCases.filter { method in
            methods.contains(method)
        }
    }

    public static func displayText(
        for methods: [UserPaymentMethod],
        otherNote: String?,
        emptyText: String = "未設定"
    ) -> String {
        let normalizedMethods = normalized(methods)
        guard !normalizedMethods.isEmpty else {
            return emptyText
        }

        let trimmedOtherNote = otherNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let titles = normalizedMethods.map { method in
            if method == .other, !trimmedOtherNote.isEmpty {
                return trimmedOtherNote
            }
            return method.displayName
        }
        return titles.joined(separator: " / ")
    }
}

public struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var handle: String
    public var displayName: String
    public var avatarURL: URL?
    public var gender: UserGender?
    public var prefecture: String?
    public var age: Int?
    public var paymentMethods: [UserPaymentMethod]
    public var paymentNote: String?
    public var accountStatus: AccountStatus

    public init(
        id: UUID,
        handle: String,
        displayName: String,
        avatarURL: URL? = nil,
        gender: UserGender? = nil,
        prefecture: String? = nil,
        age: Int? = nil,
        paymentMethods: [UserPaymentMethod] = [],
        paymentNote: String? = nil,
        accountStatus: AccountStatus = .active
    ) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.gender = gender
        self.prefecture = prefecture
        self.age = age
        self.paymentMethods = paymentMethods
        self.paymentNote = paymentNote
        self.accountStatus = accountStatus
    }

    public var paymentSummaryText: String {
        UserPaymentMethod.displayText(for: paymentMethods, otherNote: paymentNote)
    }

    public var ageText: String? {
        guard let age, age > 0 else {
            return nil
        }
        return "\(age)歳"
    }
}

public struct UserPaymentSettings: Identifiable, Codable, Hashable, Sendable {
    public var userID: UUID
    public var methods: [UserPaymentMethod]
    public var bankName: String
    public var bankBranchName: String
    public var bankAccountType: String
    public var bankAccountNumber: String
    public var bankAccountHolder: String
    public var otherNote: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    public var id: UUID { userID }

    public init(
        userID: UUID,
        methods: [UserPaymentMethod] = [],
        bankName: String = "",
        bankBranchName: String = "",
        bankAccountType: String = "",
        bankAccountNumber: String = "",
        bankAccountHolder: String = "",
        otherNote: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userID = userID
        self.methods = UserPaymentMethod.normalized(methods)
        self.bankName = bankName
        self.bankBranchName = bankBranchName
        self.bankAccountType = bankAccountType
        self.bankAccountNumber = bankAccountNumber
        self.bankAccountHolder = bankAccountHolder
        self.otherNote = otherNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var publicSummaryText: String {
        UserPaymentMethod.displayText(for: methods, otherNote: otherNote)
    }

    public func normalized(for userID: UUID? = nil) -> UserPaymentSettings {
        UserPaymentSettings(
            userID: userID ?? self.userID,
            methods: UserPaymentMethod.normalized(methods),
            bankName: Self.trimmed(bankName),
            bankBranchName: Self.trimmed(bankBranchName),
            bankAccountType: Self.trimmed(bankAccountType),
            bankAccountNumber: Self.trimmed(bankAccountNumber),
            bankAccountHolder: Self.trimmed(bankAccountHolder),
            otherNote: Self.trimmed(otherNote).nilIfBlank,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private static func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

public struct PublicUserProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { profile.id }
    public var profile: UserProfile
    public var averageStars: Double?
    public var evaluationCount: Int
    public var completedTradeCount: Int
    public var oshiTags: [PublicOshiTag]

    public init(
        profile: UserProfile,
        averageStars: Double? = nil,
        evaluationCount: Int = 0,
        completedTradeCount: Int = 0,
        oshiTags: [PublicOshiTag] = []
    ) {
        self.profile = profile
        self.averageStars = averageStars
        self.evaluationCount = evaluationCount
        self.completedTradeCount = completedTradeCount
        self.oshiTags = oshiTags
    }

    public var ratingSummary: String {
        guard let averageStars else {
            return "評価なし"
        }
        return String(format: "★ %.1f", averageStars)
    }
}

public struct PublicOshiTag: Identifiable, Codable, Hashable, Sendable {
    public var title: String
    public var groupID: UUID?
    public var characterID: UUID?
    public var priority: Int

    public var id: String {
        "\(groupID?.uuidString ?? "groupless"):\(characterID?.uuidString ?? title):\(priority)"
    }

    public var colorKey: String {
        groupID?.uuidString ?? title
    }

    public init(title: String, groupID: UUID? = nil, characterID: UUID? = nil, priority: Int = 0) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.groupID = groupID
        self.characterID = characterID
        self.priority = priority
    }

    public static func makeTags(from selections: [UserOshiSelection], limit: Int = 12) -> [PublicOshiTag] {
        var tags: [PublicOshiTag] = []
        var seen: Set<String> = []

        for selection in selections.sorted(by: { $0.priority < $1.priority }) {
            let colorGroupID = selection.groupID
            if let groupTitle = selection.displayGroupTitle {
                appendTag(
                    PublicOshiTag(
                        title: groupTitle,
                        groupID: colorGroupID,
                        priority: selection.priority
                    ),
                    into: &tags,
                    seen: &seen
                )
            }
            if let characterTitle = selection.displayCharacterTitle {
                appendTag(
                    PublicOshiTag(
                        title: characterTitle,
                        groupID: colorGroupID,
                        characterID: selection.characterID,
                        priority: selection.priority
                    ),
                    into: &tags,
                    seen: &seen
                )
            }
            if tags.count >= limit {
                break
            }
        }

        return Array(tags.prefix(max(0, limit)))
    }

    private static func appendTag(_ tag: PublicOshiTag, into tags: inout [PublicOshiTag], seen: inout Set<String>) {
        guard !tag.title.isEmpty else {
            return
        }
        let key = "\(tag.colorKey):\(tag.title)"
        guard seen.insert(key).inserted else {
            return
        }
        tags.append(tag)
    }
}

private extension UserOshiSelection {
    var displayGroupTitle: String? {
        [groupName, oshiRequestName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    var displayCharacterTitle: String? {
        [characterName, characterRequestName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }
}

public struct UserEvaluation: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var raterID: UUID
    public var raterHandle: String
    public var raterDisplayName: String
    public var raterAvatarURL: URL?
    public var stars: Int
    public var comment: String?
    public var createdAt: Date

    public init(
        id: UUID,
        raterID: UUID,
        raterHandle: String,
        raterDisplayName: String,
        raterAvatarURL: URL? = nil,
        stars: Int,
        comment: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.raterID = raterID
        self.raterHandle = raterHandle
        self.raterDisplayName = raterDisplayName
        self.raterAvatarURL = raterAvatarURL
        self.stars = stars
        self.comment = comment
        self.createdAt = createdAt
    }
}

public struct AuthUser: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var email: String?
    public var createdAt: Date?

    public init(id: UUID, email: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}

public struct AuthSession: Codable, Hashable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresIn: Int?
    public var expiresAt: Date?
    public var tokenType: String
    public var user: AuthUser

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: Int? = nil,
        expiresAt: Date? = nil,
        tokenType: String = "bearer",
        user: AuthUser
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.expiresAt = expiresAt
        self.tokenType = tokenType
        self.user = user
    }

    public var authorizationHeaderValue: String {
        "Bearer \(accessToken)"
    }

    public func shouldRefresh(now: Date = .now, leeway: TimeInterval = 300) -> Bool {
        guard refreshToken?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return false
        }
        guard let expiresAt else {
            return true
        }
        return expiresAt.timeIntervalSince(now) <= leeway
    }
}

public struct UserOshiSelection: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var groupID: UUID?
    public var characterID: UUID?
    public var oshiRequestID: UUID?
    public var characterRequestID: UUID?
    public var groupName: String?
    public var characterName: String?
    public var oshiRequestName: String?
    public var characterRequestName: String?
    public var kind: OshiKind
    public var priority: Int

    public init(
        id: UUID,
        userID: UUID,
        groupID: UUID?,
        characterID: UUID?,
        kind: OshiKind,
        priority: Int,
        oshiRequestID: UUID? = nil,
        characterRequestID: UUID? = nil,
        groupName: String? = nil,
        characterName: String? = nil,
        oshiRequestName: String? = nil,
        characterRequestName: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.groupID = groupID
        self.characterID = characterID
        self.oshiRequestID = oshiRequestID
        self.characterRequestID = characterRequestID
        self.groupName = groupName
        self.characterName = characterName
        self.oshiRequestName = oshiRequestName
        self.characterRequestName = characterRequestName
        self.kind = kind
        self.priority = priority
    }
}

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

public struct BlockedUser: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { userID }
    public var userID: UUID
    public var handle: String
    public var displayName: String
    public var avatarURL: URL?
    public var blockedAt: Date?

    public init(
        userID: UUID,
        handle: String,
        displayName: String,
        avatarURL: URL? = nil,
        blockedAt: Date? = nil
    ) {
        self.userID = userID
        self.handle = handle
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.blockedAt = blockedAt
    }
}

public enum MegrumNotificationKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case proposalReceived = "proposal_received"
    case proposalAccepted = "proposal_accepted"
    case proposalRejected = "proposal_rejected"
    case proposalRevised = "proposal_revised"
    case evidenceAdded = "evidence_added"
    case tradeCompleted = "trade_completed"
    case evaluationReceived = "evaluation_received"
    case disputeReceived = "dispute_received"
    case disputeResponded = "dispute_responded"
    case disputeClosed = "dispute_closed"
    case cancelRequested = "cancel_requested"
    case expiresSoon = "expires_soon"
    case groomReply = "groom_reply"
    case meguriMessage = "meguri_message"
    case meguriBoardReply = "meguri_board_reply"
    case meguriBoardMention = "meguri_board_mention"
    case unknown

    public var id: String { rawValue }
}

public struct MegrumNotification: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: MegrumNotificationKind
    public var title: String
    public var body: String?
    public var linkPath: String?
    public var readAt: Date?
    public var createdAt: Date

    public init(
        id: UUID,
        kind: MegrumNotificationKind,
        title: String,
        body: String? = nil,
        linkPath: String? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.linkPath = linkPath
        self.readAt = readAt
        self.createdAt = createdAt
    }

    public var isUnread: Bool {
        readAt == nil
    }
}
