import Foundation
import MegrumCore

struct GoodsSharePostContext: Identifiable, Equatable {
    let id = UUID()
    var items: [GoodsItem]
    var displayName: String

    var shareItems: [GoodsItem] {
        Array(items.prefix(20))
    }
}
