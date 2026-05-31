import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var groups: [OshiSettingsGroupDraft] = []
    @State private var charactersByGroupID: [UUID: [OshiCharacter]] = [:]
    @State private var expandedGroupKey: String?
    @State private var isSaving = false
    @State private var isLoading = false
    @State private var noticeMessage: String?
    @State private var errorMessage: String?
    @State private var showsMasterSheet = false
    @State private var requestSheet: OshiRequestSheetState?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    OshiSettingsHeader {
                        dismiss()
                    }

                    if isLoading || appState.isLoadingUserOshiSelections || appState.isLoadingOshiGroups {
                        OshiInlineLoading(text: "推し設定を読み込み中…")
                            .padding(.horizontal, 20)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(OshiPalette.warn)
                            .padding(.horizontal, 20)
                    }

                    if groups.isEmpty, !isLoading {
                        OshiEmptyState()
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(groups) { group in
                                OshiSettingsGroupCard(
                                    group: group,
                                    availableCharacters: availableCharacters(for: group),
                                    isExpanded: expandedGroupKey == group.key,
                                    isSaving: isSaving,
                                    onToggleExpanded: {
                                        withAnimation(.snappy(duration: 0.2)) {
                                            expandedGroupKey = expandedGroupKey == group.key ? nil : group.key
                                        }
                                    },
                                    onRemoveGroup: {
                                        Task { await removeGroup(group) }
                                    },
                                    onRemoveMember: { member in
                                        Task { await removeMember(member, from: group) }
                                    },
                                    onAddMember: { character in
                                        Task { await addMember(character, to: group) }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }

                    if let noticeMessage {
                        Text(noticeMessage)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .padding(.horizontal, 20)
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 116)
            }
            .scrollDismissesKeyboard(.interactively)

            Button {
                showsMasterSheet = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 48, height: 48)
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Text("推しを追加")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                }
                .padding(.leading, 16)
                .padding(.trailing, 22)
                .frame(height: 64)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.64), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.07), radius: 22, x: 0, y: 12)
            }
            .buttonStyle(.plain)
            .padding(.leading, 20)
            .padding(.bottom, 24)
            .disabled(isSaving)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .sheet(isPresented: $showsMasterSheet) {
            OshiMasterSelectSheet(
                genres: appState.oshiGenres,
                groups: appState.oshiGroups,
                selectedGroupIDs: Set(groups.compactMap(\.groupID)),
                charactersByGroupID: charactersByGroupID,
                onClose: { showsMasterSheet = false },
                onRequest: { query in
                    showsMasterSheet = false
                    requestSheet = .oshi(initialName: query)
                },
                onSelect: { group in
                    Task { await addMasterGroup(group) }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $requestSheet) { state in
            OshiRequestSheet(
                state: state,
                genres: appState.oshiGenres,
                onClose: { requestSheet = nil },
                onSubmit: { payload in
                    Task { await submitRequest(payload, state: state) }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .task {
            await prepare()
        }
    }

    private func prepare() async {
        isLoading = true
        errorMessage = nil
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        await appState.loadUserOshiSelections()

        let selectedGroupIDs = appState.userOshiSelections.compactMap(\.groupID).uniqued()
        for groupID in selectedGroupIDs {
            await loadCharactersIfNeeded(groupID: groupID)
        }
        groups = OshiSettingsGroupDraft.build(
            selections: appState.userOshiSelections,
            masterGroups: appState.oshiGroups
        )
        isLoading = false
    }

    private func availableCharacters(for group: OshiSettingsGroupDraft) -> [OshiCharacter] {
        guard let groupID = group.groupID else {
            return []
        }
        let selectedIDs = Set(group.members.compactMap(\.characterID))
        return (charactersByGroupID[groupID] ?? [])
            .filter { !selectedIDs.contains($0.id) }
            .sorted { $0.displayOrder == $1.displayOrder ? $0.name < $1.name : $0.displayOrder < $1.displayOrder }
    }

    private func loadCharactersIfNeeded(groupID: UUID) async {
        guard charactersByGroupID[groupID] == nil,
              let group = appState.oshiGroups.first(where: { $0.id == groupID })
        else {
            return
        }
        await appState.loadOshiCharacters(group: group)
        charactersByGroupID[groupID] = appState.oshiCharacters
    }

    private func addMasterGroup(_ group: OshiGroup) async {
        showsMasterSheet = false
        guard groups.contains(where: { $0.groupID == group.id }) == false else {
            noticeMessage = "すでに追加済みです。"
            return
        }
        await loadCharactersIfNeeded(groupID: group.id)
        var next = groups
        next.append(OshiSettingsGroupDraft(masterGroup: group, priority: next.count + 1))
        await persist(next, success: "推しを追加しました。")
    }

    private func removeGroup(_ group: OshiSettingsGroupDraft) async {
        await persist(
            groups.filter { $0.key != group.key },
            success: "推し設定から削除しました。"
        )
    }

    private func removeMember(_ member: OshiSettingsMemberDraft, from group: OshiSettingsGroupDraft) async {
        var next = groups
        guard let index = next.firstIndex(where: { $0.key == group.key }) else {
            return
        }
        next[index].members.removeAll { $0.id == member.id }
        await persist(next, success: "推しメンバーを外しました。")
    }

    private func addMember(_ character: OshiCharacter, to group: OshiSettingsGroupDraft) async {
        var next = groups
        guard let index = next.firstIndex(where: { $0.key == group.key }) else {
            return
        }
        guard next[index].members.contains(where: { $0.characterID == character.id }) == false else {
            return
        }
        next[index].members.append(OshiSettingsMemberDraft(character: character))
        await persist(next, success: "推しメンバーを追加しました。")
    }

    private func submitRequest(_ payload: OshiRequestSheetPayload, state: OshiRequestSheetState) async {
        requestSheet = nil
        guard let requestID = await appState.createOshiRequest(
            OshiRequestCreateInput(
                requestedName: payload.name,
                requestedKind: payload.kind,
                requestedGenreID: payload.genreID,
                note: payload.note
            )
        ) else {
            errorMessage = appState.errorMessage
            return
        }
        var next = groups
        next.append(
            OshiSettingsGroupDraft(
                requestID: requestID,
                name: payload.name,
                pending: true,
                priority: next.count + 1
            )
        )
        await persist(next, success: "追加リクエストを送信し、推し設定に仮登録しました。")
    }

    private func persist(_ nextGroups: [OshiSettingsGroupDraft], success: String) async {
        isSaving = true
        errorMessage = nil
        let inputs = OshiSettingsGroupDraft.accountSetupInputs(from: nextGroups)
        let saved = await appState.saveOshiSelections(inputs)
        if saved {
            withAnimation(.snappy(duration: 0.2)) {
                groups = nextGroups.reprioritized()
            }
            noticeMessage = success
        } else {
            errorMessage = appState.errorMessage
        }
        isSaving = false
    }
}

private struct OshiSettingsHeader: View {
    var onBack: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 56, height: 56)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            Text("推し設定")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }
}

private struct OshiSettingsGroupCard: View {
    var group: OshiSettingsGroupDraft
    var availableCharacters: [OshiCharacter]
    var isExpanded: Bool
    var isSaving: Bool
    var onToggleExpanded: () -> Void
    var onRemoveGroup: () -> Void
    var onRemoveMember: (OshiSettingsMemberDraft) -> Void
    var onAddMember: (OshiCharacter) -> Void

    private var summary: String {
        group.members.isEmpty ? "箱推し（メンバー指定なし）" : "推しメンバー \(group.members.count)人"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(group.name)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        if group.pending {
                            Text("承認待ち")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(summary)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Spacer()
                Button(action: onRemoveGroup) {
                    Text("削除")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(OshiPalette.warn)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background(OshiPalette.warn.opacity(0.11), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }

            FlowLayout(spacing: 8, rowSpacing: 9) {
                ForEach(group.members) { member in
                    Button {
                        onRemoveMember(member)
                    } label: {
                        HStack(spacing: 6) {
                            Text(member.pending ? "\(member.name)（承認待ち）" : member.name)
                                .lineLimit(1)
                            Text("×")
                                .foregroundStyle(OshiPalette.warn)
                        }
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.24), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }

                Button(action: onToggleExpanded) {
                    Text(isExpanded ? "閉じる" : "+ 追加")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .overlay {
                            Capsule()
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [5, 5]))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.35))
                        }
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if availableCharacters.isEmpty {
                        Text(group.pending ? "仮登録中の推しです。" : "追加できるメンバーがマスタにありません。")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    } else {
                        Text("追加できるメンバー")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)

                        FlowLayout(spacing: 8, rowSpacing: 8) {
                            ForEach(availableCharacters) { character in
                                Button {
                                    onAddMember(character)
                                } label: {
                                    Text("+ \(character.name)")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundStyle(MegrumTheme.ink)
                                        .padding(.horizontal, 10)
                                        .frame(height: 30)
                                        .background(.white.opacity(0.9), in: Capsule())
                                        .overlay {
                                            Capsule()
                                                .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(12)
                .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.black.opacity(0.06), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.025), radius: 12, x: 0, y: 6)
    }
}

private struct OshiMasterSelectSheet: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var selectedGroupIDs: Set<UUID>
    var charactersByGroupID: [UUID: [OshiCharacter]]
    var onClose: () -> Void
    var onRequest: (String?) -> Void
    var onSelect: (OshiGroup) -> Void

    @State private var searchText = ""
    @State private var selectedGenreID: UUID?

    private var categoryOptions: [OshiCategoryOption] {
        [OshiCategoryOption(id: nil, title: "すべて")] + genres.map { OshiCategoryOption(id: $0.id, title: $0.name) }
    }

    private var filteredGroups: [OshiGroup] {
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return groups.filter { group in
            if let selectedGenreID, group.genreID != selectedGenreID {
                return false
            }
            guard !normalized.isEmpty else {
                return true
            }
            return ([group.name] + group.aliases).contains { $0.localizedCaseInsensitiveContains(normalized) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("推しを追加")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("グループ・作品マスタから選択")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Spacer()
                Button {
                    onRequest(searchText.nilIfBlank)
                } label: {
                    Text("追加リクエスト")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 16)
                        .frame(height: 42)
                        .background(MegrumTheme.lavender.opacity(0.11), in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(width: 48, height: 48)
                        .background(.black.opacity(0.04), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredGroups) { group in
                        Button {
                            onSelect(group)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(group.name)
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(masterMeta(for: group))
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 74)
                            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(selectedGroupIDs.contains(group.id) ? MegrumTheme.lavender.opacity(0.45) : .black.opacity(0.06), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedGroupIDs.contains(group.id))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 156)
            }
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(categoryOptions) { option in
                            OshiFilterChip(
                                title: option.title,
                                isSelected: selectedGenreID == option.id
                            ) {
                                selectedGenreID = option.id
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    TextField("作品名・グループ名で検索", text: $searchText)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)
                .frame(height: 62)
                .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                }
                .padding(.horizontal, 18)
            }
            .padding(.top, 12)
            .padding(.bottom, 18)
            .background(MegrumTheme.canvas.opacity(0.96))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.black.opacity(0.08))
                    .frame(height: 0.5)
            }
        }
    }

    private func masterMeta(for group: OshiGroup) -> String {
        let kind = group.kind.displayName
        let count = charactersByGroupID[group.id]?.count
        if group.kind == .solo {
            return kind
        }
        if let count {
            return "\(kind) / \(count)メンバー"
        }
        return kind
    }
}

