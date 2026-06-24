@testable import MegrumApp
import MegrumCore
import XCTest

final class PublicUserProfileScreenTests: XCTestCase {
    func testPublicProfileUsesOwnProfileCompactHeaderMetrics() {
        XCTAssertEqual(PublicProfileLayoutMetrics.contentSpacing, OwnProfileLayoutMetrics.contentSpacing)
        XCTAssertEqual(PublicProfileLayoutMetrics.horizontalPadding, OwnProfileLayoutMetrics.horizontalPadding)
        XCTAssertEqual(PublicProfileLayoutMetrics.topPadding, OwnProfileLayoutMetrics.topPadding)
        XCTAssertEqual(PublicProfileLayoutMetrics.bottomPadding, OwnProfileLayoutMetrics.bottomPadding)
        XCTAssertEqual(PublicProfileLayoutMetrics.compactHeroAvatarSize, OwnProfileLayoutMetrics.compactHeroAvatarSize)
        XCTAssertEqual(PublicProfileLayoutMetrics.compactHeroAvatarSize, 70)
        XCTAssertEqual(ProfileVisualHeroDensity.compact.displayNameFontSize, 20)
        XCTAssertEqual(ProfileVisualHeroDensity.compact.handleFontSize, 13)
        XCTAssertEqual(ProfileVisualHeroDensity.compact.scheduleActionHeight, 38)
        XCTAssertGreaterThanOrEqual(ProfileVisualHeroDensity.compact.statMinWidth, 52)
    }

    func testPublicOshiTagsKeepGroupAndMemberInSameColorGroup() {
        let groupID = UUID(uuidString: "10000000-0000-0000-0000-000000000101")!
        let characterID = UUID(uuidString: "10000000-0000-0000-0000-000000000102")!
        let selection = UserOshiSelection(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000103")!,
            userID: UUID(uuidString: "10000000-0000-0000-0000-000000000104")!,
            groupID: groupID,
            characterID: characterID,
            kind: .specific,
            priority: 1,
            groupName: "IVE",
            characterName: "ウォニョン"
        )

        let tags = PublicOshiTag.makeTags(from: [selection])

        XCTAssertEqual(tags.map(\.title), ["IVE", "ウォニョン"])
        XCTAssertEqual(tags[0].colorKey, tags[1].colorKey)
    }

    func testPublicOshiTagsDeduplicateRepeatedGroupRows() {
        let groupID = UUID(uuidString: "10000000-0000-0000-0000-000000000201")!
        let userID = UUID(uuidString: "10000000-0000-0000-0000-000000000202")!
        let selections = [
            UserOshiSelection(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000203")!,
                userID: userID,
                groupID: groupID,
                characterID: UUID(uuidString: "10000000-0000-0000-0000-000000000204")!,
                kind: .specific,
                priority: 1,
                groupName: "TWICE",
                characterName: "モモ"
            ),
            UserOshiSelection(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000205")!,
                userID: userID,
                groupID: groupID,
                characterID: UUID(uuidString: "10000000-0000-0000-0000-000000000206")!,
                kind: .specific,
                priority: 2,
                groupName: "TWICE",
                characterName: "サナ"
            )
        ]

        let tags = PublicOshiTag.makeTags(from: selections)

        XCTAssertEqual(tags.map(\.title), ["TWICE", "モモ", "サナ"])
        XCTAssertTrue(tags.allSatisfy { $0.colorKey == groupID.uuidString })
    }

    func testEvaluationListStateShowsLoadingForEmptyLoadingList() {
        let state = PublicProfileEvaluationListState(evaluations: [], isLoading: true)

        XCTAssertTrue(state.showsLoading)
        XCTAssertFalse(state.showsEmpty)
        XCTAssertEqual(state.evaluationCount, 0)
    }

    func testEvaluationListStateShowsEmptyForLoadedEmptyList() {
        let state = PublicProfileEvaluationListState(evaluations: [], isLoading: false)

        XCTAssertFalse(state.showsLoading)
        XCTAssertTrue(state.showsEmpty)
        XCTAssertEqual(state.evaluationCount, 0)
    }

    func testEvaluationListStateKeepsRowsVisibleWhileRefreshing() {
        let state = PublicProfileEvaluationListState(
            evaluations: [
                UserEvaluation(
                    id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                    raterID: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                    raterHandle: "michi1",
                    raterDisplayName: "みち",
                    stars: 5,
                    comment: "丁寧に交換できました"
                )
            ],
            isLoading: true
        )

        XCTAssertFalse(state.showsLoading)
        XCTAssertFalse(state.showsEmpty)
        XCTAssertEqual(state.evaluationCount, 1)
    }

    func testPreviewRepositoryLoadsProfileSchedulesForPartner() async throws {
        let partnerSchedules = NativePreviewData.schedules.filter { $0.userID == NativePreviewData.partnerID }
        let startAt = try XCTUnwrap(partnerSchedules.map(\.startAt).min()).addingTimeInterval(-3_600)
        let endAt = try XCTUnwrap(partnerSchedules.map(\.endAt).max()).addingTimeInterval(3_600)

        let schedules = try await PreviewMegrumRepository().loadProfileSchedules(
            userID: NativePreviewData.partnerID,
            startAt: startAt,
            endAt: endAt
        )

        XCTAssertFalse(schedules.isEmpty)
        XCTAssertTrue(schedules.allSatisfy { $0.userID == NativePreviewData.partnerID })
        XCTAssertTrue(schedules.contains { $0.title == "開演前準備" })
    }

    @MainActor
    func testAppStateStoresProfileSchedulesByUserID() async throws {
        let partnerSchedules = NativePreviewData.schedules.filter { $0.userID == NativePreviewData.partnerID }
        let startAt = try XCTUnwrap(partnerSchedules.map(\.startAt).min()).addingTimeInterval(-3_600)
        let endAt = try XCTUnwrap(partnerSchedules.map(\.endAt).max()).addingTimeInterval(3_600)
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadProfileSchedules(
            userID: NativePreviewData.partnerID,
            startAt: startAt,
            endAt: endAt
        )

        let storedSchedules = state.profileSchedules(for: NativePreviewData.partnerID)
        let loadingUserID = state.loadingProfileScheduleUserID
        XCTAssertEqual(storedSchedules, partnerSchedules.sorted { $0.startAt < $1.startAt })
        XCTAssertNil(loadingUserID)
    }
}
