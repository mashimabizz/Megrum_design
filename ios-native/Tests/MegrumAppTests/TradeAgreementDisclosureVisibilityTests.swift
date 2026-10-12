import Foundation
import MegrumCore
import Testing
@testable import MegrumApp

@Suite("TradeAgreementDisclosureVisibility")
struct TradeAgreementDisclosureVisibilityTests {
    private let sender = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    private let receiver = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!
    private let goodsA = UUID(uuidString: "00000000-0000-0000-0000-0000000000C3")!
    private let goodsB = UUID(uuidString: "00000000-0000-0000-0000-0000000000D4")!

    private func proposal(
        exchangeMethod: ExchangeMethod,
        senderGoodsIDs: [UUID],
        receiverGoodsIDs: [UUID],
        cashAmount: Int? = nil,
        cashAmountSide: ProposalCashSide? = nil
    ) -> TradeProposal {
        TradeProposal(
            id: UUID(),
            senderID: sender,
            receiverID: receiver,
            status: .agreed,
            exchangeMethod: exchangeMethod,
            senderGoodsIDs: senderGoodsIDs,
            receiverGoodsIDs: receiverGoodsIDs,
            cashOffer: cashAmount != nil,
            cashAmount: cashAmount,
            cashAmountSide: cashAmountSide
        )
    }

    @Test("郵送ぶつぶつ交換は双方に郵送先を出す")
    func mailBarterShowsMailingForBothSides() {
        let p = proposal(exchangeMethod: .mail, senderGoodsIDs: [goodsA], receiverGoodsIDs: [goodsB])

        let senderView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: sender)
        #expect(senderView.showsMailingInfo)
        #expect(!senderView.showsPaymentInfo)

        let receiverView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: receiver)
        #expect(receiverView.showsMailingInfo)
        #expect(!receiverView.showsPaymentInfo)
    }

    @Test("片方郵送・片方お金：グッズを送る側だけ郵送先、支払う側だけ支払い情報")
    func mailForCashSplitsDisclosureByRole() {
        // sender がグッズを郵送、receiver が金額を支払う。
        let p = proposal(
            exchangeMethod: .mail,
            senderGoodsIDs: [goodsA],
            receiverGoodsIDs: [],
            cashAmount: 1500,
            cashAmountSide: .receiver
        )

        // グッズを送る sender は相手の郵送先だけを見る。
        let senderView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: sender)
        #expect(senderView.showsMailingInfo)
        #expect(!senderView.showsPaymentInfo)

        // 金額を払う receiver は相手の支払い先だけを見る（グッズを送らないので郵送先は不要）。
        let receiverView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: receiver)
        #expect(!receiverView.showsMailingInfo)
        #expect(receiverView.showsPaymentInfo)
    }

    @Test("現地手渡し・金額なしは双方とも開示ボタンを出さない")
    func handExchangeWithoutCashShowsNothing() {
        let p = proposal(exchangeMethod: .hand, senderGoodsIDs: [goodsA], receiverGoodsIDs: [goodsB])

        let senderView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: sender)
        #expect(!senderView.showsAny)

        let receiverView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: receiver)
        #expect(!receiverView.showsAny)
    }

    @Test("支払う側の判定は sender 側でも同様に効く")
    func senderAsPayerSeesPaymentOnly() {
        // 現地手渡しだが sender が金額を上乗せして払うケース。
        let p = proposal(
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [goodsB],
            cashAmount: 800,
            cashAmountSide: .sender
        )

        let senderView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: sender)
        #expect(!senderView.showsMailingInfo)
        #expect(senderView.showsPaymentInfo)

        let receiverView = TradeAgreementDisclosureVisibility(proposal: p, viewerID: receiver)
        #expect(!receiverView.showsPaymentInfo)
    }
}
