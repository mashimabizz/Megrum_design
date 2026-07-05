import Foundation
import MegrumCore

extension SupabaseMessageClient {
    func sendMessagePayload(_ payload: MessageCreatePayload) async throws -> TradeMessage {
        let rows: [MessageRow] = try await client.upsertRows(
            into: "messages",
            values: [payload],
            select: MessageRow.select
        )
        if let message = await refreshedMessage(from: rows.first) {
            return message
        }

        let fallback = TradeMessage(
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
        return await refreshedPhotoMessage(fallback)
    }

    func refreshedMessages(from rows: [MessageRow]) async -> [TradeMessage] {
        var messages: [TradeMessage] = []
        messages.reserveCapacity(rows.count)
        for row in rows {
            if let message = await refreshedMessage(from: row) {
                messages.append(message)
            }
        }
        return messages
    }

    func refreshedMessage(from row: MessageRow?) async -> TradeMessage? {
        guard let message = row?.message else {
            return nil
        }
        return await refreshedPhotoMessage(message)
    }

    func refreshedPhotoMessage(_ message: TradeMessage) async -> TradeMessage {
        guard message.messageType == .photo || message.messageType == .outfitPhoto else {
            return message
        }
        guard let storagePath = SupabaseMessagePhotoStorageMetadata.storagePath(from: message) else {
            return message
        }

        var refreshed = message
        refreshed.photoURL = (try? await client.createSignedURL(
            bucket: SupabaseMessagePhotoStorageMetadata.bucket(from: message),
            path: storagePath,
            expiresIn: 60 * 60 * 24 * 365
        )) ?? message.photoURL
        return refreshed
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    static func isOptionalReadStateError(_ error: SupabaseRESTError) -> Bool {
        error.statusCode == 400 || error.statusCode == 404
    }
}
