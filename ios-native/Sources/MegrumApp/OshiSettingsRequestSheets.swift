import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiRequestSheet: View {
    var state: OshiRequestSheetState
    var genres: [OshiGenre]
    var onClose: () -> Void
    var onSubmit: (OshiRequestSheetPayload) -> Void

    @State private var name: String
    @State private var note = ""
    @State private var kind: OshiRequestKind = .group
    @State private var genreID: UUID?

    init(
        state: OshiRequestSheetState,
        genres: [OshiGenre],
        onClose: @escaping () -> Void,
        onSubmit: @escaping (OshiRequestSheetPayload) -> Void
    ) {
        self.state = state
        self.genres = genres
        self.onClose = onClose
        self.onSubmit = onSubmit
        _name = State(initialValue: state.initialName ?? "")
    }

    private var canSubmit: Bool {
        !name.isBlank
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("推し追加リクエスト")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
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

                TextField("グループ・作品名", text: $name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .padding(.horizontal, 16)
                    .frame(height: 66)
                    .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                    }

                WrappingTagFlow(spacing: 9, rowSpacing: 9) {
                    ForEach(OshiRequestKind.allCases) { option in
                        OshiFilterChip(title: option.displayName, isSelected: kind == option) {
                            kind = option
                        }
                    }
                }

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
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, OshiRequestSheetLayoutMetrics.scrollBottomPadding)
        }
        .safeAreaInset(edge: .bottom) {
            OshiRequestSubmitFooter(
                canSubmit: canSubmit,
                onSubmit: submitRequest
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func submitRequest() {
        onSubmit(
            OshiRequestSheetPayload(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.nilIfBlank,
                kind: kind,
                genreID: genreID
            )
        )
    }
}

struct OshiMemberRequestSheet: View {
    var context: OshiMemberRequestContext
    var onClose: () -> Void
    var onSubmit: (OshiMemberRequestSheetPayload) -> Void

    @State private var name: String
    @State private var note = ""

    init(
        context: OshiMemberRequestContext,
        onClose: @escaping () -> Void,
        onSubmit: @escaping (OshiMemberRequestSheetPayload) -> Void
    ) {
        self.context = context
        self.onClose = onClose
        self.onSubmit = onSubmit
        _name = State(initialValue: context.initialName ?? "")
    }

    private var canSubmit: Bool {
        !name.isBlank
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(OshiSettingsPresentationText.memberRequestSheetTitle)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(context.groupName)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
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

                TextField(OshiSettingsPresentationText.memberRequestPlaceholder, text: $name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .padding(.horizontal, 16)
                    .frame(height: 66)
                    .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                    }

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
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, OshiRequestSheetLayoutMetrics.scrollBottomPadding)
        }
        .safeAreaInset(edge: .bottom) {
            OshiRequestSubmitFooter(
                canSubmit: canSubmit,
                onSubmit: submitRequest
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func submitRequest() {
        onSubmit(
            OshiMemberRequestSheetPayload(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.nilIfBlank
            )
        )
    }
}
