import CoreGraphics

struct MeguriMapCreationPromptPresentationState: Equatable {
    var isVisible = false

    mutating func prepare() {
        isVisible = false
    }

    mutating func show() {
        isVisible = true
    }

    var dropPinYOffset: CGFloat {
        isVisible ? 0 : -78
    }

    var dropPinOpacity: Double {
        isVisible ? 1 : 0.18
    }

    var dropPinScale: CGFloat {
        isVisible ? 1 : 0.88
    }

    var calloutOpacity: Double {
        isVisible ? 1 : 0
    }

    var calloutScale: CGFloat {
        isVisible ? 1 : 0.96
    }
}
