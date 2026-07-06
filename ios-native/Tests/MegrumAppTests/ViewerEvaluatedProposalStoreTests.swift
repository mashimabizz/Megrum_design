import Foundation
import Testing
@testable import MegrumApp

@Suite("ViewerEvaluatedProposalStore")
struct ViewerEvaluatedProposalStoreTests {
    @Test("保存した評価済みIDはユーザーごとに読み戻せる")
    func roundTrip() {
        let defaults = UserDefaults(suiteName: "ViewerEvaluatedProposalStoreTests")!
        defaults.removePersistentDomain(forName: "ViewerEvaluatedProposalStoreTests")
        let viewerID = UUID()
        let otherViewerID = UUID()
        let ids: Set<UUID> = [UUID(), UUID()]

        ViewerEvaluatedProposalStore.save(ids, viewerID: viewerID, defaults: defaults)

        #expect(ViewerEvaluatedProposalStore.load(viewerID: viewerID, defaults: defaults) == ids)
        #expect(ViewerEvaluatedProposalStore.load(viewerID: otherViewerID, defaults: defaults).isEmpty)
    }
}
