import Foundation
import MegrumDesign
import SwiftUI

struct GoodsEditorTagsSection: View {
    var tagNames: [String]
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    var isItemReadOnly: Bool
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void

    private var canAddTag: Bool {
        !isItemReadOnly
            && !tagDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && tagNames.count < 5
    }

    var body: some View {
        GoodsEditorSectionContainer(title: "タグ", systemImage: "tag") {
            VStack(alignment: .leading, spacing: 12) {
                tagList
                tagInput

                Text("タグは5件まで入力できます。保存時にグッズへ反映されます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    @ViewBuilder
    private var tagList: some View {
        if tagNames.isEmpty {
            Text("タグなし")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
        } else {
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
