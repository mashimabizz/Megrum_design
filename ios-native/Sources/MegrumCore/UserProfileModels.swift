import Foundation

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
