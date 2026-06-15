@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabaseTradeSchedulePersistenceTests: XCTestCase {
    private let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000001101")!
    private let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000001102")!

    func testScheduleParticipantIDsReturnViewerAndPartnerForSenderViewer() {
        let proposal = makeProposal(senderID: viewerID, receiverID: partnerID)

        let ids = SupabaseTradeSchedulePersistence.scheduleParticipantIDs(
            for: proposal,
            viewerID: viewerID
        )

        XCTAssertEqual(ids, [viewerID, partnerID])
    }

    func testScheduleParticipantIDsReturnViewerAndPartnerForReceiverViewer() {
        let proposal = makeProposal(senderID: partnerID, receiverID: viewerID)

        let ids = SupabaseTradeSchedulePersistence.scheduleParticipantIDs(
            for: proposal,
            viewerID: viewerID
        )

        XCTAssertEqual(ids, [viewerID, partnerID])
    }

    func testScheduleParticipantIDsReturnEmptyForNonParticipant() {
        let proposal = makeProposal(senderID: partnerID, receiverID: UUID())

        let ids = SupabaseTradeSchedulePersistence.scheduleParticipantIDs(
            for: proposal,
            viewerID: viewerID
        )

        XCTAssertTrue(ids.isEmpty)
    }

    private func makeProposal(senderID: UUID, receiverID: UUID) -> TradeProposal {
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001103")!,
            senderID: senderID,
            receiverID: receiverID,
            status: .agreed,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
    }
}
