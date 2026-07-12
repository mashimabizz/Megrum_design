import Foundation
import Testing
@testable import MegrumCore

@Suite("NetworkErrorClassifier")
struct NetworkErrorClassifierTests {
    @Test("オフライン系のURLErrorは通信エラーと判定")
    func connectivityErrors() {
        #expect(NetworkErrorClassifier.isConnectivityError(URLError(.notConnectedToInternet)))
        #expect(NetworkErrorClassifier.isConnectivityError(URLError(.networkConnectionLost)))
        #expect(NetworkErrorClassifier.isConnectivityError(URLError(.timedOut)))
        #expect(NetworkErrorClassifier.isConnectivityError(URLError(.cannotConnectToHost)))
        #expect(NetworkErrorClassifier.isConnectivityError(URLError(.dataNotAllowed)))
    }

    @Test("サーバー応答不正やデコード失敗など到達性以外は通信エラーとしない")
    func nonConnectivityErrors() {
        // badServerResponse は NSURLErrorDomain だが到達性コードではない。
        #expect(!NetworkErrorClassifier.isConnectivityError(URLError(.badServerResponse)))
        struct Dummy: Error {}
        #expect(!NetworkErrorClassifier.isConnectivityError(Dummy()))
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "x"))
        #expect(!NetworkErrorClassifier.isConnectivityError(decodingError))
    }
}
