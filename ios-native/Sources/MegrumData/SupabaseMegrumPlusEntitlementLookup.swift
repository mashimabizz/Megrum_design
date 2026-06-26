import Foundation

extension SupabaseGoodsInventoryClient {
    func loadMegrumPlusUserIDsIfNeeded(userIDs: [UUID]) async throws -> Set<UUID> {
        let ids = Array(Set(userIDs))
        guard !ids.isEmpty else {
            return []
        }
        let rows: [SupabaseMegrumPlusUserIDRow]
        do {
            rows = try await client.rpcRows(
                function: "list_megrum_plus_user_ids_for_viewer",
                payload: MegrumPlusUserIDsPayload(userIDs: ids)
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) || error == .unexpectedStatus(404) {
            return []
        }
        return Set(rows.map(\.userID))
    }
}

