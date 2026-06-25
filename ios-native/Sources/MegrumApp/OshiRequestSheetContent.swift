import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiRequestSheetContent: View {
    @Binding var name: String
    @Binding var note: String
    @Binding var kind: OshiRequestKind
    @Binding var genreID: UUID?
    var genres: [OshiGenre]
    var onClose: () -> Void

    var body: some View {
        OshiRequestSheetScrollContent {
            OshiRequestHeader(title: "推し追加リクエスト", subtitle: nil, onClose: onClose)

            OshiRequestNameField(placeholder: "グループ・作品名", name: $name)

            WrappingTagFlow(spacing: 9, rowSpacing: 9) {
                ForEach(OshiRequestKind.allCases) { option in
                    OshiFilterChip(title: option.displayName, isSelected: kind == option) {
                        kind = option
                    }
                }
            }

            genreSection
            OshiRequestNoteField(note: $note)
        }
    }

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ジャンル")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            WrappingTagFlow(spacing: 9, rowSpacing: 9) {
                OshiFilterChip(title: "ジャンル未選択", isSelected: genreID == nil) {
                    genreID = nil
                }
                ForEach(genres) { genre in
                    OshiFilterChip(title: genre.name, isSelected: genreID == genre.id) {
                        genreID = genre.id
                    }
                }
            }
        }
    }
}

struct OshiMemberRequestSheetContent: View {
    var context: OshiMemberRequestContext
    @Binding var name: String
    @Binding var note: String
    var onClose: () -> Void

    var body: some View {
        OshiRequestSheetScrollContent {
            OshiRequestHeader(
                title: OshiSettingsPresentationText.memberRequestSheetTitle,
                subtitle: context.groupName,
                onClose: onClose
            )

            OshiRequestNameField(
                placeholder: OshiSettingsPresentationText.memberRequestPlaceholder,
                name: $name
            )

            OshiRequestNoteField(note: $note)
        }
    }
}

private struct OshiRequestSheetScrollContent<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content()
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, OshiRequestSheetLayoutMetrics.scrollBottomPadding)
        }
    }
}

private struct OshiRequestHeader: View {
    var title: String
    var subtitle: String?
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
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
    }
}

private struct OshiRequestNameField: View {
    var placeholder: String
    @Binding var name: String

    var body: some View {
        TextField(placeholder, text: $name)
            .font(.system(size: 16, weight: .black, design: .rounded))
            .padding(.horizontal, 16)
            .frame(height: 66)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct OshiRequestNoteField: View {
    @Binding var note: String

    var body: some View {
        TextField("補足（任意）", text: $note, axis: .vertical)
            .font(.system(size: 16, weight: .black, design: .rounded))
            .lineLimit(4, reservesSpace: true)
            .padding(16)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
            }
    }
}
