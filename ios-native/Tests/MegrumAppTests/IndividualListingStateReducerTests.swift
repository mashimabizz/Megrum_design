@testable import MegrumApp
import MegrumCore
import XCTest

final class IndividualListingStateReducerTests: XCTestCase {
    func testConditionStripTitleUsesSingleLineListingCountCopy() {
        XCTAssertEqual(
            IndividualListingListPresentation.conditionStripTitle(index: 0, totalCount: 5),
            "個別募集 1 / 5"
        )
        XCTAssertEqual(
            IndividualListingListPresentation.conditionStripTitle(index: 2, totalCount: 0),
            "個別募集 3 / 1"
        )
    }

    func testActiveSelectionStateKeepsSelectionAndFallsBackWhenListingChanges() {
        let first = makeListing(idSuffix: "908")
        let second = makeListing(idSuffix: "909")
        var state = IndividualListingActiveSelectionState()

        state.reconcile(with: [first.id, second.id])

        XCTAssertEqual(state.activeListingID, first.id)
        XCTAssertEqual(state.activeListing(in: [first, second])?.id, first.id)
        XCTAssertEqual(state.activeListingIndex(in: [first, second]), 0)

        state.activeListingID = second.id
        state.reconcile(with: [first.id, second.id])

        XCTAssertEqual(state.activeListingID, second.id)
        XCTAssertEqual(state.activeListingIndex(in: [first, second]), 1)

        state.reconcile(with: [first.id])

        XCTAssertEqual(state.activeListingID, first.id)

        state.reconcile(with: [])

        XCTAssertNil(state.activeListingID)
        XCTAssertNil(state.activeListing(in: []))
        XCTAssertEqual(state.activeListingIndex(in: []), 0)
    }

    func testLocalScheduleStatePreservesScheduleTextTransitions() throws {
        let july18 = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 18)))
        let august2 = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 2)))
        var state = IndividualListingLocalScheduleState(localSchedule: "7/18", now: july18)

        XCTAssertEqual(state.mode, .dates)
        XCTAssertEqual(state.onDatePickerAppearText(), "7/18")

        state.mode = .consult
        XCTAssertEqual(
            state.localScheduleTextAfterModeChange(currentLocalSchedule: "7/18"),
            IndividualListingExchangeSummary.defaultLocalSchedule
        )
        XCTAssertNil(state.onDatePickerAppearText())

        state.mode = .dates
        XCTAssertEqual(
            state.localScheduleTextAfterModeChange(
                currentLocalSchedule: IndividualListingExchangeSummary.defaultLocalSchedule
            ),
            "7/18"
        )
        XCTAssertEqual(state.localScheduleTextAfterDateChange(august2), "8/2")

        state.applyExternalLocalSchedule(IndividualListingExchangeSummary.defaultLocalSchedule)

        XCTAssertEqual(state.mode, .consult)

        state.applyExternalLocalSchedule("9月3日、午後")

        XCTAssertEqual(state.mode, .dates)
        XCTAssertEqual(state.onDatePickerAppearText(), "9/3")
    }

    func testUpsertingNewListingInsertsAtFront() {
        let existing = makeListing(idSuffix: "901")
        let inserted = makeListing(idSuffix: "902")

        let updated = IndividualListingStateReducer.upserting(
            inserted,
            into: [existing]
        )

        XCTAssertEqual(updated, [inserted, existing])
    }

    func testUpsertingExistingListingReplacesAndMovesToFront() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000903")!
        let original = makeListing(id: targetID, note: "古い内容")
        let other = makeListing(idSuffix: "904")
        let updatedListing = makeListing(id: targetID, note: "新しい内容")

        let updated = IndividualListingStateReducer.upserting(
            updatedListing,
            into: [other, original]
        )

        XCTAssertEqual(updated, [updatedListing, other])
    }

    func testRemovingListingKeepsOtherListingsInOrder() {
        let first = makeListing(idSuffix: "905")
        let removed = makeListing(idSuffix: "906")
        let last = makeListing(idSuffix: "907")

        let updated = IndividualListingStateReducer.removing(
            listingID: removed.id,
            from: [first, removed, last]
        )

        XCTAssertEqual(updated, [first, last])
    }

    private func makeListing(
        idSuffix: String,
        note: String? = nil
    ) -> IndividualListing {
        makeListing(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            note: note
        )
    }

    private func makeListing(
        id: UUID,
        note: String? = nil
    ) -> IndividualListing {
        IndividualListing(
            id: id,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000999")!,
            haves: [
                ListingItemQuantity(
                    itemID: UUID(uuidString: "00000000-0000-0000-0000-000000000998")!,
                    quantity: 1
                )
            ],
            status: .active,
            note: note
        )
    }
}
