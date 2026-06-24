import Foundation
import MegrumCore

extension SupabaseMessageClient {
    func makeMessageCreatePayload(
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

    func makeLateNoticePayload(
        senderID: UUID,
        proposalID: UUID,
        lateMinutes: SupabaseMessageLateMinutes,
        reason: String,
        note: String?
    ) throws -> MessageCreatePayload {
        let normalizedReason = try requiredText(reason)
        let normalizedNote = SupabaseTextNormalizer.optional(note)
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

    func makeCancelRequestPayload(
        senderID: UUID,
        proposalID: UUID,
        reason: String,
        note: String?
    ) throws -> MessageCreatePayload {
        let normalizedReason = try requiredText(reason)
        let normalizedNote = SupabaseTextNormalizer.optional(note)
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

    func makeCancelApprovedPayload(senderID: UUID, proposalID: UUID) throws -> MessageCreatePayload {
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

    func validatePhotoMessageType(_ messageType: TradeMessageType) throws {
        guard messageType == .photo || messageType == .outfitPhoto else {
            throw SupabaseMessageClientError.invalidPhotoMessageType
        }
    }

    func validatePhotoURL(_ photoURL: URL?) throws {
        guard
            let photoURL,
            let scheme = photoURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            photoURL.host?.isEmpty == false
        else {
            throw SupabaseMessageClientError.invalidPhotoURL
        }
    }

    func validateLocation(latitude: Double, longitude: Double) throws {
        guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw SupabaseMessageClientError.invalidLocation
        }
    }

    func validateMessagePayload(
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
            if locationLatitude != nil || locationLongitude != nil || SupabaseTextNormalizer.optional(locationLabel) != nil {
                throw SupabaseMessageClientError.invalidLocation
            }
        case .location:
            guard let locationLatitude, let locationLongitude else {
                throw SupabaseMessageClientError.invalidLocation
            }
            try validateLocation(latitude: locationLatitude, longitude: locationLongitude)
            guard SupabaseTextNormalizer.optional(locationLabel) != nil else {
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

    func rejectAttachmentFields(
        photoURL: URL?,
        locationLatitude: Double?,
        locationLongitude: Double?,
        locationLabel: String?
    ) throws {
        if photoURL != nil {
            throw SupabaseMessageClientError.invalidPhotoURL
        }
        if locationLatitude != nil || locationLongitude != nil || SupabaseTextNormalizer.optional(locationLabel) != nil {
            throw SupabaseMessageClientError.invalidLocation
        }
    }

    func requiredText(_ text: String?) throws -> String {
        guard let normalized = SupabaseTextNormalizer.optional(text) else {
            throw SupabaseMessageClientError.invalidBody
        }
        return normalized
    }

    func defaultPhotoBody(for messageType: TradeMessageType) -> String? {
        messageType == .outfitPhoto ? "服装写真を共有しました" : nil
    }
}
