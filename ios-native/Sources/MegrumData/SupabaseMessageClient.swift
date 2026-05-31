import Foundation
import MegrumCore

public enum SupabaseMessageClientError: Error, Equatable, Sendable {
    case invalidPhotoMessageType
    case invalidLocation
}

public enum SupabaseMessageArrivalStatus: String, CaseIterable, Sendable {
    case enroute
    case arrived
    case left

    var defaultBody: String {
        switch self {
        case .enroute:
            "向かっています"
        case .arrived:
            "到着しました"
        case .left:
            "離れました"
        }
    }
}

private extension SupabaseMessageArrivalStatus {
    init(_ status: TradeArrivalStatus) {
        switch status {
        case .enroute:
            self = .enroute
        case .arrived:
            self = .arrived
        case .left:
            self = .left
        }
    }
}

public final class SupabaseMessageClient: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
    }

    public func loadMessages(proposalID: UUID, limit: Int = 80) async throws -> [TradeMessage] {
        let rows: [MessageRow] = try await client.fetchRows(
            from: "messages",
            select: MessageRow.select,
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "\(max(1, min(limit, 120)))")
            ]
        )
        return rows.compactMap(\.message)
    }

    public func sendTextMessage(senderID: UUID, input: TradeMessageCreateInput) async throws -> TradeMessage {
        try await sendMessage(
            senderID: senderID,
            proposalID: input.proposalID,
            messageType: .text,
            body: input.body
        )
    }

    public func sendPhotoMessage(
        senderID: UUID,
        proposalID: UUID,
        photoURL: URL,
        body: String? = nil,
        messageType: TradeMessageType = .photo
    ) async throws -> TradeMessage {
        try validatePhotoMessageType(messageType)
        return try await sendMessage(
            senderID: senderID,
            proposalID: proposalID,
            messageType: messageType,
            body: body,
            photoURL: photoURL
        )
    }

    @available(*, deprecated, message: "Use the latitude/longitude overload so location messages satisfy the DB schema.")
    public func sendLocationMessage(senderID: UUID, proposalID: UUID, body: String) async throws -> TradeMessage {
        throw SupabaseMessageClientError.invalidLocation
    }

    public func sendLocationMessage(
        senderID: UUID,
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String,
        body: String? = nil
    ) async throws -> TradeMessage {
        try validateLocation(latitude: latitude, longitude: longitude)
        let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await sendMessage(
            senderID: senderID,
            proposalID: proposalID,
            messageType: .location,
            body: body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? normalizedLabel.nilIfEmpty,
            locationLatitude: latitude,
            locationLongitude: longitude,
            locationLabel: normalizedLabel.nilIfEmpty
        )
    }

    public func sendSystemMessage(senderID: UUID, proposalID: UUID, body: String) async throws -> TradeMessage {
        try await sendMessage(senderID: senderID, proposalID: proposalID, messageType: .system, body: body)
    }

    public func sendArrivalStatusMessage(senderID: UUID, proposalID: UUID, body: String) async throws -> TradeMessage {
        try await sendArrivalStatusMessage(senderID: senderID, proposalID: proposalID, status: SupabaseMessageArrivalStatus.arrived, body: body)
    }

    public func sendArrivalStatusMessage(
        senderID: UUID,
        proposalID: UUID,
        status: SupabaseMessageArrivalStatus,
        body: String? = nil
    ) async throws -> TradeMessage {
        try await sendMessage(
            senderID: senderID,
            proposalID: proposalID,
            messageType: .arrivalStatus,
            body: body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? status.defaultBody,
            meta: ["status": status.rawValue]
        )
    }

    public func sendArrivalStatusMessage(
        senderID: UUID,
        proposalID: UUID,
        status: TradeArrivalStatus,
        body: String? = nil
    ) async throws -> TradeMessage {
        try await sendArrivalStatusMessage(
            senderID: senderID,
            proposalID: proposalID,
            status: SupabaseMessageArrivalStatus(status),
            body: body
        )
    }

    public func sendMessage(
        senderID: UUID,
        proposalID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationLabel: String? = nil,
        meta: [String: String]? = nil
    ) async throws -> TradeMessage {
        if messageType == .location {
            guard let locationLatitude, let locationLongitude else {
                throw SupabaseMessageClientError.invalidLocation
            }
            try validateLocation(latitude: locationLatitude, longitude: locationLongitude)
        }
        if messageType == .photo || messageType == .outfitPhoto {
            try validatePhotoMessageType(messageType)
        }
        let payload = MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: body,
            photoURL: photoURL,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationLabel: locationLabel,
            meta: meta
        )
        let rows: [MessageRow] = try await client.upsertRows(
            into: "messages",
            values: [payload],
            select: MessageRow.select
        )
        return rows.first?.message ?? TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: payload.body,
            photoURL: photoURL
        )
    }

    public func makeLoadMessagesRequest(proposalID: UUID, limit: Int = 80) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/messages",
            queryItems: [
                URLQueryItem(name: "select", value: MessageRow.select),
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "\(max(1, min(limit, 120)))")
            ]
        )
    }

    public func makeSendTextMessageRequest(senderID: UUID, input: TradeMessageCreateInput) throws -> URLRequest {
        try makeSendMessageRequest(
            senderID: senderID,
            proposalID: input.proposalID,
            messageType: .text,
            body: input.body
        )
    }

    public func makeSendPhotoMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        photoURL: URL,
        body: String? = nil,
        messageType: TradeMessageType = .photo
    ) throws -> URLRequest {
        try validatePhotoMessageType(messageType)
        return try makeSendMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            messageType: messageType,
            body: body,
            photoURL: photoURL
        )
    }

    @available(*, deprecated, message: "Use the latitude/longitude overload so location messages satisfy the DB schema.")
    public func makeSendLocationMessageRequest(senderID: UUID, proposalID: UUID, body: String) throws -> URLRequest {
        throw SupabaseMessageClientError.invalidLocation
    }

    public func makeSendLocationMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String,
        body: String? = nil
    ) throws -> URLRequest {
        try validateLocation(latitude: latitude, longitude: longitude)
        let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return try makeSendMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            messageType: .location,
            body: body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? normalizedLabel.nilIfEmpty,
            locationLatitude: latitude,
            locationLongitude: longitude,
            locationLabel: normalizedLabel.nilIfEmpty
        )
    }

    public func makeSendSystemMessageRequest(senderID: UUID, proposalID: UUID, body: String) throws -> URLRequest {
        try makeSendMessageRequest(senderID: senderID, proposalID: proposalID, messageType: .system, body: body)
    }

    public func makeSendArrivalStatusMessageRequest(senderID: UUID, proposalID: UUID, body: String) throws -> URLRequest {
        try makeSendArrivalStatusMessageRequest(senderID: senderID, proposalID: proposalID, status: SupabaseMessageArrivalStatus.arrived, body: body)
    }

    public func makeSendArrivalStatusMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        status: SupabaseMessageArrivalStatus,
        body: String? = nil
    ) throws -> URLRequest {
        try makeSendMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            messageType: .arrivalStatus,
            body: body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? status.defaultBody,
            meta: ["status": status.rawValue]
        )
    }

    public func makeSendArrivalStatusMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        status: TradeArrivalStatus,
        body: String? = nil
    ) throws -> URLRequest {
        try makeSendArrivalStatusMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            status: SupabaseMessageArrivalStatus(status),
            body: body
        )
    }

    public func makeSendMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationLabel: String? = nil,
        meta: [String: String]? = nil
    ) throws -> URLRequest {
        if messageType == .location {
            guard let locationLatitude, let locationLongitude else {
                throw SupabaseMessageClientError.invalidLocation
            }
            try validateLocation(latitude: locationLatitude, longitude: locationLongitude)
        }
        if messageType == .photo || messageType == .outfitPhoto {
            try validatePhotoMessageType(messageType)
        }
        let payload = MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: body,
            photoURL: photoURL,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationLabel: locationLabel,
            meta: meta
        )
        return try client.makeMutationRequest(
            path: "/rest/v1/messages",
            queryItems: [
                URLQueryItem(name: "select", value: MessageRow.select)
            ],
            method: "POST",
            body: encoder.encode([payload]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private func validatePhotoMessageType(_ messageType: TradeMessageType) throws {
        guard messageType == .photo || messageType == .outfitPhoto else {
            throw SupabaseMessageClientError.invalidPhotoMessageType
        }
    }

    private func validateLocation(latitude: Double, longitude: Double) throws {
        guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw SupabaseMessageClientError.invalidLocation
        }
    }
}

