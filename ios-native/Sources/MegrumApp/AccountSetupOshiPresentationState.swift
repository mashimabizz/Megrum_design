import Foundation
import MegrumCore

struct AccountSetupOshiPresentationState {
    var selectedInputs: [AccountSetupOshiInput]
    var filteredGroups: [OshiGroup]
    var categoryOptions: [OshiCategoryOption]
    var selectedMemberGroups: [OshiGroup]
    var selectedMemberTargets: [OnboardingOshiMemberTarget]

    init(
        groups: [OshiGroup],
        genres: [OshiGenre],
        selectedGenreID: UUID?,
        searchText: String,
        selectedGroups: [OshiGroup],
        selectedDrafts: [OnboardingOshiDraft]
    ) {
        selectedInputs = OnboardingOshiSelectionLogic.accountSetupInputs(from: selectedDrafts)
        filteredGroups = Self.filteredGroups(
            groups,
            selectedGenreID: selectedGenreID,
            searchText: searchText
        )
        categoryOptions = Self.categoryOptions(from: genres)
        selectedMemberGroups = selectedGroups.filter(\.supportsMemberSelection)
        selectedMemberTargets = selectedMemberGroups.map(OnboardingOshiMemberTarget.init(group:))
            + OnboardingOshiSelectionLogic.requestedMemberTargets(from: selectedDrafts)
    }

    private static func filteredGroups(
        _ groups: [OshiGroup],
        selectedGenreID: UUID?,
        searchText: String
    ) -> [OshiGroup] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return groups.filter { group in
            if let selectedGenreID, group.genreID != selectedGenreID {
                return false
            }
            guard !normalizedSearch.isEmpty else {
                return true
            }
            return ([group.name] + group.aliases).contains { candidate in
                candidate.localizedCaseInsensitiveContains(normalizedSearch)
            }
        }
    }

    private static func categoryOptions(from genres: [OshiGenre]) -> [OshiCategoryOption] {
        [OshiCategoryOption(id: nil, title: "すべて")] + genres.map {
            OshiCategoryOption(id: $0.id, title: $0.name)
        }
    }
}
