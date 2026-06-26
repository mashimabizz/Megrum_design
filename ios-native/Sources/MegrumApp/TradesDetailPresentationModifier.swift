import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TradeDetailSlidePresentationMetrics {
    static let leadingEdgeCaptureWidth: CGFloat = 32
    static let minimumTranslation: CGFloat = 78
    static let minimumPredictedTranslation: CGFloat = 132
    static let horizontalDominance: CGFloat = 1.16
    static let dismissFraction: CGFloat = 0.30
    static let presentationSettledDelayNanoseconds: UInt64 = 420_000_000
    static let animation: Animation = .interactiveSpring(response: 0.32, dampingFraction: 0.88, blendDuration: 0.04)
}

enum TradeDetailSlideBackSwipeResolver {
    static func interactiveOffset(translation: CGSize, screenWidth: CGFloat) -> CGFloat? {
        guard translation.width > 0 else {
            return nil
        }
        let isHorizontal = abs(translation.width) > abs(translation.height) * TradeDetailSlidePresentationMetrics.horizontalDominance
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
        let isLongEnough = offset >= TradeDetailSlidePresentationMetrics.minimumTranslation
            || predictedEndTranslationWidth >= TradeDetailSlidePresentationMetrics.minimumPredictedTranslation
            || offset >= screenWidth * TradeDetailSlidePresentationMetrics.dismissFraction
        return isLongEnough
    }
}

struct TradeDetailSlidePresentationOverlay: View {
    @Binding var detailRoute: TradeDetailRoute?
    @ObservedObject var appState: MegrumAppState
    var proposals: [TradeProposal]

    @State private var dragOffset: CGFloat = 0
    @State private var isTrackingDismissDrag = false

    var body: some View {
        GeometryReader { proxy in
            if let detailRoute {
                ZStack(alignment: .leading) {
                    detailView(for: detailRoute)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .background(MegrumTheme.canvas.ignoresSafeArea())
                        .offset(x: dragOffset)
                        .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 24, x: -8, y: 0)
                        .contentShape(Rectangle())
                        .simultaneousGesture(backSwipeGesture(screenWidth: proxy.size.width), including: .gesture)
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
        .allowsHitTesting(detailRoute != nil)
        .animation(TradeDetailSlidePresentationMetrics.animation, value: detailRoute)
        .onChange(of: detailRoute) { _, newValue in
            if newValue != nil {
                resetDismissDrag()
            }
        }
    }

    private func leadingEdgeSwipeCaptureArea(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        TradeDetailLeadingEdgePanCaptureView(
            hitWidth: TradeDetailSlidePresentationMetrics.leadingEdgeCaptureWidth,
            onChanged: { translation in
                handleBackSwipeChanged(
                    translation: translation,
                    screenWidth: screenWidth
                )
            },
            onEnded: { translation, predictedEndTranslationWidth in
                handleBackSwipeEnded(
                    translation: translation,
                    predictedEndTranslationWidth: predictedEndTranslationWidth,
                    screenWidth: screenWidth
                )
            }
        )
            .frame(
                width: TradeDetailSlidePresentationMetrics.leadingEdgeCaptureWidth,
                height: screenHeight
            )
    }

    @ViewBuilder
    private func detailView(for route: TradeDetailRoute) -> some View {
        NavigationStack {
            if let proposal = proposals.first(where: { $0.id == route.proposalID }) {
                TradeDetailScreen(appState: appState, proposal: proposal)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(action: dismissDetail) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .heavy))
                            }
                            .accessibilityLabel("やりとり一覧に戻る")
                        }
                    }
            } else {
                TradeDetailUnavailableScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる", action: dismissDetail)
                        }
                    }
            }
        }
    }

    private func backSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                handleBackSwipeChanged(
                    translation: value.translation,
                    screenWidth: screenWidth
                )
            }
            .onEnded { value in
                handleBackSwipeEnded(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    screenWidth: screenWidth
                )
            }
    }

    private func handleBackSwipeChanged(translation: CGSize, screenWidth: CGFloat) {
        guard isTrackingDismissDrag
                || TradeDetailSlideBackSwipeResolver.interactiveOffset(
                    translation: translation,
                    screenWidth: screenWidth
                ) != nil
        else {
            return
        }
        isTrackingDismissDrag = true
        updateDragOffset(max(0, min(translation.width, screenWidth)))
    }

    private func handleBackSwipeEnded(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat
    ) {
        let shouldDismiss = TradeDetailSlideBackSwipeResolver.shouldDismiss(
            translation: translation,
            predictedEndTranslationWidth: predictedEndTranslationWidth,
            screenWidth: screenWidth
        )
        guard isTrackingDismissDrag || shouldDismiss else {
            return
        }
        if shouldDismiss {
            dismissDetail()
        } else {
            resetDismissDrag(animated: true)
        }
    }

    private func dismissDetail() {
        withAnimation(TradeDetailSlidePresentationMetrics.animation) {
            detailRoute = nil
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
            withAnimation(TradeDetailSlidePresentationMetrics.animation) {
                dragOffset = 0
            }
        } else {
            updateDragOffset(0)
        }
    }
}

