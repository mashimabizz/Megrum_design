import Foundation
import MegrumCore

struct GoodsSharePostImageTile: Identifiable {
    var item: GoodsItem
    var imageData: Data?

    var id: UUID {
        item.id
    }
}
