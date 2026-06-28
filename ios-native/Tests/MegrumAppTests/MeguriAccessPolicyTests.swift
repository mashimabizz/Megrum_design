@testable import MegrumApp
import CoreGraphics
import CoreLocation
import Foundation
import MegrumCore
import XCTest

@MainActor
final class MeguriAccessPolicyTests: XCTestCase {
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
