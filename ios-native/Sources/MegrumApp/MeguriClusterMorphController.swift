import Foundation
import SwiftUI

/// クラスタの統合/分解モーフ（寄って1つになる・散らばる）を管理する共通コントローラ。
/// めぐりホーム地図と同じ演出をグルームアーカイブ等の他の地図でも再利用するための抽出。
/// - 統合: 統合される側のマーカーが統合先の中間地点へ動きながら薄くなり、最後にクラスタが出る。
/// - 分解: 分解後のマーカーがクラスタ位置に現れて、それぞれの位置へ散らばる。
@Observable
@MainActor
final class MeguriClusterMorphController {
    private(set) var displayedElements: [MeguriMapClusterBuilder.DisplayedElement] = []
    private var morphToken = UUID()

    func apply(_ next: [MeguriMapClusterBuilder.Element]) {
        guard next.map(\.id) != displayedElements.map(\.id) else {
            return
        }
        let token = UUID()
        morphToken = token
        guard !displayedElements.isEmpty else {
            displayedElements = next.map { MeguriMapClusterBuilder.DisplayedElement(element: $0, popsIn: true) }
            return
        }

        let previous = displayedElements

        // フェーズ1: これから統合される既存マーカーを、統合先の中間地点へ動かす。
        var gathering = previous
        var hasGatheringMove = false
        for target in next {
            guard case .cluster(let cluster) = target else {
                continue
            }
            let targetMemberIDs = Set(cluster.items.map(\.id))
            for index in gathering.indices where gathering[index].element.id != target.id {
                let memberIDs = Set(gathering[index].element.memberIDs)
                if !memberIDs.isEmpty, memberIDs.isSubset(of: targetMemberIDs) {
                    gathering[index].latitude = cluster.latitude
                    gathering[index].longitude = cluster.longitude
                    gathering[index].opacity = 0.10
                    hasGatheringMove = true
                }
            }
        }

        let commitFinal = { [weak self] in
            guard let self, self.morphToken == token else {
                return
            }
            // フェーズ2: 分解されたマーカーは元クラスタの位置に出して、
            // それぞれの位置へ散らばらせる。
            let previousByID = previous
            var start: [MeguriMapClusterBuilder.DisplayedElement] = []
            var needsScatter = false
            for element in next {
                let memberIDs = Set(element.memberIDs)
                if let parent = previousByID.first(where: { candidate in
                    candidate.element.id != element.id
                        && memberIDs.isSubset(of: Set(candidate.element.memberIDs))
                }) {
                    var displayed = MeguriMapClusterBuilder.DisplayedElement(element: element, popsIn: false)
                    displayed.latitude = parent.latitude
                    displayed.longitude = parent.longitude
                    start.append(displayed)
                    needsScatter = true
                } else {
                    let existed = previousByID.contains { $0.element.id == element.id }
                    let mergedHere = previousByID.contains { candidate in
                        candidate.element.id != element.id
                            && Set(candidate.element.memberIDs).isSubset(of: memberIDs)
                    }
                    start.append(
                        MeguriMapClusterBuilder.DisplayedElement(
                            element: element,
                            popsIn: !existed || Self.isMergeCluster(element, mergedHere: mergedHere)
                        )
                    )
                }
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.displayedElements = start
            }
            if needsScatter {
                Task { @MainActor in
                    await Task.yield()
                    guard self.morphToken == token else {
                        return
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        self.displayedElements = self.displayedElements.map { displayed in
                            var next = displayed
                            next.latitude = displayed.element.displayLatitude
                            next.longitude = displayed.element.displayLongitude
                            return next
                        }
                    }
                }
            }
        }

        if hasGatheringMove {
            withAnimation(.easeInOut(duration: 0.30)) {
                displayedElements = gathering
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 330_000_000)
                commitFinal()
            }
        } else {
            commitFinal()
        }
    }

    private static func isMergeCluster(_ element: MeguriMapClusterBuilder.Element, mergedHere: Bool) -> Bool {
        if case .cluster = element {
            return mergedHere
        }
        return false
    }
}
