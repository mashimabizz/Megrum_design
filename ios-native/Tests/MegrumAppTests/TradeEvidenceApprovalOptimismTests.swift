@testable import MegrumApp
import MegrumCore
import XCTest

final class TradeEvidenceApprovalOptimismTests: XCTestCase {
    func testProposalAfterApprovalCompletesAgreedProposalWhenBothParticipantsApproved() {
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000901")!
        let receiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000902")!
        let proposal = makeProposal(
            senderID: senderID,
            receiverID: receiverID,
            status: .agreed,
            approvedByReceiver: true
        )

        let approved = TradeEvidenceApprovalOptimism.proposalAfterApproval(proposal, viewerID: senderID)

        XCTAssertEqual(approved?.status, .completed)
        XCTAssertEqual(approved?.approvedBySender, true)
        XCTAssertEqual(approved?.approvedByReceiver, true)
        XCTAssertNotNil(approved?.completedAt)
    }

    func testProposalAfterApprovalIgnoresNonParticipant() {
        let proposal = makeProposal(
            senderID: UUID(uuidString: "00000000-0000-0000-0000-000000000903")!,
            receiverID: UUID(uuidString: "00000000-0000-0000-0000-000000000904")!,
            status: .agreed
        )

        let approved = TradeEvidenceApprovalOptimism.proposalAfterApproval(
            proposal,
            viewerID: UUID(uuidString: "00000000-0000-0000-0000-000000000905")!
        )

        XCTAssertNil(approved)
    }

    func testPhotosAfterApprovalMarksOnlyTargetPhotoForReceiver() throws {
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000906")!
        let receiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000907")!
        let proposal = makeProposal(senderID: senderID, receiverID: receiverID, status: .agreed)
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000908")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000909")!
        let photos = [
            try makePhoto(id: targetID, proposalID: proposal.id),
            try makePhoto(id: otherID, proposalID: proposal.id)
        ]

        let approvedPhotos = TradeEvidenceApprovalOptimism.photosAfterApproval(
            photos,
            photoID: targetID,
            viewerID: receiverID,
            proposal: proposal
        )

        XCTAssertEqual(approvedPhotos.first { $0.id == targetID }?.approvedByReceiver, true)
        XCTAssertEqual(approvedPhotos.first { $0.id == targetID }?.approvedBySender, false)
        XCTAssertEqual(approvedPhotos.first { $0.id == otherID }?.approvedByReceiver, false)
    }

    private func makeProposal(
        senderID: UUID,
        receiverID: UUID,
        status: ProposalStatus,
        approvedBySender: Bool = false,
        approvedByReceiver: Bool = false
    ) -> TradeProposal {
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000910")!,
            senderID: senderID,
            receiverID: receiverID,
            status: status,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            approvedBySender: approvedBySender,
            approvedByReceiver: approvedByReceiver,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func makePhoto(id: UUID, proposalID: UUID) throws -> TradeEvidencePhoto {
        TradeEvidencePhoto(
            id: id,
            proposalID: proposalID,
            photoURL: try XCTUnwrap(URL(string: "https://example.com/\(id.uuidString).jpg")),
            position: 1,
            takenBy: UUID(uuidString: "00000000-0000-0000-0000-000000000911")!
        )
    }
}
