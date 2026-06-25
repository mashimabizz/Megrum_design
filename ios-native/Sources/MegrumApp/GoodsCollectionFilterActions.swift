import SwiftUI

extension GoodsCollectionScreen {
    func resetFilters() {
        selectedGroupID = nil
        selectedGoodsTypeID = nil
        selectedTagNames = []
    }

    func reconcileSelectedTags() {
        let available = Set(availableTagNames)
        selectedTagNames = selectedTagNames.intersection(available)
    }

    func reconcileSelectedFilters() {
        if let selectedGroupID,
           appState?.isLoadingOshiGroups != true,
           !availableGroups.contains(where: { $0.id == selectedGroupID }) {
            self.selectedGroupID = nil
        }
        if let selectedGoodsTypeID,
           appState?.isLoadingGoodsTypes != true,
           !availableGoodsTypes.contains(where: { $0.id == selectedGoodsTypeID }) {
            self.selectedGoodsTypeID = nil
        }
        reconcileSelectedTags()
    }
}
