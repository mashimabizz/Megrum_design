@testable import MegrumApp
@testable import MegrumData
import CoreGraphics
import CoreLocation
import Foundation
import MegrumCore
import XCTest

@MainActor
final class MeguriAccessPolicyTests: XCTestCase {
    func testMeguriHomeUtilityLayoutKeepsControlsAboveTabBar() {
        XCTAssertEqual(MeguriHomeUtilityLayout.bottomPadding(safeAreaBottom: 0), 116)
        XCTAssertEqual(MeguriHomeUtilityLayout.bottomPadding(safeAreaBottom: 34), 150)
    }

    func testMeguriHomeTopControlsLayoutKeepsFilterBelowTopObstruction() {
        XCTAssertEqual(MeguriHomeTopControlsLayout.topPadding(safeAreaTop: 0), 58)
        XCTAssertEqual(MeguriHomeTopControlsLayout.topPadding(safeAreaTop: 47), 58)
        XCTAssertEqual(MeguriHomeTopControlsLayout.topPadding(safeAreaTop: 64), 74)
    }

    func testMeguriContentFilterMatchesOshiAndSeriesMetadata() {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let characterID = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!
        let otherGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000013")!
        var filter = MeguriContentFilterState(
            draft: MeguriContentMetadataDraft(
                groupID: groupID,
                characterID: characterID,
                seriesName: "live"
            )
        )
        let matchingGroom = GroomPost(
            id: UUID(),
            authorID: UUID(),
            imageURL: URL(string: "https://example.com/match.jpg")!,
            latitude: 35.681236,
            longitude: 139.767125,
            groupID: groupID,
            characterID: characterID,
            seriesName: "2026 LIVE"
        )
        let otherThread = BoardThread(
            id: UUID(),
            authorID: UUID(),
            title: "別の話題",
            body: "別グループ",
            audience: .nearby3km,
            groupID: otherGroupID,
            characterID: characterID,
            seriesName: "2026 LIVE"
        )

        XCTAssertTrue(filter.matches(groom: matchingGroom))
        XCTAssertFalse(filter.matches(thread: otherThread))

        filter.reset()

        XCTAssertTrue(filter.matches(thread: otherThread))
    }

    func testMeguriContentMetadataSuggestionsFiltersTopicGroupsBySearchText() {
        let twice = OshiGroup(id: UUID(), name: "TWICE")
        let ive = OshiGroup(id: UUID(), name: "IVE")
        let aespa = OshiGroup(id: UUID(), name: "aespa")

        XCTAssertEqual(
            MeguriContentMetadataSuggestions.filteredGroups([twice, ive, aespa], query: "  iv ").map(\.name),
            ["IVE"]
        )
        XCTAssertEqual(
            MeguriContentMetadataSuggestions.filteredGroups([twice, ive, aespa], query: "").map(\.name),
            ["TWICE", "IVE", "aespa"]
        )
    }

    func testMapCreationPromptPresentationStateResolvesDropPinAndCalloutVisibility() {
        var state = MeguriMapCreationPromptPresentationState()

        XCTAssertFalse(state.isVisible)
        XCTAssertEqual(state.dropPinYOffset, -78)
        XCTAssertEqual(state.dropPinOpacity, 0.18)
        XCTAssertEqual(state.dropPinScale, 0.88)
        XCTAssertEqual(state.calloutOpacity, 0)
        XCTAssertEqual(state.calloutScale, 0.96)

        state.show()

        XCTAssertTrue(state.isVisible)
        XCTAssertEqual(state.dropPinYOffset, 0)
        XCTAssertEqual(state.dropPinOpacity, 1)
        XCTAssertEqual(state.dropPinScale, 1)
        XCTAssertEqual(state.calloutOpacity, 1)
        XCTAssertEqual(state.calloutScale, 1)

        state.prepare()

        XCTAssertFalse(state.isVisible)
    }

