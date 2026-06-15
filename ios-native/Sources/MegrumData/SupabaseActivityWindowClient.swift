import Foundation

public enum SupabaseActivityWindowClientError: Error, Equatable, Sendable {
    case invalidVenue
    case invalidTimeRange
    case invalidRadius
    case invalidCoordinate
    case invalidEventName
    case invalidNote
    case emptyUpdate
    case malformedResponse
}

public enum SupabaseActivityWindowStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case enabled
    case disabled
    case archived

    public var id: String { rawValue }
}

public struct SupabaseActivityWindowCoordinate: Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct SupabaseActivityWindow: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var venue: String
    public var center: SupabaseActivityWindowCoordinate?
    public var radiusMeters: Int
    public var eventName: String?
    public var eventless: Bool
    public var startAt: Date
    public var endAt: Date
    public var note: String?
    public var status: SupabaseActivityWindowStatus
    public var createdAt: Date?
    public var updatedAt: Date?
}

public struct SupabaseActivityWindowCreateInput: Equatable, Sendable {
    public var venue: String
    public var center: SupabaseActivityWindowCoordinate?
    public var radiusMeters: Int
    public var eventName: String?
    public var eventless: Bool
    public var startAt: Date
    public var endAt: Date
    public var note: String?
    public var status: SupabaseActivityWindowStatus

    public init(
        venue: String,
        center: SupabaseActivityWindowCoordinate? = nil,
        radiusMeters: Int = 500,
        eventName: String? = nil,
        eventless: Bool = true,
        startAt: Date,
        endAt: Date,
        note: String? = nil,
        status: SupabaseActivityWindowStatus = .enabled
    ) {
        self.venue = venue
        self.center = center
        self.radiusMeters = radiusMeters
        self.eventName = eventName
        self.eventless = eventless
        self.startAt = startAt
        self.endAt = endAt
        self.note = note
        self.status = status
    }
}

public struct SupabaseActivityWindowUpdateInput: Equatable, Sendable {
    public var venue: String?
    public var center: SupabaseActivityWindowCoordinate?
    public var clearsCenter: Bool
    public var radiusMeters: Int?
    public var eventName: String?
    public var clearsEventName: Bool
    public var eventless: Bool?
    public var startAt: Date?
    public var endAt: Date?
    public var note: String?
    public var clearsNote: Bool
    public var status: SupabaseActivityWindowStatus?

    public init(
        venue: String? = nil,
        center: SupabaseActivityWindowCoordinate? = nil,
        clearsCenter: Bool = false,
        radiusMeters: Int? = nil,
        eventName: String? = nil,
        clearsEventName: Bool = false,
        eventless: Bool? = nil,
        startAt: Date? = nil,
        endAt: Date? = nil,
        note: String? = nil,
        clearsNote: Bool = false,
        status: SupabaseActivityWindowStatus? = nil
    ) {
        self.venue = venue
        self.center = center
        self.clearsCenter = clearsCenter
        self.radiusMeters = radiusMeters
        self.eventName = eventName
        self.clearsEventName = clearsEventName
        self.eventless = eventless
        self.startAt = startAt
        self.endAt = endAt
        self.note = note
        self.clearsNote = clearsNote
        self.status = status
    }
}

public struct SupabaseLocalModeSettings: Equatable, Sendable {
    public var userID: UUID
    public var enabled: Bool
    public var activityWindowID: UUID?
    public var radiusMeters: Int
    public var selectedCarryingIDs: [UUID]
    public var selectedWishIDs: [UUID]
    public var lastLocation: SupabaseActivityWindowCoordinate?
    public var updatedAt: Date?
}

public struct SupabaseLocalModeSettingsUpsertInput: Equatable, Sendable {
    public var enabled: Bool
    public var activityWindowID: UUID?
    public var clearsActivityWindowID: Bool
    public var radiusMeters: Int?
    public var selectedCarryingIDs: [UUID]?
    public var selectedWishIDs: [UUID]?
    public var lastLocation: SupabaseActivityWindowCoordinate?
    public var clearsLastLocation: Bool

    public init(
        enabled: Bool,
        activityWindowID: UUID? = nil,
        clearsActivityWindowID: Bool = false,
        radiusMeters: Int? = nil,
        selectedCarryingIDs: [UUID]? = nil,
        selectedWishIDs: [UUID]? = nil,
        lastLocation: SupabaseActivityWindowCoordinate? = nil,
        clearsLastLocation: Bool = false
    ) {
        self.enabled = enabled
        self.activityWindowID = activityWindowID
        self.clearsActivityWindowID = clearsActivityWindowID
        self.radiusMeters = radiusMeters
        self.selectedCarryingIDs = selectedCarryingIDs
        self.selectedWishIDs = selectedWishIDs
        self.lastLocation = lastLocation
        self.clearsLastLocation = clearsLastLocation
    }
}

