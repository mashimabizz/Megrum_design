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
