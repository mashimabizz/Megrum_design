import Foundation

extension SupabaseHomeClient {
    func loadListingWishOptionsIfNeeded(listingIDs: [UUID]) async throws -> [SupabaseHomeListingWishOptionRow] {
        guard !listingIDs.isEmpty else {
            return []
        }
        return try await client.fetchRows(
            from: "listing_wish_options",
            select: SupabaseHomeListingWishOptionRow.select,
            queryItems: try SupabaseHomeQueryItems.listingWishOptions(listingIDs: listingIDs)
        )
    }

    func loadInventoryTagsIfNeeded(inventoryIDs: [UUID]) async throws -> [SupabaseHomeInventoryTagRow] {
        guard !inventoryIDs.isEmpty else {
            return []
        }
        return try await client.fetchRows(
            from: "goods_inventory_tags",
            select: SupabaseHomeInventoryTagRow.select,
            queryItems: try SupabaseHomeQueryItems.inventoryTags(inventoryIDs: inventoryIDs)
        )
    }

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
        } catch let error as SupabaseRESTError where Self.isOptionalRPCFallbackError(error) {
            return []
        }
        return Set(rows.map(\.userID))
    }

    func loadGoodsRows(queryItems: [URLQueryItem]) async throws -> [SupabaseHomeGoodsRow] {
        do {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: SupabaseHomeGoodsRow.select,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: SupabaseHomeGoodsRow.legacySelect,
                queryItems: queryItems
            )
        }
    }

    func loadViewerUsers(userID: UUID) async throws -> [SupabaseHomeUserRow] {
        do {
            return try await client.rpcRows(
                function: "list_home_user_summaries_for_viewer",
                payload: HomeUserSummaryPayload(userID: userID, limit: 1)
            )
        } catch let error as SupabaseRESTError where Self.isOptionalRPCFallbackError(error) {
            return try await loadUsersLegacy(queryItems: SupabaseHomeQueryItems.viewerUser(userID: userID))
        } catch {
            throw error
        }
    }

    func loadPartnerUsers(excludingUserID userID: UUID, limit: Int) async throws -> [SupabaseHomeUserRow] {
        do {
            return try await client.rpcRows(
                function: "list_home_user_summaries_for_viewer",
                payload: HomeUserSummaryPayload(excludingUserID: userID, limit: limit)
            )
        } catch let error as SupabaseRESTError where Self.isOptionalRPCFallbackError(error) {
            return try await loadUsersLegacy(
                queryItems: SupabaseHomeQueryItems.partnerUsers(excludingUserID: userID, limit: limit)
            )
        } catch {
            throw error
        }
    }

    func loadUsersLegacy(queryItems: [URLQueryItem]) async throws -> [SupabaseHomeUserRow] {
        do {
            return try await client.fetchRows(
                from: "users",
                select: SupabaseHomeUserRow.select,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            return try await client.fetchRows(
                from: "users",
                select: SupabaseHomeUserRow.legacySelect,
                queryItems: queryItems
            )
        }
    }

    static func isOptionalRPCFallbackError(_ error: SupabaseRESTError) -> Bool {
        error == .unexpectedStatus(400) || error == .unexpectedStatus(404)
    }
}
