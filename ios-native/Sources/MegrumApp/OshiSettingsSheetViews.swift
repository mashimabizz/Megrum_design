import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiMasterSelectSheet: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var selectedGroupIDs: Set<UUID>
    var charactersByGroupID: [UUID: [OshiCharacter]]
    var allowsMultipleSelection = false
    var onClose: () -> Void
    var onRequest: (String?) -> Void
    var onSelect: (OshiGroup) -> Void
    var onRegisterSelected: (([OshiGroup]) -> Void)?

    @State private var searchText = ""
    @State private var selectedGenreID: UUID?
    @State private var pendingSelectedGroupIDs: Set<UUID> = []

    private var categoryOptions: [OshiCategoryOption] {
        [OshiCategoryOption(id: nil, title: "すべて")] + genres.map { OshiCategoryOption(id: $0.id, title: $0.name) }
    }

    private var filteredGroups: [OshiGroup] {
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return groups.filter { group in
            if let selectedGenreID, group.genreID != selectedGenreID {
                return false
            }
            guard !normalized.isEmpty else {
                return true
            }
            return ([group.name] + group.aliases).contains { $0.localizedCaseInsensitiveContains(normalized) }
        }
    }

    private var pendingSelectedGroups: [OshiGroup] {
        OshiMasterSelectionReducer.selectedGroups(from: groups, selectedIDs: pendingSelectedGroupIDs)
    }

    private var scrollBottomPadding: CGFloat {
        OshiMasterSelectLayoutMetrics.bottomContentPadding
            + (pendingSelectedGroupIDs.isEmpty ? 0 : OshiMasterSelectLayoutMetrics.selectedActionExtraPadding)
    }

    var body: some View {
        VStack(spacing: 0) {
            OshiMasterSelectHeader(
                onRequest: { onRequest(searchText.nilIfBlank) },
                onClose: onClose
            )

            ScrollView {
                OshiMasterCandidateGrid(
                    groups: filteredGroups,
                    selectedGroupIDs: selectedGroupIDs,
                    isSelected: isSelected,
                    onSelect: handleCandidateTap
                )
                .padding(.bottom, scrollBottomPadding)
            }
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            OshiMasterSelectFooter(
                categoryOptions: categoryOptions,
                selectedGenreID: $selectedGenreID,
                searchText: $searchText,
                allowsMultipleSelection: allowsMultipleSelection,
                pendingSelectionCount: pendingSelectedGroupIDs.count,
                onRegister: registerPendingSelection
            )
        }
        .onAppear(perform: resetPendingSelection)
        .onChange(of: selectedGroupIDs) { _, _ in
            pendingSelectedGroupIDs = pendingSelectedGroupIDs.subtracting(selectedGroupIDs)
        }
        .animation(.snappy(duration: 0.18), value: pendingSelectedGroupIDs)
    }

    private func isSelected(_ group: OshiGroup) -> Bool {
        selectedGroupIDs.contains(group.id) || pendingSelectedGroupIDs.contains(group.id)
    }

    private func handleCandidateTap(_ group: OshiGroup) {
        guard allowsMultipleSelection else {
            onSelect(group)
            return
        }
        pendingSelectedGroupIDs = OshiMasterSelectionReducer.toggling(
            groupID: group.id,
            selectedIDs: pendingSelectedGroupIDs,
            lockedIDs: selectedGroupIDs
        )
    }

    private func registerPendingSelection() {
        let selectedGroups = pendingSelectedGroups
        guard !selectedGroups.isEmpty else {
            return
        }
        pendingSelectedGroupIDs = []
        if let onRegisterSelected {
            onRegisterSelected(selectedGroups)
        } else {
            selectedGroups.forEach(onSelect)
        }
    }

    private func resetPendingSelection() {
        pendingSelectedGroupIDs = []
    }
}
