import MegrumCore

struct GoodsReportDraftState: Equatable {
    var reason: GoodsReportReason = .fakeItem
    var note = ""

    var submission: (reason: GoodsReportReason, note: String) {
        (reason, note)
    }
}
