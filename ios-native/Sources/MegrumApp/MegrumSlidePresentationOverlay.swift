import SwiftUI

struct MegrumSlideBoolPresentationOverlay<PresentedContent: View>: View {
    @Binding var isPresented: Bool
    var backSwipeInteractionScope: MegrumSlideBackSwipeInteractionScope
    /// iter1226.422：出現方向。leading は左からスライド（戻るスワイプは無効）。
    var presentationEdge: MegrumSlidePresentationEdge = .trailing
    /// iter1226.422：指追従オープン用。非nilの間はコンテンツをこのオフセットで表示する
    /// （画面幅=閉、0=全開）。ドラッグ元（ホーム等）が更新し、確定/キャンセル後に nil へ戻す。
    var openDragOffset: CGFloat?
    var content: (_ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent

    @State private var dragState = MegrumSlidePresentationDragState()

    init(
        isPresented: Binding<Bool>,
        backSwipeInteractionScope: MegrumSlideBackSwipeInteractionScope = .leadingEdge,
        presentationEdge: MegrumSlidePresentationEdge = .trailing,
        openDragOffset: CGFloat? = nil,
        @ViewBuilder content: @escaping (_ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent
    ) {
        _isPresented = isPresented
        self.backSwipeInteractionScope = backSwipeInteractionScope
        self.presentationEdge = presentationEdge
        self.openDragOffset = openDragOffset
        self.content = content
    }

    private var isMounted: Bool {
        isPresented || openDragOffset != nil
    }

    var body: some View {
        GeometryReader { proxy in
            if isMounted {
                ZStack(alignment: .leading) {
                    presentedContent(screenWidth: proxy.size.width, screenHeight: proxy.size.height)

                    if backSwipeInteractionScope == .leadingEdge, presentationEdge == .trailing {
                        leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
                    }
                }
                .offset(x: openDragOffset ?? 0)
                .transition(MegrumSlidePresentationMetrics.transition(for: presentationEdge))
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

    @ViewBuilder
    private func presentedContent(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        // leading 表示は明示的な閉じる操作のみ（戻るスワイプの方向が矛盾するため無効化）。
        switch presentationEdge == .leading ? .leadingEdge : backSwipeInteractionScope {
        case .leadingEdge:
            content(dismissPresentation)
                .megrumSlidePresentedContent(
                    width: screenWidth,
                    height: screenHeight,
                    dragOffset: dragState.dragOffset,
                    presentationEdge: presentationEdge,
                    dismiss: dismissPresentation
                )
        case .fullScreen:
            content(dismissPresentation)
                .megrumSlidePresentedContent(
                    width: screenWidth,
                    height: screenHeight,
                    dragOffset: dragState.dragOffset,
                    presentationEdge: presentationEdge,
                    dismiss: dismissPresentation
                )
                .simultaneousGesture(backSwipeGesture(screenWidth: screenWidth), including: .gesture)
        }
    }

    private func backSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard dragState.beginTrackingIfNeeded(translation: value.translation, screenWidth: screenWidth) else {
                    return
                }
                updateDragOffset(
                    dragState.clampedDragOffset(translation: value.translation, screenWidth: screenWidth)
                )
            }
            .onEnded { value in
                guard dragState.isTrackingDismissDrag else {
                    return
                }
                if dragState.shouldDismiss(
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
            dragState.dragOffset = offset
        }
    }

    private func resetDismissDrag(animated: Bool = false) {
        dragState.stopTracking()
        guard dragState.dragOffset != 0 else {
            return
        }
        if animated {
            withAnimation(MegrumSlidePresentationMetrics.animation) {
                dragState.resetDragOffset()
            }
        } else {
            updateDragOffset(0)
        }
    }
}

struct MegrumSlideItemPresentationOverlay<Item: Identifiable, PresentedContent: View>: View {
    @Binding var item: Item?
    var backSwipeInteractionScope: MegrumSlideBackSwipeInteractionScope
    var content: (_ item: Item, _ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent

    @State private var dragState = MegrumSlidePresentationDragState()

    init(
        item: Binding<Item?>,
        backSwipeInteractionScope: MegrumSlideBackSwipeInteractionScope = .leadingEdge,
        @ViewBuilder content: @escaping (_ item: Item, _ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent
    ) {
        _item = item
        self.backSwipeInteractionScope = backSwipeInteractionScope
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            if let item {
                ZStack(alignment: .leading) {
                    presentedContent(item, screenWidth: proxy.size.width, screenHeight: proxy.size.height)

                    if backSwipeInteractionScope == .leadingEdge {
                        leadingEdgeSwipeCaptureArea(screenWidth: proxy.size.width, screenHeight: proxy.size.height)
                    }
                }
                .transition(MegrumSlidePresentationMetrics.trailingTransition)
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

    @ViewBuilder
    private func presentedContent(_ item: Item, screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        switch backSwipeInteractionScope {
        case .leadingEdge:
            content(item, dismissPresentation)
                .megrumSlidePresentedContent(
                    width: screenWidth,
                    height: screenHeight,
                    dragOffset: dragState.dragOffset,
                    dismiss: dismissPresentation
                )
        case .fullScreen:
            content(item, dismissPresentation)
                .megrumSlidePresentedContent(
                    width: screenWidth,
                    height: screenHeight,
                    dragOffset: dragState.dragOffset,
                    dismiss: dismissPresentation
                )
                .simultaneousGesture(backSwipeGesture(screenWidth: screenWidth), including: .gesture)
        }
    }

    private func backSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard dragState.beginTrackingIfNeeded(translation: value.translation, screenWidth: screenWidth) else {
                    return
                }
                updateDragOffset(
                    dragState.clampedDragOffset(translation: value.translation, screenWidth: screenWidth)
                )
            }
            .onEnded { value in
                guard dragState.isTrackingDismissDrag else {
                    return
                }
                if dragState.shouldDismiss(
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
            dragState.dragOffset = offset
        }
    }

    private func resetDismissDrag(animated: Bool = false) {
        dragState.stopTracking()
        guard dragState.dragOffset != 0 else {
            return
        }
        if animated {
            withAnimation(MegrumSlidePresentationMetrics.animation) {
                dragState.resetDragOffset()
            }
        } else {
            updateDragOffset(0)
        }
    }
}

extension View {
    func megrumSlidePresentation<PresentedContent: View>(
        isPresented: Binding<Bool>,
        backSwipeInteractionScope: MegrumSlideBackSwipeInteractionScope = .leadingEdge,
        @ViewBuilder content: @escaping (_ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent
    ) -> some View {
        overlay {
            MegrumSlideBoolPresentationOverlay(
                isPresented: isPresented,
                backSwipeInteractionScope: backSwipeInteractionScope,
                content: content
            )
        }
    }

    func megrumSlideItemPresentation<Item: Identifiable, PresentedContent: View>(
        item: Binding<Item?>,
        backSwipeInteractionScope: MegrumSlideBackSwipeInteractionScope = .leadingEdge,
        @ViewBuilder content: @escaping (_ item: Item, _ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent
    ) -> some View {
        overlay {
            MegrumSlideItemPresentationOverlay(
                item: item,
                backSwipeInteractionScope: backSwipeInteractionScope,
                content: content
            )
        }
    }
}

/// めぐりメッセージ一覧のスライド表示ホスト（iter1226.427）。
/// ドラッグ中のオフセットはこのビューだけが観測して再描画するため、
/// TabContentView 全体の再評価（カクつき）を起こさない。
///
/// iter1226.432：コンテンツを閉時も破棄せず画面外へ退避する keep-alive 方式へ。
/// 従来はパン開始の瞬間にビュー全体を構築（カクつき）→ 340ms スケルトン表示
///（毎回「読み込み中」に見える）だったが、ホーム表示後のアイドル時間に
/// 先読み構築しておき、開閉はオフセット移動だけにする。
struct MeguriInboxSlideHost<PresentedContent: View>: View {
    @ObservedObject var model: MeguriInboxOpenDragModel
    @Binding var isPresented: Bool
    @ViewBuilder var content: (_ dismiss: @escaping @MainActor @Sendable () -> Void) -> PresentedContent

    @State private var dragState = MegrumSlidePresentationDragState()
    @State private var isPrewarmed = false

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            // 先読み前にユーザーがスワイプを始めた場合は従来どおりその場で構築する。
            if isPrewarmed || isPresented || model.offset != nil {
                content(dismissPresentation)
                    .megrumSlidePresentedContent(
                        width: screenWidth,
                        height: proxy.size.height,
                        dragOffset: dragState.dragOffset,
                        dismiss: dismissPresentation
                    )
                    .simultaneousGesture(backSwipeGesture(screenWidth: screenWidth), including: .gesture)
                    .offset(
                        x: MeguriInboxSlideHostGeometry.restingOffset(
                            isPresented: isPresented,
                            openDragOffset: model.offset,
                            screenWidth: screenWidth
                        )
                    )
                    .accessibilityHidden(!isPresented)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(isPresented)
        .animation(MegrumSlidePresentationMetrics.animation, value: isPresented)
        .task {
            guard !isPrewarmed else {
                return
            }
            // 起動直後の負荷を避けつつ、最初のスワイプより前に構築を済ませる。
            try? await Task.sleep(nanoseconds: MegrumDeferredContentDelay.idlePrewarm)
            isPrewarmed = true
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                resetDismissDrag()
            }
        }
    }

    private func backSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard dragState.beginTrackingIfNeeded(translation: value.translation, screenWidth: screenWidth) else {
                    return
                }
                updateDragOffset(
                    dragState.clampedDragOffset(translation: value.translation, screenWidth: screenWidth)
                )
            }
            .onEnded { value in
                guard dragState.isTrackingDismissDrag else {
                    return
                }
                if dragState.shouldDismiss(
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

    private func dismissPresentation() {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            isPresented = false
        }
    }

    private func updateDragOffset(_ offset: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dragState.dragOffset = offset
        }
    }

    private func resetDismissDrag(animated: Bool = false) {
        dragState.stopTracking()
        guard dragState.dragOffset != 0 else {
            return
        }
        if animated {
            withAnimation(MegrumSlidePresentationMetrics.animation) {
                dragState.resetDragOffset()
            }
        } else {
            updateDragOffset(0)
        }
    }
}

enum MeguriInboxSlideHostGeometry {
    /// 閉時の退避マージン。presented content の影（radius 24, x:-8）が
    /// 画面右端へ映り込まないよう、画面幅より余分に逃がす。
    static let parkedShadowMargin: CGFloat = 48

    /// keep-alive コンテンツの静止位置。
    /// 指追従中はそのオフセット、開＝0、閉＝画面外（影ぶん余分に退避）。
    static func restingOffset(isPresented: Bool, openDragOffset: CGFloat?, screenWidth: CGFloat) -> CGFloat {
        if let openDragOffset {
            return openDragOffset
        }
        return isPresented ? 0 : screenWidth + parkedShadowMargin
    }
}
