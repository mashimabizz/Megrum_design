import CoreGraphics
import Foundation

struct MegrumInteractionFeedbackPresentationState: Equatable {
    var ripples: [MegrumTapRipple] = []

    @discardableResult
    mutating func addRipple(at location: CGPoint) -> MegrumTapRipple {
        let ripple = MegrumTapRipple(location: location)
        ripples.append(ripple)
        return ripple
    }

    mutating func removeRipple(id: UUID) {
        ripples.removeAll { $0.id == id }
    }
}

struct MegrumTapRipple: Identifiable, Equatable {
    let id: UUID
    var location: CGPoint

    init(id: UUID = UUID(), location: CGPoint) {
        self.id = id
        self.location = location
    }
}

struct MegrumTapRippleAnimationState: Equatable {
    var progress: CGFloat = 0

    var opacity: Double {
        Double(1 - progress)
    }

    func diameter(reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 64 : 174
    }

    func scale(reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 0.98 : 0.22 + progress * 1.08
    }

    mutating func finish() {
        progress = 1
    }
}
