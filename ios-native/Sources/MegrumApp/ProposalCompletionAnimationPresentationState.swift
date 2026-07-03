import CoreGraphics

struct ProposalCompletionAnimationPresentationState: Equatable {
    var isShown = false

    mutating func show() {
        isShown = true
    }

    func haloScale(reduceMotion: Bool) -> CGFloat {
        isShown && !reduceMotion ? 1.16 : 0.82
    }

    var haloOpacity: Double {
        isShown ? 1 : 0.4
    }

    func badgeScale(reduceMotion: Bool) -> CGFloat {
        isShown || reduceMotion ? 1 : 0.72
    }

    func sparkleOffsetValue(_ value: CGFloat, reduceMotion: Bool) -> CGFloat {
        isShown || reduceMotion ? value : value * 0.52
    }

    func sparkleScale(reduceMotion: Bool) -> CGFloat {
        isShown || reduceMotion ? 1 : 0.36
    }

    var sparkleOpacity: Double {
        isShown ? 1 : 0
    }
}
