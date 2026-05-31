import Foundation
import MegrumCore

public enum SupabaseMessageClientError: Error, Equatable, Sendable {
    case invalidBody
    case invalidPhotoMessageType
    case invalidPhotoURL
    case invalidLocation
    case invalidMetadata
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

public enum SupabaseMessageLateMinutes: Int, CaseIterable, Sendable {
    case ten = 10
    case twenty = 20
    case thirty = 30
    case sixty = 60
    case ninety = 90

    public init(minutes: Int) throws {
        guard let value = Self(rawValue: minutes) else {
            throw SupabaseMessageClientError.invalidMetadata
        }
        self = value
    }

    var label: String {
        switch self {
        case .sixty:
            "1時間"
        case .ninety:
            "1時間以上"
        case .ten, .twenty, .thirty:
            "\(rawValue)分"
        }
    }
}

public enum SupabaseMessageSystemAction: String, Sendable {
    case cancelRequested = "cancel_requested"
    case cancelApproved = "cancel_approved"
    case lateNotice = "late_notice"
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
        try validatePhotoURL(photoURL)
        return try await sendMessage(
            senderID: senderID,
            proposalID: proposalID,
            messageType: messageType,
            body: body ?? defaultPhotoBody(for: messageType),
            photoURL: photoURL
        )
    }

    public func sendOutfitPhotoMessage(
        senderID: UUID,
        proposalID: UUID,
        photoURL: URL,
        body: String? = nil
    ) async throws -> TradeMessage {
        try await sendPhotoMessage(
            senderID: senderID,
            proposalID: proposalID,
            photoURL: photoURL,
            body: body,
            messageType: .outfitPhoto
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

    public func sendCurrentLocationMessage(
        senderID: UUID,
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String = "現在地",
        body: String? = nil
    ) async throws -> TradeMessage {
        try await sendLocationMessage(
            senderID: senderID,
            proposalID: proposalID,
            latitude: latitude,
            longitude: longitude,
            label: label,
            body: body
        )
    }

    public func sendSystemMessage(senderID: UUID, proposalID: UUID, body: String) async throws -> TradeMessage {
        try await sendMessage(senderID: senderID, proposalID: proposalID, messageType: .system, body: body)
    }

    public func sendLateNoticeMessage(
        senderID: UUID,
        proposalID: UUID,
        lateMinutes: SupabaseMessageLateMinutes,
        reason: String,
        note: String? = nil
    ) async throws -> TradeMessage {
        let payload = try makeLateNoticePayload(
            senderID: senderID,
            proposalID: proposalID,
            lateMinutes: lateMinutes,
            reason: reason,
            note: note
        )
        return try await sendMessagePayload(payload)
    }

    public func sendLateNoticeMessage(
        senderID: UUID,
        proposalID: UUID,
        lateMinutes: Int,
        reason: String,
        note: String? = nil
    ) async throws -> TradeMessage {
        try await sendLateNoticeMessage(
            senderID: senderID,
            proposalID: proposalID,
            lateMinutes: SupabaseMessageLateMinutes(minutes: lateMinutes),
            reason: reason,
            note: note
        )
    }

    public func sendCancelRequestMessage(
        senderID: UUID,
        proposalID: UUID,
        reason: String,
        note: String? = nil
    ) async throws -> TradeMessage {
        let payload = try makeCancelRequestPayload(
            senderID: senderID,
            proposalID: proposalID,
            reason: reason,
            note: note
        )
        return try await sendMessagePayload(payload)
    }

    public func sendCancelApprovedMessage(senderID: UUID, proposalID: UUID) async throws -> TradeMessage {
        let payload = try makeCancelApprovedPayload(senderID: senderID, proposalID: proposalID)
        return try await sendMessagePayload(payload)
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
        let payload = try makeMessageCreatePayload(
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
        return try await sendMessagePayload(payload)
    }

    private func sendMessagePayload(_ payload: MessageCreatePayload) async throws -> TradeMessage {
        let rows: [MessageRow] = try await client.upsertRows(
            into: "messages",
            values: [payload],
            select: MessageRow.select
        )
        return rows.first?.message ?? TradeMessage(
            id: UUID(),
            proposalID: payload.proposalId,
            senderID: payload.senderId,
            messageType: payload.tradeMessageType,
            body: payload.body,
            photoURL: payload.photoURLValue,
            locationLatitude: payload.locationLat,
            locationLongitude: payload.locationLng,
            locationLabel: payload.locationLabel,
            meta: payload.tradeMeta
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
        try validatePhotoURL(photoURL)
        return try makeSendMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            messageType: messageType,
            body: body ?? defaultPhotoBody(for: messageType),
            photoURL: photoURL
        )
    }

    public func makeSendOutfitPhotoMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        photoURL: URL,
        body: String? = nil
    ) throws -> URLRequest {
        try makeSendPhotoMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            photoURL: photoURL,
            body: body,
            messageType: .outfitPhoto
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

    public func makeSendCurrentLocationMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        latitude: Double,
        longitude: Double,
        label: String = "現在地",
        body: String? = nil
    ) throws -> URLRequest {
        try makeSendLocationMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            latitude: latitude,
            longitude: longitude,
            label: label,
            body: body
        )
    }

    public func makeSendSystemMessageRequest(senderID: UUID, proposalID: UUID, body: String) throws -> URLRequest {
        try makeSendMessageRequest(senderID: senderID, proposalID: proposalID, messageType: .system, body: body)
    }

    public func makeSendLateNoticeMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        lateMinutes: SupabaseMessageLateMinutes,
        reason: String,
        note: String? = nil
    ) throws -> URLRequest {
        let payload = try makeLateNoticePayload(
            senderID: senderID,
            proposalID: proposalID,
            lateMinutes: lateMinutes,
            reason: reason,
            note: note
        )
        return try makeMessageMutationRequest(payload)
    }

