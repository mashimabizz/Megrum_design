@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeLocalModeTests: XCTestCase {
    func testLocalActivityStatusAndWindowText() {
        let start = Date(timeIntervalSince1970: 1_780_240_800)
        let now = start.addingTimeInterval(30 * 60)
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: " 東京ドーム ",
            startedAt: start,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(settings.status(now: now), .live)
        XCTAssertEqual(settings.status(now: start.addingTimeInterval(121 * 60)), .expired)
        XCTAssertEqual(settings.displayVenue(fallbackPrefecture: "東京都"), "東京ドーム")
        XCTAssertEqual(settings.timeWindowText(now: now, calendar: calendar), "15:20-17:20")
        XCTAssertEqual(settings.radiusText, "500m")
    }

    func testLocalActivityUsesPrefectureFallbackWhenVenueIsEmpty() {
        let settings = HomeLocalActivitySettings(
            isEnabled: false,
            venue: " ",
            startedAt: nil,
            durationMinutes: 120,
            radiusMeters: 1_000,
            selectedCarryingIDs: []
        )

        XCTAssertEqual(settings.status(), .off)
        XCTAssertEqual(settings.displayVenue(fallbackPrefecture: "大阪府"), "大阪府周辺")
        XCTAssertEqual(settings.radiusText, "1km")
    }

    func testLocalActivityPersistencePreservesCoordinate() {
        let coordinate = MegrumLocationCoordinate(latitude: 35.6484, longitude: 140.0347)
        let now = Date(timeIntervalSince1970: 1_780_200_000)
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: " 幕張メッセ ",
            coordinate: coordinate,
            startedAt: nil,
            durationMinutes: 999,
            radiusMeters: 999,
            selectedCarryingIDs: []
        )

        let normalized = settings.normalizedForPersistence(now: now)

        XCTAssertEqual(normalized.venue, "幕張メッセ")
        XCTAssertEqual(normalized.coordinate, coordinate)
        XCTAssertEqual(normalized.startedAt, now)
        XCTAssertEqual(normalized.durationMinutes, HomeLocalActivitySettings.defaultDurationMinutes)
        XCTAssertEqual(normalized.radiusMeters, HomeLocalActivitySettings.defaultRadiusMeters)
    }

    func testPublicPreviewReflectsLiveLocalModeForOtherUsers() {
        let itemID = UUID(uuidString: "00000000-0000-0000-0000-000000000120")!
        let start = Date(timeIntervalSince1970: 1_780_240_800)
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: "東京ドーム",
            startedAt: start,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: [itemID]
        )
        let candidates = [
            HomeLocalCarryingCandidate(
                item: GoodsItem(id: itemID, ownerID: UUID(), title: "スア トレカ")
            )
        ]
        let summary = settings.carryingSummary(from: candidates)
        let preview = settings.publicPreview(
            now: start.addingTimeInterval(30 * 60),
            fallbackPrefecture: "東京都",
            carryingSummary: summary
        )

        XCTAssertTrue(preview.isVisible)
        XCTAssertEqual(preview.badgeText, "相手に表示中")
        XCTAssertEqual(preview.title, "東京ドームで現地交換中")
        XCTAssertTrue(preview.detail.contains("500m"))
        XCTAssertTrue(preview.detail.contains("持参 1/1件"))
    }

    func testPublicPreviewHidesOffAndExpiredLocalMode() {
        let start = Date(timeIntervalSince1970: 1_780_240_800)
        let summary = HomeLocalCarryingSummary(candidates: [], selectedIDs: [])
        let off = HomeLocalActivitySettings(
            isEnabled: false,
            venue: "",
            startedAt: nil,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        ).publicPreview(
            now: start,
            fallbackPrefecture: "東京都",
            carryingSummary: summary
        )
        let expired = HomeLocalActivitySettings(
            isEnabled: true,
            venue: "東京ドーム",
            startedAt: start,
            durationMinutes: 60,
            radiusMeters: 500,
            selectedCarryingIDs: []
        ).publicPreview(
            now: start.addingTimeInterval(61 * 60),
            fallbackPrefecture: "東京都",
            carryingSummary: summary
        )

        XCTAssertFalse(off.isVisible)
        XCTAssertEqual(off.badgeText, "未公開")
        XCTAssertFalse(expired.isVisible)
        XCTAssertEqual(expired.badgeText, "更新が必要")
    }

    func testCarryingCandidatesFilterViewerItemsAndDeduplicate() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let viewerItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            ownerID: viewerID,
            title: "ランダムトレカ A",
            tags: [GoodsTag(id: UUID(), name: "会場限定")],
            quantity: 2
        )
        let partnerItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            ownerID: partnerID,
            title: "ランダムトレカ B"
        )

        let candidates = HomeLocalCarryingCandidate.candidates(
            from: [viewerItem, partnerItem, viewerItem],
            viewerID: viewerID
        )

        XCTAssertEqual(candidates.map(\.id), [viewerItem.id])
        XCTAssertEqual(candidates.first?.subtitle, "会場限定")
        XCTAssertEqual(candidates.first?.quantity, 2)
    }

    func testCarryingSourcePrefersOwnInventoryOverHomeMatches() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let ownedInventory = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000111")!,
            ownerID: viewerID,
            title: "持参するトレカ"
        )
        let matchedItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000112")!,
            ownerID: viewerID,
            title: "ホーム候補"
        )

        let source = HomeLocalCarryingCandidate.sourceItems(
            inventory: [ownedInventory],
            matchedItems: [matchedItem],
            possibleItems: []
        )

        XCTAssertEqual(source.map(\.id), [ownedInventory.id])
    }

    func testCarryingSourceFallsBackToHomeMatchesWhenInventoryIsEmpty() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let matchedItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000113")!,
            ownerID: viewerID,
            title: "ホーム候補"
        )

        let source = HomeLocalCarryingCandidate.sourceItems(
            inventory: [],
            matchedItems: [matchedItem],
            possibleItems: []
        )

        XCTAssertEqual(source.map(\.id), [matchedItem.id])
    }

    func testCarryingSummaryAndCodecRoundTripSelection() {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        let candidates = [
            HomeLocalCarryingCandidate(
                item: GoodsItem(id: firstID, ownerID: UUID(), title: "スア 春ver.")
            ),
            HomeLocalCarryingCandidate(
                item: GoodsItem(id: secondID, ownerID: UUID(), title: "ジョンウ ラキドロ")
            )
        ]
        let encoded = HomeLocalCarryingSelectionCodec.encode([secondID, firstID])
        let decoded = HomeLocalCarryingSelectionCodec.decode(encoded)
        let summary = HomeLocalCarryingSummary(candidates: candidates, selectedIDs: decoded)

        XCTAssertEqual(decoded, [firstID, secondID])
        XCTAssertEqual(summary.countText, "持参 2/2件")
        XCTAssertEqual(summary.titleText, "スア 春ver.、ジョンウ ラキドロ")
    }

    func testCoordinateStorageCodecRoundTripsValidCurrentLocation() {
        let coordinate = MegrumLocationCoordinate(latitude: 35.70564, longitude: 139.75189)

        let decoded = HomeLocalCoordinateStorageCodec.decode(
            latitudeText: HomeLocalCoordinateStorageCodec.latitudeText(coordinate),
            longitudeText: HomeLocalCoordinateStorageCodec.longitudeText(coordinate)
        )

        XCTAssertEqual(decoded, coordinate)
        XCTAssertNil(HomeLocalCoordinateStorageCodec.decode(latitudeText: "91", longitudeText: "139.7"))
        XCTAssertNil(HomeLocalCoordinateStorageCodec.decode(latitudeText: "35.7", longitudeText: "181"))
        XCTAssertNil(HomeLocalCoordinateStorageCodec.decode(latitudeText: "", longitudeText: "139.7"))
    }

    func testHomeGroomEntrySummaryReflectsLocalModeState() {
        let live = HomeGroomEntrySummary(groomCount: 2, localStatus: .live, venue: "幕張メッセ")
        let off = HomeGroomEntrySummary(groomCount: 0, localStatus: .off, venue: "現在地未設定")

        XCTAssertEqual(live.badgeText, "2件")
        XCTAssertEqual(live.title, "近くのグルームも確認")
        XCTAssertTrue(live.detail.contains("幕張メッセ"))
        XCTAssertEqual(off.badgeText, "0件")
        XCTAssertEqual(off.title, "近くのグルームはまだありません")
    }

    func testDraftStartsWindowWhenModeIsEnabled() {
        let now = Date(timeIntervalSince1970: 1_780_200_000)
        let original = HomeLocalActivitySettings(
            isEnabled: false,
            venue: "",
            startedAt: nil,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )
        var draft = HomeLocalActivityDraft(settings: original, fallbackPrefecture: nil)
        draft.isEnabled = true
        draft.venue = "幕張メッセ"

        let saved = draft.settings(savedAt: now, original: original)

        XCTAssertTrue(saved.isEnabled)
        XCTAssertEqual(saved.venue, "幕張メッセ")
        XCTAssertEqual(saved.startedAt, now)
        XCTAssertEqual(saved.status(now: now), .live)
    }

    func testDraftPreservesActivityWindowIDWhenEditingExistingWindow() {
        let activityWindowID = UUID(uuidString: "00000000-0000-0000-0000-000000000901")!
        let startedAt = Date(timeIntervalSince1970: 1_780_200_000)
        let original = HomeLocalActivitySettings(
            activityWindowID: activityWindowID,
            isEnabled: true,
            venue: "幕張メッセ",
            startedAt: startedAt,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )
        var draft = HomeLocalActivityDraft(settings: original, fallbackPrefecture: nil)
        draft.radiusMeters = 1_000

        let saved = draft.settings(savedAt: startedAt.addingTimeInterval(60), original: original)

        XCTAssertEqual(saved.activityWindowID, activityWindowID)
        XCTAssertEqual(saved.startedAt, startedAt)
        XCTAssertEqual(saved.radiusMeters, 1_000)
    }

    func testDraftCarriesCurrentLocationCoordinateIntoSavedSettings() {
        let now = Date(timeIntervalSince1970: 1_780_200_000)
        let coordinate = MegrumLocationCoordinate(latitude: 35.70564, longitude: 139.75189)
        let original = HomeLocalActivitySettings(
            isEnabled: false,
            venue: "",
            startedAt: nil,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )
        var draft = HomeLocalActivityDraft(settings: original, fallbackPrefecture: nil)
        draft.isEnabled = true
        draft.venue = HomeLocalLocationLabel.coordinateText(coordinate)
        draft.coordinate = coordinate

        let saved = draft.settings(savedAt: now, original: original)

        XCTAssertTrue(saved.isEnabled)
        XCTAssertEqual(saved.coordinate, coordinate)
        XCTAssertEqual(saved.venue, "現在地を取得済み")
        XCTAssertEqual(saved.startedAt, now)
    }

    func testDisplayVenueHidesLegacyCoordinateText() {
        let coordinate = MegrumLocationCoordinate(latitude: 34.7332, longitude: 135.5555)
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: "現在地 34.7332, 135.5555",
            coordinate: coordinate,
            startedAt: Date(timeIntervalSince1970: 1_780_200_000),
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )

        XCTAssertEqual(settings.displayVenue(fallbackPrefecture: "大阪府"), "現在地を取得済み")
    }

    func testDisplayVenueHidesLegacyCoordinateTextEvenWithoutStoredCoordinate() {
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: "現在地: 34.7332,135.5555",
            coordinate: nil,
            startedAt: Date(timeIntervalSince1970: 1_780_200_000),
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )
        let draft = HomeLocalActivityDraft(settings: settings, fallbackPrefecture: "大阪府")

        XCTAssertEqual(settings.displayVenue(fallbackPrefecture: "大阪府"), "現在地を取得済み")
        XCTAssertEqual(draft.venue, "現在地を取得済み")
        XCTAssertEqual(draft.coordinate, MegrumLocationCoordinate(latitude: 34.7332, longitude: 135.5555))
    }

    func testLocationLabelParsesCommonCoordinateLabels() {
        XCTAssertEqual(
            HomeLocalLocationLabel.coordinate(in: "34.7332, 135.5555"),
            MegrumLocationCoordinate(latitude: 34.7332, longitude: 135.5555)
        )
        XCTAssertEqual(
            HomeLocalLocationLabel.coordinate(in: "現在地：34.7332，135.5555"),
            MegrumLocationCoordinate(latitude: 34.7332, longitude: 135.5555)
        )
        XCTAssertEqual(
            HomeLocalLocationLabel.coordinate(in: "lat=34.7332 lng=135.5555"),
            MegrumLocationCoordinate(latitude: 34.7332, longitude: 135.5555)
        )
        XCTAssertNil(HomeLocalLocationLabel.coordinate(in: "大阪府大阪市中央区1-2-3"))
    }

    @MainActor
    func testAppStateUsesAppStorageFallbackWhenRepositoryHasNoLocalModeSettings() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let selectedID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let startedAt = Date(timeIntervalSince1970: 1_780_200_000)
        let fallback = HomeLocalActivitySettings(
            isEnabled: true,
            venue: "東京ドーム",
            startedAt: startedAt,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: [selectedID]
        )

        let loadedResult = await state.loadHomeLocalModeSettings(fallback: fallback, now: startedAt)
        let loaded = try! XCTUnwrap(loadedResult)

        XCTAssertEqual(loaded, fallback)
        XCTAssertEqual(state.homeLocalModeSettings, Optional(fallback))
        XCTAssertFalse(state.isLoadingHomeLocalModeSettings)
        XCTAssertNil(state.errorMessage)
    }

    @MainActor
    func testAppStateSavesPreviewEnabledLocalModeSettings() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let selectedID = try! XCTUnwrap(state.inventory.first?.id)
        let now = Date(timeIntervalSince1970: 1_780_200_000)

        let savedResult = await state.saveHomeLocalModeSettings(
            HomeLocalActivitySettings(
                isEnabled: true,
                venue: " 幕張メッセ ",
                startedAt: nil,
                durationMinutes: 120,
                radiusMeters: 500,
                selectedCarryingIDs: [selectedID]
            ),
            now: now
        )
        let saved = try! XCTUnwrap(savedResult)

        XCTAssertNotNil(saved.activityWindowID)
        XCTAssertEqual(saved.venue, "幕張メッセ")
        XCTAssertEqual(saved.startedAt, now)
        XCTAssertEqual(saved.selectedCarryingIDs, [selectedID])
        XCTAssertEqual(state.homeLocalModeSettings, Optional(saved))
        XCTAssertFalse(state.isSavingHomeLocalModeSettings)
        XCTAssertNil(state.errorMessage)
    }

    @MainActor
    func testAppStateSavesPreviewDisabledLocalModeSettingsWithExistingWindowID() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let now = Date(timeIntervalSince1970: 1_780_200_000)
        let enabledResult = await state.saveHomeLocalModeSettings(
            HomeLocalActivitySettings(
                isEnabled: true,
                venue: "幕張メッセ",
                startedAt: now,
                durationMinutes: 120,
                radiusMeters: 500,
                selectedCarryingIDs: []
            ),
            now: now
        )
        let enabled = try! XCTUnwrap(enabledResult)
        let activityWindowID = try! XCTUnwrap(enabled.activityWindowID)

        let disabledResult = await state.saveHomeLocalModeSettings(
            HomeLocalActivitySettings(
                activityWindowID: activityWindowID,
                isEnabled: false,
                venue: "幕張メッセ",
                startedAt: now,
                durationMinutes: 120,
                radiusMeters: 500,
                selectedCarryingIDs: []
            ),
            now: now.addingTimeInterval(60)
        )
        let disabled = try! XCTUnwrap(disabledResult)

        XCTAssertEqual(disabled.activityWindowID, activityWindowID)
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertEqual(state.homeLocalModeSettings, Optional(disabled))
        XCTAssertFalse(state.isSavingHomeLocalModeSettings)
        XCTAssertNil(state.errorMessage)
    }
}
