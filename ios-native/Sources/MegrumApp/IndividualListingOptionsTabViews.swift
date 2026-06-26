import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingEditorTabs: View {
    @Binding var selection: IndividualListingOptionKind

    var body: some View {
        HStack(spacing: 0) {
            ForEach(IndividualListingOptionKind.allCases) { kind in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        selection = kind
                    }
                } label: {
                    Text(kind.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(selection == kind ? .white : MegrumTheme.ink.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            if selection == kind {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(MegrumTheme.lavender)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

struct IndividualListingWishTab: View {
    var wishes: [WishItem]
    var selectedIDs: Set<UUID>
    @Binding var filter: IndividualListingSelectionFilter
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    var onToggle: (WishItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            IndividualListingSelectionSearchAndFilterBar(
                filter: $filter,
                searchPlaceholder: "Wishを検索",
                groups: availableGroups,
                goodsTypes: availableGoodsTypes,
                tagNames: availableTagNames
            )

            if filteredWishes.isEmpty {
                IndividualListingSelectionEmptyMessage(filterIsActive: filter.isActive)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredWishes) { item in
                        Button {
                            onToggle(item)
                        } label: {
                            ListingSelectableImageTile(
                                imageURL: item.imageURL,
                                title: item.title,
                                isSelected: selectedIDs.contains(item.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.title)を候補に選択")
                        .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var filteredWishes: [WishItem] {
        wishes.filter(filter.matches)
    }

    private var availableGroups: [OshiGroup] {
        IndividualListingSelectionFilterChoices.groups(wishes: wishes, allGroups: groups)
    }

    private var availableGoodsTypes: [GoodsType] {
        IndividualListingSelectionFilterChoices.goodsTypes(wishes: wishes, allGoodsTypes: goodsTypes)
    }

    private var availableTagNames: [String] {
        IndividualListingSelectionFilterChoices.tagNames(wishes: wishes, filter: filter)
    }
}
