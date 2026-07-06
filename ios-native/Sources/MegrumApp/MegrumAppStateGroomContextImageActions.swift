import Foundation

@MainActor
extension MegrumAppState {
    /// メッセージに保存されたグルーム画像URL（約1時間で失効する署名URL）を、
    /// 表示時に有効な署名URLへ解決し直す。解決できない場合は nil。
    public func freshGroomContextImageURL(from staleURL: URL) async -> URL? {
        guard let path = GroomSignedURLPathExtractor.storagePath(from: staleURL) else {
            // 署名URL形式でなければそのまま使える想定
            return staleURL
        }
        return await repository.freshGroomImageURL(storagePath: path)
    }
}
