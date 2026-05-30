import Foundation
import MegrumCore

public final class SupabaseAccountClient: @unchecked Sendable {
    private let configuration: SupabaseConfiguration
    private let session: URLSession

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func ensureUserProfile(
        session: AuthSession,
        handle: String?,
        displayName: String?
    ) async throws -> UserProfile {
        let payload = makeUserProfileUpsertPayload(session: session, handle: handle, displayName: displayName)
        let client = SupabaseRESTClient(configuration: configuration.withAccessToken(session.accessToken), session: self.session)
        let rows: [SupabaseUserProfileRow] = try await client.upsertRows(
            into: "users",
            values: [payload],
            select: "id,handle,display_name,avatar_url,primary_area",
            onConflict: "id"
        )
        return rows.first?.profile ?? fallbackProfile(session: session, handle: handle, displayName: displayName)
    }

    public func makeEnsureUserProfileRequest(
        session: AuthSession,
        handle: String?,
        displayName: String?
    ) throws -> URLRequest {
        let payload = makeUserProfileUpsertPayload(session: session, handle: handle, displayName: displayName)
        let data = try JSONEncoder.megrumSnakeCase.encode([payload])
        return try SupabaseRESTClient(configuration: configuration.withAccessToken(session.accessToken)).makeMutationRequest(
            path: "/rest/v1/users",
            queryItems: [
                URLQueryItem(name: "select", value: "id,handle,display_name,avatar_url,primary_area"),
                URLQueryItem(name: "on_conflict", value: "id")
            ],
            method: "POST",
            body: data,
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    private func makeUserProfileUpsertPayload(
        session: AuthSession,
        handle: String?,
        displayName: String?
    ) -> UserProfileUpsertPayload {
        UserProfileUpsertPayload(
            id: session.user.id,
            handle: Self.normalizedHandle(handle, fallbackUserID: session.user.id),
            displayName: Self.normalizedDisplayName(displayName, handle: handle, email: session.user.email),
            accountStatus: "onboarding"
        )
    }

    public static func normalizedHandle(_ rawHandle: String?, fallbackUserID: UUID) -> String {
        let raw = rawHandle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingPrefix("@") ?? ""
        let sanitized = raw.map { character in
            if character.isASCIIAlphanumeric || character == "_" {
                return character
            }
            return "_"
        }
        let collapsed = String(sanitized).split(separator: "_", omittingEmptySubsequences: true).joined(separator: "_")
        if collapsed.count >= 3 {
            return String(collapsed.prefix(20))
        }
        let fallback = fallbackUserID.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return "megrum_\(fallback.prefix(12))"
    }

    private static func normalizedDisplayName(_ rawDisplayName: String?, handle: String?, email: String?) -> String {
        let displayName = rawDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        let trimmedHandle = handle?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingPrefix("@")
        if let trimmedHandle, !trimmedHandle.isEmpty {
            return String(trimmedHandle)
        }
        if let emailName = email?.split(separator: "@").first, !emailName.isEmpty {
            return String(emailName)
        }
        return "Megrum"
    }

    private func fallbackProfile(session: AuthSession, handle: String?, displayName: String?) -> UserProfile {
        UserProfile(
            id: session.user.id,
            handle: Self.normalizedHandle(handle, fallbackUserID: session.user.id),
            displayName: Self.normalizedDisplayName(displayName, handle: handle, email: session.user.email)
        )
    }
}

private struct UserProfileUpsertPayload: Encodable, Sendable {
    var id: UUID
    var handle: String
    var displayName: String
    var accountStatus: String
}

private struct SupabaseUserProfileRow: Decodable, Sendable {
    var id: UUID
    var handle: String?
    var displayName: String?
    var avatarUrl: URL?
    var primaryArea: String?

    var profile: UserProfile {
        UserProfile(
            id: id,
            handle: handle ?? "megrum",
            displayName: displayName ?? handle ?? "Megrum",
            avatarURL: avatarUrl,
            prefecture: primaryArea
        )
    }
}

private extension Character {
    var isASCIIAlphanumeric: Bool {
        unicodeScalars.allSatisfy { scalar in
            (65...90).contains(scalar.value) ||
                (97...122).contains(scalar.value) ||
                (48...57).contains(scalar.value)
        }
    }
}

private extension String {
    func trimmingPrefix(_ prefix: Character) -> String {
        var value = self
        while value.first == prefix {
            value.removeFirst()
        }
        return value
    }
}

private extension JSONEncoder {
    static var megrumSnakeCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
