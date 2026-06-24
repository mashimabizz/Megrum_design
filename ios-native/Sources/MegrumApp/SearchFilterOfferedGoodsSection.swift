import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchOfferedGoodsFilterSection: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var selectedTagSummary: String
    @Binding var selectedGroupID: UUID?
    @Binding var selectedMemberID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    var isLoadingGroups: Bool
    var isLoadingMembers: Bool
    var isLoadingGoodsTypes: Bool
    var onSelectGroup: (OshiGroup) -> Void
    var onClearGroup: () -> Void
    var onOpenTagPicker: () -> Void

    private var selectedGroupName: String {
        guard let selectedGroupID,
              let group = groups.first(where: { $0.id == selectedGroupID })
        else {
            return "すべて"
        }
        return group.name
    }

    var body: some View {
        Section {
            NavigationLink {
                SearchFilterOshiGroupPickerDestination(
                    genres: genres,
                    groups: groups,
                    selectedGroupIDs: selectedGroupID.map { Set([$0]) } ?? [],
                    onSelectGroup: onSelectGroup
                )
            } label: {
                HStack {
                    Text("グループ")
                    Spacer()
                    Text(selectedGroupName)
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }
            }

            if selectedGroupID != nil {
                Button("グループをクリア", action: onClearGroup)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }

            if isLoadingGroups {
                ProgressView("グループを読み込み中")
            }

            Picker("メンバー", selection: $selectedMemberID) {
                Text(selectedGroupID == nil ? "グループ選択後" : "グループ全体").tag(Optional<UUID>.none)
                ForEach(characters) { character in
                    Text(character.name).tag(Optional(character.id))
                }
            }
            .disabled(selectedGroupID == nil)
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            if isLoadingMembers {
                ProgressView("メンバーを読み込み中")
            }

            Picker("グッズ種別", selection: $selectedGoodsTypeID) {
                Text("すべて").tag(Optional<UUID>.none)
                ForEach(goodsTypes) { goodsType in
                    Text(goodsType.name).tag(Optional(goodsType.id))
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            if isLoadingGoodsTypes {
                ProgressView("グッズ種別を読み込み中")
            }

            Button(action: onOpenTagPicker) {
                HStack {
                    Text("タグ")
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
            Label("相手が譲るグッズ", systemImage: "shippingbox")
        }
    }
}

private struct SearchFilterOshiGroupPickerDestination: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var selectedGroupIDs: Set<UUID>
    var onSelectGroup: (OshiGroup) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OshiMasterSelectSheet(
            genres: genres,
            groups: groups,
            selectedGroupIDs: selectedGroupIDs,
            charactersByGroupID: [:],
            allowsMultipleSelection: false,
            onClose: { dismiss() },
            onRequest: { _ in dismiss() },
            onSelect: { group in
                onSelectGroup(group)
                dismiss()
            },
            onRegisterSelected: nil
        )
    }
}
