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
        OshiRequestSheetContent(
            name: $name,
            note: $note,
            kind: $kind,
            genreID: $genreID,
            genres: genres,
            onClose: onClose
        )
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
        OshiMemberRequestSheetContent(
            context: context,
            name: $name,
            note: $note,
            onClose: onClose
        )
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
