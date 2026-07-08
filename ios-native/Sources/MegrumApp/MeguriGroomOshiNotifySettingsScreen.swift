import MegrumCore
import MegrumDesign
import SwiftUI

/// FB(iter1226.390): 推し(L1グループ)ごとの圏内グルーム通知設定。
/// グループ単位のON/OFFに加え、登録メンバー(L2)のどれを通知対象にするかを個別に選べる。
struct MeguriGroomOshiNotifySettingsScreen: View {
    @ObservedObject var appState: MegrumAppState

    private struct OshiMemberRow: Identifiable {
        let id: UUID
        let name: String
    }

    private struct OshiGroupRow: Identifiable {
        let id: UUID
        let name: String
        let members: [OshiMemberRow]
    }

    /// 自分の推しから重複を除いた L1 グループ一覧（登録順・登録メンバー付き）。
    private var groups: [OshiGroupRow] {
        let selections = appState.userOshiSelections.filter { $0.groupID != nil }

        var membersByGroup: [UUID: [OshiMemberRow]] = [:]
        var seenMember: [UUID: Set<UUID>] = [:]
        for selection in selections {
            guard let groupID = selection.groupID, let characterID = selection.characterID else { continue }
            if seenMember[groupID]?.contains(characterID) == true { continue }
            seenMember[groupID, default: []].insert(characterID)
            membersByGroup[groupID, default: []].append(
                OshiMemberRow(id: characterID, name: selection.characterName?.nilIfBlank ?? "メンバー")
            )
        }

        var seenGroup = Set<UUID>()
        var rows: [OshiGroupRow] = []
        for selection in selections {
            guard let groupID = selection.groupID, !seenGroup.contains(groupID) else { continue }
            seenGroup.insert(groupID)
            rows.append(
                OshiGroupRow(
                    id: groupID,
                    name: selection.groupName?.nilIfBlank ?? "推し",
                    members: membersByGroup[groupID] ?? []
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

                        if appState.groomNotifyPref(for: group.id).enabled, !group.members.isEmpty {
                            Toggle(isOn: allMembersBinding(group.id, members: group.members)) {
                                Text("全メンバーを通知")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }

                            if !appState.groomNotifyPref(for: group.id).notifyAllMembers {
                                ForEach(group.members) { member in
                                    Toggle(isOn: memberBinding(group.id, memberID: member.id, members: group.members)) {
                                        Text(member.name)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                    }
                                    .padding(.leading, 12)
                                }
                            }
                        }
                    } footer: {
                        if appState.groomNotifyPref(for: group.id).enabled, !group.members.isEmpty {
                            Text("「全メンバー」をオフにすると、通知したいメンバーだけを選べます。")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
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

    private func save(_ groupID: UUID, _ pref: GroomNotifyPref) {
        Task {
            await appState.setGroomNotifyPref(
                groupID: groupID,
                enabled: pref.enabled,
                notifyAllMembers: pref.notifyAllMembers,
                memberCharacterIDs: pref.memberCharacterIDs
            )
        }
    }

    private func enabledBinding(_ groupID: UUID) -> Binding<Bool> {
        Binding(
            get: { appState.groomNotifyPref(for: groupID).enabled },
            set: { enabled in
                var pref = appState.groomNotifyPref(for: groupID)
                pref.enabled = enabled
                save(groupID, pref)
            }
        )
    }

    private func allMembersBinding(_ groupID: UUID, members: [OshiMemberRow]) -> Binding<Bool> {
        Binding(
            get: { appState.groomNotifyPref(for: groupID).notifyAllMembers },
            set: { all in
                var pref = appState.groomNotifyPref(for: groupID)
                pref.notifyAllMembers = all
                // 「選択」に切り替えた瞬間は、既存選択が無ければ全員を初期選択にする（通知ゼロを避ける）。
                if !all, pref.memberCharacterIDs.isEmpty {
                    pref.memberCharacterIDs = members.map(\.id)
                }
                save(groupID, pref)
            }
        )
    }

    private func memberBinding(_ groupID: UUID, memberID: UUID, members: [OshiMemberRow]) -> Binding<Bool> {
        Binding(
            get: { appState.groomNotifyPref(for: groupID).memberCharacterIDs.contains(memberID) },
            set: { on in
                var pref = appState.groomNotifyPref(for: groupID)
                var ids = Set(pref.memberCharacterIDs)
                if on { ids.insert(memberID) } else { ids.remove(memberID) }
                // 表示順を保つため members の並びで整列。
                pref.memberCharacterIDs = members.map(\.id).filter { ids.contains($0) }
                save(groupID, pref)
            }
        )
    }
}
