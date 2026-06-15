@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class SupabaseHomeLocalModePersistenceTests: XCTestCase {
    func testEnabledActivityWindowUpdateInputPreservesExistingLocalModeContract() {
        let startAt = Date(timeIntervalSince1970: 1_700_000_000)
        let endAt = startAt.addingTimeInterval(7_200)
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: "  東京ドーム  ",
            coordinate: MegrumLocationCoordinate(latitude: 35.7056, longitude: 139.7519),
            startedAt: startAt,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )

        let input = SupabaseHomeLocalModePersistence.enabledActivityWindowUpdateInput(
            settings: settings,
            startAt: startAt,
            endAt: endAt
        )

        XCTAssertEqual(input.venue, "東京ドーム")
        XCTAssertEqual(input.center, SupabaseActivityWindowCoordinate(latitude: 35.7056, longitude: 139.7519))
        XCTAssertFalse(input.clearsCenter)
        XCTAssertEqual(input.radiusMeters, 500)
        XCTAssertTrue(input.clearsEventName)
        XCTAssertEqual(input.eventless, true)
        XCTAssertEqual(input.startAt, startAt)
        XCTAssertEqual(input.endAt, endAt)
        XCTAssertTrue(input.clearsNote)
        XCTAssertEqual(input.status, .enabled)
    }

    func testLocalModeUpsertInputSortsCarryingIDsAndClearsMissingLocation() {
        let idB = UUID(uuidString: "00000000-0000-0000-0000-000000000902")!
        let idA = UUID(uuidString: "00000000-0000-0000-0000-000000000901")!
        let activityWindowID = UUID(uuidString: "00000000-0000-0000-0000-000000000903")!
        let settings = HomeLocalActivitySettings(
            isEnabled: false,
            venue: "東京ドーム",
            coordinate: nil,
            startedAt: nil,
            durationMinutes: 999,
            radiusMeters: 999,
            selectedCarryingIDs: [idB, idA]
        )

        let input = SupabaseHomeLocalModePersistence.localModeUpsertInput(
            enabled: false,
            activityWindowID: activityWindowID,
            settings: settings
        )

        XCTAssertFalse(input.enabled)
        XCTAssertEqual(input.activityWindowID, activityWindowID)
        XCTAssertEqual(input.radiusMeters, HomeLocalActivitySettings.defaultRadiusMeters)
        XCTAssertEqual(input.selectedCarryingIDs, [idA, idB])
        XCTAssertEqual(input.selectedWishIDs, [])
        XCTAssertNil(input.lastLocation)
        XCTAssertTrue(input.clearsLastLocation)
    }

    func testDisabledFallbackSettingsKeepsNormalizedValues() {
        let activityWindowID = UUID(uuidString: "00000000-0000-0000-0000-000000000904")!
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let carryingID = UUID(uuidString: "00000000-0000-0000-0000-000000000905")!
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: "  東京ドーム  ",
            coordinate: MegrumLocationCoordinate(latitude: 35.7, longitude: 139.7),
            startedAt: startedAt,
            durationMinutes: 999,
            radiusMeters: 999,
            selectedCarryingIDs: [carryingID]
        )

        let fallback = SupabaseHomeLocalModePersistence.disabledFallbackSettings(
            existingActivityWindowID: activityWindowID,
            settings: settings
        )

        XCTAssertEqual(fallback.activityWindowID, activityWindowID)
        XCTAssertFalse(fallback.isEnabled)
        XCTAssertEqual(fallback.venue, "東京ドーム")
        XCTAssertEqual(fallback.coordinate, MegrumLocationCoordinate(latitude: 35.7, longitude: 139.7))
        XCTAssertEqual(fallback.startedAt, startedAt)
        XCTAssertEqual(fallback.durationMinutes, HomeLocalActivitySettings.defaultDurationMinutes)
        XCTAssertEqual(fallback.radiusMeters, HomeLocalActivitySettings.defaultRadiusMeters)
        XCTAssertEqual(fallback.selectedCarryingIDs, [carryingID])
    }
}
