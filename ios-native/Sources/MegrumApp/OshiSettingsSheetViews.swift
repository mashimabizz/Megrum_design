import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiMasterSelectSheet: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var selectedGroupIDs: Set<UUID>
    var charactersByGroupID: [UUID: [OshiCharacter]]
    var allowsMultipleSelection = false
    var onClose: () -> Void
    var onRequest: (String?) -> Void
    var onSelect: (OshiGroup) -> Void
    var onRegisterSelected: (([OshiGroup]) -> Void)?

    @State private var searchText = ""
    @State private var selectedGenreID: UUID?
    @State private var pendingSelectedGroupIDs: Set<UUID> = []

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

    private var pendingSelectedGroups: [OshiGroup] {
        OshiMasterSelectionReducer.selectedGroups(from: groups, selectedIDs: pendingSelectedGroupIDs)
    }

    private var scrollBottomPadding: CGFloat {
        OshiMasterSelectLayoutMetrics.bottomContentPadding
            + (pendingSelectedGroupIDs.isEmpty ? 0 : OshiMasterSelectLayoutMetrics.selectedActionExtraPadding)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("推しを追加")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
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
            .padding(.bottom, 10)

            ScrollView {
                WrappingTagFlow(
                    spacing: OshiMasterSelectLayoutMetrics.candidateTagSpacing,
                    rowSpacing: OshiMasterSelectLayoutMetrics.candidateTagRowSpacing
                ) {
                    ForEach(filteredGroups) { group in
                        OshiMasterCandidateTag(
                            title: group.name,
                            isSelected: isSelected(group),
                            isLocked: selectedGroupIDs.contains(group.id),
                            action: { handleCandidateTap(group) }
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, scrollBottomPadding)
            }
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                OshiGenreSegmentBar(options: categoryOptions, selection: $selectedGenreID)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    TextField("作品名・グループ名で検索", text: $searchText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .frame(height: OshiMasterSelectLayoutMetrics.searchHeight)
                .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                }
                .padding(.horizontal, 18)

                if allowsMultipleSelection, !pendingSelectedGroupIDs.isEmpty {
                    Text(OshiSettingsPresentationText.masterSelectionCountTitle(selectionCount: pendingSelectedGroupIDs.count))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .transition(.opacity)

                    Button(action: registerPendingSelection) {
                        Text(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: pendingSelectedGroupIDs.count))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: OshiMasterSelectLayoutMetrics.registerButtonHeight)
                            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityLabel(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: pendingSelectedGroupIDs.count))
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 14)
            .background(MegrumTheme.canvas.opacity(0.96))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.black.opacity(0.08))
                    .frame(height: 0.5)
            }
        }
        .onAppear(perform: resetPendingSelection)
        .onChange(of: selectedGroupIDs) { _, _ in
            pendingSelectedGroupIDs = pendingSelectedGroupIDs.subtracting(selectedGroupIDs)
        }
        .animation(.snappy(duration: 0.18), value: pendingSelectedGroupIDs)
    }

    private func isSelected(_ group: OshiGroup) -> Bool {
        selectedGroupIDs.contains(group.id) || pendingSelectedGroupIDs.contains(group.id)
    }

    private func handleCandidateTap(_ group: OshiGroup) {
        guard allowsMultipleSelection else {
            onSelect(group)
            return
        }
        pendingSelectedGroupIDs = OshiMasterSelectionReducer.toggling(
            groupID: group.id,
            selectedIDs: pendingSelectedGroupIDs,
            lockedIDs: selectedGroupIDs
        )
    }

    private func registerPendingSelection() {
        let selectedGroups = pendingSelectedGroups
        guard !selectedGroups.isEmpty else {
            return
        }
        pendingSelectedGroupIDs = []
        if let onRegisterSelected {
            onRegisterSelected(selectedGroups)
        } else {
            selectedGroups.forEach(onSelect)
        }
    }

    private func resetPendingSelection() {
        pendingSelectedGroupIDs = []
    }
}

private struct OshiGenreSegmentBar: View {
    var options: [OshiCategoryOption]
    @Binding var selection: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        withAnimation(.snappy(duration: 0.16)) {
                            selection = option.id
                        }
                    } label: {
                        Text(option.title)
                            .font(.system(size: 13.5, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .foregroundStyle(selection == option.id ? .white : MegrumTheme.ink)
                            .padding(.horizontal, 15)
                            .frame(minWidth: OshiMasterSelectLayoutMetrics.genreSegmentMinWidth)
                            .frame(height: OshiMasterSelectLayoutMetrics.genreSegmentHeight - 6)
                            .background(selection == option.id ? MegrumTheme.lavender : .clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)

                    if index < options.count - 1 {
                        Rectangle()
                            .fill(.black.opacity(0.08))
                            .frame(width: 0.5, height: 18)
                            .padding(.horizontal, 2)
                    }
                }
            }
            .padding(3)
            .background(.white.opacity(0.94), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 1)
        }
    }
}

