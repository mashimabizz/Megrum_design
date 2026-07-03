import SwiftUI

enum EdgeBackSwipeResolver {
    static let leadingEdgeWidth: CGFloat = 32
    static let minimumTranslation: CGFloat = 64
    static let minimumPredictedTranslation: CGFloat = 96
    static let horizontalDominance: CGFloat = 1.25

    static func shouldTrigger(
        startLocation: CGPoint,
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat
    ) -> Bool {
        guard startLocation.x <= leadingEdgeWidth else {
            return false
        }
        let isRightSwipe = translation.width > 0 || predictedEndTranslationWidth > 0
        let isHorizontal = abs(translation.width) > abs(translation.height) * horizontalDominance
        let isLongEnough = translation.width >= minimumTranslation
            || predictedEndTranslationWidth >= minimumPredictedTranslation
        return isRightSwipe && isHorizontal && isLongEnough
    }
}

enum InteractiveBackSwipeResolver {
    static let minimumTrackingTranslation: CGFloat = 8
    static let minimumTranslation: CGFloat = 72
    static let minimumPredictedTranslation: CGFloat = 112
    static let horizontalDominance: CGFloat = 1.25
    static let defaultScreenWidth: CGFloat = 390
    static let maximumOvershoot: CGFloat = 28

    static func trackedOffset(
        translation: CGSize,
        screenWidth: CGFloat = defaultScreenWidth
    ) -> CGFloat? {
        guard translation.width > 0 else {
            return nil
        }
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        guard absX >= minimumTrackingTranslation,
              absX > absY * horizontalDominance
        else {
            return nil
        }
        return min(translation.width, max(screenWidth, 1) + maximumOvershoot)
    }

    static func shouldTrigger(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat = defaultScreenWidth
    ) -> Bool {
        guard trackedOffset(translation: translation, screenWidth: screenWidth) != nil else {
            return false
        }
        return translation.width >= minimumTranslation
            || predictedEndTranslationWidth >= minimumPredictedTranslation
    }
}

private struct EdgeBackSwipeModifier: ViewModifier {
    var isEnabled: Bool
    var action: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        guard isEnabled,
                              EdgeBackSwipeResolver.shouldTrigger(
                                startLocation: value.startLocation,
                                translation: value.translation,
                                predictedEndTranslationWidth: value.predictedEndTranslation.width
                              )
                        else {
                            return
                        }
                        action()
                    }
            )
    }
}

private struct InteractiveBackSwipeModifier: ViewModifier {
    var isEnabled: Bool
    var isSuppressed: () -> Bool
    var action: () -> Void

    @Environment(\.megrumBackSwipeHandledBySlidePresentation) private var isHandledBySlidePresentation
    @State private var presentationState = InteractiveBackSwipePresentationState()

    private let resetAnimation = Animation.interactiveSpring(response: 0.28, dampingFraction: 0.86)

    @ViewBuilder
    func body(content: Content) -> some View {
        if isHandledBySlidePresentation {
            content
        } else {
            content
                .background(widthReader)
                .offset(x: presentationState.dragOffset)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: InteractiveBackSwipeResolver.minimumTrackingTranslation)
                        .onChanged(handleDragChanged)
                        .onEnded(handleDragEnded),
                    including: .gesture
                )
        }
    }

    private var widthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    presentationState.updateContainerWidth(proxy.size.width)
                }
                .onChange(of: proxy.size.width) { _, newValue in
                    presentationState.updateContainerWidth(newValue)
                }
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        guard isEnabled, !isSuppressed() else {
            resetDrag(animated: true)
            return
        }

        guard presentationState.beginTrackingIfNeeded(translation: value.translation) else {
            return
        }

        presentationState.dragOffset = presentationState.trackedOffset(translation: value.translation)
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        guard presentationState.isTrackingBackSwipe else {
            return
        }
        let shouldTrigger = isEnabled
            && !isSuppressed()
            && presentationState.shouldTrigger(
                translation: value.translation,
                predictedEndTranslationWidth: value.predictedEndTranslation.width
            )
        presentationState.stopTracking()

        guard shouldTrigger else {
            resetDrag(animated: true)
            return
        }

        resetDrag(animated: true)
        action()
    }

    private func resetDrag(animated: Bool) {
        guard presentationState.dragOffset != 0 || presentationState.isTrackingBackSwipe else {
            return
        }
        presentationState.stopTracking()
        if animated {
            withAnimation(resetAnimation) {
                presentationState.resetDragOffset()
            }
        } else {
            presentationState.resetDragOffset()
        }
    }
}

extension View {
    func megrumEdgeBackSwipe(
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        modifier(EdgeBackSwipeModifier(isEnabled: isEnabled, action: action))
    }

    func megrumInteractiveBackSwipe(
        isEnabled: Bool = true,
        isSuppressed: @escaping () -> Bool = { false },
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            InteractiveBackSwipeModifier(
                isEnabled: isEnabled,
                isSuppressed: isSuppressed,
                action: action
            )
        )
    }
}
