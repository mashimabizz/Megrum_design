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
            title: "近くの掲示板",
            body: "駅前広場の情報です",
            audience: .nearby3km,
            latitude: 35.684236,
            longitude: 139.767125
        )
        let far = BoardThread(
            id: UUID(),
            authorID: otherID,
            title: "遠い掲示板",
            body: "別会場の情報です",
            audience: .nearby3km,
            latitude: 35.701236,
            longitude: 139.767125
        )
        let mine = BoardThread(
            id: UUID(),
            authorID: viewerID,
            title: "自分の掲示板",
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
        XCTAssertEqual(MeguriMapKind.grooms.radiusMeters, 1_000, accuracy: 0.1)
        XCTAssertEqual(MeguriMapKind.boards.radiusMeters, 1_000, accuracy: 0.1)
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
        XCTAssertEqual(MegrumLocationState.meguriNotice(phase: .notDetermined, errorMessage: nil)?.message, "現在地を許可すると、近くのグルームと1km圏内の掲示板を表示できます")
    }
}
