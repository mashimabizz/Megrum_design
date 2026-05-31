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

    public func insertRows<Payload: Encodable & Sendable, Row: Decodable & Sendable>(
        into table: String,
        values: [Payload],
        select: String = "*"
    ) async throws -> [Row] {
        let request = try makeInsertRequest(into: table, values: values, select: select)
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

    public func rpcValue<Payload: Encodable & Sendable, Value: Decodable & Sendable>(
        function name: String,
        payload: Payload
    ) async throws -> Value {
        let request = try makeRPCRequest(function: name, payload: payload)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseRESTError.unexpectedStatus(httpResponse.statusCode)
        }
        return try decoder.decode(Value.self, from: data)
    }

    public func rpcVoid<Payload: Encodable & Sendable>(
        function name: String,
        payload: Payload
    ) async throws {
        let request = try makeRPCRequest(function: name, payload: payload)
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseRESTError.unexpectedStatus(httpResponse.statusCode)
        }
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

    public func uploadObject(
        bucket: String,
        path: String,
        data: Data,
        contentType: String,
        cacheControl: String = "3600",
        upsert: Bool = false
    ) async throws {
        let request = try makeStorageObjectUploadRequest(
            bucket: bucket,
            path: path,
            data: data,
            contentType: contentType,
            cacheControl: cacheControl,
            upsert: upsert
        )
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseRESTError.unexpectedStatus(httpResponse.statusCode)
        }
    }

    public func createSignedURL(bucket: String, path: String, expiresIn: Int = 3_600) async throws -> URL {
        let request = try makeStorageSignedURLRequest(bucket: bucket, path: path, expiresIn: expiresIn)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRESTError.unexpectedStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseRESTError.unexpectedStatus(httpResponse.statusCode)
        }

        let signed = try decoder.decode(StorageSignedURLResponse.self, from: data).signedURL
        if let absoluteURL = URL(string: signed), absoluteURL.scheme != nil {
            return absoluteURL
        }
        guard let relativeURL = URL(string: signed, relativeTo: configuration.projectURL)?.absoluteURL else {
            throw SupabaseRESTError.invalidURL
        }
        return relativeURL
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

    public func makeInsertRequest<Payload: Encodable & Sendable>(
        into table: String,
        values: [Payload],
        select: String = "*"
    ) throws -> URLRequest {
        try makeMutationRequest(
            path: "/rest/v1/\(table)",
            queryItems: [URLQueryItem(name: "select", value: select)],
            method: "POST",
            body: encoder.encode(values),
            prefer: "return=representation"
        )
    }

    public func makeUpsertRequest<Payload: Encodable & Sendable>(
        into table: String,
        values: [Payload],
        select: String = "*",
        onConflict: String? = nil
    ) throws -> URLRequest {
        try makeMutationRequest(
            path: "/rest/v1/\(table)",
            queryItems: mutationQueryItems(select: select, onConflict: onConflict),
            method: "POST",
            body: encoder.encode(values),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    public func makeDeleteRequest(
        from table: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        try makeMutationRequest(
            path: "/rest/v1/\(table)",
            queryItems: queryItems,
            method: "DELETE",
            body: nil,
            prefer: "return=minimal"
        )
    }

    public func makeStorageObjectUploadRequest(
        bucket: String,
        path: String,
        data: Data,
        contentType: String,
        cacheControl: String = "3600",
        upsert: Bool = false
    ) throws -> URLRequest {
        var request = try makeMutationRequest(
            path: "/storage/v1/object/\(bucket)/\(path)",
            method: "POST",
            body: data
        )
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(cacheControl, forHTTPHeaderField: "cache-control")
        if upsert {
            request.setValue("true", forHTTPHeaderField: "x-upsert")
        }
        return request
    }

    public func makeStorageSignedURLRequest(bucket: String, path: String, expiresIn: Int = 3_600) throws -> URLRequest {
        let body = try JSONSerialization.data(withJSONObject: ["expiresIn": expiresIn])
        return try makeMutationRequest(
            path: "/storage/v1/object/sign/\(bucket)/\(path)",
            method: "POST",
            body: body
        )
    }

    public func publicStorageObjectURL(bucket: String, path: String) throws -> URL {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseRESTError.invalidURL
        }
        components.path = normalizedPath("/storage/v1/object/public/\(bucket)/\(path)")
        guard let url = components.url else {
            throw SupabaseRESTError.invalidURL
        }
        return url
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

private struct StorageSignedURLResponse: Decodable, Sendable {
    var signedURL: String

    enum CodingKeys: String, CodingKey {
        case signedURL
    }
}
