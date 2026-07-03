@testable import MegrumApp
import MegrumCore
import XCTest

final class TradeEvidencePhotoStateReducerTests: XCTestCase {
    func testPhotosPreferCachedNonEmptyPhotos() throws {
        let proposal = makeProposal(evidencePhotoURL: try XCTUnwrap(URL(string: "https://example.com/fallback.jpg")))
        let cached = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000801")!,
            proposalID: proposal.id,
            url: try XCTUnwrap(URL(string: "https://example.com/cached.jpg"))
        )

        let photos = TradeEvidencePhotoStateReducer.photos(
            for: proposal,
            in: [proposal.id: [cached]],
            viewerID: UUID(uuidString: "00000000-0000-0000-0000-000000000802")!
        )

        XCTAssertEqual(photos, [cached])
    }

    func testPhotosFallbackToLegacyProposalEvidenceURL() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000803")!
        let evidenceURL = try XCTUnwrap(URL(string: "https://example.com/evidence.jpg"))
        let proposal = makeProposal(evidencePhotoURL: evidenceURL)

        let photos = TradeEvidencePhotoStateReducer.photos(
            for: proposal,
            in: [:],
            viewerID: viewerID
        )

        XCTAssertEqual(photos.count, 1)
        XCTAssertEqual(photos.first?.id, proposal.id)
        XCTAssertEqual(photos.first?.proposalID, proposal.id)
        XCTAssertEqual(photos.first?.photoURL, evidenceURL)
        XCTAssertEqual(photos.first?.position, 1)
        XCTAssertEqual(photos.first?.takenBy, viewerID)
    }

    func testPhotosRespectExplicitlyCachedEmptyPhotos() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000813")!
        let evidenceURL = try XCTUnwrap(URL(string: "https://example.com/evidence.jpg"))
        let proposal = makeProposal(evidencePhotoURL: evidenceURL)

        let photos = TradeEvidencePhotoStateReducer.photos(
            for: proposal,
            in: [proposal.id: []],
            viewerID: viewerID
        )

        XCTAssertEqual(photos, [])
    }

    func testReplacingLoadedPhotosKeepsLoadedPhotosOrUsesFallbackWhenEmpty() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000804")!
        let proposal = makeProposal(evidencePhotoURL: try XCTUnwrap(URL(string: "https://example.com/fallback.jpg")))
        let loaded = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000805")!,
            proposalID: proposal.id,
            url: try XCTUnwrap(URL(string: "https://example.com/loaded.jpg"))
        )

        let withLoaded = TradeEvidencePhotoStateReducer.replacingLoadedPhotos(
            in: [:],
            proposal: proposal,
            loadedPhotos: [loaded],
            viewerID: viewerID
        )
        let withFallback = TradeEvidencePhotoStateReducer.replacingLoadedPhotos(
            in: [:],
            proposal: proposal,
            loadedPhotos: [],
            viewerID: viewerID
        )

        XCTAssertEqual(withLoaded[proposal.id], [loaded])
        XCTAssertEqual(withFallback[proposal.id]?.first?.photoURL, proposal.evidencePhotoURL)
        XCTAssertEqual(withFallback[proposal.id]?.first?.takenBy, viewerID)
    }

    func testTradeEvidenceListPresentationStateFiltersLocallyDeletedPhotos() throws {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000814")!
        let visible = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000815")!,
            proposalID: proposalID,
            url: try XCTUnwrap(URL(string: "https://example.com/visible.jpg"))
        )
        let deleted = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000816")!,
            proposalID: proposalID,
            url: try XCTUnwrap(URL(string: "https://example.com/deleted.jpg"))
        )
        var state = TradeEvidenceListPresentationState()

        state.markDeleted(deleted)

        XCTAssertEqual(state.displayedPhotos(from: [visible, deleted]), [visible])
    }

    func testTradeEvidenceListPresentationStateClearsPresentedPhotoWhenDeleted() throws {
        let photo = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000817")!,
            proposalID: UUID(uuidString: "00000000-0000-0000-0000-000000000818")!,
            url: try XCTUnwrap(URL(string: "https://example.com/presented.jpg"))
        )
        var state = TradeEvidenceListPresentationState()

        state.openPhoto(photo)
        state.markDeleted(photo)

        XCTAssertNil(state.presentedPhoto)
        XCTAssertEqual(state.displayedPhotos(from: [photo]), [])
    }

    func testTradeEvidenceListPresentationStateTracksDeleteConfirmation() throws {
        let photo = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000819")!,
            proposalID: UUID(uuidString: "00000000-0000-0000-0000-000000000820")!,
            url: try XCTUnwrap(URL(string: "https://example.com/delete.jpg"))
        )
        var state = TradeEvidenceListPresentationState()

        state.requestDelete(photo)
        XCTAssertTrue(state.isDeleteConfirmationPresented)
        XCTAssertEqual(state.pendingDeletePhoto, photo)

        state.clearPendingDelete()
        XCTAssertFalse(state.isDeleteConfirmationPresented)
        XCTAssertNil(state.pendingDeletePhoto)
    }

    private func makeProposal(evidencePhotoURL: URL?) -> TradeProposal {
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000806")!,
            senderID: UUID(uuidString: "00000000-0000-0000-0000-000000000807")!,
            receiverID: UUID(uuidString: "00000000-0000-0000-0000-000000000808")!,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            evidencePhotoURL: evidencePhotoURL,
            evidenceTakenAt: Date(timeIntervalSince1970: 100)
        )
    }

    private func makePhoto(id: UUID, proposalID: UUID, url: URL) -> TradeEvidencePhoto {
        TradeEvidencePhoto(
            id: id,
            proposalID: proposalID,
            photoURL: url,
            position: 1,
            takenBy: UUID(uuidString: "00000000-0000-0000-0000-000000000809")!
        )
    }
}
