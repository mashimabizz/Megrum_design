import Foundation

/// グッズ種別選択の「最近使った」履歴（最大5件、最近順）。UserDefaults に UUID をカンマ区切りで保存する。iter1226.385 / FB8-8。
enum GoodsTypeRecentSelection {
    static let storageKey = "megrum.goodsType.recentIDs.v1"
    static let limit = 5

    /// 保存文字列（"uuid,uuid,..."）から最近順のID配列へ。
    static func recentIDs(from raw: String) -> [UUID] {
        raw.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
    }

    /// 指定IDを先頭に入れ、重複を除き、上限まで詰めた保存文字列を返す。
    static func updatedRaw(recording id: UUID, into raw: String) -> String {
        var ids = recentIDs(from: raw).filter { $0 != id }
        ids.insert(id, at: 0)
        return ids.prefix(limit).map(\.uuidString).joined(separator: ",")
    }
}
