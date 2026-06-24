import MegrumCore
import MegrumDesign
import SwiftUI

struct EmptyCollectionMessage: View {
    var title: String
    var systemImage: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
        } description: {
            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        } actions: {
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.lavender)
            }
        }
        .foregroundStyle(MegrumTheme.muted)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        }
    }
}

struct CollectionGridSkeleton: View {
    var columns: Int

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: GoodsGridLayout.columnSpacing), count: layout.columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: GoodsGridLayout.rowSpacing) {
            ForEach(0..<layout.skeletonTileCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
                        .fill(MegrumTheme.lavender.opacity(0.12))
                        .aspectRatio(GoodsGridLayout.tileAspectRatio, contentMode: .fit)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(MegrumTheme.lavender.opacity(0.12))
                        .frame(height: 13)
                }
                .redacted(reason: .placeholder)
            }
        }
        .accessibilityLabel("グッズを読み込み中")
    }
}

struct GoodsCollectionResultsArea: View {
    var isShowingLoadingState: Bool
    var filteredItems: [GoodsItem]
    var columns: Int
    var emptyMessageTitle: String
    var emptyMessageSystemImage: String
    var emptyMessageDetail: String
    var emptyMessageActionTitle: String?
    var emptyMessageAction: (() -> Void)?
    var entryKind: GoodsEntryKind
    var viewerID: UUID?
    var busyItemID: UUID?
    var isSelectionMode: Bool
    var selectedItemIDs: Set<UUID>
    var onOpenItem: ((GoodsItem) -> Void)?
    var onCreateIndividualListing: ((GoodsItem) -> Void)?
    var onEditItem: ((GoodsItem) -> Void)?
    var onHideItem: ((GoodsItem) -> Void)?
    var onDeleteItem: ((GoodsItem) -> Void)?
    var onBeginSelection: ((GoodsItem) -> Void)?
    var onToggleSelection: ((GoodsItem) -> Void)?
    var adPlacement: AdPlacement?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()

    var body: some View {
        if isShowingLoadingState {
            CollectionLoadingNotice()
            CollectionGridSkeleton(columns: columns)
        } else if filteredItems.isEmpty {
            EmptyCollectionMessage(
                title: emptyMessageTitle,
                systemImage: emptyMessageSystemImage,
                message: emptyMessageDetail,
                actionTitle: emptyMessageActionTitle,
                action: emptyMessageAction
            )
        } else {
            GoodsGrid(
                items: filteredItems,
                columns: columns,
                context: GoodsGridContext(entryKind: entryKind),
                viewerID: viewerID,
                onOpenItem: onOpenItem,
                onCreateIndividualListing: onCreateIndividualListing,
                onEditItem: onEditItem,
                onHideItem: onHideItem,
                onDeleteItem: onDeleteItem,
                busyItemID: busyItemID,
                isSelectionMode: isSelectionMode,
                selectedItemIDs: selectedItemIDs,
                onBeginSelection: onBeginSelection,
                onToggleSelection: onToggleSelection
            )
            if let adPlacement {
                AdBannerSlot(
                    placement: adPlacement,
                    displayContext: adDisplayContext
                )
            }
        }
    }
}
