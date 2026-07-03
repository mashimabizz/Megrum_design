import CoreGraphics
import Foundation

struct GroomViewerLikeButtonPresentationState: Equatable {
    var burstToken = UUID()
    var isBursting = false

    var likeIconScale: CGFloat {
        isBursting ? 1.16 : 1
    }

    mutating func startBurst(token: UUID = UUID()) {
        burstToken = token
        isBursting = true
    }

    mutating func finishBurst() {
        isBursting = false
    }
}