private struct OshiRequestSheet: View {
    var state: OshiRequestSheetState
    var genres: [OshiGenre]
    var onClose: () -> Void
    var onSubmit: (OshiRequestSheetPayload) -> Void

    @State private var name: String
    @State private var note = ""
    @State private var kind: OshiRequestKind = .group
    @State private var genreID: UUID?

    init(
        state: OshiRequestSheetState,
        genres: [OshiGenre],
        onClose: @escaping () -> Void,
        onSubmit: @escaping (OshiRequestSheetPayload) -> Void
    ) {
        self.state = state
        self.genres = genres
        self.onClose = onClose
        self.onSubmit = onSubmit
        _name = State(initialValue: state.initialName ?? "")
    }

    private var canSubmit: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("推し追加リクエスト")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text("送信後、推し設定に仮登録されます")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(width: 48, height: 48)
                            .background(.black.opacity(0.04), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                TextField("グループ・作品名", text: $name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .padding(.horizontal, 16)
                    .frame(height: 66)
                    .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                    }

                FlowLayout(spacing: 9, rowSpacing: 9) {
                    ForEach(OshiRequestKind.allCases) { option in
                        OshiFilterChip(title: option.displayName, isSelected: kind == option) {
                            kind = option
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        OshiFilterChip(title: "ジャンル未選択", isSelected: genreID == nil) {
                            genreID = nil
                        }
                        ForEach(genres) { genre in
                            OshiFilterChip(title: genre.name, isSelected: genreID == genre.id) {
                                genreID = genre.id
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                TextField("補足（任意）", text: $note, axis: .vertical)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .lineLimit(4, reservesSpace: true)
                    .padding(16)
                    .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                    }

                Button {
                    onSubmit(
                        OshiRequestSheetPayload(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
                            kind: kind,
                            genreID: genreID
                        )
                    )
                } label: {
                    Text("送信して仮登録")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(canSubmit ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.25), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}

private struct OshiFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 18)
                .frame(height: 46)
                .background(isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? MegrumTheme.lavender : .black.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct OshiEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("推しが未設定です")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("左下の「推しを追加」からグループ・作品を追加できます。")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
                .foregroundStyle(.black.opacity(0.12))
        }
    }
}

private struct OshiInlineLoading: View {
    var text: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(MegrumTheme.lavender)
            Text(text)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private enum OshiPalette {
    static let warn = Color(red: 0.84, green: 0.46, blue: 0.36)
}

private struct FlowLayout<Content: View>: View {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    var content: Content

    init(spacing: CGFloat = 8, rowSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 68), spacing: spacing)],
            alignment: .leading,
            spacing: rowSpacing
        ) {
            content
        }
    }
}

