import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// マイグッズ / ほしいもの一覧の絞り込みシート（iter: インラインフィルタ行の後継）。
/// ホーム→検索の検索フィルターと同じ構造で、項目はグループ・メンバー・グッズ種別・シリーズの4つ。
struct GoodsCollectionFilterSheet: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedGroupID: UUID?
    @Binding var selectedMemberID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    @Binding var selectedTagNames: Set<String>
    var availableGroups: [OshiGroup]
    var availableGoodsTypes: [GoodsType]
    var availableTagNames: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingTagPicker = false

    private var selectedGroup: OshiGroup? {
        guard let selectedGroupID else {
            return nil
        }
        return availableGroups.first { $0.id == selectedGroupID }
            ?? appState.oshiGroups.first { $0.id == selectedGroupID }
    }

    private var selectedTagSummary: String {
        if selectedTagNames.isEmpty {
            return "指定なし"
        }
        let names = selectedTagNames.sorted().map { "#\($0)" }
        if names.count <= 2 {
            return names.joined(separator: " ")
        }
        return "\(names.prefix(2).joined(separator: " ")) 他\(names.count - 2)件"
    }

    var body: some View {
        Form {
            SearchOfferedGoodsFilterSection(
                genres: appState.oshiGenres,
                groups: availableGroups,
                characters: selectedGroupID == nil ? [] : appState.oshiCharacters,
                goodsTypes: availableGoodsTypes,
                myOshiGroupIDs: Set(appState.userOshiSelections.compactMap(\.groupID)),
                selectedTagSummary: selectedTagSummary,
                selectedGroupID: $selectedGroupID,
                selectedMemberID: $selectedMemberID,
                selectedGoodsTypeID: $selectedGoodsTypeID,
                isLoadingGroups: appState.isLoadingOshiGroups,
                isLoadingMembers: appState.isLoadingOshiCharacters,
                isLoadingGoodsTypes: appState.isLoadingGoodsTypes,
                onSelectGroup: selectGroup,
                onClearGroup: clearGroupSelection,
                onOpenTagPicker: { isShowingTagPicker = true },
                headerTitle: "絞り込み",
                headerSystemImage: "line.3.horizontal.decrease"
            )

            Section {
                Button("条件をリセット", role: .destructive, action: resetFilters)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("絞り込み")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isShowingTagPicker) {
            NavigationStack {
                SearchGoodsTagSelectionSheet(
                    candidateNames: availableTagNames,
                    selectedGroupName: selectedGroup?.name,
                    selectedTags: $selectedTagNames
                )
            }
        }
        .onAppear(perform: loadSelectedGroupMembersIfNeeded)
    }

    private func selectGroup(_ group: OshiGroup) {
        selectedGroupID = group.id
        selectedMemberID = nil
        Task {
            await appState.loadOshiCharacters(group: group)
        }
    }

    private func clearGroupSelection() {
        selectedGroupID = nil
        selectedMemberID = nil
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
    }

    private func resetFilters() {
        selectedGroupID = nil
        selectedMemberID = nil
        selectedGoodsTypeID = nil
        selectedTagNames = []
    }

    private func loadSelectedGroupMembersIfNeeded() {
        guard let selectedGroup else {
            return
        }
        Task {
            await appState.loadOshiCharacters(group: selectedGroup)
        }
    }
}

/// 一覧右下に浮かせる絞り込みボタン（検索画面のフィルターアイコンと同トーン）。
struct GoodsCollectionFilterFloatingButton: View {
    var activeFilterCount: Int
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 62, height: 62)
                    .background(.regularMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))
                    .megrumLiquidGlass(.circle, tint: MegrumTheme.lavender.opacity(0.14), interactive: true)

                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 23, height: 23)
                        .background(MegrumTheme.lavender, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1.4))
                        .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 6, y: 3)
                        .allowsHitTesting(false)
                        .offset(x: 6, y: -6)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("絞り込み")
    }
}
