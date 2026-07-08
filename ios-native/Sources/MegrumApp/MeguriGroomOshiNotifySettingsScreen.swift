import MegrumCore
import MegrumDesign
import SwiftUI

/// FB8-7: 推し(L1グループ)ごとの圏内グルーム通知設定。
/// グループ単位でオン/オフを切り替え、登録メンバーがいる場合は「登録メンバーのみ通知」も選べる。iter1226.388。
struct MeguriGroomOshiNotifySettingsScreen: View {
    @ObservedObject var appState: MegrumAppState

    private struct OshiGroupRow: Identifiable {
        let id: UUID
        let name: String
        let hasRegisteredMembers: Bool
    }

    /// 自分の推しから重複を除いた L1 グループ一覧（登録順）。
    private var groups: [OshiGroupRow] {
        let selections = appState.userOshiSelections.filter { $0.groupID != nil }
        var membersByGroup: [UUID: Bool] = [:]
        for selection in selections {
            guard let groupID = selection.groupID else { continue }
            if selection.characterID != nil {
                membersByGroup[groupID] = true
            } else if membersByGroup[groupID] == nil {
                membersByGroup[groupID] = false
            }
        }

        var seen = Set<UUID>()
        var rows: [OshiGroupRow] = []
        for selection in selections {
            guard let groupID = selection.groupID, !seen.contains(groupID) else { continue }
            seen.insert(groupID)
            rows.append(
                OshiGroupRow(
                    id: groupID,
                    name: selection.groupName?.nilIfBlank ?? "推し",
                    hasRegisteredMembers: membersByGroup[groupID] ?? false
                )
            )
        }
        return rows
    }

    var body: some View {
        List {
            if groups.isEmpty {
                Section {
                    Text("推しを設定すると、推しごとに圏内グルームの通知を切り替えられます。")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            } else {
                ForEach(groups) { group in
                    Section {
                        Toggle(isOn: enabledBinding(group.id)) {
                            Text(group.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        if appState.groomNotifyPref(for: group.id).enabled, group.hasRegisteredMembers {
                            Toggle(isOn: membersOnlyBinding(group.id)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("登録メンバーのみ通知")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    Text("オフにするとこのグループ全体の新着グルームを通知します。")
                                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                        .foregroundStyle(MegrumTheme.muted)
                                }
                            }
                        }
                    }
                }
            }
        }
        .tint(MegrumTheme.lavender)
        .navigationTitle("推しごとの通知")
        .megrumInlineNavigationTitle()
        .task {
            if appState.userOshiSelections.isEmpty {
                await appState.loadUserOshiSelections()
            }
            await appState.loadGroomNotifyPrefs()
        }
    }

    private func enabledBinding(_ groupID: UUID) -> Binding<Bool> {
        Binding(
            get: { appState.groomNotifyPref(for: groupID).enabled },
            set: { enabled in
                let membersOnly = appState.groomNotifyPref(for: groupID).membersOnly
                Task {
                    await appState.setGroomNotifyPref(
                        groupID: groupID,
                        enabled: enabled,
                        membersOnly: membersOnly
                    )
                }
            }
        )
    }

    private func membersOnlyBinding(_ groupID: UUID) -> Binding<Bool> {
        Binding(
            get: { appState.groomNotifyPref(for: groupID).membersOnly },
            set: { membersOnly in
                let enabled = appState.groomNotifyPref(for: groupID).enabled
                Task {
                    await appState.setGroomNotifyPref(
                        groupID: groupID,
                        enabled: enabled,
                        membersOnly: membersOnly
                    )
                }
            }
        )
    }
}
