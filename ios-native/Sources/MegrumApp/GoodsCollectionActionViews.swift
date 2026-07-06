import MegrumCore
import SwiftUI

struct GoodsCollectionFloatingControls: View {
    var showsAddButton: Bool
    var addButtonLabel: String
    var addButtonHint: String
    var tutorialAnchorID: TutorialAnchorID? = nil
    var isSelectionMode: Bool
    var quickActionItem: GoodsItem?
    var quickActionHeader: GoodsQuickActionHeaderPresentation?
    var quickActions: [GoodsQuickActionKind]
    var selectedCount: Int
    var onAdd: () -> Void
    var onDismissQuickAction: () -> Void
    var onQuickAction: (GoodsQuickActionKind) -> Void
    var onBulkTag: () -> Void
    var onBulkShare: () -> Void
    var onBulkDelete: () -> Void
    var onCancelSelection: () -> Void

    var body: some View {
        if showsAddButton && !isSelectionMode && quickActionItem == nil {
            AddGoodsButton(accessibilityLabel: addButtonLabel, accessibilityHint: addButtonHint, action: onAdd)
                .tutorialAnchor(ifPresent: tutorialAnchorID)
                .padding(.leading, FloatingActionLayoutMetrics.leadingPadding)
                .padding(.bottom, FloatingActionLayoutMetrics.addButtonBottomPadding)
        }

        if let quickActionItem {
            GoodsQuickActionBackdrop(onDismiss: onDismissQuickAction)
                .transition(.opacity)
            GoodsCollectionQuickActionPanel(
                item: quickActionItem,
                headerPresentation: quickActionHeader,
                actions: quickActions,
                onAction: onQuickAction
            )
            .padding(.horizontal, GoodsSelectionFooterMetrics.horizontalPadding)
            .padding(.bottom, FloatingActionLayoutMetrics.contentBottomPadding)
            .transition(
                .scale(
                    scale: GoodsQuickActionPresentationMetrics.panelTransitionScale,
                    anchor: .bottom
                )
                .combined(with: .opacity)
            )
        }

        if isSelectionMode {
            GoodsSelectionFooter(
                selectedCount: selectedCount,
                onTag: onBulkTag,
                onShare: onBulkShare,
                onDelete: onBulkDelete,
                onCancel: onCancelSelection
            )
            .padding(.horizontal, GoodsSelectionFooterMetrics.horizontalPadding)
            .padding(.bottom, GoodsSelectionFooterMetrics.bottomPadding)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
