import Foundation
import MegrumCore

struct HomeProposalStartConfirmationPayload: Identifiable, Equatable {
    private static let fallbackSenderOwnerID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    var id = UUID()
    var proposalSelection: HomeDiscoveryProposalSelection
    var receiverGoods: [HomeMockGoods]
    var senderGoods: [HomeMockGoods]
    var senderCashAmount: Int?

    var receiverGoodsItems: [GoodsItem] {
        receiverGoods.map { $0.proposalGoodsItem() }
    }

    var senderGoodsItems: [GoodsItem] {
        senderGoods.map { $0.proposalGoodsItem(fallbackOwnerID: Self.fallbackSenderOwnerID) }
    }
}
