import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDetailSlidePresentationOverlay: View {
    @Binding var detailRoute: TradeDetailRoute?
    @ObservedObject var appState: MegrumAppState
    var proposals: [TradeProposal]

    @State private var presentationState = TradeDetailSlidePresentationState()

    var body: some View {
        GeometryReader { proxy in
            if let visibleRoute = presentationState.visibleRoute {
                ZStack(alignment: .leading) {
                    detailView(for: visibleRoute)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .background(MegrumTheme.canvas.ignoresSafeArea())
                        .offset(x: presentationState.contentOffset(screenWidth: proxy.size.width))
                        .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 24, x: -8, y: 0)
                        .contentShape(Rectangle())
                        .simultaneousGesture(backSwipeGesture(screenWidth: proxy.size.width), including: .gesture)
                        .zIndex(1)

                    if presentationState.isDetailPresented {
                        leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
                            .zIndex(2)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(presentationState.hasVisibleRoute)
        .onAppear {
            if let detailRoute, !presentationState.hasVisibleRoute {
                presentDetail(detailRoute)
            }
        }
        .onChange(of: detailRoute) { _, newValue in
            if let newValue {
                presentDetail(newValue)
            } else {
                beginDismissal(clearsRoute: false)
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
        MegrumDeferredContent {
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
        updateDismissDrag(translation: translation, screenWidth: screenWidth)
    }

    private func handleBackSwipeEnded(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat
    ) {
        let shouldDismiss = presentationState.shouldDismiss(
            translation: translation,
            predictedEndTranslationWidth: predictedEndTranslationWidth,
            screenWidth: screenWidth
        )
        guard presentationState.isTrackingDismissDrag || shouldDismiss else {
            return
        }
        if shouldDismiss {
            beginDismissal(clearsRoute: true)
        } else {
            resetDismissDrag(animated: true)
        }
    }

    private func dismissDetail() {
        beginDismissal(clearsRoute: true)
    }

    private func presentDetail(_ route: TradeDetailRoute) {
        var token = UUID()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            token = presentationState.preparePresentation(route: route)
        }
        Task { @MainActor in
            await Task.yield()
            guard presentationState.canCompletePresentation(
                token: token,
                route: route,
                currentRoute: detailRoute
            ) else {
                return
            }
            withAnimation(TradeDetailSlidePresentationMetrics.animation) {
                presentationState.markPresented()
            }
        }
    }

    private func beginDismissal(clearsRoute: Bool) {
        guard presentationState.hasVisibleRoute else {
            resetDismissDrag()
            return
        }
        guard let token = presentationState.prepareDismissal() else {
            return
        }
        withAnimation(TradeDetailSlidePresentationMetrics.animation) {
            presentationState.markDismissed()
        }
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: TradeDetailSlidePresentationMetrics.presentationSettledDelayNanoseconds)
            } catch {
                return
            }
            guard presentationState.canCompleteDismissal(token: token) else {
                return
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                presentationState.completeDismissal()
                if clearsRoute {
                    detailRoute = nil
                }
            }
        }
    }

    private func updateDismissDrag(translation: CGSize, screenWidth: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            _ = presentationState.beginTrackingDismissDragIfNeeded(
                translation: translation,
                screenWidth: screenWidth
            )
        }
    }

    private func updateDragOffset(_ offset: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            presentationState.setDragOffset(offset)
        }
    }

    private func resetDismissDrag(animated: Bool = false) {
        presentationState.stopTrackingDismissDrag()
        guard presentationState.dragOffset != 0 else {
            return
        }
        if animated {
            withAnimation(TradeDetailSlidePresentationMetrics.animation) {
                presentationState.setDragOffset(0)
            }
        } else {
            updateDragOffset(0)
        }
    }
}
