import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingOptionsStep: View {
    @Binding var optionKind: IndividualListingOptionKind
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var selectedWishIDs: Set<UUID>
    @Binding var selectedWishLogic: ListingLogic
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    @Binding var selectedConditionGroupID: UUID?
    @Binding var selectedConditionMemberIDs: Set<UUID>
    @Binding var excludesSelectedConditionMembers: Bool
    @Binding var selectedConditionGoodsTypeID: UUID?
    @Binding var selectedConditionTagNames: [String]
    @Binding var conditionQuantity: Int
    @Binding var cashAmount: Int
    var onToggleWish: (WishItem) -> Void
    var onToggleConditionMember: (UUID) -> Void
    var onToggleConditionTag: (String) -> Void
    var onLoadCharacters: (OshiGroup) -> Void
    var onCreateOshiRequest: (OshiRequestSheetPayload) -> Void

    @State private var showsOshiMasterSheet = false
    @State private var requestSheet: OshiRequestSheetState?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IndividualListingStepTitle(step: .options)

            IndividualListingEditorTabs(selection: $optionKind)

            switch optionKind {
            case .wish:
                IndividualListingWishTab(
                    wishes: wishes,
                    selectedIDs: selectedWishIDs,
                    onToggle: onToggleWish
                )
            case .condition:
                IndividualListingConditionTab(
                    inventory: inventory,
                    wishes: wishes,
                    groups: groups,
                    characters: characters,
                    goodsTypes: goodsTypes,
                    selectedGroupID: $selectedConditionGroupID,
                    selectedMemberIDs: $selectedConditionMemberIDs,
                    excludesSelectedMembers: $excludesSelectedConditionMembers,
                    selectedGoodsTypeID: $selectedConditionGoodsTypeID,
                    selectedTagNames: $selectedConditionTagNames,
                    quantity: $conditionQuantity,
                    onShowOshiPicker: { showsOshiMasterSheet = true },
                    onToggleMember: onToggleConditionMember,
                    onToggleTag: onToggleConditionTag
                )
            case .cash:
                IndividualListingCashTab(amount: $cashAmount)
            }
        }
        .sheet(isPresented: $showsOshiMasterSheet) {
            OshiMasterSelectSheet(
                genres: genres,
                groups: groups,
                selectedGroupIDs: selectedConditionGroupID.map { Set([$0]) } ?? [],
                charactersByGroupID: selectedConditionGroupID.map { [$0: characters] } ?? [:],
                onClose: { showsOshiMasterSheet = false },
                onRequest: { query in
                    showsOshiMasterSheet = false
                    requestSheet = .oshi(initialName: query)
                },
                onSelect: { group in
                    selectedConditionGroupID = group.id
                    showsOshiMasterSheet = false
                    onLoadCharacters(group)
                }
            )
        }
        .sheet(item: $requestSheet) { state in
            OshiRequestSheet(
                state: state,
                genres: genres,
                onClose: { requestSheet = nil },
                onSubmit: { payload in
                    onCreateOshiRequest(payload)
                    requestSheet = nil
                }
            )
        }
    }
}

private struct IndividualListingEditorTabs: View {
    @Binding var selection: IndividualListingOptionKind

    var body: some View {
        HStack(spacing: 0) {
            ForEach(IndividualListingOptionKind.allCases) { kind in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        selection = kind
                    }
                } label: {
                    Text(kind.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(selection == kind ? .white : MegrumTheme.ink.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            if selection == kind {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(MegrumTheme.lavender)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct IndividualListingWishTab: View {
    var wishes: [WishItem]
    var selectedIDs: Set<UUID>
    var onToggle: (WishItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Wishから選ぶ")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                Text("Wishを検索")
                Spacer()
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted.opacity(0.68))
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(MegrumTheme.ink.opacity(0.05), in: Capsule())

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(wishes) { item in
                    Button {
                        onToggle(item)
                    } label: {
                        ListingSelectableImageTile(
                            imageURL: item.imageURL,
                            title: item.title,
                            isSelected: selectedIDs.contains(item.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.title)を候補に選択")
                    .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
                }
            }
        }
    }
}

private struct IndividualListingConditionTab: View {
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
    var onToggleTag: (String) -> Void

    @State private var showsMemberPicker = false

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
            Text("画像なしで条件を作る")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                rowTitle("タグ")
                Spacer()
                Text("候補から選択")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            TagCandidatePreviewSelector(
                candidateNames: tagCandidateNames,
                previewItemsByTag: tagPreviewItemsByTag,
                selectedNames: $selectedTagNames,
                emptyMessage: "この推しに紐づくタグ候補はまだありません",
                onToggle: onToggleTag
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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

    private var tagCandidateNames: [String] {
        tagBuilder.candidateNames()
    }

    private var tagPreviewItemsByTag: [String: [TagPreviewItem]] {
        tagBuilder.previewItemsByTag()
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

private struct IndividualListingMemberPickerSheet: View {
    var groupName: String
    var characters: [OshiCharacter]
    var selectedIDs: Set<UUID>
    @Binding var excludesSelectedMembers: Bool
    var onToggle: (UUID) -> Void
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if characters.isEmpty {
                        Text("メンバー候補はまだありません")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        FlowLayout(spacing: 9, rowSpacing: 9) {
                            ForEach(characters) { character in
                                memberButton(character)
                            }
                        }
                    }

                    if !selectedIDs.isEmpty {
                        Toggle(isOn: $excludesSelectedMembers) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("選んだメンバー以外で指定")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                Text("例：モモ・サナ以外なら、その他メンバーを希望します。")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                        }
                        .tint(MegrumTheme.lavender)
                        .padding(16)
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(groupName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onClose)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
        }
    }

    private func memberButton(_ character: OshiCharacter) -> some View {
        let selected = selectedIDs.contains(character.id)
        return Button {
            onToggle(character.id)
        } label: {
            HStack(spacing: 7) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                }
                Text(character.name)
                    .lineLimit(1)
            }
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(selected ? .white : MegrumTheme.ink)
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(selected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.92)), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct IndividualListingCashTab: View {
    @Binding var amount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("定価で受け付ける")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            IndividualListingCashAmountCard(amount: $amount)
        }
    }
}
