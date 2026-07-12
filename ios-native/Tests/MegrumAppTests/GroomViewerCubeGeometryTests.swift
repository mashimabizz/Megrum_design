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
final class GroomViewerCubeTransitionPlannerTests: XCTestCase {
    private let a = UUID()
    private let b = UUID()
    private let c = UUID()

    /// [a, a, b, c] を返す（0,1=投稿者a、2=b、3=c）。
    private var authors: [UUID] { [a, a, b, c] }

    func testTapAcrossAuthorBoundaryStartsTransitionWithoutChangingIndex() {
        // index 1（投稿者a末尾）→ index 2（投稿者b）は境界なので回転（＝index即変更しない）。
        let decision = GroomViewerCubeTransitionPlanner.decideMove(
            authorIDs: authors,
            currentIndex: 1,
            delta: 1,
            reduceMotion: false,
            isOpeningSettled: true,
            hasActiveTransition: false
        )
        XCTAssertEqual(decision, .transition(source: 1, target: 2, direction: 1))
    }

    func testTransitionCommitsToTargetIndexExactlyOnce() {
        // 完了時に渡された targetIndex へ 1 回だけ commit されること（id 一致時のみ）。
        let transition = GroomViewerCubeTransition(
            sourceIndex: 1, targetIndex: 2, direction: 1, progress: 1, origin: .tap
        )
        // 現在の遷移が同一 id → commit すべき。
        XCTAssertTrue(shouldCommit(active: transition, completed: transition))
        // 連打で別遷移に置き換わっている → 古い完了は破棄（commit しない）。
        let newer = GroomViewerCubeTransition(
            sourceIndex: 2, targetIndex: 3, direction: 1, progress: 0.3, origin: .tap
        )
        XCTAssertFalse(shouldCommit(active: newer, completed: transition))
        XCTAssertFalse(shouldCommit(active: nil, completed: transition))
    }

    private func shouldCommit(
        active: GroomViewerCubeTransition?,
        completed: GroomViewerCubeTransition
    ) -> Bool {
        active?.id == completed.id
    }

    func testTapWithinSameAuthorSwitchesImmediately() {
        // index 0 → 1 は同一投稿者a。回転せず即切替。
        let decision = GroomViewerCubeTransitionPlanner.decideMove(
            authorIDs: authors,
            currentIndex: 0,
            delta: 1,
            reduceMotion: false,
            isOpeningSettled: true,
            hasActiveTransition: false
        )
        XCTAssertEqual(decision, .immediate(index: 1))
    }

    func testReduceMotionSwitchesImmediatelyEvenAcrossAuthors() {
        let decision = GroomViewerCubeTransitionPlanner.decideMove(
            authorIDs: authors,
            currentIndex: 1,
            delta: 1,
            reduceMotion: true,
            isOpeningSettled: true,
            hasActiveTransition: false
        )
        XCTAssertEqual(decision, .immediate(index: 2))
    }

    func testNotSettledSwitchesImmediatelyEvenAcrossAuthors() {
        let decision = GroomViewerCubeTransitionPlanner.decideMove(
            authorIDs: authors,
            currentIndex: 1,
            delta: 1,
            reduceMotion: false,
            isOpeningSettled: false,
            hasActiveTransition: false
        )
        XCTAssertEqual(decision, .immediate(index: 2))
    }

    func testTapDuringActiveTransitionIsIgnoredNoDoubleTransition() {
        let decision = GroomViewerCubeTransitionPlanner.decideMove(
            authorIDs: authors,
            currentIndex: 1,
            delta: 1,
            reduceMotion: false,
            isOpeningSettled: true,
            hasActiveTransition: true
        )
        XCTAssertEqual(decision, .ignore)
    }

    func testBackwardDirectionAcrossAuthorBoundaryIsNegative() {
        // index 2（投稿者b）→ index 1（投稿者a）は境界。戻る＝direction -1。
        let decision = GroomViewerCubeTransitionPlanner.decideMove(
            authorIDs: authors,
            currentIndex: 2,
            delta: -1,
            reduceMotion: false,
            isOpeningSettled: true,
            hasActiveTransition: false
        )
        XCTAssertEqual(decision, .transition(source: 2, target: 1, direction: -1))
    }

    func testForwardPastEndDismissesBackwardPastStartIgnored() {
        // 末尾（index 3）から先へ → 閉じる。
        XCTAssertEqual(
            GroomViewerCubeTransitionPlanner.decideMove(
                authorIDs: authors, currentIndex: 3, delta: 1,
                reduceMotion: false, isOpeningSettled: true, hasActiveTransition: false
            ),
            .dismiss
        )
        // 先頭（index 0）から前へ → 何もしない。
        XCTAssertEqual(
            GroomViewerCubeTransitionPlanner.decideMove(
                authorIDs: authors, currentIndex: 0, delta: -1,
                reduceMotion: false, isOpeningSettled: true, hasActiveTransition: false
            ),
            .ignore
        )
    }

