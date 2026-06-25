import MegrumDesign
import SwiftUI

struct GoodsEditorTagPickerButton: View {
    var tagCount: Int
    var isItemReadOnly: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "tag")
                    .font(.system(size: 15, weight: .black))
                Text(tagCount == 0 ? "タグを選ぶ" : "タグを追加")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .black))
            }
            .foregroundStyle(MegrumTheme.lavender)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isItemReadOnly || tagCount >= 5)
    }
}

struct GoodsEditorSelectedTagList: View {
    var tagNames: [String]
    var isItemReadOnly: Bool
    var onRemoveTag: (String) -> Void

    var body: some View {
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
}

struct GoodsEditorSuggestedTagList: View {
    var tagNames: [String]
    var currentTagCount: Int
    var isItemReadOnly: Bool
    var onAddSuggestedTag: (String) -> Void

    var body: some View {
        if !tagNames.isEmpty {
            GoodsEditorFlowLayout(spacing: 8) {
                ForEach(tagNames, id: \.self) { tag in
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
                    .disabled(isItemReadOnly || currentTagCount >= 5)
                }
            }
        }
    }
}

struct GoodsEditorTagInputRow: View {
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    var isItemReadOnly: Bool
    var canAddTag: Bool
    var onAddTag: () -> Void

    var body: some View {
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
