import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriContentMetadataFields: View {
    var title: String
    @Binding var draft: MeguriContentMetadataDraft
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var userOshiSelections: [UserOshiSelection] = []
    var inventory: [GoodsItem] = []
    var wishes: [WishItem] = []
    var isLoadingGroups: Bool
    var isLoadingCharacters: Bool
    var onLoadGroups: () async -> Void
    var onLoadCharacters: (OshiGroup?) async -> Void
    var onLoadUserOshiSelections: () async -> Void = {}
    @State private var isShowingAllGroups = false
    @State private var isShowingAllCharacters = false
    @State private var isShowingSeriesSearch = false
    @State private var groupSearchText = ""
    @State private var seriesSearchText = ""

    private var selectedGroup: OshiGroup? {
        groups.first { $0.id == draft.groupID }
    }

    private var availableCharacters: [OshiCharacter] {
        guard let groupID = draft.groupID else {
            return []
        }
        return characters.filter { $0.groupID == groupID }
    }

    private var preferredGroups: [OshiGroup] {
        MeguriContentMetadataSuggestions.preferredGroups(
            groups: groups,
            selections: userOshiSelections
        )
    }

    private var otherGroups: [OshiGroup] {
        groups.filter { group in
            !preferredGroups.contains { $0.id == group.id }
        }
    }

    private var preferredCharacters: [OshiCharacter] {
        MeguriContentMetadataSuggestions.preferredCharacters(
            characters: availableCharacters,
            selections: userOshiSelections,
            groupID: draft.groupID
        )
    }

    private var otherCharacters: [OshiCharacter] {
        availableCharacters.filter { character in
            !preferredCharacters.contains { $0.id == character.id }
        }
    }

    private var filteredSeriesCandidates: [String] {
        MeguriContentMetadataSuggestions.filteredSeriesCandidates(
            seriesCandidates,
            query: seriesSearchText
        )
    }

    private var filteredGroupCandidates: [OshiGroup] {
        MeguriContentMetadataSuggestions.filteredGroups(
            otherGroups,
            query: groupSearchText
        )
    }

    private var seriesCandidates: [String] {
        MeguriContentMetadataSuggestions.seriesCandidates(
            inventory: inventory,
            wishes: wishes,
            groupID: draft.groupID,
            characterID: draft.characterID
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            metadataSection(
                title: "トピック",
                isLoading: isLoadingGroups
            ) {
                chipRow {
                    metadataChip(
                        title: "指定なし",
                        isSelected: draft.groupID == nil
                    ) {
                        selectGroup(nil)
                        Task { await onLoadCharacters(nil) }
                    }

                    ForEach(preferredGroups) { group in
                        metadataChip(
                            title: group.name,
                            isSelected: draft.groupID == group.id
                        ) {
                            selectGroup(group)
                        }
                    }
                }

                if isShowingAllGroups || preferredGroups.isEmpty {
                    topicSearchField
                    chipRow {
                        ForEach(filteredGroupCandidates.prefix(16)) { group in
                            metadataChip(
                                title: group.name,
                                isSelected: draft.groupID == group.id
                            ) {
                                selectGroup(group)
                            }
                        }
                    }
                } else if !otherGroups.isEmpty {
                    secondaryChoiceButton("これ以外のトピックから選ぶ") {
                        withAnimation(.smooth(duration: 0.16)) {
                            isShowingAllGroups = true
                        }
                    }
                }
            }

            if selectedGroup?.supportsMemberSelection == true {
                metadataSection(
                    title: "メンバー・キャラクター",
                    isLoading: isLoadingCharacters
                ) {
                    chipRow {
                        metadataChip(
                            title: "指定なし",
                            isSelected: draft.characterID == nil
                        ) {
                            draft.selectCharacter(nil)
                        }

                        ForEach(preferredCharacters) { character in
                            metadataChip(
                                title: character.name,
                                isSelected: draft.characterID == character.id
                            ) {
                                draft.selectCharacter(character)
                            }
                        }
                    }

                    if isShowingAllCharacters || preferredCharacters.isEmpty {
                        chipRow {
                            ForEach(otherCharacters) { character in
                                metadataChip(
                                    title: character.name,
                                    isSelected: draft.characterID == character.id
                                ) {
                                    draft.selectCharacter(character)
                                }
                            }
                        }
                    } else if !otherCharacters.isEmpty {
                        secondaryChoiceButton("それ以外のメンバー・キャラクターから選ぶ") {
                            withAnimation(.smooth(duration: 0.16)) {
                                isShowingAllCharacters = true
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("シリーズ")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                if !seriesCandidates.isEmpty {
                    chipRow {
                        ForEach(seriesCandidates.prefix(8), id: \.self) { name in
                            metadataChip(
                                title: name,
                                isSelected: draft.normalizedSeriesName == name
                            ) {
                                selectSeries(name)
                            }
                        }
                    }
                    secondaryChoiceButton("これ以外のシリーズから選ぶ") {
                        withAnimation(.smooth(duration: 0.16)) {
                            isShowingSeriesSearch = true
                        }
                    }
                }

                if isShowingSeriesSearch || seriesCandidates.isEmpty {
                    seriesSearchField
                    if !filteredSeriesCandidates.isEmpty {
                        chipRow {
                            ForEach(filteredSeriesCandidates.prefix(12), id: \.self) { name in
                                metadataChip(
                                    title: name,
                                    isSelected: draft.normalizedSeriesName == name
                                ) {
                                    selectSeries(name)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            if groups.isEmpty {
                await onLoadGroups()
            }
            if userOshiSelections.isEmpty {
                await onLoadUserOshiSelections()
            }
            if let selectedGroup, characters.filter({ $0.groupID == selectedGroup.id }).isEmpty {
                await onLoadCharacters(selectedGroup)
            }
        }
    }

    private var topicSearchField: some View {
        TextField("トピックを検索", text: $groupSearchText)
        #if os(iOS)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        #endif
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }

    private var seriesSearchField: some View {
        TextField("シリーズ名を検索・入力", text: Binding(
            get: {
                seriesSearchText.isEmpty ? draft.seriesName : seriesSearchText
            },
            set: { value in
                seriesSearchText = value
                draft.seriesName = value
            }
        ))
        #if os(iOS)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        #endif
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }

    private func selectGroup(_ group: OshiGroup?) {
        draft.selectGroup(group)
        groupSearchText = group?.name ?? ""
        isShowingAllCharacters = false
        Task { await onLoadCharacters(group) }
    }

    private func selectSeries(_ name: String) {
        draft.seriesName = name
        seriesSearchText = name
    }

    private func metadataSection<Content: View>(
        title: String,
        isLoading: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MegrumTheme.lavender)
                }
            }
            content()
        }
    }

    private func chipRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                content()
            }
            .padding(.vertical, 2)
        }
    }

    private func metadataChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .lineLimit(1)
                .padding(.horizontal, 13)
                .frame(height: 36)
                .background(isSelected ? MegrumTheme.lavender : .white, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? .white.opacity(0.3) : MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func secondaryChoiceButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .black))
            }
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .padding(.top, 2)
        }
        .buttonStyle(.plain)
    }
}

