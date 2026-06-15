import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiMasterSelectSheet: View {
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

struct OshiFilterChip: View {
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

struct FlowLayout<Content: View>: View {
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

private struct OshiCategoryOption: Identifiable {
    var id: UUID?
    var title: String
}

enum OshiRequestSheetState: Identifiable, Hashable {
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

struct OshiRequestSheetPayload {
    var name: String
    var note: String?
    var kind: OshiRequestKind
    var genreID: UUID?
}
