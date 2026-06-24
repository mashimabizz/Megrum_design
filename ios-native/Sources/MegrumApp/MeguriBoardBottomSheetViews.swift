import MegrumCore
import MegrumDesign
import SwiftUI

enum MeguriBoardSheetDetent: Equatable {
    case compact
    case regular
    case expanded

    var isCompact: Bool {
        self == .compact
    }

    var usesExpandedRows: Bool {
        self == .expanded
    }

    func height(in viewportHeight: CGFloat) -> CGFloat {
        MeguriBoardSheetLayout.visibleHeight(for: self, in: viewportHeight)
    }

    func moved(up: Bool) -> Self {
        switch (self, up) {
        case (.compact, true):
            .regular
        case (.regular, true):
            .expanded
        case (.expanded, true):
            .expanded
        case (.expanded, false):
            .regular
        case (.regular, false):
            .compact
        case (.compact, false):
            .compact
        }
    }
}

enum MeguriBoardSheetLayout {
    static func expandedHeight(in viewportHeight: CGFloat) -> CGFloat {
        max(viewportHeight - 8, 1)
    }

    static func visibleHeight(for detent: MeguriBoardSheetDetent, in viewportHeight: CGFloat) -> CGFloat {
        let expanded = expandedHeight(in: viewportHeight)
        switch detent {
        case .compact:
            return min(max(viewportHeight * 0.20, 154), 166)
        case .regular:
            return min(max(viewportHeight * 0.48, 330), expanded)
        case .expanded:
            return expanded
        }
    }

    static func restingOffset(for detent: MeguriBoardSheetDetent, in viewportHeight: CGFloat) -> CGFloat {
        expandedHeight(in: viewportHeight) - visibleHeight(for: detent, in: viewportHeight)
    }

    static func interactiveOffset(
        for detent: MeguriBoardSheetDetent,
        in viewportHeight: CGFloat,
        dragTranslation: CGFloat
    ) -> CGFloat {
        let compactOffset = restingOffset(for: .compact, in: viewportHeight)
        let proposed = restingOffset(for: detent, in: viewportHeight) + dragTranslation
        return min(max(proposed, 0), compactOffset)
    }

    static func targetDetent(
        from detent: MeguriBoardSheetDetent,
        translation: CGFloat,
        predictedTranslation: CGFloat
    ) -> MeguriBoardSheetDetent {
        let movement = abs(predictedTranslation) > abs(translation) ? predictedTranslation : translation
        if movement < -36 {
            return .expanded
        }
        if movement > 36 {
            return .compact
        }
        return detent
    }
}

struct MeguriBoardBottomSheet: View {
    @Binding var detent: MeguriBoardSheetDetent
    var viewportHeight: CGFloat
    var threads: [BoardThread]
    var grooms: [GroomPost]
    var replyCounts: [UUID: Int]
    var isLoading: Bool
    var selectedScope: BoardThread.Audience
    var selectedPrefecture: String
    var onChangeScope: (BoardThread.Audience) -> Void
    var onOpenPrefecture: () -> Void
    var onOpenGroomComposer: () -> Void
    var onOpenThreadComposer: () -> Void
    var onOpenThread: (BoardThread) -> Void

    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MeguriBoardSheetGrabber()
                .gesture(sheetDragGesture)

            MeguriBoardSheetTopSurface(
                groomCount: grooms.count,
                threadCount: threads.count,
                onOpenGroomComposer: onOpenGroomComposer,
                onOpenThreadComposer: onOpenThreadComposer
            )

            VStack(alignment: .leading, spacing: 16) {
                MeguriBoardThreadListState(
                    threads: threads,
                    grooms: grooms,
                    replyCounts: replyCounts,
                    isLoading: isLoading,
                    onOpenThread: onOpenThread
                )
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .frame(height: MeguriBoardSheetLayout.expandedHeight(in: viewportHeight), alignment: .top)
        .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 18, y: -8)
        .offset(y: MeguriBoardSheetLayout.interactiveOffset(
            for: detent,
            in: viewportHeight,
            dragTranslation: dragTranslation
        ))
        .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.88), value: detent)
        .ignoresSafeArea(edges: .bottom)
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                detent = MeguriBoardSheetLayout.targetDetent(
                    from: detent,
                    translation: value.translation.height,
                    predictedTranslation: value.predictedEndTranslation.height
                )
            }
    }
}