    func testSwipeCommitByProgressOrPredictedThreshold() {
        // 進捗がしきい値超え → 確定。
        XCTAssertTrue(
            GroomViewerCubeTransitionPlanner.swipeCommits(
                progress: GroomViewerCubeGeometry.commitProgressThreshold + 0.01,
                predicted: 0
            )
        )
        // 進捗は足りないが勢い（predicted）がしきい値超え → 確定。
        XCTAssertTrue(
            GroomViewerCubeTransitionPlanner.swipeCommits(
                progress: 0.1,
                predicted: GroomViewerCubeGeometry.commitPredictedThreshold + 0.01
            )
        )
        // どちらも足りない → キャンセル（戻す）。
        XCTAssertFalse(
            GroomViewerCubeTransitionPlanner.swipeCommits(progress: 0.1, predicted: 0.1)
        )
    }
}

@MainActor
final class GroomViewerFacePlannerTests: XCTestCase {
    private func groom(id: UUID, author: UUID) -> GroomPost {
        GroomPost(
            id: id,
            authorID: author,
            imageURL: URL(string: "https://example.com/\(id.uuidString).jpg")!,
            latitude: 35.0,
            longitude: 139.0,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    /// 投稿者違いの2件（境界）。source=0（authorA）→ target=1（authorB）。
    private func makeGrooms() -> (grooms: [GroomPost], g0: UUID, g1: UUID) {
        let g0 = UUID()
        let g1 = UUID()
        let a = UUID()
        let b = UUID()
        return ([groom(id: g0, author: a), groom(id: g1, author: b)], g0, g1)
    }

    private func transition(source: Int, target: Int, progress: Double) -> GroomViewerCubeTransition {
        GroomViewerCubeTransition(
            sourceIndex: source,
            targetIndex: target,
            direction: 1,
            progress: progress,
            origin: .tap
        )
    }

    func testNormalStateShowsOnlyCurrentLayer() {
        let (grooms, g0, _) = makeGrooms()
        let layers = GroomViewerFacePlanner.layers(grooms: grooms, currentIndex: 0, transition: nil)
        XCTAssertEqual(layers.map(\.role), [.current])
        XCTAssertEqual(layers.first?.id, g0)
        XCTAssertEqual(layers.first?.isInteractionEnabled, true)
    }

    func testTransitionShowsOutgoingThenIncomingBothNonInteractive() {
        let (grooms, g0, g1) = makeGrooms()
        let layers = GroomViewerFacePlanner.layers(
            grooms: grooms, currentIndex: 0, transition: transition(source: 0, target: 1, progress: 0.5)
        )
        XCTAssertEqual(layers.map(\.role), [.outgoing, .incoming])
        XCTAssertEqual(layers.map(\.groomIndex), [0, 1])
        XCTAssertEqual(layers[0].id, g0)
        XCTAssertEqual(layers[1].id, g1)
        // 回転中は source/target とも操作無効（直列化）。
        XCTAssertEqual(layers.allSatisfy { !$0.isInteractionEnabled }, true)
        // incoming が前面。
        XCTAssertGreaterThan(layers[1].zIndex, layers[0].zIndex)
    }

    /// 核心：回転中の target(incoming) 面と、commit 後の current 面が **同じ id**。
    /// これにより SwiftUI が同一 View として扱い、面を作り直さず昇格できる。
    func testIncomingLayerIdEqualsCurrentLayerIdAfterCommit() {
        let (grooms, _, g1) = makeGrooms()
        let during = GroomViewerFacePlanner.layers(
            grooms: grooms, currentIndex: 0, transition: transition(source: 0, target: 1, progress: 1)
        )
        let incoming = during.first { $0.role == .incoming }
        // commit 後：currentIndex=targetIndex, transition=nil
        let after = GroomViewerFacePlanner.layers(grooms: grooms, currentIndex: 1, transition: nil)
        let current = after.first { $0.role == .current }
        XCTAssertEqual(incoming?.id, current?.id)
        XCTAssertEqual(current?.id, g1)
    }

    func testTransitionToCommitReducesToSingleTargetLayer() {
        let (grooms, _, g1) = makeGrooms()
        let during = GroomViewerFacePlanner.layers(
            grooms: grooms, currentIndex: 0, transition: transition(source: 0, target: 1, progress: 0.8)
        )
        XCTAssertEqual(during.count, 2)
        let after = GroomViewerFacePlanner.layers(grooms: grooms, currentIndex: 1, transition: nil)
        XCTAssertEqual(after.count, 1)
        XCTAssertEqual(after.map(\.role), [.current])
        XCTAssertEqual(after.first?.groomIndex, 1)
        XCTAssertEqual(after.first?.id, g1)
    }

    func testIncomingTransformAtProgressOneEqualsRestingIdentity() {
        // progress=1 の incoming が恒等（resting）と完全一致するので、昇格時に変形差が出ない。
        XCTAssertEqual(
            GroomViewerCubeGeometry.incoming(progress: 1, direction: 1, width: 390),
            GroomViewerCubeGeometry.resting
        )
        XCTAssertEqual(
            GroomViewerCubeGeometry.incoming(progress: 1, direction: -1, width: 390),
            GroomViewerCubeGeometry.resting
        )
        // 途中はまだ回転している（恒等ではない）。
        XCTAssertNotEqual(
            GroomViewerCubeGeometry.incoming(progress: 0.5, direction: 1, width: 390),
            GroomViewerCubeGeometry.resting
        )
    }

    func testOutOfRangeTransitionFallsBackToCurrent() {
        let (grooms, g0, _) = makeGrooms()
        // targetIndex 範囲外 → current にフォールバック（クラッシュしない）。
        let layers = GroomViewerFacePlanner.layers(
            grooms: grooms, currentIndex: 0, transition: transition(source: 0, target: 9, progress: 0.5)
        )
        XCTAssertEqual(layers.map(\.role), [.current])
        XCTAssertEqual(layers.first?.id, g0)
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
        // 入力は B が先頭に現れる交互の並び（レール表示順を想定）
        let grooms = [
            groom(author: b, minutesAgo: 10),
            groom(author: a, minutesAgo: 20),
            groom(author: b, minutesAgo: 30),
            groom(author: a, minutesAgo: 40)
        ]

        let ordered = GroomViewerAuthorNavigation.orderedGroupingAuthors(grooms)

        // 投稿者ブロックは入力の先頭出現順（B → A）、ブロック内は古い→新しい
        XCTAssertEqual(ordered.map(\.authorID), [b, b, a, a])
        XCTAssertLessThan(ordered[0].createdAt, ordered[1].createdAt)
        XCTAssertLessThan(ordered[2].createdAt, ordered[3].createdAt)
    }

    func testAuthorBlockRangeCoversCurrentAuthorRun() {
        let a = UUID()
        let b = UUID()
        let authors = [a, a, b, b, b]

        XCTAssertEqual(GroomViewerAuthorNavigation.authorBlockRange(authorIDs: authors, currentIndex: 0), 0..<2)
        XCTAssertEqual(GroomViewerAuthorNavigation.authorBlockRange(authorIDs: authors, currentIndex: 3), 2..<5)
        // 範囲外は現在位置のみの安全な範囲
        XCTAssertEqual(GroomViewerAuthorNavigation.authorBlockRange(authorIDs: authors, currentIndex: 9), 9..<10)
    }

    /// iter1226.470：先頭セグメント判定＝currentIndex がブロックの lowerBound と一致するか。
    /// 左タップの「現在グルームを最初から再生し直す」条件（それ以外は前グルームへ）。
    func testFirstSegmentOfBlockPredicate() {
        let a = UUID()
        let b = UUID()
        let authors = [a, a, b, b, b]
        func isFirstOfBlock(_ index: Int) -> Bool {
            index == GroomViewerAuthorNavigation.authorBlockRange(authorIDs: authors, currentIndex: index).lowerBound
        }
        XCTAssertTrue(isFirstOfBlock(0))   // 投稿者a の先頭 → 再生し直し
        XCTAssertFalse(isFirstOfBlock(1))  // a の2件目 → 前グルームへ
        XCTAssertTrue(isFirstOfBlock(2))   // 投稿者b の先頭 → 再生し直し
        XCTAssertFalse(isFirstOfBlock(3))  // b の2件目 → 前グルームへ
        XCTAssertFalse(isFirstOfBlock(4))  // b の3件目 → 前グルームへ
    }
}

@MainActor
final class GroomImageCacheKeyNormalizationTests: XCTestCase {
    /// iter1226.446：署名トークンが回転しても同一画像として扱えること（キャッシュキーの根拠）。
    func testStoragePathIgnoresRotatingSignedToken() {
        let first = URL(string: "https://x.supabase.co/storage/v1/object/sign/groom-posts/user1/photo.jpg?token=AAA")!
        let second = URL(string: "https://x.supabase.co/storage/v1/object/sign/groom-posts/user1/photo.jpg?token=BBB")!
        XCTAssertEqual(
            GroomSignedURLPathExtractor.storagePath(from: first),
            GroomSignedURLPathExtractor.storagePath(from: second)
        )
        XCTAssertEqual(GroomSignedURLPathExtractor.storagePath(from: first), "user1/photo.jpg")
    }

    func testStoragePathIsNilForNonGroomURL() {
        let url = URL(string: "https://example.com/other/image.jpg")!
        XCTAssertNil(GroomSignedURLPathExtractor.storagePath(from: url))
    }
}
