import MegrumDesign
import Foundation
import SwiftUI

struct GoodsBulkTagRoute: Identifiable, Equatable {
    var itemIDs: Set<UUID>

    var id: String {
        itemIDs.map(\.uuidString).sorted().joined(separator: "-")
    }
}

struct GoodsBulkTagSheet: View {
    var selectedCount: Int
    var candidateNames: [String] = []
    var previewItemsByTag: [String: [TagPreviewItem]] = [:]
    var navigationTitle = "シリーズを設定"
    var textFieldPlaceholder = "例：会場限定"
    var footerText: String?
    var confirmationTitle = "追加"
    var onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tagDraft = ""
    @State private var selectedCandidateNames: [String] = []

    private var trimmedTag: String {
        tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                if !candidateNames.isEmpty {
                    Section {
                        TagCandidatePreviewSelector(
                            candidateNames: candidateNames,
                            previewItemsByTag: previewItemsByTag,
                            selectedNames: $selectedCandidateNames,
                            maxSelection: 1,
                            emptyMessage: "このグループに紐づくシリーズ候補はまだありません",
                            onToggle: toggleCandidateTag
                        )
                    } header: {
                        Text("候補")
                    } footer: {
                        Text("候補はもう一度タップすると入力欄に入ります。")
                    }
                }

                Section {
                    TextField(textFieldPlaceholder, text: $tagDraft)
                } header: {
                    Text("追加するシリーズ")
                } footer: {
                    Text(footerText ?? "\(selectedCount)件のグッズに同じシリーズを追加します。")
                }
            }
            .navigationTitle(navigationTitle)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmationTitle) {
                        MegrumHaptics.performSelectionChanged {
                            onApply(trimmedTag)
                            dismiss()
                        }
                    }
                    .disabled(trimmedTag.isEmpty)
                }
            }
        }
    }

    private func toggleCandidateTag(_ name: String) {
        if selectedCandidateNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            selectedCandidateNames = []
            if trimmedTag.caseInsensitiveCompare(name) == .orderedSame {
                tagDraft = ""
            }
        } else {
            selectedCandidateNames = [name]
            tagDraft = name
        }
    }
}
