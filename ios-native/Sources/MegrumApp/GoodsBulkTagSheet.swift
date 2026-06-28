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
    var imageSuggestionNames: [String] = []
    var isSuggestingFromImage = false
    var imageSuggestionError: String?
    var canSuggestFromImage = true
    var onSuggestFromImage: (() -> Void)?
    var onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tagDraft = ""
    @State private var selectedCandidateNames: [String] = []

    private var trimmedTag: String {
        tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var combinedCandidateNames: [String] {
        TagNameNormalizer.uniquePreservingOrder(candidateNames + imageSuggestionNames, limit: 18)
    }

    var body: some View {
        NavigationStack {
            Form {
                if !combinedCandidateNames.isEmpty {
                    Section {
                        TagCandidatePreviewSelector(
                            candidateNames: combinedCandidateNames,
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

                if onSuggestFromImage != nil {
                    Section {
                        Button {
                            MegrumHaptics.performSelectionChanged {
                                onSuggestFromImage?()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isSuggestingFromImage {
                                    ProgressView()
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text("画像からシリーズ名称の候補を出す")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .disabled(isSuggestingFromImage || !canSuggestFromImage)

                        if let imageSuggestionError, !imageSuggestionError.isEmpty {
                            Text(imageSuggestionError)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    } footer: {
                        if canSuggestFromImage {
                            Text("登録した画像と選択中のグループ情報を使って候補を検索します。")
                        } else {
                            Text("画像を登録すると、画像からシリーズ候補を検索できます。")
                        }
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
