import Foundation
import MegrumCore
import MegrumData
import XCTest
@testable import MegrumApp

/// iter1226.423：再打診・評価の「黙って失敗して詰まる」の回帰防止。
final class TradeSubmitErrorRecoveryTests: XCTestCase {
    @MainActor
    func testReviseErrorMessageExplainsMeetupRequirement() {
        let constraint = SupabaseRESTError.serverRejected(
            status: 400,
            message: "new row for relation \"proposals\" violates check constraint \"proposals_meetup_required\""
        )
        XCTAssertTrue(
            MegrumAppState.proposalReviseErrorMessage(from: constraint).contains("待ち合わせ")
        )

        let other = SupabaseRESTError.serverRejected(status: 400, message: "some other failure")
        XCTAssertTrue(MegrumAppState.proposalReviseErrorMessage(from: other).contains("some other failure"))

        XCTAssertEqual(
            MegrumAppState.proposalReviseErrorMessage(from: URLError(.timedOut)),
            "打診を更新できませんでした"
        )
    }

    @MainActor
    func testEvaluationErrorMessageExplainsStatusAndServerDetail() {
        XCTAssertTrue(
            MegrumAppState.tradeEvaluationErrorMessage(from: SupabaseProposalClientError.invalidStatus)
                .contains("取引完了後")
        )
        XCTAssertTrue(
            MegrumAppState.tradeEvaluationErrorMessage(
                from: SupabaseRESTError.serverRejected(status: 500, message: "boom")
            ).contains("boom")
        )
        XCTAssertEqual(
            MegrumAppState.tradeEvaluationErrorMessage(from: URLError(.timedOut)),
            "評価を送信できませんでした"
        )
    }

    func testInitialMeetupApplicationClaimsOnlyOnce() {
        var flags = ProposalCreateInitialStateFlags()

        XCTAssertTrue(flags.claimInitialMeetupApplication())
        XCTAssertFalse(flags.claimInitialMeetupApplication())
    }

    /// 署名URLの差し替えだけでは「変更あり」と判定しない（ホームのサムネ再読込防止）。
    @MainActor
    func testHomeNearbyBoardContentComparisonIgnoresSignedURLs() {
        let id = UUID()
        let base = BoardThread(
            id: id,
            authorID: UUID(),
            title: "物販列",
            body: "本文",
            audience: .nearby3km,
            imageURLs: [URL(string: "https://example.com/img.png?token=aaa")!],
            imagePaths: ["boards/img.png"],
            seriesName: "2026 LIVE",
            createdAt: Date(timeIntervalSince1970: 1_780_000_000),
            latestActivityAt: Date(timeIntervalSince1970: 1_780_000_100),
            replyCount: 3
        )
        var refreshed = base
        refreshed.imageURLs = [URL(string: "https://example.com/img.png?token=bbb")!]

        XCTAssertTrue(MegrumAppState.homeNearbyBoardContentEquals([base], [refreshed]))

        var changed = refreshed
        changed.replyCount = 4
        XCTAssertFalse(MegrumAppState.homeNearbyBoardContentEquals([base], [changed]))
        XCTAssertFalse(MegrumAppState.homeNearbyBoardContentEquals([base], []))
    }
}
