import MegrumCore

struct UserReportDraftState: Equatable {
    var reason: UserReportReason = .harassment
    var note = ""

    var submission: (reason: UserReportReason, note: String) {
        (reason, note)
    }
}
