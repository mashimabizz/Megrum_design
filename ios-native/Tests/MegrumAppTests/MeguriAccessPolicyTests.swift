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
