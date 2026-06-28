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
        let tagMap = await bestEffortGoodsTagMap(inventoryIDs: rows.map(\.id))
        return Self.goodsItems(from: rows, tagMap: tagMap, projectURL: client.projectURL)
    }

    func loadWishes() async throws -> [WishItem] {
        let rows = try await fetchOwnGoodsRows(kind: GoodsEntryKind.wish.inventoryKind)
        let tagMap = await bestEffortGoodsTagMap(inventoryIDs: rows.map(\.id))
        return Self.wishItems(from: rows, tagMap: tagMap, projectURL: client.projectURL)
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

    private func bestEffortGoodsTagMap(inventoryIDs: [UUID]) async -> [UUID: [GoodsTag]] {
        do {
            return try await loadGoodsTagMap(inventoryIDs: inventoryIDs)
        } catch {
            return [:]
        }
    }

    private func loadGoodsTagMap(inventoryIDs: [UUID]) async throws -> [UUID: [GoodsTag]] {
        guard !inventoryIDs.isEmpty else {
            return [:]
        }
        let rows: [OwnedGoodsInventoryTagRow] = try await client.fetchRows(
            from: "goods_inventory_tags",
            select: OwnedGoodsInventoryTagRow.select,
            queryItems: Self.goodsTagQueryItems(inventoryIDs: inventoryIDs)
        )
        return Self.goodsTagMap(from: rows)
    }

    static func ownGoodsQueryItems(userID: UUID, kind: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "kind", value: "eq.\(kind)"),
            URLQueryItem(name: "status", value: "neq.archived")
        ]
    }

    static func goodsTagQueryItems(inventoryIDs: [UUID]) -> [URLQueryItem] {
        [
            URLQueryItem(
                name: "inventory_id",
                value: "in.(\(inventoryIDs.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")))"
            ),
            URLQueryItem(name: "order", value: "created_at.asc")
        ]
    }

    static func goodsTagMap(from rows: [OwnedGoodsInventoryTagRow]) -> [UUID: [GoodsTag]] {
        rows.reduce(into: [UUID: [GoodsTag]]()) { result, row in
            guard let tag = row.tag?.goodsTag else {
                return
            }
            result[row.inventoryId, default: []].append(tag)
        }
    }

    static func goodsItems(from rows: [GoodsInventoryRow]) -> [GoodsItem] {
        goodsItems(from: rows, tagMap: [:])
    }

    static func goodsItems(from rows: [GoodsInventoryRow], tagMap: [UUID: [GoodsTag]]) -> [GoodsItem] {
        goodsItems(from: rows, tagMap: tagMap, projectURL: nil)
    }

    static func goodsItems(from rows: [GoodsInventoryRow], tagMap: [UUID: [GoodsTag]], projectURL: URL?) -> [GoodsItem] {
        rows.map { row in
            var item = row.makeGoodsItem(projectURL: projectURL)
            item.tags = tagMap[row.id] ?? []
            return item
        }
    }

    static func wishItems(from rows: [GoodsInventoryRow]) -> [WishItem] {
        wishItems(from: rows, tagMap: [:])
    }

    static func wishItems(from rows: [GoodsInventoryRow], tagMap: [UUID: [GoodsTag]]) -> [WishItem] {
        wishItems(from: rows, tagMap: tagMap, projectURL: nil)
    }

    static func wishItems(from rows: [GoodsInventoryRow], tagMap: [UUID: [GoodsTag]], projectURL: URL?) -> [WishItem] {
        rows.map { row in
            var item = row.makeWishItem(projectURL: projectURL)
            item.tags = tagMap[row.id] ?? []
            return item
        }
    }
}