private struct MessageRow: Decodable, Sendable {
    static let select = "id,proposal_id,sender_id,message_type,body,photo_url,location_lat,location_lng,location_label,meta,created_at"

    var id: UUID
    var proposalId: UUID
    var senderId: UUID
    var messageType: String
    var body: String?
    var photoUrl: URL?
    var locationLat: Double?
    var locationLng: Double?
    var locationLabel: String?
    var meta: [String: String]?
    var createdAt: Date?

    var message: TradeMessage? {
        guard let type = TradeMessageType(rawValue: messageType) else {
            return nil
        }
        let resolvedBody = body ?? fallbackBody(for: type)
        return TradeMessage(
            id: id,
            proposalID: proposalId,
            senderID: senderId,
            messageType: type,
            body: resolvedBody,
            photoURL: photoUrl,
            locationLatitude: locationLat,
            locationLongitude: locationLng,
            locationLabel: locationLabel,
            meta: meta ?? [:],
            createdAt: createdAt ?? .now
        )
    }

    private func fallbackBody(for type: TradeMessageType) -> String? {
        switch type {
        case .location:
            locationLabel
        case .arrivalStatus:
            meta?["body"] ?? meta?["label"] ?? meta?["status"].flatMap(SupabaseMessageArrivalStatus.init(rawValue:))?.defaultBody
        case .text, .photo, .outfitPhoto, .system:
            nil
        }
    }
}

private struct MessageCreatePayload: Encodable, Sendable {
    var proposalId: UUID
    var senderId: UUID
    var messageType: String
    var body: String?
    var photoUrl: String?
    var locationLat: Double?
    var locationLng: Double?
    var locationLabel: String?
    var meta: [String: String]?

    init(senderID: UUID, input: TradeMessageCreateInput) {
        self.init(
            proposalID: input.proposalID,
            senderID: senderID,
            messageType: .text,
            body: input.body
        )
    }

    init(
        proposalID: UUID,
        senderID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationLabel: String? = nil,
        meta: [String: String]? = nil
    ) {
        self.proposalId = proposalID
        self.senderId = senderID
        self.messageType = messageType.rawValue
        self.body = body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.photoUrl = photoURL?.absoluteString
        self.locationLat = locationLatitude
        self.locationLng = locationLongitude
        self.locationLabel = locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.meta = meta?.isEmpty == true ? nil : meta
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
