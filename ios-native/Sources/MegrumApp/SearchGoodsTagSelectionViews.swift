import MegrumDesign
import SwiftUI

struct SearchGoodsTagSelectionSheet: View {
    var candidateNames: [String]
    var selectedGroupName: String?
    @Binding var selectedTags: Set<String>

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var normalizedSearchText: String {
        searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
    }

    private var filteredCandidateNames: [String] {
        let normalized = normalizedSearchText
        guard !normalized.isEmpty else {
            return candidateNames
        }
        return candidateNames.filter { $0.localizedCaseInsensitiveContains(normalized) }
    }

    private var canAddSearchText: Bool {
        let normalized = normalizedSearchText
        guard !normalized.isEmpty else {
            return false
        }
        return !containsTag(normalized)
    }

    var body: some View {
        Form {
            Section {
                TextField("シリーズを検索・追加", text: $searchText)
                    .disableAutocorrection(true)

                if canAddSearchText {
                    Button {
                        MegrumHaptics.performSelectionChanged {
                            addTag(normalizedSearchText)
                            searchText = ""
                        }
                    } label: {
                        Label("「\(normalizedSearchText)」を追加", systemImage: "plus.circle.fill")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                    }
                }
            }

            if !selectedTags.isEmpty {
                Section("選択中") {
                    WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                        ForEach(selectedTags.sorted(), id: \.self) { tagName in
                            SearchFilterChip(title: tagName, isSelected: true) {
                                removeTag(tagName)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }

            Section(candidateSectionTitle) {
                if filteredCandidateNames.isEmpty {
                    Text("候補がありません。検索欄からシリーズを追加できます。")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                        ForEach(filteredCandidateNames, id: \.self) { tagName in
                            SearchFilterChip(title: tagName, isSelected: containsTag(tagName)) {
                                toggleTag(tagName)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("シリーズを選択")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完了") {
                    dismiss()
                }
            }
        }
    }

    private var candidateSectionTitle: String {
        if let selectedGroupName {
            return "\(selectedGroupName)のシリーズ候補"
        }
        return "推しに紐づくシリーズ候補"
    }

    private func toggleTag(_ tagName: String) {
        if containsTag(tagName) {
            removeTag(tagName)
        } else {
            addTag(tagName)
        }
    }

    private func addTag(_ tagName: String) {
        guard let normalized = TagNameNormalizer.uniquePreservingOrder([tagName]).first else {
            return
        }
        selectedTags.insert(normalized)
    }

    private func removeTag(_ tagName: String) {
        guard let existing = selectedTags.first(where: { $0.localizedCaseInsensitiveCompare(tagName) == .orderedSame }) else {
            return
        }
        selectedTags.remove(existing)
    }

    private func containsTag(_ tagName: String) -> Bool {
        selectedTags.contains { $0.localizedCaseInsensitiveCompare(tagName) == .orderedSame }
    }
}

private struct SearchWrappingTagPicker: View {
    var tags: [String]
    @Binding var selectedTags: Set<String>

    private let columns = [GridItem(.adaptive(minimum: 118), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                SearchFilterChip(title: tag, isSelected: selectedTags.contains(tag)) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
    }
}

private struct SearchFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performSelectionChanged(action)
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 18)
                .frame(minHeight: 46)
                .background(isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.regularMaterial), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(isSelected ? 0.7 : 0.45), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
