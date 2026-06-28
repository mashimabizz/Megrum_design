import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDetailSlidePresentationOverlay: View {
    @Binding var detailRoute: TradeDetailRoute?
    @ObservedObject var appState: MegrumAppState
    var proposals: [TradeProposal]

    @State private var visibleRoute: TradeDetailRoute?
    @State private var isDetailPresented = false
    @State private var dragOffset: CGFloat = 0
    @State private var isTrackingDismissDrag = false
    @State private var transitionToken = UUID()

    var body: some View {
        GeometryReader { proxy in
            if let visibleRoute {
                ZStack(alignment: .leading) {
                    detailView(for: visibleRoute)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .background(MegrumTheme.canvas.ignoresSafeArea())
                        .offset(x: TradeDetailSlidePresentationResolver.contentOffset(
                            isPresented: isDetailPresented,
                            dragOffset: dragOffset,
                            screenWidth: proxy.size.width
                        ))
                        .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 24, x: -8, y: 0)
                        .contentShape(Rectangle())
                        .simultaneousGesture(backSwipeGesture(screenWidth: proxy.size.width), including: .gesture)
                        .zIndex(1)

                    if isDetailPresented {
                        leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
                            .zIndex(2)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(visibleRoute != nil)
        .onAppear {
            if let detailRoute, visibleRoute == nil {
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
            beginDismissal(clearsRoute: true)
        } else {
            resetDismissDrag(animated: true)
        }
    }

    private func dismissDetail() {
        beginDismissal(clearsRoute: true)
    }

    private func presentDetail(_ route: TradeDetailRoute) {
        let token = UUID()
        transitionToken = token
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            visibleRoute = route
            isDetailPresented = false
            dragOffset = 0
            isTrackingDismissDrag = false
        }
        Task { @MainActor in
            await Task.yield()
            guard transitionToken == token,
                  visibleRoute == route,
                  detailRoute == route else {
                return
            }
            withAnimation(TradeDetailSlidePresentationMetrics.animation) {
                isDetailPresented = true
            }
        }
    }

    private func beginDismissal(clearsRoute: Bool) {
        guard visibleRoute != nil else {
            resetDismissDrag()
            return
        }
        let token = UUID()
        transitionToken = token
        isTrackingDismissDrag = false
        withAnimation(TradeDetailSlidePresentationMetrics.animation) {
            isDetailPresented = false
        }
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: TradeDetailSlidePresentationMetrics.presentationSettledDelayNanoseconds)
            } catch {
                return
            }
            guard transitionToken == token else {
                return
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                visibleRoute = nil
                dragOffset = 0
                if clearsRoute {
                    detailRoute = nil
                }
            }
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
