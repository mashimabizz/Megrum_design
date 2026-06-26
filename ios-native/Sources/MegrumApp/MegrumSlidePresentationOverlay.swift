import MegrumDesign
import SwiftUI

private struct MegrumBackSwipeHandledBySlidePresentationKey: EnvironmentKey {
    static let defaultValue = false
}

struct MegrumSlidePresentationDismissAction: Sendable {
    var action: @MainActor @Sendable () -> Void

    @MainActor
    func callAsFunction() {
        action()
    }
}

private struct MegrumSlidePresentationDismissKey: EnvironmentKey {
    static let defaultValue: MegrumSlidePresentationDismissAction? = nil
}

extension EnvironmentValues {
    var megrumBackSwipeHandledBySlidePresentation: Bool {
        get { self[MegrumBackSwipeHandledBySlidePresentationKey.self] }
        set { self[MegrumBackSwipeHandledBySlidePresentationKey.self] = newValue }
    }

    var megrumSlidePresentationDismiss: MegrumSlidePresentationDismissAction? {
        get { self[MegrumSlidePresentationDismissKey.self] }
        set { self[MegrumSlidePresentationDismissKey.self] = newValue }
    }
}

enum MegrumSlidePresentationMetrics {
    static let leadingEdgeCaptureWidth: CGFloat = 24
    static let minimumTranslation: CGFloat = 78
    static let minimumPredictedTranslation: CGFloat = 132
    static let horizontalDominance: CGFloat = 1.16
    static let dismissFraction: CGFloat = 0.30
    static let animation: Animation = .interactiveSpring(
        response: 0.32,
        dampingFraction: 0.88,
        blendDuration: 0.04
    )
}

enum MegrumSlideBackSwipeResolver {
    static func interactiveOffset(translation: CGSize, screenWidth: CGFloat) -> CGFloat? {
        guard translation.width > 0 else {
            return nil
        }
        let isHorizontal = abs(translation.width) > abs(translation.height) * MegrumSlidePresentationMetrics.horizontalDominance
        guard isHorizontal else {
            return nil
        }
        return min(translation.width, screenWidth)
    }

    static func shouldDismiss(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat
    ) -> Bool {
        guard let offset = interactiveOffset(translation: translation, screenWidth: screenWidth) else {
            return false
        }
        return offset >= MegrumSlidePresentationMetrics.minimumTranslation
            || predictedEndTranslationWidth >= MegrumSlidePresentationMetrics.minimumPredictedTranslation
            || offset >= screenWidth * MegrumSlidePresentationMetrics.dismissFraction
    }
}

struct MegrumSlideBoolPresentationOverlay<PresentedContent: View>: View {
    @Binding var isPresented: Bool
    var content: (_ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent

    @State private var dragOffset: CGFloat = 0
    @State private var isTrackingDismissDrag = false

    var body: some View {
        GeometryReader { proxy in
            if isPresented {
                ZStack(alignment: .leading) {
                    content(dismissPresentation)
                        .environment(\.megrumBackSwipeHandledBySlidePresentation, true)
                        .environment(
                            \.megrumSlidePresentationDismiss,
                             MegrumSlidePresentationDismissAction(action: dismissPresentation)
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .background(MegrumTheme.canvas.ignoresSafeArea())
                        .offset(x: dragOffset)
                        .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 24, x: -8, y: 0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                        .zIndex(1)

                    leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
                        .zIndex(2)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(isPresented)
        .animation(MegrumSlidePresentationMetrics.animation, value: isPresented)
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                resetDismissDrag()
            }
        }
    }

    private func backSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard isTrackingDismissDrag
                        || MegrumSlideBackSwipeResolver.interactiveOffset(
                            translation: value.translation,
                            screenWidth: screenWidth
                        ) != nil
                else {
                    return
                }
                isTrackingDismissDrag = true
                updateDragOffset(max(0, min(value.translation.width, screenWidth)))
            }
            .onEnded { value in
                guard isTrackingDismissDrag else {
                    return
                }
                if MegrumSlideBackSwipeResolver.shouldDismiss(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    screenWidth: screenWidth
                ) {
                    dismissPresentation()
                } else {
                    resetDismissDrag(animated: true)
                }
            }
    }

    private func leadingEdgeSwipeCaptureArea(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        Color.black.opacity(0.001)
            .frame(width: MegrumSlidePresentationMetrics.leadingEdgeCaptureWidth, height: screenHeight)
            .contentShape(Rectangle())
            .gesture(backSwipeGesture(screenWidth: screenWidth), including: .gesture)
    }

    private func dismissPresentation() {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            isPresented = false
        }
    }