    func testGroomStoryComposerPresentationStateTracksCaptionAndToastLifecycle() {
        let firstToastID = UUID(uuidString: "00000000-0000-0000-0000-00000000BB01")!
        let secondToastID = UUID(uuidString: "00000000-0000-0000-0000-00000000BB02")!
        var state = GroomStoryComposerPresentationState()

        XCTAssertNil(state.captionForPublish)

        state.captionText = "会場入口の一枚"

        XCTAssertEqual(state.captionForPublish, "会場入口の一枚")

        state.clearCaptionAfterPhotoReset()

        XCTAssertEqual(state.captionText, "")
        XCTAssertNil(state.captionForPublish)

        state.showToast("最後に地図上でピンを立ててください", toastID: firstToastID)
        state.showToast("投稿する写真を選択してください", toastID: secondToastID)
        state.clearToast(ifMatching: firstToastID)

        XCTAssertEqual(state.toastMessage, "投稿する写真を選択してください")

        state.clearToast(ifMatching: secondToastID)

        XCTAssertNil(state.toastMessage)
    }

    func testGroomStoryExportJPEGBudgetStaysBelowUploadLimit() {
        XCTAssertLessThanOrEqual(GroomStoryExportRenderer.maxJPEGBytes, SupabaseGroomClient.maxUploadBytes)
    }

    func testMeguriProfileSettingsDraftHydratesFromProfileAndKeepsSaveEligibility() {
        let profile = MeguriProfile(
            userID: UUID(),
            displayName: "まくはり民",
            avatarID: "avatar_4",
            avatarURL: URL(string: "https://example.com/avatar.jpg")
        )
        var state = MeguriProfileSettingsDraftState()

        state.hydrate(profile: profile, viewerDisplayName: "ビューアー", viewerAvatarURL: nil)

        XCTAssertEqual(state.displayName, "まくはり民")
        XCTAssertEqual(state.selectedAvatarID, "avatar_4")
        XCTAssertEqual(state.visibleAvatarURL?.absoluteString, "https://example.com/avatar.jpg")
        XCTAssertTrue(state.hasCustomAvatar)
        XCTAssertEqual(state.avatarFallback, "まくはり民")
        XCTAssertTrue(state.canSave(isSaving: false))
        XCTAssertFalse(state.canSave(isSaving: true))

        state.selectPresetAvatar("avatar_2")

        XCTAssertEqual(state.selectedAvatarID, "avatar_2")
        XCTAssertNil(state.visibleAvatarURL)
        XCTAssertTrue(state.clearsAvatarURL)
    }

    func testMeguriProfileSettingsDraftHydratesOnlyWhenBlankAndTracksAlert() {
        var state = MeguriProfileSettingsDraftState()

        state.displayName = "  "
        state.hydrateIfNeeded(profile: nil, viewerDisplayName: "表示名", viewerAvatarURL: nil)

        XCTAssertEqual(state.displayName, "表示名")

        state.displayName = "編集中"
        state.hydrateIfNeeded(
            profile: MeguriProfile(userID: UUID(), displayName: "保存済み"),
            viewerDisplayName: nil,
            viewerAvatarURL: nil
        )

        XCTAssertEqual(state.displayName, "編集中")

        state.setFailureMessage(nil)
        XCTAssertTrue(state.hasAlert)
        XCTAssertEqual(state.localAlertMessage, "めぐりプロフィールを保存できませんでした")

        state.clearAlert()
        XCTAssertFalse(state.hasAlert)
    }

    func testMeguriProfileSettingsDraftHydratesPublicProfileIdentity() {
        let profile = MeguriProfile(
            userID: UUID(),
            displayName: "匿名めぐり名",
            avatarID: "avatar_4",
            avatarURL: URL(string: "https://example.com/meguri.jpg"),
            usesPublicProfile: true
        )
        var state = MeguriProfileSettingsDraftState()

        state.hydrate(
            profile: profile,
            viewerDisplayName: "グッズ交換名",
            viewerAvatarURL: URL(string: "https://example.com/public.jpg")
        )

        XCTAssertTrue(state.usesPublicProfile)
        XCTAssertEqual(state.displayName, "グッズ交換名")
        XCTAssertEqual(state.visibleAvatarURL?.absoluteString, "https://example.com/public.jpg")
        XCTAssertTrue(state.hasCustomAvatar)

        state.syncPublicProfile(
            displayName: "変更後のグッズ交換名",
            avatarURL: URL(string: "https://example.com/public-new.jpg")
        )

        XCTAssertEqual(state.displayName, "変更後のグッズ交換名")
        XCTAssertEqual(state.visibleAvatarURL?.absoluteString, "https://example.com/public-new.jpg")
        XCTAssertNil(state.avatarUpload)
        XCTAssertFalse(state.clearsAvatarURL)
    }