public final class SupabaseActivityWindowClient: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder
    private let dateFormatter: ISO8601DateFormatter

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
        self.dateFormatter = Self.makeDateFormatter()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
        self.dateFormatter = Self.makeDateFormatter()
    }

    public func loadActivityWindows(
        userID: UUID,
        status: SupabaseActivityWindowStatus? = nil,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 50
    ) async throws -> [SupabaseActivityWindow] {
        let rows: [ActivityWindowRow] = try await client.fetchRows(
            from: "activity_windows",
            select: ActivityWindowRow.select,
            queryItems: activityWindowQueryItems(
                userID: userID,
                userFilter: "eq",
                status: status,
                from: from,
                to: to,
                limit: limit
            )
        )
        return rows.map(\.activityWindow)
    }

    public func loadVisibleActivityWindows(
        excludingUserID userID: UUID,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 500
    ) async throws -> [SupabaseActivityWindow] {
        let rows: [ActivityWindowRow] = try await client.fetchRows(
            from: "activity_windows",
            select: ActivityWindowRow.select,
            queryItems: activityWindowQueryItems(
                userID: userID,
                userFilter: "neq",
                status: .enabled,
                from: from,
                to: to,
                limit: limit
            )
        )
        return rows.map(\.activityWindow)
    }

    public func createActivityWindow(
        userID: UUID,
        input: SupabaseActivityWindowCreateInput
    ) async throws -> SupabaseActivityWindow {
        try validateCreateInput(input)
        let rows: [ActivityWindowRow] = try await client.insertRows(
            into: "activity_windows",
            values: [ActivityWindowCreatePayload(userID: userID, input: input, dateFormatter: dateFormatter)],
            select: ActivityWindowRow.select
        )
        guard let activityWindow = rows.first?.activityWindow else {
            throw SupabaseActivityWindowClientError.malformedResponse
        }
        return activityWindow
    }

    public func updateActivityWindow(
        userID: UUID,
        activityWindowID: UUID,
        input: SupabaseActivityWindowUpdateInput
    ) async throws -> SupabaseActivityWindow? {
        let payload = try ActivityWindowUpdatePayload(input: input, dateFormatter: dateFormatter)
        let rows: [ActivityWindowRow] = try await client.updateRows(
            in: "activity_windows",
            values: payload,
            select: ActivityWindowRow.select,
            queryItems: ownedActivityWindowQueryItems(userID: userID, activityWindowID: activityWindowID)
        )
        return rows.first?.activityWindow
    }

    @discardableResult
    public func disableOtherEnabledActivityWindows(
        userID: UUID,
        keeping activityWindowID: UUID
    ) async throws -> [SupabaseActivityWindow] {
        let rows: [ActivityWindowRow] = try await client.updateRows(
            in: "activity_windows",
            values: ActivityWindowStatusPayload(status: .disabled),
            select: ActivityWindowRow.select,
            queryItems: otherEnabledActivityWindowQueryItems(userID: userID, keeping: activityWindowID)
        )
        return rows.map(\.activityWindow)
    }

    public func loadLocalModeSettings(userID: UUID) async throws -> SupabaseLocalModeSettings? {
        let rows: [LocalModeSettingsRow] = try await client.fetchRows(
            from: "user_local_mode_settings",
            select: LocalModeSettingsRow.select,
            queryItems: localModeSettingsQueryItems(userID: userID)
        )
        return rows.first?.settings
    }

    public func upsertLocalModeSettings(
        userID: UUID,
        input: SupabaseLocalModeSettingsUpsertInput
    ) async throws -> SupabaseLocalModeSettings {
        let payload = try LocalModeSettingsUpsertPayload(userID: userID, input: input)
        let rows: [LocalModeSettingsRow] = try await client.upsertRows(
            into: "user_local_mode_settings",
            values: [payload],
            select: LocalModeSettingsRow.select,
            onConflict: "user_id"
        )
        guard let settings = rows.first?.settings else {
            throw SupabaseActivityWindowClientError.malformedResponse
        }
        return settings
    }

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

    private func activityWindowQueryItems(
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

    private func ownedActivityWindowQueryItems(userID: UUID, activityWindowID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(activityWindowID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    private func otherEnabledActivityWindowQueryItems(userID: UUID, keeping activityWindowID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.\(SupabaseActivityWindowStatus.enabled.rawValue)"),
            URLQueryItem(name: "id", value: "neq.\(activityWindowID.uuidString.lowercased())")
        ]
    }

    private func localModeSettingsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func validateCreateInput(_ input: SupabaseActivityWindowCreateInput) throws {
        try validateVenue(input.venue)
        guard input.startAt < input.endAt else {
            throw SupabaseActivityWindowClientError.invalidTimeRange
        }
        try validateRadius(input.radiusMeters)
        if let center = input.center {
            try validateCoordinate(center)
        }
        try validateEventName(input.eventName)
        try validateNote(input.note)
    }

    private func validateVenue(_ venue: String) throws {
        let normalized = SupabaseTextNormalizer.trimmed(venue)
        guard !normalized.isEmpty, normalized.count <= 100 else {
            throw SupabaseActivityWindowClientError.invalidVenue
        }
    }

    private func validateRadius(_ radiusMeters: Int) throws {
        guard (50...5_000).contains(radiusMeters) else {
            throw SupabaseActivityWindowClientError.invalidRadius
        }
    }

    private func validateCoordinate(_ coordinate: SupabaseActivityWindowCoordinate) throws {
        guard (-90...90).contains(coordinate.latitude),
              (-180...180).contains(coordinate.longitude)
        else {
            throw SupabaseActivityWindowClientError.invalidCoordinate
        }
    }

    private func validateEventName(_ eventName: String?) throws {
        guard SupabaseTextNormalizer.optional(eventName)?.count ?? 0 <= 100 else {
            throw SupabaseActivityWindowClientError.invalidEventName
        }
    }

    private func validateNote(_ note: String?) throws {
        guard SupabaseTextNormalizer.optional(note)?.count ?? 0 <= 200 else {
            throw SupabaseActivityWindowClientError.invalidNote
        }
    }

    private func boundedLimit(_ limit: Int, upperBound: Int) -> Int {
        max(1, min(limit, upperBound))
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private static func makeDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}

private struct ActivityWindowRow: Decodable, Sendable {
    static let select = "id,user_id,venue,center_lat,center_lng,radius_m,event_name,eventless,start_at,end_at,note,status,created_at,updated_at"

    var id: UUID
    var userId: UUID
    var venue: String
    var centerLat: FlexibleDouble?
    var centerLng: FlexibleDouble?
    var radiusM: Int?
    var eventName: String?
    var eventless: Bool?
    var startAt: Date
    var endAt: Date
    var note: String?
    var status: SupabaseActivityWindowStatus
    var createdAt: Date?
    var updatedAt: Date?

    var activityWindow: SupabaseActivityWindow {
        let center = centerLat.flatMap { lat in
            centerLng.map { lng in
                SupabaseActivityWindowCoordinate(latitude: lat.value, longitude: lng.value)
            }
        }
        return SupabaseActivityWindow(
            id: id,
            userID: userId,
            venue: venue,
            center: center,
            radiusMeters: radiusM ?? 500,
            eventName: eventName,
            eventless: eventless ?? false,
            startAt: startAt,
            endAt: endAt,
            note: note,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct ActivityWindowCreatePayload: Encodable, Sendable {
    var userId: UUID
    var venue: String
    var centerLat: Double?
    var centerLng: Double?
    var radiusM: Int
    var eventName: String?
    var eventless: Bool
    var startAt: String
    var endAt: String
    var note: String?
    var status: String

    init(userID: UUID, input: SupabaseActivityWindowCreateInput, dateFormatter: ISO8601DateFormatter) {
        self.userId = userID
        self.venue = SupabaseTextNormalizer.trimmed(input.venue)
        self.centerLat = input.center?.latitude
        self.centerLng = input.center?.longitude
        self.radiusM = input.radiusMeters
        self.eventName = SupabaseTextNormalizer.optional(input.eventName)
        self.eventless = input.eventless
        self.startAt = dateFormatter.string(from: input.startAt)
        self.endAt = dateFormatter.string(from: input.endAt)
        self.note = SupabaseTextNormalizer.optional(input.note)
        self.status = input.status.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case venue
        case centerLat
        case centerLng
        case radiusM
        case eventName
        case eventless
        case startAt
        case endAt
        case note
        case status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(venue, forKey: .venue)
        try container.encodeIfPresent(centerLat, forKey: .centerLat)
        try container.encodeIfPresent(centerLng, forKey: .centerLng)
        try container.encode(radiusM, forKey: .radiusM)
        if let eventName {
            try container.encode(eventName, forKey: .eventName)
        } else {
            try container.encodeNil(forKey: .eventName)
        }
        try container.encode(eventless, forKey: .eventless)
        try container.encode(startAt, forKey: .startAt)
        try container.encode(endAt, forKey: .endAt)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(status, forKey: .status)
    }
}

private struct ActivityWindowUpdatePayload: Encodable, Sendable {
    private var venue: String?
    private var centerLat: Double??
    private var centerLng: Double??
    private var radiusM: Int?
    private var eventName: String??
    private var eventless: Bool?
    private var startAt: String?
    private var endAt: String?
    private var note: String??
    private var status: String?

    init(input: SupabaseActivityWindowUpdateInput, dateFormatter: ISO8601DateFormatter) throws {
        if let venue = input.venue {
            let normalized = SupabaseTextNormalizer.trimmed(venue)
            guard !normalized.isEmpty, normalized.count <= 100 else {
                throw SupabaseActivityWindowClientError.invalidVenue
            }
            self.venue = normalized
        }
        if let center = input.center {
            guard (-90...90).contains(center.latitude),
                  (-180...180).contains(center.longitude)
            else {
                throw SupabaseActivityWindowClientError.invalidCoordinate
            }
            self.centerLat = .some(.some(center.latitude))
            self.centerLng = .some(.some(center.longitude))
        } else if input.clearsCenter {
            self.centerLat = .some(nil)
            self.centerLng = .some(nil)
        }
        if let radiusMeters = input.radiusMeters {
            guard (50...5_000).contains(radiusMeters) else {
                throw SupabaseActivityWindowClientError.invalidRadius
            }
            self.radiusM = radiusMeters
        }
        if let eventName = input.eventName {
            let normalized = SupabaseTextNormalizer.trimmed(eventName)
            guard normalized.count <= 100 else {
                throw SupabaseActivityWindowClientError.invalidEventName
            }
            self.eventName = .some(normalized.isEmpty ? nil : normalized)
        } else if input.clearsEventName {
            self.eventName = .some(nil)
        }
        self.eventless = input.eventless
        if let startAt = input.startAt {
            self.startAt = dateFormatter.string(from: startAt)
        }
        if let endAt = input.endAt {
            self.endAt = dateFormatter.string(from: endAt)
        }
        if let startAt = input.startAt, let endAt = input.endAt, startAt >= endAt {
            throw SupabaseActivityWindowClientError.invalidTimeRange
        }
        if let note = input.note {
            let normalized = SupabaseTextNormalizer.trimmed(note)
            guard normalized.count <= 200 else {
                throw SupabaseActivityWindowClientError.invalidNote
            }
            self.note = .some(normalized.isEmpty ? nil : normalized)
        } else if input.clearsNote {
            self.note = .some(nil)
        }
        self.status = input.status?.rawValue

        guard venue != nil
            || centerLat != nil
            || centerLng != nil
            || radiusM != nil
            || eventName != nil
            || eventless != nil
            || startAt != nil
            || endAt != nil
            || note != nil
            || status != nil
        else {
            throw SupabaseActivityWindowClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case venue
        case centerLat
        case centerLng
        case radiusM
        case eventName
        case eventless
        case startAt
        case endAt
        case note
        case status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(venue, forKey: .venue)
        if let centerLat {
            switch centerLat {
            case let .some(value):
                try container.encode(value, forKey: .centerLat)
            case .none:
                try container.encodeNil(forKey: .centerLat)
            }
        }
        if let centerLng {
            switch centerLng {
            case let .some(value):
                try container.encode(value, forKey: .centerLng)
            case .none:
                try container.encodeNil(forKey: .centerLng)
            }
        }
        try container.encodeIfPresent(radiusM, forKey: .radiusM)
        if let eventName {
            switch eventName {
            case let .some(value):
                try container.encode(value, forKey: .eventName)
            case .none:
                try container.encodeNil(forKey: .eventName)
            }
        }
        try container.encodeIfPresent(eventless, forKey: .eventless)
        try container.encodeIfPresent(startAt, forKey: .startAt)
        try container.encodeIfPresent(endAt, forKey: .endAt)
        if let note {
            switch note {
            case let .some(value):
                try container.encode(value, forKey: .note)
            case .none:
                try container.encodeNil(forKey: .note)
            }
        }
        try container.encodeIfPresent(status, forKey: .status)
    }
}

private struct ActivityWindowStatusPayload: Encodable, Sendable {
    var status: SupabaseActivityWindowStatus
}

private struct LocalModeSettingsRow: Decodable, Sendable {
    static let select = "user_id,enabled,aw_id,radius_m,selected_carrying_ids,selected_wish_ids,last_lat,last_lng,updated_at"

    var userId: UUID
    var enabled: Bool?
    var awId: UUID?
    var radiusM: Int?
    var selectedCarryingIds: [UUID]?
    var selectedWishIds: [UUID]?
    var lastLat: FlexibleDouble?
    var lastLng: FlexibleDouble?
    var updatedAt: Date?

    var settings: SupabaseLocalModeSettings {
        let lastLocation = lastLat.flatMap { lat in
            lastLng.map { lng in
                SupabaseActivityWindowCoordinate(latitude: lat.value, longitude: lng.value)
            }
        }
        return SupabaseLocalModeSettings(
            userID: userId,
            enabled: enabled ?? false,
            activityWindowID: awId,
            radiusMeters: radiusM ?? 500,
            selectedCarryingIDs: selectedCarryingIds ?? [],
            selectedWishIDs: selectedWishIds ?? [],
            lastLocation: lastLocation,
            updatedAt: updatedAt
        )
    }
}

private struct LocalModeSettingsUpsertPayload: Encodable, Sendable {
    private var userId: UUID
    private var enabled: Bool
    private var awId: UUID??
    private var radiusM: Int?
    private var selectedCarryingIds: [UUID]?
    private var selectedWishIds: [UUID]?
    private var lastLat: Double??
    private var lastLng: Double??

    init(userID: UUID, input: SupabaseLocalModeSettingsUpsertInput) throws {
        self.userId = userID
        self.enabled = input.enabled
        if let activityWindowID = input.activityWindowID {
            self.awId = .some(.some(activityWindowID))
        } else if input.clearsActivityWindowID {
            self.awId = .some(nil)
        }
        if let radiusMeters = input.radiusMeters {
            guard (50...5_000).contains(radiusMeters) else {
                throw SupabaseActivityWindowClientError.invalidRadius
            }
            self.radiusM = radiusMeters
        }
        self.selectedCarryingIds = Self.deduplicated(input.selectedCarryingIDs)
        self.selectedWishIds = Self.deduplicated(input.selectedWishIDs)
        if let lastLocation = input.lastLocation {
            guard (-90...90).contains(lastLocation.latitude),
                  (-180...180).contains(lastLocation.longitude)
            else {
                throw SupabaseActivityWindowClientError.invalidCoordinate
            }
            self.lastLat = .some(.some(lastLocation.latitude))
            self.lastLng = .some(.some(lastLocation.longitude))
        } else if input.clearsLastLocation {
            self.lastLat = .some(nil)
            self.lastLng = .some(nil)
        }
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case enabled
        case awId
        case radiusM
        case selectedCarryingIds
        case selectedWishIds
        case lastLat
        case lastLng
    }

    private static func deduplicated(_ ids: [UUID]?) -> [UUID]? {
        guard let ids else {
            return nil
        }
        var seen = Set<UUID>()
        return ids.filter { seen.insert($0).inserted }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(enabled, forKey: .enabled)
        if let awId {
            switch awId {
            case let .some(value):
                try container.encode(value, forKey: .awId)
            case .none:
                try container.encodeNil(forKey: .awId)
            }
        }
        try container.encodeIfPresent(radiusM, forKey: .radiusM)
        try container.encodeIfPresent(selectedCarryingIds, forKey: .selectedCarryingIds)
        try container.encodeIfPresent(selectedWishIds, forKey: .selectedWishIds)
        if let lastLat {
            switch lastLat {
            case let .some(value):
                try container.encode(value, forKey: .lastLat)
            case .none:
                try container.encodeNil(forKey: .lastLat)
            }
        }
        if let lastLng {
            switch lastLng {
            case let .some(value):
                try container.encode(value, forKey: .lastLng)
            case .none:
                try container.encodeNil(forKey: .lastLng)
            }
        }
    }
}

private struct FlexibleDouble: Decodable, Sendable {
    var value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self.value = value
            return
        }
        let rawValue = try container.decode(String.self)
        guard let value = Double(rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a Double-compatible value"
            )
        }
        self.value = value
    }
}
