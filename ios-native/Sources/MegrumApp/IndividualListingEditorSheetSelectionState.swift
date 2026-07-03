import MegrumCore
import SwiftUI

extension IndividualListingEditorSheet {
    func toggleHave(_ item: GoodsItem) {
        draft.toggleHave(item.id, maxQuantity: draft.maxHaveQuantity(for: item))
    }

    func toggleWish(_ item: WishItem) {
        draft.toggleWish(item.id)
    }

    func selectAllVisibleItems() {
        switch presentationState.step {
        case .haves where presentationState.havesTab == .goods:
            if allVisibleHavesAreSelected {
                draft.deselectHaves(visibleHaveSelectionItems)
            } else {
                draft.selectAllHaves(visibleHaveSelectionItems)
            }
        case .options where draft.optionKind == .wish:
            if allVisibleWishesAreSelected {
                draft.deselectWishes(visibleWishSelectionItems)
            } else {
                draft.selectAllWishes(visibleWishSelectionItems)
            }
        default:
            break
        }
    }

    var visibleHaveSelectionItems: [GoodsItem] {
        appState.inventory.filter(presentationState.haveSelectionFilter.matches)
    }

    var visibleWishSelectionItems: [WishItem] {
        appState.wishes.filter(presentationState.wishSelectionFilter.matches)
    }

    var showsSelectAllVisibleButton: Bool {
        switch presentationState.step {
        case .haves:
            return presentationState.havesTab == .goods
        case .options:
            return draft.optionKind == .wish
        case .exchange:
            return false
        }
    }

    var canSelectAllVisible: Bool {
        switch presentationState.step {
        case .haves where presentationState.havesTab == .goods:
            return !visibleHaveSelectionItems.isEmpty
        case .options where draft.optionKind == .wish:
            return !visibleWishSelectionItems.isEmpty
        default:
            return false
        }
    }

    var selectAllVisibleButtonTitle: String {
        switch presentationState.step {
        case .haves where presentationState.havesTab == .goods:
            return allVisibleHavesAreSelected
                ? IndividualListingEditorBottomBarPresentation.deselectAllVisibleTitle
                : IndividualListingEditorBottomBarPresentation.selectAllVisibleTitle
        case .options where draft.optionKind == .wish:
            return allVisibleWishesAreSelected
                ? IndividualListingEditorBottomBarPresentation.deselectAllVisibleTitle
                : IndividualListingEditorBottomBarPresentation.selectAllVisibleTitle
        default:
            return IndividualListingEditorBottomBarPresentation.selectAllVisibleTitle
        }
    }

    var allVisibleHavesAreSelected: Bool {
        !visibleHaveSelectionItems.isEmpty
            && visibleHaveSelectionItems.allSatisfy { draft.selectedHaveIDs.contains($0.id) }
    }

    var allVisibleWishesAreSelected: Bool {
        !visibleWishSelectionItems.isEmpty
            && visibleWishSelectionItems.allSatisfy { draft.selectedWishIDs.contains($0.id) }
    }

    var haveLogicBinding: Binding<ListingLogic> {
        Binding(
            get: { draft.haveLogic },
            set: { draft.setHaveLogic($0) }
        )
    }

    var wishLogicBinding: Binding<ListingLogic> {
        Binding(
            get: { draft.wishLogic },
            set: { draft.setWishLogic($0) }
        )
    }

    var haveMinimumCountBinding: Binding<Int> {
        Binding(
            get: { draft.resolvedHaveMinimumCount },
            set: { draft.setHaveMinimumCount($0) }
        )
    }

    var wishMinimumCountBinding: Binding<Int> {
        Binding(
            get: { draft.resolvedWishMinimumCount },
            set: { draft.setWishMinimumCount($0) }
        )
    }
}