struct MeguriContentFilterSheet: View {
    @Binding var filter: MeguriContentFilterState
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var userOshiSelections: [UserOshiSelection] = []
    var inventory: [GoodsItem] = []
    var wishes: [WishItem] = []
    var isLoadingGroups: Bool
    var isLoadingCharacters: Bool
    var onLoadGroups: () async -> Void
    var onLoadCharacters: (OshiGroup?) async -> Void
    var onLoadUserOshiSelections: () async -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            MeguriContentMetadataFields(
                title: "表示する内容",
                draft: $filter.draft,
                groups: groups,
                characters: characters,
                userOshiSelections: userOshiSelections,
                inventory: inventory,
                wishes: wishes,
                isLoadingGroups: isLoadingGroups,
                isLoadingCharacters: isLoadingCharacters,
                onLoadGroups: onLoadGroups,
                onLoadCharacters: onLoadCharacters,
                onLoadUserOshiSelections: onLoadUserOshiSelections
            )
            .padding(20)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("フィルター")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("リセット") {
                    filter.reset()
                    Task { await onLoadCharacters(nil) }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

struct MeguriContentMetadataPrompt: View {
    var title: String
    @Binding var draft: MeguriContentMetadataDraft
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var userOshiSelections: [UserOshiSelection] = []
    var inventory: [GoodsItem] = []
    var wishes: [WishItem] = []
    var isLoadingGroups: Bool
    var isLoadingCharacters: Bool
    var isSubmitting: Bool
    var onLoadGroups: () async -> Void
    var onLoadCharacters: (OshiGroup?) async -> Void
    var onLoadUserOshiSelections: () async -> Void = {}
    var onCancel: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 34, height: 34)
                        .background(MegrumTheme.canvas, in: Circle())
                }
                .buttonStyle(.plain)
            }

            MeguriContentMetadataFields(
                title: "トピックとシリーズ",
                draft: $draft,
                groups: groups,
                characters: characters,
                userOshiSelections: userOshiSelections,
                inventory: inventory,
                wishes: wishes,
                isLoadingGroups: isLoadingGroups,
                isLoadingCharacters: isLoadingCharacters,
                onLoadGroups: onLoadGroups,
                onLoadCharacters: onLoadCharacters,
                onLoadUserOshiSelections: onLoadUserOshiSelections
            )

            Button(action: onSubmit) {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("投稿する")
                    }
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
            .opacity(isSubmitting ? 0.72 : 1)
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 28, y: 16)
        .padding(.horizontal, 18)
    }
}
