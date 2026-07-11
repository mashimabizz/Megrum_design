import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TagPreviewItem: Identifiable, Hashable {
    var id: UUID
    var title: String
    var imageURL: URL?
}

struct TagCandidatePreviewSelector: View {
    var candidateNames: [String]
    var previewItemsByTag: [String: [TagPreviewItem]]
    @Binding var selectedNames: [String]
    var maxSelection = 5
    var emptyMessage = "シリーズ候補はまだありません"
    var onToggle: (String) -> Void

    @State private var previewState = TagCandidatePreviewSelectionState()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !selectedNames.isEmpty {
                selectedTags
            }

            if candidateNames.isEmpty {
                Text(emptyMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
            } else {
                // iter1226.452：タグの高さを固定（プレビュー画像はタグ列の下に別枠で出す）。
                // 以前はプレビュー吹き出しがタグのセル内に入り、選択のたびに折り返しが変わって
                // タグの位置がズレ、押しづらくなっていた。
                WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                    ForEach(candidateNames, id: \.self) { name in
                        tagButton(name)
                    }
                }

                if let previewedName = previewState.previewedName,
                   !isSelected(previewedName),
                   candidateNames.contains(previewedName) {
                    TagCandidatePreviewGroup(
                        name: previewedName,
                        items: previewItemsByTag[previewedName] ?? [],
                        onRegister: {
                            MegrumHaptics.performSelectionChanged {
                                toggle(previewedName)
                            }
                        }
                    )
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var selectedTags: some View {
        WrappingTagFlow(spacing: 8, rowSpacing: 8) {
            ForEach(selectedNames, id: \.self) { name in
                Button {
                    MegrumHaptics.performSelectionChanged {
                        toggle(name)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("#\(name)")
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 29)
                    .background(MegrumTheme.lavender, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tagButton(_ name: String) -> some View {
        let selected = isSelected(name)
        let previewing = previewState.isPreviewing(name)
        let disabled = previewState.isDisabled(name, selectedNames: selectedNames, maxSelection: maxSelection)
        return Button {
                if selected || previewing {
                    MegrumHaptics.performSelectionChanged {
                        toggle(name)
                    }
                } else {
                    MegrumHaptics.buttonTap()
                    withAnimation(.smooth(duration: 0.18)) {
                        previewState.preview(name)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text("#\(name)")
                    if previewing && !selected {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 10, weight: .black))
                    }
                }
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(selected ? .white : MegrumTheme.lavender)
                .lineLimit(1)
                .padding(.horizontal, 11)
                .frame(height: 30)
                .background(
                    selected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(MegrumTheme.lavender.opacity(previewing ? 0.16 : 0.10)),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(MegrumTheme.lavender.opacity(previewing ? 0.45 : 0.22), lineWidth: 1)
                }
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("シリーズ候補 #\(name)")
        .accessibilityHint(previewing ? "もう一度タップするとこのシリーズを選択します" : "タップすると紐づく画像を下に表示します")
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }

    private func toggle(_ name: String) {
        withAnimation(.smooth(duration: 0.18)) {
            onToggle(name)
            previewState.clearPreview(ifMatches: name)
        }
    }

    private func isSelected(_ name: String) -> Bool {
        previewState.isSelected(name, selectedNames: selectedNames)
    }
}

/// iter1226.452：候補タグ列の「下」に別枠で出す紐づき画像プレビュー。
/// タグのセル内に入れないので、タップしてもタグの折り返し順は変わらない。
private struct TagCandidatePreviewGroup: View {
    var name: String
    var items: [TagPreviewItem]
    var onRegister: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("#\(name)")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 8)
                Button(action: onRegister) {
                    Text("このシリーズを登録")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(MegrumTheme.lavender, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if items.isEmpty {
                Text("紐づく画像はまだありません")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(height: 44)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 8)
                                .frame(width: 52, height: 52)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.lavender.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
    }
}