private struct OshiSettingsGroupDraft: Identifiable, Hashable, Sendable {
    var groupID: UUID?
    var requestID: UUID?
    var name: String
    var pending: Bool
    var priority: Int
    var members: [OshiSettingsMemberDraft]

    var key: String {
        if let groupID {
            return "master:\(groupID.uuidString)"
        }
        return "request:\(requestID?.uuidString ?? name)"
    }

    var id: String { key }

    init(masterGroup: OshiGroup, priority: Int) {
        self.groupID = masterGroup.id
        self.requestID = nil
        self.name = masterGroup.name
        self.pending = false
        self.priority = priority
        self.members = []
    }

    init(requestID: UUID, name: String, pending: Bool, priority: Int, members: [OshiSettingsMemberDraft] = []) {
        self.groupID = nil
        self.requestID = requestID
        self.name = name
        self.pending = pending
        self.priority = priority
        self.members = members
    }

    static func build(selections: [UserOshiSelection], masterGroups: [OshiGroup]) -> [OshiSettingsGroupDraft] {
        let groupsByID = Dictionary(uniqueKeysWithValues: masterGroups.map { ($0.id, $0) })
        var result: [String: OshiSettingsGroupDraft] = [:]

        for selection in selections.sorted(by: { $0.priority < $1.priority }) {
            let groupKey: String
            let baseGroup: OshiSettingsGroupDraft
            if let groupID = selection.groupID {
                groupKey = "master:\(groupID.uuidString)"
                baseGroup = OshiSettingsGroupDraft(
                    groupID: groupID,
                    requestID: nil,
                    name: selection.groupName ?? groupsByID[groupID]?.name ?? "選択済みグループ",
                    pending: false,
                    priority: selection.priority,
                    members: []
                )
            } else if let requestID = selection.oshiRequestID {
                groupKey = "request:\(requestID.uuidString)"
                baseGroup = OshiSettingsGroupDraft(
                    groupID: nil,
                    requestID: requestID,
                    name: selection.oshiRequestName ?? "承認待ちの推し",
                    pending: true,
                    priority: selection.priority,
                    members: []
                )
            } else {
                continue
            }

            var group = result[groupKey] ?? baseGroup
            group.priority = min(group.priority, selection.priority)
            if let characterID = selection.characterID {
                group.members.append(
                    OshiSettingsMemberDraft(
                        characterID: characterID,
                        name: selection.characterName ?? "選択済みメンバー",
                        pending: false
                    )
                )
            } else if let characterRequestID = selection.characterRequestID {
                group.members.append(
                    OshiSettingsMemberDraft(
                        characterRequestID: characterRequestID,
                        name: selection.characterRequestName ?? "承認待ちメンバー",
                        pending: true
                    )
                )
            }
            result[groupKey] = group
        }

        return Array(result.values).sorted { lhs, rhs in
            lhs.priority == rhs.priority ? lhs.name.localizedCompare(rhs.name) == .orderedAscending : lhs.priority < rhs.priority
        }
    }

