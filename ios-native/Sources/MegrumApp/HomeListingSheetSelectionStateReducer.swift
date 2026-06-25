import Foundation
import MegrumCore

struct HomeListingSheetSelectionState: Equatable, Sendable {
    var selectedWantedIndices: Set<Int> = []
    var selectedOfferIndices: Set<Int> = []
    var selectedReceiveIndices: Set<Int> = []
    var cashAmountText = ""
}

enum HomeListingSheetSelectionStateReducer {
    static func preparingInitialSelection(
        itemCount: Int,
        logic: ListingLogic
    ) -> HomeListingSheetSelectionState {
        HomeListingSheetSelectionState(
            selectedWantedIndices: HomeListingSelectionPolicy.initialWantedIndices(
                itemCount: itemCount,
                logic: logic
            )
        )
    }

    static func resetting(
        itemCount: Int,
        logic: ListingLogic
    ) -> HomeListingSheetSelectionState {
        preparingInitialSelection(itemCount: itemCount, logic: logic)
    }

    static func togglingWanted(
        at index: Int,
        in state: HomeListingSheetSelectionState,
        itemCount: Int,
        logic: ListingLogic
    ) -> HomeListingSheetSelectionState {
        let selectedWantedIndices = HomeListingSelectionPolicy.wantedIndices(
            afterTapping: index,
            current: state.selectedWantedIndices,
            itemCount: itemCount,
            logic: logic
        )
        let cashAmountText = selectedWantedIndices.isEmpty ? "" : state.cashAmountText
        return HomeListingSheetSelectionState(
            selectedWantedIndices: selectedWantedIndices,
            selectedOfferIndices: [],
            selectedReceiveIndices: state.selectedReceiveIndices,
            cashAmountText: cashAmountText
        )
    }

    static func togglingOffer(
        at index: Int,
        in state: HomeListingSheetSelectionState,
        itemCount: Int,
        logic: ListingLogic
    ) -> HomeListingSheetSelectionState {
        var next = state
        next.selectedOfferIndices = HomeListingSelectionPolicy.offerIndices(
            afterTapping: index,
            current: state.selectedOfferIndices,
            itemCount: itemCount,
            logic: logic
        )
        return next
    }

    static func togglingReceive(
        at index: Int,
        in state: HomeListingSheetSelectionState,
        itemCount: Int,
        logic: ListingLogic
    ) -> HomeListingSheetSelectionState {
        var next = state
        next.selectedReceiveIndices = HomeListingSelectionPolicy.offerIndices(
            afterTapping: index,
            current: state.selectedReceiveIndices,
            itemCount: itemCount,
            logic: logic
        )
        return next
    }
}
