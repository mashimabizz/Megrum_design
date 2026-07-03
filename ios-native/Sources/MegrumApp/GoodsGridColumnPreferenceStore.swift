import Foundation
import MegrumCore

struct GoodsGridColumnPreferenceContext: Equatable {
    var entryKind: GoodsEntryKind
    var viewerID: UUID?
}

enum GoodsGridColumnPreferenceStore {
    private static let keyPrefix = "megrum.goodsGrid.columns"
    private static let anonymousViewerKey = "anonymous"

    static func load(
        context: GoodsGridColumnPreferenceContext,
        defaults: UserDefaults = .standard
    ) -> Int {
        let key = storageKey(context: context)
        guard defaults.object(forKey: key) != nil else {
            return GoodsGridLayout.minimumColumns
        }

        return GoodsGridLayout(columns: defaults.integer(forKey: key)).columns
    }

    static func save(
        columns: Int,
        context: GoodsGridColumnPreferenceContext,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(
            GoodsGridLayout(columns: columns).columns,
            forKey: storageKey(context: context)
        )
    }

    static func storageKey(context: GoodsGridColumnPreferenceContext) -> String {
        let viewerKey = context.viewerID?.uuidString.lowercased() ?? anonymousViewerKey
        return "\(keyPrefix).\(context.entryKind.rawValue).\(viewerKey)"
    }
}