    static func accountSetupInputs(from groups: [OshiSettingsGroupDraft]) -> [AccountSetupOshiInput] {
        groups.reprioritized().flatMap { group -> [AccountSetupOshiInput] in
            if group.members.isEmpty {
                return [
                    AccountSetupOshiInput(
                        groupID: group.groupID,
                        characterID: nil,
                        kind: .box,
                        priority: group.priority,
                        oshiRequestID: group.requestID,
                        characterRequestID: nil
                    )
                ]
            }
            return group.members.enumerated().map { memberOffset, member in
                AccountSetupOshiInput(
                    groupID: group.groupID,
                    characterID: member.characterID,
                    kind: .specific,
                    priority: group.priority * 1_000 + memberOffset,
                    oshiRequestID: group.requestID,
                    characterRequestID: member.characterRequestID
                )
            }
        }
    }

    private init(
        groupID: UUID?,
        requestID: UUID?,
        name: String,
        pending: Bool,
        priority: Int,
        members: [OshiSettingsMemberDraft]
    ) {
        self.groupID = groupID
        self.requestID = requestID
        self.name = name
        self.pending = pending
        self.priority = priority
        self.members = members
    }
}

private struct OshiSettingsMemberDraft: Identifiable, Hashable, Sendable {
    var characterID: UUID?
    var characterRequestID: UUID?
    var name: String
    var pending: Bool

