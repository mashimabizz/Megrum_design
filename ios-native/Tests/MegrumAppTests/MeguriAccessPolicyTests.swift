@testable import MegrumApp
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
    }
}
