import SwiftUI

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
                        .megrumSlidePresentedContent(
                            width: proxy.size.width,
                            height: proxy.size.height,
                            dragOffset: dragOffset,
                            dismiss: dismissPresentation
                        )

                    leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
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
        MegrumSlideLeadingEdgeSwipeCaptureArea(
            screenHeight: screenHeight,
            gesture: backSwipeGesture(screenWidth: screenWidth)
        )
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
                        .megrumSlidePresentedContent(
                            width: proxy.size.width,
                            height: proxy.size.height,
                            dragOffset: dragOffset,
                            dismiss: dismissPresentation
                        )

                    leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
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
        MegrumSlideLeadingEdgeSwipeCaptureArea(
            screenHeight: screenHeight,
            gesture: backSwipeGesture(screenWidth: screenWidth)
        )
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
