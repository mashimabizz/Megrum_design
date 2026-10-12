import Foundation
import MegrumCore

/// めぐりメッセージ（テキストのやりとり）の端末側キャッシュ（iter1226.462）。
///
/// テキストのやりとりはアプリ側で保持し、アプリを開き直しても即座に表示できるようにする
/// （ネットワーク再取得は裏で走り、届き次第置き換わる）。ユーザーごとにJSONで保存する。
/// 画像はポリシー（`MeguriMessageMediaPolicy`＝14日）で期限切れ→サーバー削除されるため、
/// キャッシュにURLが残っていても表示時に日付でプレースホルダへ差し替えられる。
enum MeguriMessageLocalStore {
    private static func fileURL(for viewerID: UUID) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("MegrumMeguriMessages", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("messages-\(viewerID.uuidString.lowercased()).json")
    }

    static func load(viewerID: UUID) -> [MeguriMessage] {
        guard let url = try? fileURL(for: viewerID),
              let data = try? Data(contentsOf: url)
        else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MeguriMessage].self, from: data)) ?? []
    }

    static func save(_ messages: [MeguriMessage], viewerID: UUID) {
        guard let url = try? fileURL(for: viewerID) else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(messages) else {
            return
        }
        #if os(iOS)
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try? data.write(to: url, options: [.atomic])
        #endif
    }
}
