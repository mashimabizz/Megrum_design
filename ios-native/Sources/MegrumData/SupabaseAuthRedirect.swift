import Foundation

public struct SupabaseAuthRedirectPayload: Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresIn: Int?
    public var expiresAt: Date?
    public var tokenType: String

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: Int? = nil,
        expiresAt: Date? = nil,
        tokenType: String = "bearer"
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.expiresAt = expiresAt
        self.tokenType = tokenType
    }
}

public enum SupabaseAuthRedirectParser {
    public static func parse(_ url: URL) -> SupabaseAuthRedirectPayload? {
        let parameters = parameters(from: url)
        guard let accessToken = nonEmptyParameter(parameters["access_token"]) else {
            return nil
        }

        return SupabaseAuthRedirectPayload(
            accessToken: accessToken,
            refreshToken: nonEmptyParameter(parameters["refresh_token"]),
            expiresIn: parameters["expires_in"].flatMap(Int.init),
            expiresAt: parameters["expires_at"].flatMap(Double.init).map(Date.init(timeIntervalSince1970:)),
            tokenType: nonEmptyParameter(parameters["token_type"]) ?? "bearer"
        )
    }

    private static func parameters(from url: URL) -> [String: String] {
        var values: [String: String] = [:]
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            values.merge(queryItems.parameters) { _, new in new }
        }
        if let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment,
           let fragmentItems = URLComponents(string: "?\(fragment)")?.queryItems {
            values.merge(fragmentItems.parameters) { _, new in new }
        }
        return values
    }

    private static func nonEmptyParameter(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return value
    }
}

private extension Array where Element == URLQueryItem {
    var parameters: [String: String] {
        reduce(into: [:]) { result, item in
            result[item.name] = item.value ?? ""
        }
    }
}
