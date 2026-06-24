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
    var emptyMessage = "タグ候補はまだありません"
    var onToggle: (String) -> Void

    @State private var previewedName: String?

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
                WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                    ForEach(candidateNames, id: \.self) { name in
                        tagButton(name)
                    }
                }
            }
        }
    }

    private var selectedTags: some View {
        WrappingTagFlow(spacing: 8, rowSpacing: 8) {
            ForEach(selectedNames, id: \.self) { name in
                Button {
                    toggle(name)
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
        let previewing = previewedName == name
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                if selected || previewing {
                    toggle(name)
                } else {
                    withAnimation(.smooth(duration: 0.18)) {
                        previewedName = name
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
            .accessibilityLabel("タグ候補 #\(name)")
            .accessibilityHint(previewing ? "もう一度タップするとこのタグを選択します" : "タップすると紐づく画像の吹き出しを表示します")
            .disabled(!selected && selectedNames.count >= maxSelection)
            .opacity(!selected && selectedNames.count >= maxSelection ? 0.45 : 1)

            if previewing && !selected {
                TagCandidatePreviewPopover(
                    name: name,
                    items: previewItemsByTag[name] ?? []
                )
                .padding(.top, 7)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topLeading)))
            }
        }
        .zIndex(previewing ? 2 : 0)
    }

    private func toggle(_ name: String) {
        withAnimation(.smooth(duration: 0.18)) {
            onToggle(name)
            if previewedName == name {
                previewedName = nil
            }
        }
    }

    private func isSelected(_ name: String) -> Bool {
        selectedNames.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }
}

private struct TagCandidatePreviewPopover: View {
    var name: String
    var items: [TagPreviewItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("#\(name)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("もう一度タップで登録")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            HStack(spacing: 8) {
                ForEach(items.prefix(3)) { item in
                    ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 8)
                        .frame(width: 44, height: 44)
                }
                if items.isEmpty {
                    Text("紐づく画像はまだありません")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(height: 44)
                }
            }
        }
        .padding(10)
        .frame(width: TagCandidatePreviewMetrics.width, alignment: .leading)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(alignment: .topLeading) {
            Triangle()
                .fill(.white.opacity(0.96))
                .frame(width: 16, height: 8)
                .offset(x: 24, y: -7)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 5)
    }
}

enum TagCandidatePreviewMetrics {
    static let width: CGFloat = 232
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
