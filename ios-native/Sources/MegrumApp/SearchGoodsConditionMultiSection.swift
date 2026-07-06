import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// 検索フィルターのグッズ条件セクション（複数選択・項目内OR）。
/// グループは「自分の推し」を既定チップで並べ、他はマスタから追加できる。
struct SearchGoodsConditionMultiSection: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedGroupIDs: Set<UUID>
    @Binding var selectedMemberIDs: Set<UUID>
    @Binding var selectedGoodsTypeIDs: Set<UUID>
    var selectedTagSummary: String
    var onOpenTagPicker: () -> Void

    /// 選択グループごとのメンバー（ローカルキャッシュ）。
    @State private var charactersByGroupID: [UUID: [OshiCharacter]] = [:]

    private var myOshiGroupIDs: [UUID] {
        var seen: Set<UUID> = []
        return appState.userOshiSelections.compactMap(\.groupID).filter { seen.insert($0).inserted }
    }

    /// チップに出すグループ：自分の推し＋選択中（マスタ追加分）。
    private var chipGroups: [OshiGroup] {
        var ids = myOshiGroupIDs
        for id in selectedGroupIDs where !ids.contains(id) {
            ids.append(id)
        }
        return ids.compactMap { id in
            appState.oshiGroups.first { $0.id == id }
        }
    }

    private var availableMembers: [OshiCharacter] {
        selectedGroupIDs
            .sorted { $0.uuidString < $1.uuidString }
            .flatMap { charactersByGroupID[$0] ?? [] }
    }

    private var selectedGoodsTypeSummary: String {
        let names = appState.goodsTypes
            .filter { selectedGoodsTypeIDs.contains($0.id) }
            .map(\.name)
        if names.isEmpty {
            return "すべて"
        }
        if names.count <= 2 {
            return names.joined(separator: "・")
        }
        return "\(names.prefix(2).joined(separator: "・")) 他\(names.count - 2)件"
    }

    var body: some View {
        Section {
            groupChips

            NavigationLink {
                SearchFilterGroupAddDestination(
                    genres: appState.oshiGenres,
                    groups: appState.oshiGroups,
                    myOshiGroupIDs: Set(myOshiGroupIDs),
                    onToggleGroup: toggleGroup
                )
            } label: {
                HStack {
                    Text("ほかのグループから追加")
                    Spacer()
                    Text(selectedGroupIDs.isEmpty ? "すべて" : "\(selectedGroupIDs.count)件選択")
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            if !selectedGroupIDs.isEmpty {
                memberChips
            }

            NavigationLink {
                GoodsTypeSelectSheet(
                    goodsTypes: appState.goodsTypes,
                    selectedGoodsTypeIDs: $selectedGoodsTypeIDs
                )
            } label: {
                HStack {
                    Text("グッズ種別")
                    Spacer()
                    Text(selectedGoodsTypeSummary)
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }
            }

            Button(action: onOpenTagPicker) {
                HStack {
                    Text("シリーズ")
                    Spacer()
                    Text(selectedTagSummary)
                        .foregroundStyle(MegrumTheme.muted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Label("相手が譲るグッズ（複数選択OK）", systemImage: "shippingbox")
        } footer: {
            Text("同じ項目で複数選ぶと、どれかに当てはまるものが表示されます。")
        }
        .task(id: selectedGroupIDs) {
            await loadMembersForSelectedGroups()
        }
    }

    private var groupChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("グループ（自分の推し）")
                .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            if chipGroups.isEmpty {
                Text("推し設定をすると、ここに推しが並びます")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            } else {
                WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                    ForEach(chipGroups) { group in
                        ChoiceChip(
                            title: group.name,
                            isSelected: selectedGroupIDs.contains(group.id),
                            style: .compact
                        ) {
                            toggleGroup(group.id)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var memberChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("メンバー")
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                if appState.isLoadingOshiCharacters {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if availableMembers.isEmpty {
                Text(appState.isLoadingOshiCharacters ? "読み込み中" : "メンバー情報がありません")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            } else {
                WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                    ForEach(availableMembers) { member in
                        ChoiceChip(
                            title: member.name,
                            isSelected: selectedMemberIDs.contains(member.id),
                            style: .compact
                        ) {
                            toggleMember(member.id)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleGroup(_ groupID: UUID) {
        if selectedGroupIDs.contains(groupID) {
            selectedGroupIDs.remove(groupID)
            let removedMemberIDs = Set((charactersByGroupID[groupID] ?? []).map(\.id))
            selectedMemberIDs.subtract(removedMemberIDs)
        } else {
            selectedGroupIDs.insert(groupID)
        }
    }

    private func toggleMember(_ memberID: UUID) {
        if selectedMemberIDs.contains(memberID) {
            selectedMemberIDs.remove(memberID)
        } else {
            selectedMemberIDs.insert(memberID)
        }
    }

    private func loadMembersForSelectedGroups() async {
        for groupID in selectedGroupIDs where charactersByGroupID[groupID] == nil {
            guard let group = appState.oshiGroups.first(where: { $0.id == groupID }) else {
                continue
            }
            await appState.loadOshiCharacters(group: group)
            charactersByGroupID[groupID] = appState.oshiCharacters
        }
    }
}

/// 「ほかのグループから追加」の遷移先（推し追加と同じマスタシート・タップでトグル）。
private struct SearchFilterGroupAddDestination: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var myOshiGroupIDs: Set<UUID>
    var onToggleGroup: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OshiMasterSelectSheet(
            genres: genres,
            groups: groups,
            selectedGroupIDs: [],
            charactersByGroupID: [:],
            myOshiGroupIDs: myOshiGroupIDs,
            showsRequestButton: false,
            onClose: { dismiss() },
            onRequest: { _ in dismiss() },
            onSelect: { group in
                onToggleGroup(group.id)
                dismiss()
            }
        )
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}