    private func updateDragOffset(_ offset: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dragOffset = offset
        }
    }

    private func resetDismissDrag(animated: Bool = false) {
        isTrackingDismissDrag = false
        guard dragOffset != 0 else {
            return
        }
        if animated {
            withAnimation(MegrumSlidePresentationMetrics.animation) {
                dragOffset = 0
            }
        } else {
            updateDragOffset(0)
        }
    }
}

struct MegrumSlideItemPresentationOverlay<Item: Identifiable, PresentedContent: View>: View {
    @Binding var item: Item?
    var content: (_ item: Item, _ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent

    @State private var dragOffset: CGFloat = 0
    @State private var isTrackingDismissDrag = false

    var body: some View {
        GeometryReader { proxy in
            if let item {
                ZStack(alignment: .leading) {
                    content(item, dismissPresentation)
                        .environment(\.megrumBackSwipeHandledBySlidePresentation, true)
                        .environment(
                            \.megrumSlidePresentationDismiss,
                             MegrumSlidePresentationDismissAction(action: dismissPresentation)
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .background(MegrumTheme.canvas.ignoresSafeArea())
                        .offset(x: dragOffset)
                        .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 24, x: -8, y: 0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                        .zIndex(1)

                    leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
                        .zIndex(2)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(item != nil)
        .animation(MegrumSlidePresentationMetrics.animation, value: item?.id)
        .onChange(of: item?.id) { _, newValue in
            if newValue != nil {
                resetDismissDrag()
            }
        }
    }

    private func backSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard isTrackingDismissDrag
                        || MegrumSlideBackSwipeResolver.interactiveOffset(
                            translation: value.translation,
                            screenWidth: screenWidth
                        ) != nil
                else {
                    return
                }
                isTrackingDismissDrag = true
                updateDragOffset(max(0, min(value.translation.width, screenWidth)))
            }
            .onEnded { value in
                guard isTrackingDismissDrag else {
                    return
                }
                if MegrumSlideBackSwipeResolver.shouldDismiss(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    screenWidth: screenWidth
                ) {
                    dismissPresentation()
                } else {
                    resetDismissDrag(animated: true)
                }
            }
    }

    private func leadingEdgeSwipeCaptureArea(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        Color.black.opacity(0.001)
            .frame(width: MegrumSlidePresentationMetrics.leadingEdgeCaptureWidth, height: screenHeight)
            .contentShape(Rectangle())
            .gesture(backSwipeGesture(screenWidth: screenWidth), including: .gesture)
    }

    private func dismissPresentation() {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            item = nil
        }
    }

    private func updateDragOffset(_ offset: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dragOffset = offset
        }
    }

    private func resetDismissDrag(animated: Bool = false) {
        isTrackingDismissDrag = false
        guard dragOffset != 0 else {
            return
        }
        if animated {
            withAnimation(MegrumSlidePresentationMetrics.animation) {
                dragOffset = 0
            }
        } else {
            updateDragOffset(0)
        }
    }
}

extension View {
    func megrumSlidePresentation<PresentedContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping (_ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent
    ) -> some View {
        overlay {
            MegrumSlideBoolPresentationOverlay(isPresented: isPresented, content: content)
        }
    }

    func megrumSlideItemPresentation<Item: Identifiable, PresentedContent: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (_ item: Item, _ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent
    ) -> some View {
        overlay {
            MegrumSlideItemPresentationOverlay(item: item, content: content)
        }
    }
}
