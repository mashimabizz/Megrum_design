import Foundation

public final class SupabaseRESTClient: @unchecked Sendable {
    let configuration: SupabaseConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    let encoder: JSONEncoder

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

}