private struct OshiMasterCandidateTag: View {
    var title: String
    var isSelected: Bool
    var isLocked: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14.5, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .foregroundStyle(foregroundStyle)
                .padding(.horizontal, OshiMasterSelectLayoutMetrics.candidateTagHorizontalPadding)
                .frame(
                    minWidth: OshiMasterSelectLayoutMetrics.candidateTagMinimumWidth,
                    minHeight: OshiMasterSelectLayoutMetrics.candidateTagMinHeight
                )
                .background(
                    backgroundStyle,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(borderStyle, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel(isSelected ? "\(title)、選択済み" : title)
    }

    private var foregroundStyle: AnyShapeStyle {
        if isSelected, !isLocked {
            return AnyShapeStyle(.white)
        }
        if isSelected {
            return AnyShapeStyle(MegrumTheme.lavender.opacity(0.82))
        }
        return AnyShapeStyle(MegrumTheme.ink)
    }

    private var backgroundStyle: AnyShapeStyle {
        if isSelected, !isLocked {
            return AnyShapeStyle(MegrumTheme.lavender)
        }
        if isSelected {
            return AnyShapeStyle(MegrumTheme.lavender.opacity(0.10))
        }
        return AnyShapeStyle(.white.opacity(0.94))
    }

    private var borderStyle: Color {
        isSelected ? MegrumTheme.lavender.opacity(isLocked ? 0.34 : 0.8) : .black.opacity(0.08)
    }
}

struct OshiRequestSheet: View {
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
        !name.isBlank
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("推し追加リクエスト")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
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

                WrappingTagFlow(spacing: 9, rowSpacing: 9) {
                    ForEach(OshiRequestKind.allCases) { option in
                        OshiFilterChip(title: option.displayName, isSelected: kind == option) {
                            kind = option
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("ジャンル")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)

                    WrappingTagFlow(spacing: 9, rowSpacing: 9) {
                        OshiFilterChip(title: "ジャンル未選択", isSelected: genreID == nil) {
                            genreID = nil
                        }
                        ForEach(genres) { genre in
                            OshiFilterChip(title: genre.name, isSelected: genreID == genre.id) {
                                genreID = genre.id
                            }
                        }
                    }
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
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, OshiRequestSheetLayoutMetrics.scrollBottomPadding)
        }
        .safeAreaInset(edge: .bottom) {
            OshiRequestSubmitFooter(
                canSubmit: canSubmit,
                onSubmit: submitRequest
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func submitRequest() {
        onSubmit(
            OshiRequestSheetPayload(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.nilIfBlank,
                kind: kind,
                genreID: genreID
            )
        )
    }
}

struct OshiMemberRequestSheet: View {
    var context: OshiMemberRequestContext
    var onClose: () -> Void
    var onSubmit: (OshiMemberRequestSheetPayload) -> Void

    @State private var name: String
    @State private var note = ""

    init(
        context: OshiMemberRequestContext,
        onClose: @escaping () -> Void,
        onSubmit: @escaping (OshiMemberRequestSheetPayload) -> Void
    ) {
        self.context = context
        self.onClose = onClose
        self.onSubmit = onSubmit
        _name = State(initialValue: context.initialName ?? "")
    }

    private var canSubmit: Bool {
        !name.isBlank
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(OshiSettingsPresentationText.memberRequestSheetTitle)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(context.groupName)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
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

                TextField(OshiSettingsPresentationText.memberRequestPlaceholder, text: $name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .padding(.horizontal, 16)
                    .frame(height: 66)
                    .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.black.opacity(0.08), lineWidth: 1)
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
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, OshiRequestSheetLayoutMetrics.scrollBottomPadding)
        }
        .safeAreaInset(edge: .bottom) {
            OshiRequestSubmitFooter(
                canSubmit: canSubmit,
                onSubmit: submitRequest
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func submitRequest() {
        onSubmit(
            OshiMemberRequestSheetPayload(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.nilIfBlank
            )
        )
    }
}

struct OshiFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.84)
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

private struct OshiRequestSubmitFooter: View {
    var canSubmit: Bool
    var onSubmit: () -> Void

    var body: some View {
        Button(action: onSubmit) {
            Text("送信して仮登録")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: OshiRequestSheetLayoutMetrics.submitButtonHeight)
                .background(
                    canSubmit ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.25),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(MegrumTheme.canvas.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }
}
