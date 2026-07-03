import Foundation
import MegrumCore

struct OshiRequestDraftState: Equatable {
    var name: String
    var note = ""
    var kind: OshiRequestKind = .group
    var genreID: UUID?

    init(initialName: String? = nil) {
        self.name = initialName ?? ""
    }

    var canSubmit: Bool {
        !name.isBlank
    }

    var payload: OshiRequestSheetPayload {
        OshiRequestSheetPayload(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.nilIfBlank,
            kind: kind,
            genreID: genreID
        )
    }
}

struct OshiMemberRequestDraftState: Equatable {
    var name: String
    var note = ""

    init(initialName: String? = nil) {
        self.name = initialName ?? ""
    }

    var canSubmit: Bool {
        !name.isBlank
    }

    var payload: OshiMemberRequestSheetPayload {
        OshiMemberRequestSheetPayload(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.nilIfBlank
        )
    }
}