    func testMeguriProfileSettingsDraftKeepsStoredMeguriIdentityWhenSavingPublicProfileMode() {
        let profile = MeguriProfile(
            userID: UUID(),
            displayName: "匿名めぐり名",
            avatarID: "avatar_4",
            avatarURL: URL(string: "https://example.com/meguri.jpg"),
            usesPublicProfile: false,
            lastChangedAt: Date(timeIntervalSince1970: 2_000)
        )
        var state = MeguriProfileSettingsDraftState()

        state.hydrate(
            profile: profile,
            viewerDisplayName: "グッズ交換名",
            viewerAvatarURL: URL(string: "https://example.com/public.jpg")
        )
        state.usesPublicProfile = true
        state.syncPublicProfile(
            displayName: "グッズ交換名",
            avatarURL: URL(string: "https://example.com/public.jpg")
        )

        XCTAssertEqual(
            state.displayNameForSave(currentProfile: profile, syncedPublicDisplayName: "グッズ交換名"),
            "匿名めぐり名"
        )
        XCTAssertEqual(state.avatarIDForSave(currentProfile: profile), "avatar_4")
        XCTAssertEqual(
            state.avatarURLForSave(currentProfile: profile)?.absoluteString,
            "https://example.com/meguri.jpg"
        )
        XCTAssertNil(state.avatarUploadForSave())
        XCTAssertFalse(state.clearsAvatarURLForSave())
    }

    func testGroomAccessAllowsNearbyAndBlocksOutsideOneKilometer() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let current = MegrumLocationCoordinate(latitude: 35.681236, longitude: 139.767125)
        let nearby = GroomPost(
            id: UUID(),
            authorID: otherID,
            imageURL: URL(string: "https://example.com/near.jpg")!,
            latitude: 35.684236,
            longitude: 139.767125
        )
        let far = GroomPost(
            id: UUID(),
            authorID: otherID,
            imageURL: URL(string: "https://example.com/far.jpg")!,
            latitude: 35.701236,
            longitude: 139.767125
        )
        let mine = GroomPost(
            id: UUID(),
            authorID: viewerID,
            imageURL: URL(string: "https://example.com/mine.jpg")!,
            latitude: 35.701236,
            longitude: 139.767125
        )

