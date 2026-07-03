import MegrumCore

struct TradeEvaluationDraftState: Equatable {
    var stars = 5
    var comment = ""

    var submittedComment: String? {
        comment.nilIfBlank
    }
}
