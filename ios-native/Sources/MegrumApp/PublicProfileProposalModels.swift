import Foundation
import MegrumCore

struct ListingProposalTarget: Identifiable, Equatable {
    var listing: IndividualListing
    var targetItem: GoodsItem
    var receiverGoodsIDs: [UUID]

    var id: UUID { listing.id }

    init?(listing: IndividualListing, goodsByID: [UUID: GoodsItem]) {
        let receiverGoodsIDs = listing.haves.map(\.itemID).deduplicated()
        guard
            let targetItem = receiverGoodsIDs.compactMap({ goodsByID[$0] }).first
        else {
            return nil
        }
        self.listing = listing
        self.targetItem = targetItem
        self.receiverGoodsIDs = receiverGoodsIDs
    }
}

struct PublicProfileEvaluationListState: Equatable {
    var evaluationCount: Int
    var isLoading: Bool

    init(evaluations: [UserEvaluation], isLoading: Bool) {
        self.evaluationCount = evaluations.count
        self.isLoading = isLoading
    }

    var showsLoading: Bool {
        isLoading && evaluationCount == 0
    }

    var showsEmpty: Bool {
        !isLoading && evaluationCount == 0
    }
}

private extension Array where Element == UUID {
    func deduplicated() -> [UUID] {
        var seen: Set<UUID> = []
        return filter { seen.insert($0).inserted }
    }
}
