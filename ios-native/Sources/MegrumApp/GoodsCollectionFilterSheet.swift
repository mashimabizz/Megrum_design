import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// マイグッズ / ほしいもの一覧の絞り込みシート。
/// 各項目（グループ・メンバー・グッズ種別・シリーズ）は複数選択でき、項目内は OR で検索する。
/// 選択は下書きとして持ち、「フィルターを適用」を押した時にだけ一覧へ反映する。
struct GoodsCollectionFilterSheet: View {
    var items: [GoodsItem]
    var availableGroups: [OshiGroup]
    var availableGoodsTypes: [GoodsType]
    /// メンバー名の解決用（items 側に名前が無い場合のフォールバック）。
    var characters: [OshiCharacter] = []
    @Binding var selectedGroupIDs: Set<UUID>
    @Binding var selectedMemberIDs: Set<UUID>
    @Binding var selectedGoodsTypeIDs: Set<UUID>
    @Binding var selectedTagNames: Set<String>

    @Environment(\.dismiss) private var dismiss
    @State private var draft = GoodsCollectionFilter()
    @State private var didLoadDraft = false

    private var availableMembers: [(id: UUID, name: String)] {
        let nameByID = Dictionary(characters.map { ($0.id, $0.name) }) { first, _ in first }
        return GoodsCollectionFilterChoices.members(items: items, selectedGroupIDs: draft.groupIDs)
            .map { member in
                member.name == "メンバー"
                    ? (id: member.id, name: nameByID[member.id] ?? member.name)
                    : member
            }
    }

    private var availableTagNames: [String] {
        GoodsCollectionFilterChoices.tagNames(
            items: items,
            selectedGroupIDs: draft.groupIDs,
            selectedGoodsTypeIDs: draft.goodsTypeIDs
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("複数選んだ項目は、どれかに当てはまれば表示されます。")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                filterSection(title: "グループ", isEmptyMessage: "対象のグループがありません", isEmpty: availableGroups.isEmpty) {
                    ForEach(availableGroups) { group in
                        ChoiceChip(
                            title: group.name,
                            isSelected: draft.groupIDs.contains(group.id),
                            style: .compact
                        ) {
                            toggleGroup(group.id)
                        }
                    }
                }

                if !draft.groupIDs.isEmpty {
                filterSection(title: "メンバー", isEmptyMessage: "対象のメンバーがありません", isEmpty: availableMembers.isEmpty) {
                    ForEach(availableMembers, id: \.id) { member in
                        ChoiceChip(
                            title: member.name,
                            isSelected: draft.memberIDs.contains(member.id),
                            style: .compact
                        ) {
                            toggle(\.memberIDs, value: member.id)
                        }
                    }
                }
                }

                filterSection(title: "グッズ種別", isEmptyMessage: "対象のグッズ種別がありません", isEmpty: availableGoodsTypes.isEmpty) {
                    ForEach(availableGoodsTypes) { goodsType in
                        ChoiceChip(
                            title: goodsType.name,
                            isSelected: draft.goodsTypeIDs.contains(goodsType.id),
                            style: .compact
                        ) {
                            toggle(\.goodsTypeIDs, value: goodsType.id)
                        }
                    }
                }

                filterSection(title: "シリーズ", isEmptyMessage: "対象のシリーズがありません", isEmpty: availableTagNames.isEmpty) {
                    ForEach(availableTagNames, id: \.self) { tagName in
                        ChoiceChip(
                            title: "#\(tagName)",
                            isSelected: draft.tagNames.contains(tagName),
                            style: .compact
                        ) {
                            toggle(\.tagNames, value: tagName)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("絞り込み")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button(action: applyAndDismiss) {
                    Text(applyButtonTitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: MegrumTheme.lavender.opacity(0.25), radius: 12, y: 6)
                }
                .buttonStyle(.plain)

                Button("条件をリセット", role: .destructive, action: resetDraft)
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .background(MegrumTheme.canvas.opacity(0.97))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.black.opacity(0.08))
                    .frame(height: 0.5)
            }
        }
        .onAppear(perform: loadDraftIfNeeded)
    }

    private var applyButtonTitle: String {
        draft.isActive ? "フィルターを適用（\(draft.activeCount)件）" : "フィルターを適用"
    }

    @ViewBuilder
    private func filterSection<Content: View>(
        title: String,
        isEmptyMessage: String,
        isEmpty: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if isEmpty {
                Text(isEmptyMessage)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            } else {
                WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                    content()
                }
            }
        }
    }

    private func loadDraftIfNeeded() {
        guard !didLoadDraft else {
            return
        }
        didLoadDraft = true
        draft = GoodsCollectionFilter(
            groupIDs: selectedGroupIDs,
            memberIDs: selectedMemberIDs,
            goodsTypeIDs: selectedGoodsTypeIDs,
            tagNames: selectedTagNames
        )
    }

    private func toggleGroup(_ groupID: UUID) {
        toggle(\.groupIDs, value: groupID)
        // グループ選択が変わったら、対象外になったメンバー・シリーズの下書きを整理
        let memberIDs = Set(GoodsCollectionFilterChoices.members(items: items, selectedGroupIDs: draft.groupIDs).map(\.id))
        draft.memberIDs = draft.memberIDs.intersection(memberIDs)
        let tagNames = Set(
            GoodsCollectionFilterChoices.tagNames(
                items: items,
                selectedGroupIDs: draft.groupIDs,
                selectedGoodsTypeIDs: draft.goodsTypeIDs
            )
        )
        draft.tagNames = draft.tagNames.intersection(tagNames)
    }

    private func toggle<Value: Hashable>(_ keyPath: WritableKeyPath<GoodsCollectionFilter, Set<Value>>, value: Value) {
        if draft[keyPath: keyPath].contains(value) {
            draft[keyPath: keyPath].remove(value)
        } else {
            draft[keyPath: keyPath].insert(value)
        }
    }

    private func resetDraft() {
        draft = GoodsCollectionFilter()
    }

    private func applyAndDismiss() {
        selectedGroupIDs = draft.groupIDs
        selectedMemberIDs = draft.memberIDs
        selectedGoodsTypeIDs = draft.goodsTypeIDs
        selectedTagNames = draft.tagNames
        dismiss()
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
