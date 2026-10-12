import Foundation
import MegrumCore

/// 相手ユーザー情報（公開プロフィール・めぐりプロフィール）の端末キャッシュ（iter1226.466）。
///
/// 取引一覧（`TradesScreen`）やめぐりメッセージ一覧は、相手の表示名・アバターを
/// `publicProfilesByUserID` / `meguriProfilesByUserID` から引く。これらは画面を開いた
/// タイミングでネットワーク遅延ロードされるため、起動時のオフラインスナップショット
/// （`MegrumOfflineSnapshotStore`）だけでは取りこぼす。
///
/// そこで、セッション中に読み込まれた相手プロフィールを認証ユーザーID単位で常時保存し、
/// 次回オフライン起動時に復元する。一度でも表示した相手の情報はオフラインでも残る。
enum ProfileDirectoryLocalStore {
    struct Payload: Codable, Sendable {
        var publicProfiles: [UUID: PublicUserProfile]
        var meguriProfiles: [UUID: MeguriProfile]
    }

    private static func fileURL(for userID: UUID) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("MegrumProfileDirectory", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("profiles-\(userID.uuidString.lowercased()).json")
    }

    static func load(userID: UUID) -> Payload? {
        guard let url = try? fileURL(for: userID),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Payload.self, from: data)
    }

    static func save(_ payload: Payload, userID: UUID) {
        guard let url = try? fileURL(for: userID) else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else {
            return
        }
        #if os(iOS)
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try? data.write(to: url, options: [.atomic])
        #endif
    }

    static func clear(userID: UUID) {
        guard let url = try? fileURL(for: userID) else {
            return
        }
        try? FileManager.default.removeItem(at: url)
    }
}
