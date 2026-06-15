import Foundation
import MegrumDesign
import SwiftUI

struct GoodsEditorTagsSection: View {
    var tagNames: [String]
    var suggestedTagNames: [String] = []
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    var isItemReadOnly: Bool
    var onAddSuggestedTag: (String) -> Void = { _ in }
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void

    private var canAddTag: Bool {
        !isItemReadOnly
            && !tagDraft.isBlank
            && tagNames.count < 5
    }

    private var availableSuggestedTags: [String] {
        suggestedTagNames
            .filter { suggestion in
                !tagNames.contains { $0.caseInsensitiveCompare(suggestion) == .orderedSame }
            }
            .prefix(max(0, 5 - tagNames.count))
            .map(\.self)
    }

    var body: some View {
        GoodsEditorSectionContainer(title: "タグ", systemImage: "tag") {
            VStack(alignment: .leading, spacing: 12) {
                tagList
                suggestedTagList
                tagInput

                Text("タグは5件まで入力できます。保存時にグッズへ反映されます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    @ViewBuilder
    private var tagList: some View {
        if !tagNames.isEmpty {
            GoodsEditorFlowLayout(spacing: 8) {
                ForEach(tagNames, id: \.self) { tag in
                    Button {
                        onRemoveTag(tag)
                    } label: {
                        HStack(spacing: 5) {
                            Text("#\(tag)")
                            Image(systemName: "xmark")
                                .font(.caption.weight(.black))
                        }
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.9), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isItemReadOnly)
                }
            }
        }
    }

    @ViewBuilder
    private var suggestedTagList: some View {
        if !availableSuggestedTags.isEmpty {
            GoodsEditorFlowLayout(spacing: 8) {
                ForEach(availableSuggestedTags, id: \.self) { tag in
                    Button {
                        onAddSuggestedTag(tag)
                    } label: {
                        Text("#\(tag)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(MegrumTheme.lavender)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(isItemReadOnly || tagNames.count >= 5)
                }
            }
        }
    }

    private var tagInput: some View {
        HStack(spacing: 10) {
            TextField("例：会場限定", text: $tagDraft)
                .focused(isTagFieldFocused)
                .submitLabel(.done)
                .onSubmit(onAddTag)
                .megrumTextFieldStyle()
            Button("追加", action: onAddTag)
                .buttonStyle(.bordered)
                .tint(MegrumTheme.lavender)
                .disabled(!canAddTag)
        }
        .disabled(isItemReadOnly)
    }
}
