import Foundation

public enum SupabaseRESTError: Error, Equatable, Sendable {
    case invalidURL
    case unexpectedStatus(Int)
}

public final class SupabaseRESTClient: @unchecked Sendable {
    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    public func fetchRows<Row: Decodable & Sendable>(
        from table: String,
        select: String = "*",
        queryItems: [URLQueryItem] = []
    ) async throws -> [Row] {
        let request = try makeRequest(
            path: "/rest/v1/\(table)",
            queryItems: [URLQueryItem(name: "select", value: select)] + queryItems
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseRESTError.unexpectedStatus(httpResponse.statusCode)
        }
        return try decoder.decode([Row].self, from: data)
    }

    public func makeRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseRESTError.invalidURL
        }
        components.path = normalizedPath(path)
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SupabaseRESTError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.accessToken ?? configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func normalizedPath(_ path: String) -> String {
        path.hasPrefix("/") ? path : "/\(path)"
    }
}
