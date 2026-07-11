import MegrumCore
import XCTest

final class MeguriMessageMediaPolicyTests: XCTestCase {
    func testImageIsNotExpiredBeforeFourteenDays() {
        let sentAt = Date(timeIntervalSince1970: 0)
        let justBefore = sentAt.addingTimeInterval(MeguriMessageMediaPolicy.imageRetentionInterval - 1)

        XCTAssertFalse(MeguriMessageMediaPolicy.isImageExpired(sentAt: sentAt, now: justBefore))
    }

    func testImageExpiresAtExactlyFourteenDays() {
        let sentAt = Date(timeIntervalSince1970: 0)
        let atBoundary = sentAt.addingTimeInterval(MeguriMessageMediaPolicy.imageRetentionInterval)

        XCTAssertTrue(MeguriMessageMediaPolicy.isImageExpired(sentAt: sentAt, now: atBoundary))
    }

    func testImageExpiresAfterFourteenDays() {
        let sentAt = Date(timeIntervalSince1970: 0)
        let wellAfter = sentAt.addingTimeInterval(MeguriMessageMediaPolicy.imageRetentionInterval * 3)

        XCTAssertTrue(MeguriMessageMediaPolicy.isImageExpired(sentAt: sentAt, now: wellAfter))
    }

    func testRetentionIsFourteenDays() {
        XCTAssertEqual(MeguriMessageMediaPolicy.imageRetentionDays, 14)
        XCTAssertEqual(MeguriMessageMediaPolicy.imageRetentionInterval, 14 * 24 * 60 * 60, accuracy: 0.001)
    }
}
