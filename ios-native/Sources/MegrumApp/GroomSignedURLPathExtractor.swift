import Foundation

/// めぐりメッセージ等に保存された「署名付きURL」から、バケット内のストレージパスを
/// 取り出す。保存された署名URLは約1時間で失効するため、表示時にパスから
/// 署名し直すために使う（iter1226.342）。
enum GroomSignedURLPathExtractor {
    /// 例: https://.../storage/v1/object/sign/groom-posts/<uid>/<file>.jpg?token=...
    ///     → "<uid>/<file>.jpg"
    static func storagePath(from url: URL, bucket: String = "groom-posts") -> String? {
        let components = url.path.split(separator: "/").map(String.init)
        guard let bucketIndex = components.firstIndex(of: bucket),
              bucketIndex + 1 < components.count
        else {
            return nil
        }
        let path = components[(bucketIndex + 1)...].joined(separator: "/")
        return path.isEmpty ? nil : path
    }
}
