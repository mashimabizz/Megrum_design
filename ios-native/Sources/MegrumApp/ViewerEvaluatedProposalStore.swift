import Foundation

/// 自分が評価送信済みの proposal ID をローカルにも保持する。
/// サーバーからの読み込みは起動シーケンスの後半になるため、これが無いと
/// 起動直後だけ「評価待ち」が過計上され、やりとりバッジが後から減って見える。
enum ViewerEvaluatedProposalStore {
    private static func key(viewerID: UUID) -> String {
        "megrum.viewerEvaluatedProposalIDs.\(viewerID.uuidString)"
    }

    static func load(viewerID: UUID, defaults: UserDefaults = .standard) -> Set<UUID> {
        let raw = defaults.stringArray(forKey: key(viewerID: viewerID)) ?? []
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    static func save(_ ids: Set<UUID>, viewerID: UUID, defaults: UserDefaults = .standard) {
        defaults.set(ids.map(\.uuidString).sorted(), forKey: key(viewerID: viewerID))
    }
}
