@testable import MegrumApp
import CoreGraphics
import MegrumCore
import XCTest

final class PublicUserProfileScreenTests: XCTestCase {
    func testUserReportDraftStateKeepsReasonAndRawNoteForSubmission() {
        var state = UserReportDraftState()

        XCTAssertEqual(state.reason, .harassment)
        XCTAssertEqual(state.submission.note, "")

        state.reason = .privacy
        state.note = "  個人情報が書かれています  "

        XCTAssertEqual(state.submission.reason, .privacy)
        XCTAssertEqual(state.submission.note, "  個人情報が書かれています  ")
    }

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

    func testPublicExchangeConditionsPresentationCollectsReadonlyConditions() {
        let userID = UUID(uuidString: "10000000-0000-0000-0000-000000000901")!
        let listingID = UUID(uuidString: "10000000-0000-0000-0000-000000000902")!
        let exchangeSummary = IndividualListingExchangeSummary(
            handoffMethod: .both,
            localPrefecture: "東京都",
            localPlaceMemo: "会場付近",
            localSchedule: "7月3日",
            shippingFee: .negotiate,
            shippingDays: .twoToFourDays,
            acceptsOutsideCondition: true
        )
        let listing = IndividualListing(
            id: listingID,
            ownerID: userID,
            haves: [],
            note: exchangeSummary.storageLine
        )
        let settings = HomeDefaultExchangeSettings(
            preference: .local,
            localPrefecture: "大阪府",
            localDateKeys: ["2026-07-03"],
            localDateDetails: [
                "2026-07-03": HomeExchangeLocalDateDetail(prefecture: "大阪府", memo: "梅田")
            ],
            mailShippingFee: .owner,
            mailShippingDays: .oneDay
        )
        let profile = UserProfile(
            id: userID,
            handle: "michi",
            displayName: "みち",
            paymentMethods: [.paypay]
        )

        let presentation = PublicExchangeConditionsPresentation(
            standardSettings: settings,
            listings: [listing],
            profile: profile
        )

        XCTAssertEqual(presentation.standardSettings, settings)
        XCTAssertEqual(presentation.listingConditions.map(\.id), [listingID])
        XCTAssertEqual(presentation.paymentSummaryText, "PayPay")
        XCTAssertFalse(presentation.isEmpty)
    }

    func testPublicExchangeConditionsPresentationShowsEmptyWhenNothingIsPublic() {
        let presentation = PublicExchangeConditionsPresentation(
            standardSettings: nil,
            listings: [
                IndividualListing(
                    id: UUID(uuidString: "10000000-0000-0000-0000-000000000911")!,
                    ownerID: UUID(uuidString: "10000000-0000-0000-0000-000000000912")!,
                    haves: [],
                    note: "メモだけ"
                )
            ],
            profile: nil
        )

        XCTAssertNil(presentation.standardSettings)
        XCTAssertTrue(presentation.listingConditions.isEmpty)
        XCTAssertEqual(presentation.paymentSummaryText, "未設定")
        XCTAssertTrue(presentation.isEmpty)
    }

    func testPublicProfilePresentationStateStartsGoodsProposalBeforeListing() throws {
        let ownerID = UUID(uuidString: "10000000-0000-0000-0000-000000000921")!
        let goodsID = UUID(uuidString: "10000000-0000-0000-0000-000000000922")!
        let listingID = UUID(uuidString: "10000000-0000-0000-0000-000000000923")!
        let goods = GoodsItem(id: goodsID, ownerID: ownerID, title: "譲るトレカ")
        let listing = IndividualListing(
            id: listingID,
            ownerID: ownerID,
            haves: [ListingItemQuantity(itemID: goodsID)]
        )
        var state = PublicUserProfilePresentationState()

        state.startPrimaryProposal(
            allowsProposalActions: true,
            tradeGoods: [goods],
            listings: [listing],
            goodsByID: [goodsID: goods]
        )

        XCTAssertEqual(state.proposalTargetItem?.id, goodsID)
        XCTAssertNil(state.listingProposalTarget)
    }

    func testPublicProfilePresentationStateSelectsListingOnlyWhenAllowed() {
        let ownerID = UUID(uuidString: "10000000-0000-0000-0000-000000000931")!
        let goodsID = UUID(uuidString: "10000000-0000-0000-0000-000000000932")!
        let listingID = UUID(uuidString: "10000000-0000-0000-0000-000000000933")!
        let goods = GoodsItem(id: goodsID, ownerID: ownerID, title: "譲るアクスタ")
        let listing = IndividualListing(
            id: listingID,
            ownerID: ownerID,
            haves: [ListingItemQuantity(itemID: goodsID)]
        )
        var state = PublicUserProfilePresentationState()

        state.selectListing(
            listingID,
            allowsProposalActions: false,
            listings: [listing],
            goodsByID: [goodsID: goods]
        )
        XCTAssertNil(state.listingProposalTarget)

        state.selectListing(
            listingID,
            allowsProposalActions: true,
            listings: [listing],
            goodsByID: [goodsID: goods]
        )
        XCTAssertEqual(state.listingProposalTarget?.id, listingID)
        XCTAssertEqual(state.listingProposalTarget?.targetItem.id, goodsID)
    }

    func testPublicProfilePresentationStateClearsBlockTargetWhenDialogDismisses() {
        let userID = UUID(uuidString: "10000000-0000-0000-0000-000000000941")!
        var state = PublicUserProfilePresentationState()
        state.blockTarget = PublicProfileModerationTarget(userID: userID, displayName: "みち")

        state.updateBlockConfirmationPresentation(true)
        XCTAssertEqual(state.blockTarget?.userID, userID)

        state.updateBlockConfirmationPresentation(false)
        XCTAssertNil(state.blockTarget)
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
