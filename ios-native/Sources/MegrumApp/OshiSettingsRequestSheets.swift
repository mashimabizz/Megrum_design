import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiRequestSheet: View {
    var state: OshiRequestSheetState
    var genres: [OshiGenre]
    var onClose: () -> Void
    var onSubmit: (OshiRequestSheetPayload) -> Void

    @State private var draftState: OshiRequestDraftState

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
        _draftState = State(initialValue: OshiRequestDraftState(initialName: state.initialName))
    }

    var body: some View {
        OshiRequestSheetContent(
            name: $draftState.name,
            note: $draftState.note,
            kind: $draftState.kind,
            genreID: $draftState.genreID,
            genres: genres,
            onClose: onClose
        )
        .safeAreaInset(edge: .bottom) {
            OshiRequestSubmitFooter(
                canSubmit: draftState.canSubmit,
                onSubmit: submitRequest
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func submitRequest() {
        onSubmit(draftState.payload)
    }
}

struct OshiMemberRequestSheet: View {
    var context: OshiMemberRequestContext
    var onClose: () -> Void
    var onSubmit: (OshiMemberRequestSheetPayload) -> Void

    @State private var draftState: OshiMemberRequestDraftState

    init(
        context: OshiMemberRequestContext,
        onClose: @escaping () -> Void,
        onSubmit: @escaping (OshiMemberRequestSheetPayload) -> Void
    ) {
        self.context = context
        self.onClose = onClose
        self.onSubmit = onSubmit
        _draftState = State(initialValue: OshiMemberRequestDraftState(initialName: context.initialName))
    }

    var body: some View {
        OshiMemberRequestSheetContent(
            context: context,
            name: $draftState.name,
            note: $draftState.note,
            onClose: onClose
        )
        .safeAreaInset(edge: .bottom) {
            OshiRequestSubmitFooter(
                canSubmit: draftState.canSubmit,
                onSubmit: submitRequest
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func submitRequest() {
        onSubmit(draftState.payload)
    }
}
