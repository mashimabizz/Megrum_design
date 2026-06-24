import Foundation
import MegrumCore

struct ProposalReadStateRow: Decodable, Sendable {
    static let select = "proposal_id,user_id,last_read_at,updated_at"

    var proposalId: UUID
    var userId: UUID
    var lastReadAt: Date
    var updatedAt: Date?

    var readState: ProposalReadState {
        ProposalReadState(
            proposalID: proposalId,
            userID: userId,
            lastReadAt: lastReadAt,
            updatedAt: updatedAt
        )
    }
}

struct ProposalReadStateUpsertPayload: Encodable, Sendable {
    var proposalId: UUID
    var userId: UUID
    var lastReadAt: String
    var updatedAt: String

    init(proposalID: UUID, userID: UUID, lastReadAt: Date, updatedAt: Date) {
        self.proposalId = proposalID
        self.userId = userID
        self.lastReadAt = SupabaseDateEncoding.isoTimestamp(lastReadAt)
        self.updatedAt = SupabaseDateEncoding.isoTimestamp(updatedAt)
    }
}

struct MessageRow: Decodable, Sendable {
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

enum MessageMetadataValue: Codable, Equatable, Sendable {
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

struct MessageCreatePayload: Encodable, Sendable {
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
        self.body = SupabaseTextNormalizer.optional(body)
        self.photoUrl = photoURL?.absoluteString
        self.locationLat = locationLatitude
        self.locationLng = locationLongitude
        self.locationLabel = SupabaseTextNormalizer.optional(locationLabel)
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
