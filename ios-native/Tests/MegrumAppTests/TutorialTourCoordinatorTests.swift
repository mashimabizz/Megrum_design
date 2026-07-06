@testable import MegrumApp
import XCTest

@MainActor
final class TutorialTourCoordinatorTests: XCTestCase {
    func testStartsInactive() {
        let coordinator = TutorialTourCoordinator()
        XCTAssertFalse(coordinator.isActive)
        XCTAssertNil(coordinator.currentBeat)
    }

    func testStartBeginsAtFirstBeat() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start()
        XCTAssertTrue(coordinator.isActive)
        XCTAssertEqual(coordinator.currentBeat?.id, "1-1")
        XCTAssertEqual(coordinator.currentBeat?.chapter, .welcome)
    }

    func testStartAtSpecificBeat() {
        let coordinator = TutorialTourCoordinator()
        let beat = TutorialScript.beat(withID: "4-7")
        XCTAssertNotNil(beat)
        coordinator.start(at: beat)
        XCTAssertEqual(coordinator.currentBeat?.id, "4-7")
    }

    func testAdvanceWalksAllBeatsThenFinishes() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start()
        for expected in TutorialScript.beats.dropFirst() {
            coordinator.advance()
            XCTAssertEqual(coordinator.currentBeat, expected)
        }
        coordinator.advance()
        XCTAssertNil(coordinator.currentBeat)
        XCTAssertFalse(coordinator.isActive)
    }

    func testRetreatMovesBackAndStopsAtStart() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start(at: TutorialScript.beat(withID: "4-3"))
        XCTAssertTrue(coordinator.canRetreat)
        coordinator.retreat()
        XCTAssertEqual(coordinator.currentBeat?.id, "4-2")
        coordinator.start()
        XCTAssertFalse(coordinator.canRetreat)
        coordinator.retreat()
        XCTAssertEqual(coordinator.currentBeat?.id, "1-1")
    }

    func testChapterScopePlaysSingleChapterOnly() {
        let coordinator = TutorialTourCoordinator()
        coordinator.startChapter(.trades)
        XCTAssertEqual(coordinator.currentBeat?.id, "8-1")
        XCTAssertFalse(coordinator.canRetreat)
        coordinator.advance()
        XCTAssertEqual(coordinator.currentBeat?.id, "8-2")
        XCTAssertTrue(coordinator.canRetreat)
        coordinator.advance()
        XCTAssertNil(coordinator.currentBeat)
    }

    func testChapterScopeSkipsLeadingTabBandBeat() {
        let coordinator = TutorialTourCoordinator()
        // めぐり章の先頭 9-1 は「タブへ移動するよ」のつなぎビート。単体再生では 9-2 から始める。
        coordinator.startChapter(.meguri)
        XCTAssertEqual(coordinator.currentBeat?.id, "9-2")
        // 実質先頭より前（9-1）へは戻らない。
        XCTAssertFalse(coordinator.canRetreat)
        coordinator.retreat()
        XCTAssertEqual(coordinator.currentBeat?.id, "9-2")
        coordinator.advance()
        XCTAssertTrue(coordinator.canRetreat)
        // ほしいもの章も同様に 5-1（タブ帯）を飛ばして 5-2 から。
        coordinator.startChapter(.wish)
        XCTAssertEqual(coordinator.currentBeat?.id, "5-2")
    }

    func testScriptIntegrity() {
        let beats = TutorialScript.beats
        XCTAssertFalse(beats.isEmpty)
        // ID一意
        XCTAssertEqual(Set(beats.map(\.id)).count, beats.count)
        // 章は登場順に単調（後戻りしない）
        let chapterOrder = beats.map(\.chapter.rawValue)
        XCTAssertEqual(chapterOrder, chapterOrder.sorted())
        // 全10章が存在する
        XCTAssertEqual(Set(beats.map(\.chapter)).count, TutorialChapter.allCases.count)
    }

    func testChapterProgressCountsMatchScript() {
        let inventoryBeats = TutorialScript.beats.filter { $0.chapter == .inventory }
        XCTAssertEqual(inventoryBeats.count, 15)
        let first = TutorialScript.chapterProgress(of: inventoryBeats[0])
        XCTAssertEqual(first.index, 1)
        XCTAssertEqual(first.count, 15)
        let listingBeats = TutorialScript.beats.filter { $0.chapter == .listing }
        XCTAssertEqual(listingBeats.count, 16)
        let proposalBeats = TutorialScript.beats.filter { $0.chapter == .proposal }
        XCTAssertEqual(proposalBeats.count, 13)
        let meguriBeats = TutorialScript.beats.filter { $0.chapter == .meguri }
        XCTAssertEqual(meguriBeats.count, 6)
    }

    func testTargetTabsFollowChapters() {
        XCTAssertEqual(TutorialScript.beat(withID: "2-1")?.targetTab, .home)
        XCTAssertEqual(TutorialScript.beat(withID: "4-1")?.targetTab, .inventory)
        XCTAssertEqual(TutorialScript.beat(withID: "5-2")?.targetTab, .wish)
        XCTAssertEqual(TutorialScript.beat(withID: "5-2")?.requestedWishSection, .wishes)
        XCTAssertEqual(TutorialScript.beat(withID: "6-2")?.requestedWishSection, .listings)
        XCTAssertEqual(TutorialScript.beat(withID: "8-1")?.targetTab, .trades)
        XCTAssertEqual(TutorialScript.beat(withID: "9-2")?.targetTab, .meguri)
    }

    func testHomeFocusAnchorsOnHomeChapter() {
        XCTAssertEqual(TutorialScript.beat(withID: "2-1")?.homeFocusAnchor, .homeSectionUserTag)
        XCTAssertEqual(TutorialScript.beat(withID: "2-2")?.homeFocusAnchor, .homeSectionUser)
        XCTAssertEqual(TutorialScript.beat(withID: "2-3")?.homeFocusAnchor, .homeSectionHaves)
        XCTAssertNil(TutorialScript.beat(withID: "4-2")?.homeFocusAnchor)
    }

    func testVisualQAStartBeatParsing() {
        XCTAssertEqual(
            VisualQAPreviewMode.tutorialStartBeat(environment: ["MEGRUM_VISUAL_QA_TUTORIAL_STEP": "6-10"])?.id,
            "6-10"
        )
        XCTAssertEqual(
            VisualQAPreviewMode.tutorialStartBeat(environment: ["MEGRUM_VISUAL_QA_TUTORIAL_STEP": "0"])?.id,
            "1-1"
        )
        XCTAssertNil(VisualQAPreviewMode.tutorialStartBeat(environment: [:]))
        XCTAssertNil(VisualQAPreviewMode.tutorialStartBeat(environment: ["MEGRUM_VISUAL_QA_TUTORIAL_STEP": "unknown"]))
    }
}