        XCTAssertTrue(MeguriAccessPolicy.canOpenGroom(nearby, currentCoordinate: current, viewerID: viewerID))
        XCTAssertFalse(MeguriAccessPolicy.canOpenGroom(far, currentCoordinate: current, viewerID: viewerID))
        XCTAssertTrue(MeguriAccessPolicy.canOpenGroom(mine, currentCoordinate: nil, viewerID: viewerID))
        XCTAssertTrue(MeguriAccessPolicy.groomAccessMessage(far, currentCoordinate: current, viewerID: viewerID).contains("1km圏外"))
    }

    func testBoardAccessAllowsNearbyAndBlocksOutsideOneKilometer() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let current = MegrumLocationCoordinate(latitude: 35.681236, longitude: 139.767125)
        let nearby = BoardThread(
            id: UUID(),
            authorID: otherID,
            title: "近くのチャットルーム",
            body: "駅前広場の情報です",
            audience: .nearby3km,
            latitude: 35.684236,
            longitude: 139.767125
        )
        let far = BoardThread(
            id: UUID(),
            authorID: otherID,
            title: "遠いチャットルーム",
            body: "別会場の情報です",
            audience: .nearby3km,
            latitude: 35.701236,
            longitude: 139.767125
        )
        let mine = BoardThread(
            id: UUID(),
            authorID: viewerID,
            title: "自分のチャットルーム",
            body: "自分で立てたものです",
            audience: .samePrefecture
        )

        XCTAssertTrue(MeguriAccessPolicy.canOpenBoard(nearby, currentCoordinate: current, viewerID: viewerID))
        XCTAssertFalse(MeguriAccessPolicy.canOpenBoard(far, currentCoordinate: current, viewerID: viewerID))
        XCTAssertTrue(MeguriAccessPolicy.canOpenBoard(mine, currentCoordinate: nil, viewerID: viewerID))
        XCTAssertTrue(MeguriAccessPolicy.boardAccessMessage(far, currentCoordinate: current, viewerID: viewerID).contains("1km圏外"))

        let premiumState = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .megrumPlus, isActive: true, source: .subscription)
            ]
        )
        XCTAssertTrue(
            MeguriAccessPolicy.canOpenBoard(
                far,
                currentCoordinate: current,
                viewerID: viewerID,
                subscriptionState: premiumState
            )
        )
        XCTAssertEqual(
            MeguriAccessPolicy.boardAccessMessage(
                far,
                currentCoordinate: current,
                viewerID: viewerID,
                subscriptionState: premiumState
            ),
            ""
        )
    }

    func testCreationLocationPolicyAllowsInsideOneKilometerAndBlocksOutside() {
        let current = MegrumLocationCoordinate(latitude: 35.681236, longitude: 139.767125)
        let samePlace = MegrumLocationCoordinate(latitude: 35.681236, longitude: 139.767125)
        let nearby = MegrumLocationCoordinate(latitude: 35.684236, longitude: 139.767125)
        let far = MegrumLocationCoordinate(latitude: 35.701236, longitude: 139.767125)

        XCTAssertEqual(MeguriAccessPolicy.creationRadiusMeters, 1_000, accuracy: 0.1)
        XCTAssertTrue(MeguriAccessPolicy.canCreateAt(samePlace, currentCoordinate: current))
        XCTAssertTrue(MeguriAccessPolicy.canCreateAt(nearby, currentCoordinate: current))
        XCTAssertFalse(MeguriAccessPolicy.canCreateAt(far, currentCoordinate: current))
        XCTAssertFalse(MeguriAccessPolicy.canCreateAt(nearby, currentCoordinate: nil))
        XCTAssertTrue(
            MeguriAccessPolicy.creationLocationMessage(
                selectedCoordinate: far,
                currentCoordinate: current
            ).contains("1km圏外")
        )
    }

    func testBottomSheetLayoutSnapsBetweenPreloadedDetents() {
        let viewportHeight: CGFloat = 800
        let expandedHeight = MeguriBoardSheetLayout.expandedHeight(in: viewportHeight)
        let compactVisibleHeight = MeguriBoardSheetLayout.visibleHeight(for: .compact, in: viewportHeight)
        let compactOffset = MeguriBoardSheetLayout.restingOffset(for: .compact, in: viewportHeight)
        let regularOffset = MeguriBoardSheetLayout.restingOffset(for: .regular, in: viewportHeight)
        let expandedOffset = MeguriBoardSheetLayout.restingOffset(for: .expanded, in: viewportHeight)

        XCTAssertEqual(expandedHeight, 792, accuracy: 0.1)
        XCTAssertGreaterThanOrEqual(compactVisibleHeight, 154)
        XCTAssertLessThanOrEqual(compactVisibleHeight, 166)
        XCTAssertGreaterThan(compactOffset, regularOffset)
        XCTAssertGreaterThan(regularOffset, expandedOffset)
        XCTAssertEqual(expandedOffset, 0, accuracy: 0.1)
        XCTAssertEqual(
            MeguriBoardSheetLayout.interactiveOffset(for: .expanded, in: viewportHeight, dragTranslation: 2_000),
            compactOffset,
            accuracy: 0.1
        )
        XCTAssertEqual(
            MeguriBoardSheetLayout.targetDetent(from: .regular, translation: -48, predictedTranslation: -80),
            .expanded
        )
        XCTAssertEqual(
            MeguriBoardSheetLayout.targetDetent(from: .compact, translation: -48, predictedTranslation: -80),
            .expanded
        )
        XCTAssertEqual(
            MeguriBoardSheetLayout.targetDetent(from: .regular, translation: 58, predictedTranslation: 72),
            .compact
        )
        XCTAssertEqual(
            MeguriBoardSheetLayout.targetDetent(from: .expanded, translation: 58, predictedTranslation: 72),
            .compact
        )
    }

    func testMeguriMapRangeCirclesUseOneKilometerRadius() {
        XCTAssertEqual(MeguriMapKind.all.radiusMeters, 1_000, accuracy: 0.1)
        XCTAssertEqual(MeguriMapKind.grooms.radiusMeters, 1_000, accuracy: 0.1)
        XCTAssertEqual(MeguriMapKind.boards.radiusMeters, 1_000, accuracy: 0.1)
    }

    func testMeguriHomeMapInitialCameraFitsOneKilometerCircle() {
        XCTAssertEqual(MeguriHomeMapCamera.focusedSpan.latitudeDelta, 0.032, accuracy: 0.0001)
        XCTAssertEqual(MeguriHomeMapCamera.focusedSpan.longitudeDelta, 0.032, accuracy: 0.0001)
    }

    func testMapCreationPromptPositionStaysInsideRightEdge() {
        let viewport = CGSize(width: 393, height: 852)
        let tapPoint = CGPoint(x: 380, y: 360)
        let position = MeguriMapCreationPromptLayout.position(for: tapPoint, in: viewport)

        XCTAssertNotEqual(MeguriMapCreationPromptLayout.placement(for: tapPoint, in: viewport), .trailing)
        XCTAssertGreaterThanOrEqual(position.x - MeguriMapCreationPromptLayout.calloutSize.width / 2, 0)
        XCTAssertLessThanOrEqual(position.x + MeguriMapCreationPromptLayout.calloutSize.width / 2, viewport.width)
    }

    func testMapCreationPromptPositionStaysInsideLeftEdge() {
        let viewport = CGSize(width: 393, height: 852)
        let tapPoint = CGPoint(x: 12, y: 360)
        let position = MeguriMapCreationPromptLayout.position(for: tapPoint, in: viewport)

        XCTAssertEqual(MeguriMapCreationPromptLayout.placement(for: tapPoint, in: viewport), .trailing)
        XCTAssertGreaterThanOrEqual(position.x - MeguriMapCreationPromptLayout.calloutSize.width / 2, 0)
        XCTAssertLessThanOrEqual(position.x + MeguriMapCreationPromptLayout.calloutSize.width / 2, viewport.width)
    }

    func testMapCreationPromptPositionLeavesBottomControlsClear() {
        let viewport = CGSize(width: 393, height: 852)
        let tapPoint = CGPoint(x: 280, y: 820)
        let position = MeguriMapCreationPromptLayout.position(for: tapPoint, in: viewport)

        XCTAssertEqual(MeguriMapCreationPromptLayout.placement(for: tapPoint, in: viewport), .above)
        XCTAssertLessThanOrEqual(position.y + MeguriMapCreationPromptLayout.calloutSize.height / 2, 632)
    }

    func testMapCreationPromptAvoidsPinWhenClampedNearLeftEdge() {
        let viewport = CGSize(width: 393, height: 852)
        let tapPoint = CGPoint(x: 4, y: 520)
        let calloutFrame = MeguriMapCreationPromptLayout.calloutFrame(for: tapPoint, in: viewport)
        let pinFrame = MeguriMapCreationPromptLayout.pinAvoidanceFrame(for: tapPoint)

        XCTAssertFalse(calloutFrame.intersects(pinFrame))
    }

    func testMapCreationPromptAvoidsLeftFloatingControls() {
        let viewport = CGSize(width: 393, height: 852)
        let tapPoint = CGPoint(x: 24, y: 520)
        let calloutFrame = MeguriMapCreationPromptLayout.calloutFrame(for: tapPoint, in: viewport)
        let leftFloatingControlsFrame = CGRect(x: 0, y: 382, width: 138, height: 250)

        XCTAssertFalse(calloutFrame.intersects(leftFloatingControlsFrame))
    }

    func testMapCreationPromptPointerTracksPinWhenCalloutIsClamped() {
        let viewport = CGSize(width: 393, height: 852)
        let tapPoint = CGPoint(x: 20, y: 520)
        let placement = MeguriMapCreationPromptLayout.placement(for: tapPoint, in: viewport)
        let position = MeguriMapCreationPromptLayout.position(for: tapPoint, in: viewport)
        let pointerOffset = MeguriMapCreationPromptLayout.pointerOffset(for: tapPoint, in: viewport)

        XCTAssertEqual(placement, .trailing)
        XCTAssertEqual(position.y + pointerOffset, tapPoint.y - 36, accuracy: 0.1)
    }

    func testGroomArchiveOverviewMetricsFitFreeArchiveOnOneScreen() {
        let freeMetrics = GroomArchiveOverviewGridMetrics.metrics(itemCount: 10, availableWidth: 340)
        XCTAssertEqual(freeMetrics.columns.count, 5)
        XCTAssertEqual(GroomArchiveOverviewGridMetrics.containerHeight(itemCount: 10), 150)

        let plusMetrics = GroomArchiveOverviewGridMetrics.metrics(itemCount: 18, availableWidth: 340)
        XCTAssertEqual(plusMetrics.columns.count, 6)
        XCTAssertEqual(GroomArchiveOverviewGridMetrics.containerHeight(itemCount: 18), 190)
        XCTAssertLessThanOrEqual(plusMetrics.thumbnailSize, freeMetrics.thumbnailSize)
    }

    func testGroomArchiveStoryPresentationStateTracksInsightsSheet() {
        var state = GroomArchiveStoryPresentationState()

        XCTAssertFalse(state.showsInsights)

        state.showInsights()

        XCTAssertTrue(state.showsInsights)

        state.dismissInsights()

        XCTAssertFalse(state.showsInsights)
    }

    func testGroomArchiveStoryPresentationStateMovesWithinBoundsAndDismissesAfterLast() {
        var state = GroomArchiveStoryPresentationState(initialIndex: 1)

        XCTAssertEqual(state.currentIndex, 1)
        XCTAssertEqual(state.move(by: -1, itemCount: 3), .moved)
        XCTAssertEqual(state.currentIndex, 0)
        XCTAssertEqual(state.move(by: -1, itemCount: 3), .unchanged)
        XCTAssertEqual(state.currentIndex, 0)

        XCTAssertEqual(state.move(by: 1, itemCount: 3), .moved)
        XCTAssertEqual(state.move(by: 1, itemCount: 3), .moved)
        XCTAssertEqual(state.currentIndex, 2)
        XCTAssertEqual(state.move(by: 1, itemCount: 3), .dismiss)
        XCTAssertEqual(state.currentIndex, 2)
    }

    func testGroomArchiveStoryPresentationStateTracksDragDisplayAndOutcomes() {
        var state = GroomArchiveStoryPresentationState()

        state.updateDrag(CGSize(width: 12, height: 180))

        XCTAssertEqual(state.dragOffset, CGSize(width: 12, height: 180))
        XCTAssertEqual(state.imageYOffset, 36, accuracy: 0.001)
        XCTAssertEqual(state.imageScale, 0.92, accuracy: 0.001)
        XCTAssertEqual(state.dragOutcome(for: CGSize(width: 0, height: -90)), .showInsights)
        XCTAssertEqual(state.dragOutcome(for: CGSize(width: 0, height: 124)), .dismiss)
        XCTAssertEqual(state.dragOutcome(for: CGSize(width: 0, height: 20)), .none)

        state.resetDrag()

        XCTAssertEqual(state.dragOffset, .zero)
    }

    func testGroomArchivePresentationStateTracksSelectedGroomAndPlusSheet() {
        let groom = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000701")!,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000000702")!,
            imageURL: URL(string: "https://example.com/groom.jpg")!,
            latitude: 35.6812,
            longitude: 139.7671,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        var state = GroomArchivePresentationState()

        XCTAssertNil(state.selectedGroom)
        XCTAssertNil(state.selectedGroomID)
        XCTAssertFalse(state.showsMegrumPlus)

        state.select(groom)
        state.showMegrumPlus()

        XCTAssertEqual(state.selectedGroomID, groom.id)
        XCTAssertEqual(state.selectedGroom, groom)
        XCTAssertTrue(state.showsMegrumPlus)

        state.dismissMegrumPlus()

        XCTAssertFalse(state.showsMegrumPlus)
    }

    func testGroomMapClustersNearbyPostsAndKeepsNewestFirst() {
        let older = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
            imageURL: URL(string: "https://example.com/older.jpg")!,
            latitude: 35.000,
            longitude: 139.000,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000000302")!,
            imageURL: URL(string: "https://example.com/newer.jpg")!,
            latitude: 35.001,
            longitude: 139.001,
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let distant = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000203")!,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000000303")!,
            imageURL: URL(string: "https://example.com/distant.jpg")!,
            latitude: 35.040,
            longitude: 139.040,
            createdAt: Date(timeIntervalSince1970: 300)
        )

        let clusters = GroomMapCluster.clusters(from: [older, distant, newer], cellDegrees: 0.01)
        let grouped = try! XCTUnwrap(clusters.first { $0.posts.count == 2 })
        let single = try! XCTUnwrap(clusters.first { $0.posts.count == 1 })

        XCTAssertEqual(grouped.title, "2件のグルーム")
        XCTAssertEqual(grouped.posts.map(\.id), [newer.id, older.id])
        XCTAssertEqual(grouped.coordinate.latitude, 35.0005, accuracy: 0.0001)
        XCTAssertEqual(grouped.coordinate.longitude, 139.0005, accuracy: 0.0001)
        XCTAssertEqual(single.id, distant.id.uuidString)
    }

    func testGroomFeedOrderingPrioritizesUnreadLatestAndExcludesViewerPost() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let latestUnread = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            authorID: otherID,
            imageURL: URL(string: "https://example.com/latest.jpg")!,
            latitude: 35.681236,
            longitude: 139.767125,
            createdAt: Date(timeIntervalSince1970: 300)
        )
        let olderUnread = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            authorID: otherID,
            imageURL: URL(string: "https://example.com/older.jpg")!,
            latitude: 35.681236,
            longitude: 139.767125,
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let readPost = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!,
            authorID: otherID,
            imageURL: URL(string: "https://example.com/read.jpg")!,
            latitude: 35.681236,
            longitude: 139.767125,
            createdAt: Date(timeIntervalSince1970: 400)
        )
        let viewerPost = GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000104")!,
            authorID: viewerID,
            imageURL: URL(string: "https://example.com/mine.jpg")!,
            latitude: 35.681236,
            longitude: 139.767125,
            createdAt: Date(timeIntervalSince1970: 500)
        )

        let sorted = GroomFeedOrdering.sorted(
            [readPost, viewerPost, olderUnread, latestUnread],
            viewerID: viewerID,
            viewedIDs: [readPost.id]
        )

        XCTAssertEqual(sorted.map(\.id), [latestUnread.id, olderUnread.id, readPost.id])
    }

    func testLocationPermissionPhaseAndNoticeCopy() {
        let requesting = MegrumLocationState.permissionPhase(
            authorizationStatus: .notDetermined,
            isRequestingLocation: true,
            hasCoordinate: false,
            locationServicesEnabled: true,
            hasError: false
        )
        let denied = MegrumLocationState.permissionPhase(
            authorizationStatus: .denied,
            isRequestingLocation: false,
            hasCoordinate: false,
            locationServicesEnabled: true,
            hasError: true
        )
        let servicesOff = MegrumLocationState.permissionPhase(
            authorizationStatus: .authorizedAlways,
            isRequestingLocation: false,
            hasCoordinate: false,
            locationServicesEnabled: false,
            hasError: false
        )

        XCTAssertEqual(requesting, .requesting)
        XCTAssertEqual(denied, .denied)
        XCTAssertEqual(servicesOff, .servicesDisabled)
        XCTAssertEqual(MegrumLocationState.meguriNotice(phase: .requesting, errorMessage: nil)?.message, "現在地を確認しています")
        XCTAssertEqual(MegrumLocationState.meguriNotice(phase: .denied, errorMessage: nil)?.actionTitle, "設定")
        XCTAssertEqual(MegrumLocationState.meguriNotice(phase: .notDetermined, errorMessage: nil)?.message, "現在地を許可すると、近くのグルームと1km圏内のチャットルームを表示できます")
    }
}
