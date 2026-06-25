import Foundation
import MegrumCore

extension SupabaseMessageClient {
    func sendMessagePayload(_ payload: MessageCreatePayload) async throws -> TradeMessage {
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

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    static func isOptionalReadStateError(_ error: SupabaseRESTError) -> Bool {
        switch error {
        case .unexpectedStatus(400), .unexpectedStatus(404):
            true
        case .invalidURL, .unexpectedStatus:
            false
        }
    }
}
