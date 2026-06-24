import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingConditionTab: View {
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    @Binding var selectedGroupID: UUID?
    @Binding var selectedMemberIDs: Set<UUID>
    @Binding var excludesSelectedMembers: Bool
    @Binding var selectedGoodsTypeID: UUID?
    @Binding var selectedTagNames: [String]
    @Binding var quantity: Int
    var onShowOshiPicker: () -> Void
    var onToggleMember: (UUID) -> Void

    @State private var showsMemberPicker = false
    @State private var showsTagSheet = false

    private var selectedGroup: OshiGroup? {
        groups.first { $0.id == selectedGroupID } ?? groups.first
    }

    private var selectedGoodsType: GoodsType? {
        goodsTypes.first { $0.id == selectedGoodsTypeID } ?? goodsTypes.first
    }

    private var selectedMembers: [OshiCharacter] {
        characters.filter { selectedMemberIDs.contains($0.id) }
    }

    private var usesLogicChoice: Bool {
        selectedMemberIDs.count > 1 || excludesSelectedMembers
    }

    private var tagBuilder: IndividualListingConditionTagBuilder {
        IndividualListingConditionTagBuilder(
            inventory: inventory,
            wishes: wishes,
            selectedGroupID: selectedGroupID
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 0) {
                actionRow(
                    title: "グループ / 作品",
                    value: selectedGroup?.name ?? "選択",
                    action: onShowOshiPicker
                )
                Divider()
                actionRow(
                    title: "メンバー / キャラ",
                    value: memberSummary,
                    action: { showsMemberPicker = true }
                )
                Divider()
                goodsTypeRow
                Divider()
                tagRow
                Divider()
                if usesLogicChoice {
                    logicHintRow
                } else {
                    quantityRow
                }
            }
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
            }
        }
        .sheet(isPresented: $showsMemberPicker) {
            IndividualListingMemberPickerSheet(
                groupName: selectedGroup?.name ?? "メンバー",
                characters: characters.filter { selectedGroupID == nil || $0.groupID == selectedGroupID },
                selectedIDs: selectedMemberIDs,
                excludesSelectedMembers: $excludesSelectedMembers,
                onToggle: onToggleMember,
                onClose: { showsMemberPicker = false }
            )
        }
        .sheet(isPresented: $showsTagSheet) {
            GoodsBulkTagSheet(
                selectedCount: max(1, selectedTagNames.count),
                candidateNames: tagCandidateNames,
                previewItemsByTag: tagPreviewItemsByTag,
                navigationTitle: "タグを登録",
                textFieldPlaceholder: "例：会場限定",
                footerText: "この条件にタグを追加します。",
                confirmationTitle: "追加"
            ) { tagName in
                addConditionTag(tagName)
            }
        }
    }

    private var goodsTypeRow: some View {
        HStack {
            rowTitle("グッズ種別")
            Spacer()
            Menu {
                ForEach(goodsTypes) { type in
                    Button(type.name) {
                        selectedGoodsTypeID = type.id
                    }
                }
            } label: {
                rowValue(selectedGoodsType?.name ?? "選択", showsChevron: true)
            }
            .disabled(goodsTypes.isEmpty)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }

    private var tagRow: some View {
        Button {
            showsTagSheet = true
        } label: {
            HStack {
                rowTitle("タグ")
                Spacer()
                rowValue(tagSummary, showsChevron: true)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }

    private var quantityRow: some View {
        HStack {
            rowTitle("数量")
            Spacer()
            HStack(spacing: 10) {
                quantityButton(systemName: "minus") {
                    quantity = max(1, quantity - 1)
                }
                Text("\(quantity)点")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 52)
                quantityButton(systemName: "plus") {
                    quantity = min(99, quantity + 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }

    private var logicHintRow: some View {
        HStack {
            rowTitle("希望の扱い")
            Spacer()
            Text("下の選択で指定")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }

    private var memberSummary: String {
        guard !selectedMembers.isEmpty else {
            return "指定なし"
        }
        let names = selectedMembers.prefix(2).map(\.name).joined(separator: "・")
        let suffix = selectedMembers.count > 2 ? " 他\(selectedMembers.count - 2)人" : ""
        return excludesSelectedMembers ? "\(names)\(suffix)以外" : "\(names)\(suffix)"
    }

    private var tagSummary: String {
        guard !selectedTagNames.isEmpty else {
            return "追加"
        }
        return selectedTagNames.prefix(2).map { "#\($0)" }.joined(separator: " ")
            + (selectedTagNames.count > 2 ? " 他\(selectedTagNames.count - 2)" : "")
    }

    private var tagCandidateNames: [String] {
        tagBuilder.candidateNames()
    }

    private var tagPreviewItemsByTag: [String: [TagPreviewItem]] {
        tagBuilder.previewItemsByTag()
    }

    private func addConditionTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !selectedTagNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }),
              selectedTagNames.count < 5
        else {
            return
        }
        selectedTagNames.append(trimmed)
    }

    private func actionRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                rowTitle(title)
                Spacer()
                rowValue(value, showsChevron: true)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }

    private func rowTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
    }

    private func rowValue(_ value: String, showsChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundStyle(MegrumTheme.lavender)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
    }

    private func quantityButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.lavender.opacity(0.10), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
