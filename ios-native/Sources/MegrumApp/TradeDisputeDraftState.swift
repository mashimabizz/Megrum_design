import Foundation
import MegrumCore

struct TradeDisputeDraftState: Equatable {
    var category: TradeDisputeCategory = .wrong
    var factMemo = ""

    var trimmedFactMemo: String {
        factMemo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedFactMemo.isEmpty
    }
}