    var id: String {
        if let characterID {
            return "master:\(characterID.uuidString)"
        }
        return "request:\(characterRequestID?.uuidString ?? name)"
    }

    init(character: OshiCharacter) {
        self.characterID = character.id
        self.characterRequestID = nil
        self.name = character.name
        self.pending = false
    }

    init(characterID: UUID? = nil, characterRequestID: UUID? = nil, name: String, pending: Bool) {
        self.characterID = characterID
        self.characterRequestID = characterRequestID
        self.name = name
        self.pending = pending
    }
}

private struct OshiCategoryOption: Identifiable {
    var id: UUID?
    var title: String
}

private enum OshiRequestSheetState: Identifiable, Hashable {
    case oshi(initialName: String?)

    var id: String {
        switch self {
        case .oshi(let initialName):
            "oshi:\(initialName ?? "")"
        }
    }

    var initialName: String? {
        if case .oshi(let initialName) = self {
            return initialName
        }
        return nil
    }
}

private struct OshiRequestSheetPayload {
    var name: String
    var note: String?
    var kind: OshiRequestKind
    var genreID: UUID?
}

private extension Array where Element == OshiSettingsGroupDraft {
    func reprioritized() -> [OshiSettingsGroupDraft] {
        enumerated().map { offset, group in
            var next = group
            next.priority = offset + 1
            return next
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        reduce(into: []) { result, element in
            if !result.contains(element) {
                result.append(element)
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
