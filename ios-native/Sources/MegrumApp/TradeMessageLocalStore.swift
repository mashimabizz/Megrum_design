import Foundation
import MegrumCore

/// 取引チャット（TradeMessage）の端末側キャッシュ（iter1226.463）。
///
/// めぐりメッセージ（`MeguriMessageLocalStore`）と同様に、やりとりを端末へ保存し、
/// アプリを閉じても・オフラインでも保持したメッセージを表示できるようにする。
/// proposal ごとの配列（`messagesByProposalID`）をユーザー単位で丸ごとJSON保存する。
enum TradeMessageLocalStore {
    private static func fileURL(for viewerID: UUID) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("MegrumTradeMessages", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("messages-\(viewerID.uuidString.lowercased()).json")
    }

    static func load(viewerID: UUID) -> [UUID: [TradeMessage]] {
        guard let url = try? fileURL(for: viewerID),
              let data = try? Data(contentsOf: url)
        else {
            return [:]
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([UUID: [TradeMessage]].self, from: data)) ?? [:]
    }

    static func save(_ messagesByProposalID: [UUID: [TradeMessage]], viewerID: UUID) {
        guard let url = try? fileURL(for: viewerID) else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(messagesByProposalID) else {
            return
        }
        #if os(iOS)
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try? data.write(to: url, options: [.atomic])
        #endif
    }
}
