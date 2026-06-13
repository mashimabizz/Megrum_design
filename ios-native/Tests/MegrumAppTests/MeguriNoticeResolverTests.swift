@testable import MegrumApp
import XCTest

final class MeguriNoticeResolverTests: XCTestCase {
    func testLocalMessageWinsOverLocationAndAppError() {
        let notice = MeguriNoticeResolver.notice(
            localMessage: "写真を読み込めませんでした",
            locationNotice: MegrumLocationNotice(message: "現在地を許可してください", actionTitle: "許可"),
            appErrorMessage: "データを読み込めませんでした"
        )

        XCTAssertEqual(
            notice,
            MegrumLocationNotice(message: "写真を読み込めませんでした", actionTitle: nil)
        )
    }

    func testLocationNoticeWinsOverAppError() {
        let locationNotice = MegrumLocationNotice(message: "現在地を許可してください", actionTitle: "許可")

        let notice = MeguriNoticeResolver.notice(
            localMessage: nil,
            locationNotice: locationNotice,
            appErrorMessage: "データを読み込めませんでした"
        )

        XCTAssertEqual(notice, locationNotice)
    }

    func testAppErrorFallsBackWhenNoLocalOrLocationNotice() {
        let notice = MeguriNoticeResolver.notice(
            localMessage: nil,
            locationNotice: nil,
            appErrorMessage: "データを読み込めませんでした"
        )

        XCTAssertEqual(
            notice,
            MegrumLocationNotice(message: "データを読み込めませんでした", actionTitle: nil)
        )
    }

    func testNilWhenNoNoticeSourceExists() {
        let notice = MeguriNoticeResolver.notice(
            localMessage: nil,
            locationNotice: nil,
            appErrorMessage: nil
        )

        XCTAssertNil(notice)
    }
}
