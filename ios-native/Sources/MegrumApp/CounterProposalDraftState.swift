import Foundation
import MegrumCore

struct CounterProposalDraftState: Equatable {
    var exchangeMethod: ExchangeMethod
    var selectedConditionTags: Set<String>
    var message: String

    init(
        exchangeMethod: ExchangeMethod,
        selectedConditionTags: Set<String>,
        message: String = ""
    ) {
        self.exchangeMethod = exchangeMethod
        self.selectedConditionTags = selectedConditionTags
        self.message = message
    }

    init(proposal: TradeProposal) {
        self.init(
            exchangeMethod: proposal.exchangeMethod,
            selectedConditionTags: Set(proposal.conditionTags)
        )
    }

    var submittedMessage: String? {
        message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank
    }

    static func availableConditionTags(
        defaultOptions: [String],
        proposalTags: [String]
    ) -> [String] {
        var seen = Set<String>()
        return (defaultOptions + proposalTags).filter { tag in
            seen.insert(tag).inserted
        }
    }

    func orderedConditionTags(in availableConditionTags: [String]) -> [String] {
        availableConditionTags.filter { selectedConditionTags.contains($0) }
    }

    mutating func toggleConditionTag(_ tag: String) {
        if selectedConditionTags.contains(tag) {
            selectedConditionTags.remove(tag)
        } else {
            selectedConditionTags.insert(tag)
        }
    }
}