    public func makeSendLateNoticeMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        lateMinutes: Int,
        reason: String,
        note: String? = nil
    ) throws -> URLRequest {
        try makeSendLateNoticeMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            lateMinutes: SupabaseMessageLateMinutes(minutes: lateMinutes),
            reason: reason,
            note: note
        )
    }

    public func makeSendCancelRequestMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        reason: String,
        note: String? = nil
    ) throws -> URLRequest {
        let payload = try makeCancelRequestPayload(
            senderID: senderID,
            proposalID: proposalID,
            reason: reason,
            note: note
        )
        return try makeMessageMutationRequest(payload)
    }

    public func makeSendCancelApprovedMessageRequest(senderID: UUID, proposalID: UUID) throws -> URLRequest {
        let payload = try makeCancelApprovedPayload(senderID: senderID, proposalID: proposalID)
        return try makeMessageMutationRequest(payload)
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
        let payload = try makeMessageCreatePayload(
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
        return try makeMessageMutationRequest(payload)
    }

    private func makeMessageMutationRequest(_ payload: MessageCreatePayload) throws -> URLRequest {
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

    private func makeMessageCreatePayload(
        proposalID: UUID,
        senderID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationLabel: String? = nil,
        meta: [String: String]? = nil
    ) throws -> MessageCreatePayload {
        try validateMessagePayload(
            messageType: messageType,
            body: body,
            photoURL: photoURL,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationLabel: locationLabel,
            meta: meta
        )
        return MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: body,
            photoURL: photoURL,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationLabel: locationLabel,
            meta: meta?.mapValues(MessageMetadataValue.string)
        )
    }

    private func makeLateNoticePayload(
        senderID: UUID,
        proposalID: UUID,
        lateMinutes: SupabaseMessageLateMinutes,
        reason: String,
        note: String?
    ) throws -> MessageCreatePayload {
        let normalizedReason = try requiredText(reason)
        let normalizedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let body = "\(lateMinutes.label)遅れる旨が通知されました\n理由：\(normalizedReason)\(normalizedNote.map { "\n\($0)" } ?? "")"
        return MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: .system,
            body: body,
            meta: [
                "action": .string(SupabaseMessageSystemAction.lateNotice.rawValue),
                "notified_by": .string(senderID.uuidString.lowercased()),
                "late_minutes": .int(lateMinutes.rawValue),
                "reason": .string(normalizedReason),
                "note": normalizedNote.map(MessageMetadataValue.string) ?? .null
            ]
        )
    }

    private func makeCancelRequestPayload(
        senderID: UUID,
        proposalID: UUID,
        reason: String,
        note: String?
    ) throws -> MessageCreatePayload {
        let normalizedReason = try requiredText(reason)
        let normalizedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let body = "取引キャンセルが申請されました\n理由：\(normalizedReason)\(normalizedNote.map { "\n\($0)" } ?? "")"
        return MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: .system,
            body: body,
            meta: [
                "action": .string(SupabaseMessageSystemAction.cancelRequested.rawValue),
                "requested_by": .string(senderID.uuidString.lowercased()),
                "reason": .string(normalizedReason),
                "note": normalizedNote.map(MessageMetadataValue.string) ?? .null
            ]
        )
    }

    private func makeCancelApprovedPayload(senderID: UUID, proposalID: UUID) throws -> MessageCreatePayload {
        MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: .system,
            body: "取引キャンセルが合意されました（評価への影響なし）",
            meta: [
                "action": .string(SupabaseMessageSystemAction.cancelApproved.rawValue),
                "approved_by": .string(senderID.uuidString.lowercased())
            ]
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

    private func validatePhotoURL(_ photoURL: URL?) throws {
        guard
            let photoURL,
            let scheme = photoURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            photoURL.host?.isEmpty == false
        else {
            throw SupabaseMessageClientError.invalidPhotoURL
        }
    }

    private func validateLocation(latitude: Double, longitude: Double) throws {
        guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw SupabaseMessageClientError.invalidLocation
        }
    }

    private func validateMessagePayload(
        messageType: TradeMessageType,
        body: String?,
        photoURL: URL?,
        locationLatitude: Double?,
        locationLongitude: Double?,
        locationLabel: String?,
        meta: [String: String]?
    ) throws {
        switch messageType {
        case .text:
            _ = try requiredText(body)
            try rejectAttachmentFields(photoURL: photoURL, locationLatitude: locationLatitude, locationLongitude: locationLongitude, locationLabel: locationLabel)
        case .system:
            _ = try requiredText(body)
            try rejectAttachmentFields(photoURL: photoURL, locationLatitude: locationLatitude, locationLongitude: locationLongitude, locationLabel: locationLabel)
        case .photo, .outfitPhoto:
            try validatePhotoMessageType(messageType)
            try validatePhotoURL(photoURL)
            if let locationLatitude, let locationLongitude {
                try validateLocation(latitude: locationLatitude, longitude: locationLongitude)
                throw SupabaseMessageClientError.invalidLocation
            }
            if locationLatitude != nil || locationLongitude != nil || locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty != nil {
                throw SupabaseMessageClientError.invalidLocation
            }
        case .location:
            guard let locationLatitude, let locationLongitude else {
                throw SupabaseMessageClientError.invalidLocation
            }
            try validateLocation(latitude: locationLatitude, longitude: locationLongitude)
            guard locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty != nil else {
                throw SupabaseMessageClientError.invalidLocation
            }
            if photoURL != nil {
                throw SupabaseMessageClientError.invalidPhotoURL
            }
        case .arrivalStatus:
            _ = try requiredText(body)
            try rejectAttachmentFields(photoURL: photoURL, locationLatitude: locationLatitude, locationLongitude: locationLongitude, locationLabel: locationLabel)
            guard
                let status = meta?["status"],
                SupabaseMessageArrivalStatus(rawValue: status) != nil
            else {
                throw SupabaseMessageClientError.invalidMetadata
            }
        }
    }

    private func rejectAttachmentFields(
        photoURL: URL?,
        locationLatitude: Double?,
        locationLongitude: Double?,
        locationLabel: String?
    ) throws {
        if photoURL != nil {
            throw SupabaseMessageClientError.invalidPhotoURL
        }
        if locationLatitude != nil || locationLongitude != nil || locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty != nil {
            throw SupabaseMessageClientError.invalidLocation
        }
    }

    private func requiredText(_ text: String?) throws -> String {
        guard let normalized = text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            throw SupabaseMessageClientError.invalidBody
        }
        return normalized
    }

    private func defaultPhotoBody(for messageType: TradeMessageType) -> String? {
        messageType == .outfitPhoto ? "服装写真を共有しました" : nil
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
    var meta: [String: MessageMetadataValue]?
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
            meta: meta?.compactMapValues(\.stringValue) ?? [:],
            createdAt: createdAt ?? .now
        )
    }

    private func fallbackBody(for type: TradeMessageType) -> String? {
        switch type {
        case .location:
            locationLabel
        case .arrivalStatus:
            meta?["body"]?.stringValue
                ?? meta?["label"]?.stringValue
                ?? meta?["status"]?.stringValue.flatMap(SupabaseMessageArrivalStatus.init(rawValue:))?.defaultBody
        case .text, .photo, .outfitPhoto, .system:
            nil
        }
    }
}

private enum MessageMetadataValue: Codable, Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    var stringValue: String? {
        switch self {
        case let .string(value):
            value
        case let .int(value):
            "\(value)"
        case let .double(value):
            "\(value)"
        case let .bool(value):
            value ? "true" : "false"
        case .null:
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
    var meta: [String: MessageMetadataValue]?

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
        meta: [String: MessageMetadataValue]? = nil
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

    var tradeMessageType: TradeMessageType {
        TradeMessageType(rawValue: messageType) ?? .system
    }

    var photoURLValue: URL? {
        photoUrl.flatMap(URL.init(string:))
    }

    var tradeMeta: [String: String] {
        meta?.compactMapValues(\.stringValue) ?? [:]
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
