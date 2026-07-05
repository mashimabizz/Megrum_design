import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingHavesGoodsSelection: View {
    var inventory: [GoodsItem]
    var selectedIDs: Set<UUID>
    @Binding var filter: IndividualListingSelectionFilter
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    var onToggle: (GoodsItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            IndividualListingSelectionSearchAndFilterBar(
                filter: $filter,
                searchPlaceholder: "グッズを検索",
                groups: availableGroups,
                goodsTypes: availableGoodsTypes,
                tagNames: availableTagNames
            )

            if filteredInventory.isEmpty {
                IndividualListingSelectionEmptyMessage(filterIsActive: filter.isActive)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredInventory) { item in
                        Button {
                            onToggle(item)
                        } label: {
                            ListingSquareSelectableImageTile(
                                imageURL: item.imageURL,
                                title: item.title,
                                isSelected: selectedIDs.contains(item.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.title)を譲るものに選択")
                        .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var filteredInventory: [GoodsItem] {
        inventory.filter(filter.matches)
    }

    private var availableGroups: [OshiGroup] {
        IndividualListingSelectionFilterChoices.groups(items: inventory, allGroups: groups)
    }

    private var availableGoodsTypes: [GoodsType] {
        IndividualListingSelectionFilterChoices.goodsTypes(items: inventory, allGoodsTypes: goodsTypes)
    }

    private var availableTagNames: [String] {
        IndividualListingSelectionFilterChoices.tagNames(items: inventory, filter: filter)
    }
}

private struct ListingSquareSelectableImageTile: View {
    var imageURL: URL?
    var title: String
    var isSelected: Bool

    var body: some View {
        ListingGoodsImage(url: imageURL, title: title, cornerRadius: 12)
            .aspectRatio(1, contentMode: .fit)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "checkmark")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(MegrumTheme.lavender, in: Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 2)
                    }
                    .opacity(isSelected ? 1 : 0)
                    .padding(7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            }
    }
}
