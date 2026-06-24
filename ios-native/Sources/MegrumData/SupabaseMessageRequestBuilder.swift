import Foundation
import MegrumCore

extension SupabaseMessageClient {
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

    public func makeLoadProposalReadStateRequest(proposalID: UUID, userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/proposal_read_states",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalReadStateRow.select),
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
    }

    public func makeMarkProposalMessagesReadRequest(
        proposalID: UUID,
        userID: UUID,
        lastReadAt: Date,
        updatedAt: Date = .now
    ) throws -> URLRequest {
        let payload = ProposalReadStateUpsertPayload(
            proposalID: proposalID,
            userID: userID,
            lastReadAt: lastReadAt,
            updatedAt: updatedAt
        )
        return try client.makeUpsertRequest(
            into: "proposal_read_states",
            values: [payload],
            select: ProposalReadStateRow.select,
            onConflict: "proposal_id,user_id"
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
        let normalizedLabel = SupabaseTextNormalizer.trimmed(label)
        return try makeSendMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            messageType: .location,
            body: SupabaseTextNormalizer.optional(body) ?? SupabaseTextNormalizer.optional(normalizedLabel),
            locationLatitude: latitude,
            locationLongitude: longitude,
            locationLabel: SupabaseTextNormalizer.optional(normalizedLabel)
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
            body: SupabaseTextNormalizer.optional(body) ?? status.defaultBody,
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

    func makeMessageMutationRequest(_ payload: MessageCreatePayload) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/messages",
            queryItems: [
                URLQueryItem(name: "select", value: MessageRow.select)
            ],
            method: "POST",
            body: encoder.encode([payload]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }
}
