import Foundation
import MegrumCore
import Testing
@testable import MegrumApp

@Suite("MeguriAccessPolicyGroomGate")
struct MeguriAccessPolicyGroomGateTests {
    private let viewerID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
    private let authorID = UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!
    private let viewerCoordinate = MegrumLocationCoordinate(latitude: 35.0, longitude: 139.0)

    private func groom(latitude: Double, wasNotified: Bool = false) -> GroomPost {
        GroomPost(
            id: UUID(),
            authorID: authorID,
            imageURL: URL(string: "https://example.com/g.jpg")!,
            latitude: latitude,
            longitude: 139.0,
            wasNotified: wasNotified
        )
    }

    private var premium: UserSubscriptionState {
        UserSubscriptionState(entitlements: [
            UserEntitlement(key: .megrumPlus, isActive: true, source: .subscription)
        ])
    }

    // 緯度 +0.005 ≈ 約550m（圏内）、+0.02 ≈ 約2.2km（圏外）。

    @Test("圏内グルームは無料で開ける")
    func inRangeIsFree() {
        #expect(MeguriAccessPolicy.canOpenGroom(
            groom(latitude: 35.005),
            currentCoordinate: viewerCoordinate,
            viewerID: viewerID
        ))
    }

    @Test("自分のグルームは常に開ける")
    func ownIsAlwaysOpen() {
        let own = GroomPost(
            id: UUID(),
            authorID: viewerID,
            imageURL: URL(string: "https://example.com/g.jpg")!,
            latitude: 35.02,
            longitude: 139.0
        )
        #expect(MeguriAccessPolicy.canOpenGroom(
            own,
            currentCoordinate: viewerCoordinate,
            viewerID: viewerID
        ))
    }

    @Test("圏外・非通知は開けない")
    func outOfRangeNotNotifiedBlocked() {
        #expect(!MeguriAccessPolicy.canOpenGroom(
            groom(latitude: 35.02, wasNotified: false),
            currentCoordinate: viewerCoordinate,
            viewerID: viewerID,
            wasNotified: false,
            subscriptionState: premium
        ))
    }

    @Test("圏外・通知済み・非プレミアムは開けない")
    func outOfRangeNotifiedNonPremiumBlocked() {
        #expect(!MeguriAccessPolicy.canOpenGroom(
            groom(latitude: 35.02, wasNotified: true),
            currentCoordinate: viewerCoordinate,
            viewerID: viewerID,
            wasNotified: true,
            subscriptionState: .free
        ))
    }

    @Test("圏外・通知済み・プレミアムは開ける")
    func outOfRangeNotifiedPremiumOpens() {
        #expect(MeguriAccessPolicy.canOpenGroom(
            groom(latitude: 35.02, wasNotified: true),
            currentCoordinate: viewerCoordinate,
            viewerID: viewerID,
            wasNotified: true,
            subscriptionState: premium
        ))
    }
}
