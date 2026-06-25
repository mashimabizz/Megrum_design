import Foundation
import MegrumDesign
import SwiftUI

struct GoodsEditorTagsSection: View {
    var tagNames: [String]
    var suggestedTagNames: [String] = []
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    var isItemReadOnly: Bool
    var onOpenTagSheet: (() -> Void)? = nil
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
                GoodsEditorSelectedTagList(
                    tagNames: tagNames,
                    isItemReadOnly: isItemReadOnly,
                    onRemoveTag: onRemoveTag
                )

                if let onOpenTagSheet {
                    GoodsEditorTagPickerButton(
                        tagCount: tagNames.count,
                        isItemReadOnly: isItemReadOnly,
                        action: onOpenTagSheet
                    )
                } else {
                    GoodsEditorSuggestedTagList(
                        tagNames: availableSuggestedTags,
                        currentTagCount: tagNames.count,
                        isItemReadOnly: isItemReadOnly,
                        onAddSuggestedTag: onAddSuggestedTag
                    )

                    GoodsEditorTagInputRow(
                        tagDraft: $tagDraft,
                        isTagFieldFocused: isTagFieldFocused,
                        isItemReadOnly: isItemReadOnly,
                        canAddTag: canAddTag,
                        onAddTag: onAddTag
                    )
                }

                Text("タグは5件まで入力できます。保存時にグッズへ反映されます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}
