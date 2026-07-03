import CoreGraphics

struct GroomViewerDragPresentationState: Equatable {
    static let dismissThreshold: CGFloat = 100

    private static let progressDenominator: CGFloat = 320
    private static let scaleReduction: CGFloat = 0.12
    private static let minimumScale: CGFloat = 0.88
    private static let cornerRadiusMultiplier: CGFloat = 28

    var translation: CGSize = .zero

    var progress: CGFloat {
        min(max(translation.height / Self.progressDenominator, 0), 1)
    }

    var verticalOffset: CGFloat {
        max(translation.height, 0)
    }

    var scale: CGFloat {
        max(Self.minimumScale, 1 - progress * Self.scaleReduction)
    }

    var cornerRadius: CGFloat {
        progress * Self.cornerRadiusMultiplier
    }

    mutating func update(with translation: CGSize) {
        guard translation.height > 0 else {
            return
        }
        self.translation = translation
    }

    mutating func reset() {
        translation = .zero
    }

    func shouldDismiss(for translation: CGSize) -> Bool {
        translation.height > Self.dismissThreshold
    }
}
