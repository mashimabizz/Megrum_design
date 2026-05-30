import Foundation

public enum SupabaseRESTError: Error, Equatable, Sendable {
    case invalidURL
    case unexpectedStatus(Int)
}

public final class SupabaseRESTClient: @unchecked Sendable {
    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
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

    public func upsertRows<Payload: Encodable & Sendable, Row: Decodable & Sendable>(
        into table: String,
        values: [Payload],
        select: String = "*",
        onConflict: String? = nil
    ) async throws -> [Row] {
        let request = try makeMutationRequest(
            path: "/rest/v1/\(table)",
            queryItems: mutationQueryItems(select: select, onConflict: onConflict),
            method: "POST",
            body: encoder.encode(values),
            prefer: "resolution=merge-duplicates,return=representation"
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

    public func updateRows<Payload: Encodable & Sendable, Row: Decodable & Sendable>(
        in table: String,
        values: Payload,
        select: String = "*",
        queryItems: [URLQueryItem]
    ) async throws -> [Row] {
        let request = try makeMutationRequest(
            path: "/rest/v1/\(table)",
            queryItems: [URLQueryItem(name: "select", value: select)] + queryItems,
            method: "PATCH",
            body: encoder.encode(values),
            prefer: "return=representation"
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

    public func rpcRows<Payload: Encodable & Sendable, Row: Decodable & Sendable>(
        function name: String,
        payload: Payload
    ) async throws -> [Row] {
        let request = try makeRPCRequest(function: name, payload: payload)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseRESTError.unexpectedStatus(httpResponse.statusCode)
        }
        return try decoder.decode([Row].self, from: data)
    }

    public func deleteRows(
        from table: String,
        queryItems: [URLQueryItem]
    ) async throws {
        let request = try makeMutationRequest(
            path: "/rest/v1/\(table)",
            queryItems: queryItems,
            method: "DELETE",
            body: nil,
            prefer: "return=minimal"
        )
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseRESTError.unexpectedStatus(httpResponse.statusCode)
        }
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

    public func makeRPCRequest<Payload: Encodable & Sendable>(
        function name: String,
        payload: Payload
    ) throws -> URLRequest {
        try makeMutationRequest(
            path: "/rest/v1/rpc/\(name)",
            method: "POST",
            body: encoder.encode(payload)
        )
    }

    public func makeMutationRequest(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String,
        body: Data?,
        prefer: String? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseRESTError.invalidURL
        }
        components.path = normalizedPath(path)
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SupabaseRESTError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.accessToken ?? configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        return request
    }

    private func normalizedPath(_ path: String) -> String {
        path.hasPrefix("/") ? path : "/\(path)"
    }

    private func mutationQueryItems(select: String, onConflict: String?) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: "select", value: select)]
        if let onConflict {
            queryItems.append(URLQueryItem(name: "on_conflict", value: onConflict))
        }
        return queryItems
    }
}
