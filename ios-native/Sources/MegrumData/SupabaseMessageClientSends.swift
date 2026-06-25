import Foundation
import MegrumCore

extension SupabaseMessageClient {
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
        let normalizedLabel = SupabaseTextNormalizer.trimmed(label)
        return try await sendMessage(
            senderID: senderID,
            proposalID: proposalID,
            messageType: .location,
            body: SupabaseTextNormalizer.optional(body) ?? SupabaseTextNormalizer.optional(normalizedLabel),
            locationLatitude: latitude,
            locationLongitude: longitude,
            locationLabel: SupabaseTextNormalizer.optional(normalizedLabel)
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
        try await sendArrivalStatusMessage(
            senderID: senderID,
            proposalID: proposalID,
            status: SupabaseMessageArrivalStatus.arrived,
            body: body
        )
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
            body: SupabaseTextNormalizer.optional(body) ?? status.defaultBody,
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
}
