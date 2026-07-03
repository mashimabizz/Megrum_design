#if os(iOS)
import UIKit

struct GoodsSharePostPayload: Identifiable {
    let id = UUID()
    var text: String
    var images: [UIImage]

    var activityItems: [Any] {
        [text] + images
    }
}
#endif
