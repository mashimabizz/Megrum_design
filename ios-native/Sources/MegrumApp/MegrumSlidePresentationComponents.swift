import MegrumDesign
import SwiftUI

struct MegrumSlidePresentedContentModifier: ViewModifier {
    var width: CGFloat
    var height: CGFloat
    var dragOffset: CGFloat
    var presentationEdge: MegrumSlidePresentationEdge = .trailing
    var dismiss: @MainActor @Sendable () -> Void

    func body(content: Content) -> some View {
        content
            .environment(\.megrumBackSwipeHandledBySlidePresentation, true)
            .environment(
                \.megrumSlidePresentationDismiss,
                 MegrumSlidePresentationDismissAction(action: dismiss)
            )
            .frame(width: width, height: height)
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .offset(x: dragOffset)
            .shadow(
                color: MegrumTheme.ink.opacity(0.16),
                radius: 24,
                x: presentationEdge == .trailing ? -8 : 8,
                y: 0
            )
            .transition(MegrumSlidePresentationMetrics.transition(for: presentationEdge))
            .zIndex(1)
    }
}

struct MegrumSlideLeadingEdgeSwipeCaptureArea<SwipeGesture: Gesture>: View {
    var screenHeight: CGFloat
    var gesture: SwipeGesture

    var body: some View {
        Color.black.opacity(0.001)
            .frame(width: MegrumSlidePresentationMetrics.leadingEdgeCaptureWidth, height: screenHeight)
            .contentShape(Rectangle())
            .gesture(gesture, including: .gesture)
            .zIndex(2)
    }
}

extension View {
    func megrumSlidePresentedContent(
        width: CGFloat,
        height: CGFloat,
        dragOffset: CGFloat,
        presentationEdge: MegrumSlidePresentationEdge = .trailing,
        dismiss: @escaping @MainActor @Sendable () -> Void
    ) -> some View {
        modifier(
            MegrumSlidePresentedContentModifier(
                width: width,
                height: height,
                dragOffset: dragOffset,
                presentationEdge: presentationEdge,
                dismiss: dismiss
            )
        )
    }
}
