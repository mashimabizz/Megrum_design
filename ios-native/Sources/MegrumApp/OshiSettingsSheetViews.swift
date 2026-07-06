import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiMasterSelectSheet: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var selectedGroupIDs: Set<UUID>
    var charactersByGroupID: [UUID: [OshiCharacter]]
    /// 自分が設定済みの推し（L1）のグループID。空でなければ「自分の推し」カテゴリを先頭に出し、既定にする。
    var myOshiGroupIDs: Set<UUID> = []
    /// 検索文字列からL2名ヒットの親L1 ID集合を返す（未指定ならL1名のみで検索）。
    var onSearchCharacterGroups: ((String) async -> Set<UUID>)? = nil
    var allowsMultipleSelection = false
    var showsRequestButton = true
    var onClose: () -> Void
    var onRequest: (String?) -> Void
    var onSelect: (OshiGroup) -> Void
    var onRegisterSelected: (([OshiGroup]) -> Void)?

    @State private var sheetState = OshiMasterSelectSheetState()
    @State private var characterHitGroupIDs: Set<UUID> = []

    private var showsMyOshiCategory: Bool {
        groups.contains { myOshiGroupIDs.contains($0.id) }
    }

    private var categoryOptions: [OshiCategoryOption] {
        var options: [OshiCategoryOption] = []
        if showsMyOshiCategory {
            options.append(OshiCategoryOption(id: OshiMasterSelectSheetState.myOshiCategoryID, title: "自分の推し"))
        }
        options.append(OshiCategoryOption(id: nil, title: "すべて"))
        options += genres.map { OshiCategoryOption(id: $0.id, title: $0.name) }
        return options
    }

    private var filteredGroups: [OshiGroup] {
        sheetState.filteredGroups(
            from: groups,
            myOshiGroupIDs: myOshiGroupIDs,
            characterHitGroupIDs: characterHitGroupIDs
        )
    }

    private var pendingSelectedGroups: [OshiGroup] {
        sheetState.pendingSelectedGroups(from: groups)
    }

    private var scrollBottomPadding: CGFloat {
        OshiMasterSelectLayoutMetrics.bottomContentPadding
            + (sheetState.hasPendingSelection ? OshiMasterSelectLayoutMetrics.selectedActionExtraPadding : 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            OshiMasterSelectHeader(
                showsRequestButton: showsRequestButton,
                onRequest: { onRequest(sheetState.requestSearchText) },
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
                selectedGenreID: $sheetState.selectedGenreID,
                searchText: $sheetState.searchText,
                allowsMultipleSelection: allowsMultipleSelection,
                pendingSelectionCount: sheetState.pendingSelectionCount,
                onRegister: registerPendingSelection
            )
        }
        .onAppear {
            resetPendingSelection()
            if showsMyOshiCategory, sheetState.selectedGenreID == nil {
                sheetState.selectedGenreID = OshiMasterSelectSheetState.myOshiCategoryID
            }
        }
        .onChange(of: selectedGroupIDs) { _, _ in
            sheetState.removeLockedPendingSelection(selectedGroupIDs: selectedGroupIDs)
        }
        .task(id: sheetState.searchText) {
            // L2名からの検索（デバウンスして問い合わせ）
            guard let onSearchCharacterGroups else {
                return
            }
            let query = sheetState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                characterHitGroupIDs = []
                return
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }
            characterHitGroupIDs = await onSearchCharacterGroups(query)
        }
        .animation(.snappy(duration: 0.18), value: sheetState.pendingSelectedGroupIDs)
    }

    private func isSelected(_ group: OshiGroup) -> Bool {
        sheetState.isSelected(group, selectedGroupIDs: selectedGroupIDs)
    }

    private func handleCandidateTap(_ group: OshiGroup) {
        guard allowsMultipleSelection else {
            onSelect(group)
            return
        }
        sheetState.togglePendingGroup(group.id, lockedIDs: selectedGroupIDs)
    }

    private func registerPendingSelection() {
        let selectedGroups = pendingSelectedGroups
        guard !selectedGroups.isEmpty else {
            return
        }
        sheetState.clearPendingSelection()
        if let onRegisterSelected {
            onRegisterSelected(selectedGroups)
        } else {
            selectedGroups.forEach(onSelect)
        }
    }

    private func resetPendingSelection() {
        sheetState.clearPendingSelection()
    }
}
