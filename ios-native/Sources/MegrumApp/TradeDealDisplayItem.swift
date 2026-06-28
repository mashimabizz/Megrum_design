import Foundation
import MegrumCore

enum TradeDealDisplayItem: Identifiable {
    case goods(GoodsItem)
    case cash(amount: Int?)

    var id: String {
        switch self {
        case .goods(let item):
            "goods:\(item.id.uuidString)"
        case .cash(let amount):
            "cash:\(amount.map(String.init) ?? "fixed-price")"
        }
    }
}
