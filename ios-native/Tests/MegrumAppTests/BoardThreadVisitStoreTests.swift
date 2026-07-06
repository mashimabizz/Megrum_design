import Foundation
import Testing
@testable import MegrumApp

@Suite("BoardThreadVisitStore")
struct BoardThreadVisitStoreTests {
    @Test("訪問時刻はユーザー・スレッドごとに保存され読み戻せる")
    func roundTrip() {
        let defaults = UserDefaults(suiteName: "BoardThreadVisitStoreTests")!
        defaults.removePersistentDomain(forName: "BoardThreadVisitStoreTests")
        let viewerID = UUID()
        let threadID = UUID()
        let visitedAt = Date(timeIntervalSince1970: 1_750_000_000)

        BoardThreadVisitStore.recordVisit(
            threadID: threadID,
            viewerID: viewerID,
            at: visitedAt,
            defaults: defaults
        )

        let stored = BoardThreadVisitStore.visitedAt(
            threadID: threadID,
            viewerID: viewerID,
            defaults: defaults
        )
        #expect(stored.map { abs($0.timeIntervalSince(visitedAt)) < 1 } == true)
        #expect(BoardThreadVisitStore.visitedAt(threadID: UUID(), viewerID: viewerID, defaults: defaults) == nil)
        #expect(BoardThreadVisitStore.visitedAt(threadID: threadID, viewerID: UUID(), defaults: defaults) == nil)
    }

    @Test("記録が上限を超えたら古い訪問から間引かれる")
    func prunesOldEntries() {
        let defaults = UserDefaults(suiteName: "BoardThreadVisitStoreTests.prune")!
        defaults.removePersistentDomain(forName: "BoardThreadVisitStoreTests.prune")
        let viewerID = UUID()
        let oldThreadID = UUID()
        BoardThreadVisitStore.recordVisit(
            threadID: oldThreadID,
            viewerID: viewerID,
            at: Date(timeIntervalSince1970: 1),
            defaults: defaults
        )
        for index in 0..<200 {
            BoardThreadVisitStore.recordVisit(
                threadID: UUID(),
                viewerID: viewerID,
                at: Date(timeIntervalSince1970: TimeInterval(1000 + index)),
                defaults: defaults
            )
        }
        #expect(BoardThreadVisitStore.visitedAt(threadID: oldThreadID, viewerID: viewerID, defaults: defaults) == nil)
    }
}
