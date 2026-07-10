@testable import MegrumApp
import CoreGraphics
import Foundation
import MegrumCore
import XCTest

@MainActor
final class GroomViewerCubeGeometryTests: XCTestCase {
    private let width: CGFloat = 390

    func testForwardOutgoingFaceRotatesAwayAroundTrailingEdge() {
        let start = GroomViewerCubeGeometry.outgoing(progress: 0, direction: 1, width: width)
        XCTAssertEqual(start.offsetX, 0)
        XCTAssertEqual(start.degrees, 0)
        XCTAssertEqual(start.anchorX, 1)

        // iter1226.437：外側視点（凸）の回転方向。
        let end = GroomViewerCubeGeometry.outgoing(progress: 1, direction: 1, width: width)
        XCTAssertEqual(end.offsetX, -width)
        XCTAssertEqual(end.degrees, -90)
    }

    func testForwardIncomingFaceRisesFromRightSideToFront() {
        let start = GroomViewerCubeGeometry.incoming(progress: 0, direction: 1, width: width)
        XCTAssertEqual(start.offsetX, width)
        XCTAssertEqual(start.degrees, 90)
        XCTAssertEqual(start.anchorX, 0)

        let end = GroomViewerCubeGeometry.incoming(progress: 1, direction: 1, width: width)
        XCTAssertEqual(end.offsetX, 0)
        XCTAssertEqual(end.degrees, 0)
    }

    func testBackwardDirectionMirrorsForward() {
        let outgoing = GroomViewerCubeGeometry.outgoing(progress: 0.5, direction: -1, width: width)
        XCTAssertEqual(outgoing.offsetX, width / 2)
        XCTAssertEqual(outgoing.degrees, 45)
        XCTAssertEqual(outgoing.anchorX, 0)

        let incoming = GroomViewerCubeGeometry.incoming(progress: 0.5, direction: -1, width: width)
        XCTAssertEqual(incoming.offsetX, -width / 2)
        XCTAssertEqual(incoming.degrees, -45)
        XCTAssertEqual(incoming.anchorX, 1)
    }

    func testDragProgressFollowsFingerAndClamps() {
        // 進む（左スワイプ）：負の translation が進捗になる
        XCTAssertEqual(
            GroomViewerCubeGeometry.dragProgress(translationX: -195, direction: 1, width: width),
            0.5,
            accuracy: 0.0001
        )
        // 逆方向へ引いても 0 で止まる
        XCTAssertEqual(GroomViewerCubeGeometry.dragProgress(translationX: 80, direction: 1, width: width), 0)
        // 1 を超えない
        XCTAssertEqual(GroomViewerCubeGeometry.dragProgress(translationX: -800, direction: 1, width: width), 1)
        // 戻る（右スワイプ）
        XCTAssertEqual(
            GroomViewerCubeGeometry.dragProgress(translationX: 195, direction: -1, width: width),
            0.5,
            accuracy: 0.0001
        )
        XCTAssertEqual(GroomViewerCubeGeometry.dragProgress(translationX: -10, direction: 1, width: 0), 0)
    }

    func testAuthorSwitchTargetIndexJumpsBetweenAuthorBlocks() {
        let a = UUID()
        let b = UUID()
        let c = UUID()
        let authors = [a, a, b, b, b, c]

        // 進む：次の投稿者ブロックの先頭
        XCTAssertEqual(
            GroomViewerAuthorNavigation.authorSwitchTargetIndex(authorIDs: authors, currentIndex: 0, direction: 1),
            2
        )
        XCTAssertEqual(
            GroomViewerAuthorNavigation.authorSwitchTargetIndex(authorIDs: authors, currentIndex: 3, direction: 1),
            5
        )
        // 最後の投稿者からは進めない
        XCTAssertNil(
            GroomViewerAuthorNavigation.authorSwitchTargetIndex(authorIDs: authors, currentIndex: 5, direction: 1)
        )

        // 戻る：前の投稿者ブロックの先頭
        XCTAssertEqual(
            GroomViewerAuthorNavigation.authorSwitchTargetIndex(authorIDs: authors, currentIndex: 5, direction: -1),
            2
        )
        XCTAssertEqual(
            GroomViewerAuthorNavigation.authorSwitchTargetIndex(authorIDs: authors, currentIndex: 4, direction: -1),
            0
        )
        // 先頭の投稿者からは戻れない
        XCTAssertNil(
            GroomViewerAuthorNavigation.authorSwitchTargetIndex(authorIDs: authors, currentIndex: 1, direction: -1)
        )
    }

    func testShadesDarkenRecedingFaceAndLightenArrivingFace() {
        XCTAssertEqual(GroomViewerCubeGeometry.outgoingShade(progress: 0), 0)
        XCTAssertEqual(
            GroomViewerCubeGeometry.outgoingShade(progress: 1),
            GroomViewerCubeGeometry.maxShadeOpacity
        )
        XCTAssertEqual(
            GroomViewerCubeGeometry.incomingShade(progress: 0),
            GroomViewerCubeGeometry.maxShadeOpacity
        )
        XCTAssertEqual(GroomViewerCubeGeometry.incomingShade(progress: 1), 0)
    }
}

@MainActor
final class GroomViewerAuthorGroupingTests: XCTestCase {
    private func groom(author: UUID, minutesAgo: Int) -> GroomPost {
        GroomPost(
            id: UUID(),
            authorID: author,
            imageURL: URL(string: "https://example.com/\(minutesAgo).jpg")!,
            latitude: 35.0,
            longitude: 139.0,
            createdAt: Date(timeIntervalSinceNow: -Double(minutesAgo) * 60)
        )
    }

    func testOrderingGroupsInterleavedAuthorsIntoBlocks() {
        let a = UUID()
        let b = UUID()
        // 時刻順だと A, B, A, B と交互になる並び
        let grooms = [
            groom(author: a, minutesAgo: 40),
            groom(author: b, minutesAgo: 30),
            groom(author: a, minutesAgo: 20),
            groom(author: b, minutesAgo: 10)
        ]

        let ordered = GroomViewerAuthorNavigation.orderedGroupingAuthors(grooms.shuffled())

        // 投稿者ブロックにまとまり（A の一連 → B の一連）、ブロック内は古い→新しい
        XCTAssertEqual(ordered.map(\.authorID), [a, a, b, b])
        XCTAssertLessThan(ordered[0].createdAt, ordered[1].createdAt)
        XCTAssertLessThan(ordered[2].createdAt, ordered[3].createdAt)
    }
}
