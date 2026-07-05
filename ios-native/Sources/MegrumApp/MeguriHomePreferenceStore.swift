import Foundation

/// めぐりホームの表示種別（すべて/グルーム/チャットルーム）とフィルタ内容を
/// ユーザーごとに永続化する。アプリを閉じて開いても状態を維持する。
enum MeguriHomePreferenceStore {
    static func mapKindKey(userID: UUID) -> String {
        "meguri.home.mapKind.\(userID.uuidString.lowercased())"
    }

    static func filterKey(userID: UUID) -> String {
        "meguri.home.filter.\(userID.uuidString.lowercased())"
    }

    static func loadMapKind(userID: UUID, defaults: UserDefaults = .standard) -> MeguriMapKind? {
        defaults.string(forKey: mapKindKey(userID: userID)).flatMap(MeguriMapKind.init(rawValue:))
    }

    static func saveMapKind(_ kind: MeguriMapKind, userID: UUID, defaults: UserDefaults = .standard) {
        defaults.set(kind.rawValue, forKey: mapKindKey(userID: userID))
    }

    static func loadFilterDraft(userID: UUID, defaults: UserDefaults = .standard) -> MeguriContentMetadataDraft? {
        guard let data = defaults.data(forKey: filterKey(userID: userID)) else {
            return nil
        }
        return try? JSONDecoder().decode(MeguriContentMetadataDraft.self, from: data)
    }

    static func saveFilterDraft(_ draft: MeguriContentMetadataDraft, userID: UUID, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(draft) else {
            return
        }
        defaults.set(data, forKey: filterKey(userID: userID))
    }
}
