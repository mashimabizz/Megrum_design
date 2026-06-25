import Foundation

extension SupabaseRESTClient {
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
        applyDefaultHeaders(to: &request)
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
        applyDefaultHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        return request
    }

    func mutationQueryItems(select: String, onConflict: String?) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: "select", value: select)]
        if let onConflict {
            queryItems.append(URLQueryItem(name: "on_conflict", value: onConflict))
        }
        return queryItems
    }

    private func applyDefaultHeaders(to request: inout URLRequest) {
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.accessToken ?? configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private func normalizedPath(_ path: String) -> String {
        path.hasPrefix("/") ? path : "/\(path)"
    }
}
