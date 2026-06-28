import Foundation

public struct MeguriProfile: Identifiable, Codable, Hashable, Sendable {
    public static let maximumDisplayNameLength = 24

    public var userID: UUID
    public var displayName: String
    public var avatarID: String
    public var lastChangedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public var id: UUID { userID }

    public init(
        userID: UUID,
        displayName: String,
        avatarID: String = "avatar_1",
        lastChangedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.userID = userID
        self.displayName = displayName
        self.avatarID = avatarID
        self.lastChangedAt = lastChangedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func lockedUntil(now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard let lastChangedAt else {
            return nil
        }
        let unlockDate = calendar.date(byAdding: .month, value: 1, to: lastChangedAt)
            ?? lastChangedAt.addingTimeInterval(30 * 24 * 60 * 60)
        return unlockDate > now ? unlockDate : nil
    }
}

public struct MeguriProfileUpdateInput: Equatable, Sendable {
    public var displayName: String
    public var avatarID: String

    public init(displayName: String, avatarID: String) {
        self.displayName = displayName
        self.avatarID = avatarID
    }
}

public enum MeguriProfileValidationError: Error, Equatable, Sendable {
    case invalidDisplayName
    case lockedUntil(Date)
}

public enum MeguriProfileValidation {
    public static func normalizedDisplayName(_ displayName: String) -> String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func validate(
        displayName: String,
        avatarID: String,
        existingProfile: MeguriProfile?,
        now: Date = .now
    ) throws -> MeguriProfileUpdateInput {
        let normalizedName = normalizedDisplayName(displayName)
        guard
            !normalizedName.isEmpty,
            normalizedName.count <= MeguriProfile.maximumDisplayNameLength
        else {
            throw MeguriProfileValidationError.invalidDisplayName
        }

        if let existingProfile,
           let lockedUntil = existingProfile.lockedUntil(now: now),
           (existingProfile.displayName != normalizedName || existingProfile.avatarID != avatarID) {
            throw MeguriProfileValidationError.lockedUntil(lockedUntil)
        }

        return MeguriProfileUpdateInput(displayName: normalizedName, avatarID: avatarID)
    }
}
