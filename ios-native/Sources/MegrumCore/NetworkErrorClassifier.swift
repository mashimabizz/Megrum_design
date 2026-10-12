import Foundation

/// ネットワーク到達性に起因するエラーかどうかを判定する（iter1226.465）。
///
/// オフラインや電波が弱い状況では `URLSession` が `URLError`（`NSURLErrorDomain`）を投げる。
/// これを「通信状態が悪くデータ取得できない」ケースとして識別し、ホーム画面などで
/// その旨を表示する判断に使う。サーバー由来の 4xx/5xx（`SupabaseRESTError`）は含めない。
public enum NetworkErrorClassifier {
    /// 通信到達性の問題（オフライン・接続断・タイムアウト等）なら true。
    public static func isConnectivityError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return false
        }
        return connectivityCodes.contains(nsError.code)
    }

    /// 到達性に関わる URLError コード群（`URLError.Code.rawValue` と一致）。
    private static let connectivityCodes: Set<Int> = [
        URLError.notConnectedToInternet.rawValue,
        URLError.networkConnectionLost.rawValue,
        URLError.timedOut.rawValue,
        URLError.cannotConnectToHost.rawValue,
        URLError.cannotFindHost.rawValue,
        URLError.dnsLookupFailed.rawValue,
        URLError.dataNotAllowed.rawValue,
        URLError.internationalRoamingOff.rawValue,
        URLError.callIsActive.rawValue,
        URLError.secureConnectionFailed.rawValue
    ]
}
