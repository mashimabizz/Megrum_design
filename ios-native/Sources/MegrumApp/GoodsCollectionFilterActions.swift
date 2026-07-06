import SwiftUI

extension GoodsCollectionScreen {
    func resetFilters() {
        selectedGroupIDs = []
        selectedMemberIDs = []
        selectedGoodsTypeIDs = []
        selectedTagNames = []
    }

    func reconcileSelectedTags() {
        let available = Set(availableTagNames)
        selectedTagNames = selectedTagNames.intersection(available)
    }

    func reconcileSelectedFilters() {
        if appState?.isLoadingOshiGroups != true {
            let availableGroupIDs = Set(availableGroups.map(\.id))
            let nextGroupIDs = selectedGroupIDs.intersection(availableGroupIDs)
            if nextGroupIDs != selectedGroupIDs {
                selectedGroupIDs = nextGroupIDs
            }
        }
        let availableMemberIDs = Set(
            GoodsCollectionFilterChoices.members(items: filterBaseItems, selectedGroupIDs: selectedGroupIDs).map(\.id)
        )
        let nextMemberIDs = selectedMemberIDs.intersection(availableMemberIDs)
        if nextMemberIDs != selectedMemberIDs {
            selectedMemberIDs = nextMemberIDs
        }
        if appState?.isLoadingGoodsTypes != true {
            let availableGoodsTypeIDs = Set(availableGoodsTypes.map(\.id))
            let nextGoodsTypeIDs = selectedGoodsTypeIDs.intersection(availableGoodsTypeIDs)
            if nextGoodsTypeIDs != selectedGoodsTypeIDs {
                selectedGoodsTypeIDs = nextGoodsTypeIDs
            }
        }
        reconcileSelectedTags()
    }
}
