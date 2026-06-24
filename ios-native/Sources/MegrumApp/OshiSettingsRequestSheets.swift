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

struct OshiFilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 18)
                .frame(height: 46)
                .background(isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? MegrumTheme.lavender : .black.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct OshiRequestSubmitFooter: View {
    var canSubmit: Bool
    var onSubmit: () -> Void

    var body: some View {
        Button(action: onSubmit) {
            Text("送信して仮登録")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: OshiRequestSheetLayoutMetrics.submitButtonHeight)
                .background(
                    canSubmit ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.25),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(MegrumTheme.canvas.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }
}