#if canImport(UIKit)
private struct TradeDetailLeadingEdgePanCaptureView: UIViewRepresentable {
    var hitWidth: CGFloat
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize, CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> TradeDetailLeadingEdgePanView {
        let view = TradeDetailLeadingEdgePanView(frame: .zero)
        view.hitWidth = hitWidth
        view.backgroundColor = UIColor.black.withAlphaComponent(0.001)
        view.onWindowChanged = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }

        return view
    }

    func updateUIView(_ uiView: TradeDetailLeadingEdgePanView, context: Context) {
        uiView.hitWidth = hitWidth
        context.coordinator.parent = self
    }

    static func dismantleUIView(_ uiView: TradeDetailLeadingEdgePanView, coordinator: Coordinator) {
        coordinator.detach()
        uiView.onWindowChanged = nil
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: TradeDetailLeadingEdgePanCaptureView
        weak var attachedWindow: UIWindow?
        weak var edgePanGesture: UIPanGestureRecognizer?

        init(parent: TradeDetailLeadingEdgePanCaptureView) {
            self.parent = parent
        }

        func attach(to window: UIWindow?) {
            guard attachedWindow !== window else {
                return
            }
            detach()
            guard let window else {
                return
            }

            let edgePanGesture = UIPanGestureRecognizer(
                target: self,
                action: #selector(handleEdgePan(_:))
            )
            edgePanGesture.maximumNumberOfTouches = 1
            edgePanGesture.cancelsTouchesInView = false
            edgePanGesture.delegate = self
            window.addGestureRecognizer(edgePanGesture)
            attachedWindow = window
            self.edgePanGesture = edgePanGesture
        }

        func detach() {
            if let edgePanGesture,
               let gestureView = edgePanGesture.view {
                gestureView.removeGestureRecognizer(edgePanGesture)
            }
            attachedWindow = nil
            edgePanGesture = nil
        }

        @objc func handleEdgePan(_ gesture: UIPanGestureRecognizer) {
            let translationPoint = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            let translation = CGSize(width: translationPoint.x, height: translationPoint.y)
            switch gesture.state {
            case .began, .changed:
                parent.onChanged(translation)
            case .ended:
                parent.onEnded(
                    translation,
                    projectedTranslationWidth(translation.width, velocityX: velocity.x)
                )
            case .cancelled, .failed:
                parent.onEnded(translation, translation.width)
            default:
                break
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
                  let gestureView = panGesture.view
            else {
                return true
            }

            let location = panGesture.location(in: gestureView)
            guard location.x <= parent.hitWidth else {
                return false
            }

            let velocity = panGesture.velocity(in: gestureView)
            guard velocity.x > 0 else {
                return false
            }

            return abs(velocity.x) >= abs(velocity.y) * 0.75
        }

        private func projectedTranslationWidth(_ translationWidth: CGFloat, velocityX: CGFloat) -> CGFloat {
            translationWidth + velocityX * 0.18
        }
    }
}

private final class TradeDetailLeadingEdgePanView: UIView {
    var hitWidth: CGFloat = 32
    var onWindowChanged: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChanged?(window)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        point.x >= 0 && point.x <= hitWidth
    }
}
#else
private struct TradeDetailLeadingEdgePanCaptureView: View {
    var hitWidth: CGFloat
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize, CGFloat) -> Void

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.001))
    }
}
#endif
