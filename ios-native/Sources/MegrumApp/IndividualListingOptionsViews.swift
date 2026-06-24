import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingOptionsStep: View {
    @Binding var optionKind: IndividualListingOptionKind
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var selectedWishIDs: Set<UUID>
    @Binding var selectedWishLogic: ListingLogic
    @Binding var wishFilter: IndividualListingSelectionFilter
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    @Binding var selectedConditionGroupID: UUID?
    @Binding var selectedConditionMemberIDs: Set<UUID>
    @Binding var excludesSelectedConditionMembers: Bool
    @Binding var selectedConditionGoodsTypeID: UUID?
    @Binding var selectedConditionTagNames: [String]
    @Binding var conditionQuantity: Int
    @Binding var cashPricingMode: IndividualListingCashPricingMode
    @Binding var cashAmount: Int
    var onToggleWish: (WishItem) -> Void
    var onToggleConditionMember: (UUID) -> Void
    var onLoadCharacters: (OshiGroup) -> Void
    var onCreateOshiRequest: (OshiRequestSheetPayload) -> Void

    @State private var showsOshiMasterSheet = false
    @State private var requestSheet: OshiRequestSheetState?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IndividualListingStepTitle(step: .options)

            IndividualListingEditorTabs(selection: $optionKind)

            switch optionKind {
            case .wish:
                IndividualListingWishTab(
                    wishes: wishes,
                    selectedIDs: selectedWishIDs,
                    filter: $wishFilter,
                    groups: groups,
                    goodsTypes: goodsTypes,
                    onToggle: onToggleWish
                )
            case .condition:
                IndividualListingConditionTab(
                    inventory: inventory,
                    wishes: wishes,
                    groups: groups,
                    characters: characters,
                    goodsTypes: goodsTypes,
                    selectedGroupID: $selectedConditionGroupID,
                    selectedMemberIDs: $selectedConditionMemberIDs,
                    excludesSelectedMembers: $excludesSelectedConditionMembers,
                    selectedGoodsTypeID: $selectedConditionGoodsTypeID,
                    selectedTagNames: $selectedConditionTagNames,
                    quantity: $conditionQuantity,
                    onShowOshiPicker: { showsOshiMasterSheet = true },
                    onToggleMember: onToggleConditionMember
                )
            case .cash:
                IndividualListingCashTab(
                    pricingMode: $cashPricingMode,
                    amount: $cashAmount
                )
            }
        }
        .sheet(isPresented: $showsOshiMasterSheet) {
            OshiMasterSelectSheet(
                genres: genres,
                groups: groups,
                selectedGroupIDs: selectedConditionGroupID.map { Set([$0]) } ?? [],
                charactersByGroupID: selectedConditionGroupID.map { [$0: characters] } ?? [:],
                onClose: { showsOshiMasterSheet = false },
                onRequest: { query in
                    showsOshiMasterSheet = false
                    requestSheet = .oshi(initialName: query)
                },
                onSelect: { group in
                    selectedConditionGroupID = group.id
                    showsOshiMasterSheet = false
                    onLoadCharacters(group)
                }
            )
        }
        .sheet(item: $requestSheet) { state in
            OshiRequestSheet(
                state: state,
                genres: genres,
                onClose: { requestSheet = nil },
                onSubmit: { payload in
                    onCreateOshiRequest(payload)
                    requestSheet = nil
                }
            )
        }
    }
}

private struct IndividualListingEditorTabs: View {
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

private struct IndividualListingWishTab: View {
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
