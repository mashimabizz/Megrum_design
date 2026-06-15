import Foundation
import MegrumCore
import MegrumData

struct SupabaseOwnedGoodsPersistence: Sendable {
    private let client: SupabaseRESTClient
    private let userID: UUID

    init(client: SupabaseRESTClient, userID: UUID) {
        self.client = client
        self.userID = userID
    }

    func loadTradeGoods() async throws -> [GoodsItem] {
        let rows = try await fetchOwnGoodsRows(kind: GoodsEntryKind.inventory.inventoryKind)
        return Self.goodsItems(from: rows)
    }

    func loadWishes() async throws -> [WishItem] {
        let rows = try await fetchOwnGoodsRows(kind: GoodsEntryKind.wish.inventoryKind)
        return Self.wishItems(from: rows)
    }

    private func fetchOwnGoodsRows(kind: String) async throws -> [GoodsInventoryRow] {
        do {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: GoodsInventoryRow.select,
                queryItems: Self.ownGoodsQueryItems(userID: userID, kind: kind)
            )
        } catch {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: GoodsInventoryRow.legacySelect,
                queryItems: Self.ownGoodsQueryItems(userID: userID, kind: kind)
            )
        }
    }

    static func ownGoodsQueryItems(userID: UUID, kind: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "kind", value: "eq.\(kind)"),
            URLQueryItem(name: "status", value: "neq.archived")
        ]
    }

    static func goodsItems(from rows: [GoodsInventoryRow]) -> [GoodsItem] {
        rows.map(\.goodsItem)
    }

    static func wishItems(from rows: [GoodsInventoryRow]) -> [WishItem] {
        rows.map(\.wishItem)
    }
}
