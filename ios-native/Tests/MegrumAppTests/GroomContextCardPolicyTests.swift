import Foundation
import Testing
@testable import MegrumApp

@Suite("GroomContextCardPolicy")
struct GroomContextCardPolicyTests {
    @Test("メッセージから24時間以内は失効確定ではない")
    func withinLifetime() {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let createdAt = now.addingTimeInterval(-23 * 60 * 60)
        #expect(GroomContextCardPolicy.isCertainlyExpired(messageCreatedAt: createdAt, now: now) == false)
    }

    @Test("メッセージから24時間を超えたら失効確定")
    func pastLifetime() {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let createdAt = now.addingTimeInterval(-25 * 60 * 60)
        #expect(GroomContextCardPolicy.isCertainlyExpired(messageCreatedAt: createdAt, now: now) == true)
    }
}
