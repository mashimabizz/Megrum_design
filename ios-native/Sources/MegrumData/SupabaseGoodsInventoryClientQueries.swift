import Foundation
import MegrumCore

enum GoodsInventoryAvailabilityQueryMode {
    case marketAvailableQuantity
    case quantity

    var queryItem: URLQueryItem {
        switch self {
        case .marketAvailableQuantity:
            URLQueryItem(name: "market_available_qty", value: "gt.0")
        case .quantity:
            URLQueryItem(name: "quantity", value: "gt.0")
        }
    }
}

extension SupabaseGoodsInventoryClient {
    func goodsTypeQueryItems(limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "order", value: "display_order.asc,name.asc"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    func boundedLimit(_ limit: Int, upperBound: Int = 100) -> Int {
        max(1, min(limit, upperBound))
    }

    func searchQueryItems(
        viewerID: UUID,
        input: GoodsSearchInput,
        availability: GoodsInventoryAvailabilityQueryMode
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "kind", value: "eq.for_trade"),
            URLQueryItem(name: "status", value: "in.(active,reserved)"),
            availability.queryItem,
            URLQueryItem(name: "user_id", value: "neq.\(viewerID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "updated_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(input.limit, 100)))")
        ]

        let query = SupabaseTextNormalizer.trimmed(input.query)
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "title", value: "ilike.*\(query)*"))
        }
        if let groupFilter = idFilterValue(input.groupIDs) {
            queryItems.append(URLQueryItem(name: "group_id", value: groupFilter))
        }
        if let memberFilter = idFilterValue(input.memberIDs) {
            queryItems.append(URLQueryItem(name: "character_id", value: memberFilter))
        }
        if let goodsTypeFilter = idFilterValue(input.goodsTypeIDs) {
            queryItems.append(URLQueryItem(name: "goods_type_id", value: goodsTypeFilter))
        }
        return queryItems
    }

    /// 単数は eq、複数は in.(...)（項目内OR）。
    private func idFilterValue(_ ids: [UUID]) -> String? {
        let lowercased = ids.map { $0.uuidString.lowercased() }
        switch lowercased.count {
        case 0:
            return nil
        case 1:
            return "eq.\(lowercased[0])"
        default:
            return "in.(\(lowercased.sorted().joined(separator: ",")))"
        }
    }

    func publicTradeGoodsQueryItems(
        userID: UUID,
        limit: Int,
        availability: GoodsInventoryAvailabilityQueryMode
    ) -> [URLQueryItem] {
        [
            URLQueryItem(name: "kind", value: "eq.for_trade"),
            URLQueryItem(name: "status", value: "in.(active,reserved)"),
            availability.queryItem,
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "updated_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(limit, 100)))")
        ]
    }

    func ownedItemQueryItems(userID: UUID, itemID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(itemID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "neq.traded")
        ]
    }
}

/// 検索結果に相手の表示名・アバターを載せるためのオーナー要約。
struct GoodsOwnerSummaryRow: Decodable, Sendable {
    static let select = "id,handle,display_name,avatar_url"

    var id: UUID
    var handle: String?
    var displayName: String?
    var avatarUrl: String?
}

extension SupabaseGoodsInventoryClient {
    /// user_id in.(...) でオーナーの表示名・ハンドル・アバターをまとめて取得する。
    /// 表示補助なので失敗しても検索自体は成立させる（呼び出し側で try? する）。
    func loadGoodsOwnerSummaries(userIDs: [UUID]) async throws -> [UUID: GoodsOwnerSummaryRow] {
        let uniqueIDs = Set(userIDs)
        guard !uniqueIDs.isEmpty else {
            return [:]
        }
        let idList = uniqueIDs.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")
        let rows: [GoodsOwnerSummaryRow] = try await client.fetchRows(
            from: "users",
            select: GoodsOwnerSummaryRow.select,
            queryItems: [URLQueryItem(name: "id", value: "in.(\(idList))")]
        )
        return Dictionary(rows.map { ($0.id, $0) }) { first, _ in first }
    }

    /// GoodsItem の owner 系フィールドへオーナー要約を反映する。
    func applyingOwnerSummaries(
        _ items: [GoodsItem],
        owners: [UUID: GoodsOwnerSummaryRow]
    ) -> [GoodsItem] {
        guard !owners.isEmpty else {
            return items
        }
        return items.map { item in
            guard let owner = owners[item.ownerID] else {
                return item
            }
            var item = item
            let displayName = owner.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let handle = owner.handle?.trimmingCharacters(in: .whitespacesAndNewlines)
            item.ownerDisplayName = (displayName?.isEmpty == false ? displayName : nil)
                ?? (handle?.isEmpty == false ? handle : nil)
            item.ownerHandle = handle?.isEmpty == false ? handle : nil
            item.ownerAvatarURL = owner.avatarUrl.flatMap(URL.init(string:))
            return item
        }
    }
}
