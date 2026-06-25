import Foundation

extension SupabaseActivityWindowClient {
    public func makeLoadActivityWindowsRequest(
        userID: UUID,
        status: SupabaseActivityWindowStatus? = nil,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 50
    ) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + activityWindowQueryItems(
                    userID: userID,
                    userFilter: "eq",
                    status: status,
                    from: from,
                    to: to,
                    limit: limit
                )
        )
    }

    public func makeLoadVisibleActivityWindowsRequest(
        excludingUserID userID: UUID,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 500
    ) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + activityWindowQueryItems(
                    userID: userID,
                    userFilter: "neq",
                    status: .enabled,
                    from: from,
                    to: to,
                    limit: limit
                )
        )
    }

    public func makeCreateActivityWindowRequest(
        userID: UUID,
        input: SupabaseActivityWindowCreateInput
    ) throws -> URLRequest {
        try validateCreateInput(input)
        return try client.makeInsertRequest(
            into: "activity_windows",
            values: [ActivityWindowCreatePayload(userID: userID, input: input, dateFormatter: dateFormatter)],
            select: ActivityWindowRow.select
        )
    }

    public func makeUpdateActivityWindowRequest(
        userID: UUID,
        activityWindowID: UUID,
        input: SupabaseActivityWindowUpdateInput
    ) throws -> URLRequest {
        let payload = try ActivityWindowUpdatePayload(input: input, dateFormatter: dateFormatter)
        return try client.makeMutationRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + ownedActivityWindowQueryItems(userID: userID, activityWindowID: activityWindowID),
            method: "PATCH",
            body: encoder.encode(payload),
            prefer: "return=representation"
        )
    }

    public func makeDisableOtherEnabledActivityWindowsRequest(
        userID: UUID,
        keeping activityWindowID: UUID
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + otherEnabledActivityWindowQueryItems(userID: userID, keeping: activityWindowID),
            method: "PATCH",
            body: encoder.encode(ActivityWindowStatusPayload(status: .disabled)),
            prefer: "return=representation"
        )
    }

    public func makeLoadLocalModeSettingsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/user_local_mode_settings",
            queryItems: [URLQueryItem(name: "select", value: LocalModeSettingsRow.select)]
                + localModeSettingsQueryItems(userID: userID)
        )
    }

    public func makeUpsertLocalModeSettingsRequest(
        userID: UUID,
        input: SupabaseLocalModeSettingsUpsertInput
    ) throws -> URLRequest {
        let payload = try LocalModeSettingsUpsertPayload(userID: userID, input: input)
        return try client.makeUpsertRequest(
            into: "user_local_mode_settings",
            values: [payload],
            select: LocalModeSettingsRow.select,
            onConflict: "user_id"
        )
    }

    func activityWindowQueryItems(
        userID: UUID,
        userFilter: String,
        status: SupabaseActivityWindowStatus?,
        from: Date?,
        to: Date?,
        limit: Int
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "user_id", value: "\(userFilter).\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "start_at.asc"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit, upperBound: 500))")
        ]
        if let status {
            queryItems.append(URLQueryItem(name: "status", value: "eq.\(status.rawValue)"))
        }
        if let from {
            queryItems.append(URLQueryItem(name: "end_at", value: "gt.\(dateFormatter.string(from: from))"))
        }
        if let to {
            queryItems.append(URLQueryItem(name: "start_at", value: "lt.\(dateFormatter.string(from: to))"))
        }
        return queryItems
    }

    func ownedActivityWindowQueryItems(userID: UUID, activityWindowID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(activityWindowID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    func otherEnabledActivityWindowQueryItems(userID: UUID, keeping activityWindowID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.\(SupabaseActivityWindowStatus.enabled.rawValue)"),
            URLQueryItem(name: "id", value: "neq.\(activityWindowID.uuidString.lowercased())")
        ]
    }

    func localModeSettingsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }
}
