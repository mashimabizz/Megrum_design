#if os(iOS)
import UIKit

struct GoodsSharePostPayload: Identifiable {
    let id = UUID()
    var text: String
    var image: UIImage
}
#endif
