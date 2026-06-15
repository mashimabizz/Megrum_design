@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabasePaymentSettingsPersistenceTests: XCTestCase {
    func testReturnedSettingsPreservesNormalizedMethodsFromSummaryUpdate() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000701")!
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_100)
        let stored = UserPaymentSettings(
            userID: userID,
            methods: [],
            bankName: "みずほ銀行",
            bankBranchName: "渋谷支店",
            bankAccountType: "普通",
            bankAccountNumber: "1234567",
            bankAccountHolder: "ヤマダ ハナコ",
            otherNote: "メルペイ相談可",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let normalized = UserPaymentSettings(
            userID: userID,
            methods: [.paypay, .bankTransfer],
            otherNote: "メルペイ相談可"
        )

        let returned = SupabasePaymentSettingsPersistence.returnedSettings(
            storedSettings: stored,
            normalizedSettings: normalized
        )

        XCTAssertEqual(returned.userID, userID)
        XCTAssertEqual(returned.methods, [.bankTransfer, .paypay])
        XCTAssertEqual(returned.bankName, "みずほ銀行")
        XCTAssertEqual(returned.bankBranchName, "渋谷支店")
        XCTAssertEqual(returned.bankAccountType, "普通")
        XCTAssertEqual(returned.bankAccountNumber, "1234567")
        XCTAssertEqual(returned.bankAccountHolder, "ヤマダ ハナコ")
        XCTAssertEqual(returned.otherNote, "メルペイ相談可")
        XCTAssertEqual(returned.createdAt, createdAt)
        XCTAssertEqual(returned.updatedAt, updatedAt)
    }

    func testFallbackProfileReflectsNormalizedPaymentSummary() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000702")!
        let normalized = UserPaymentSettings(
            userID: userID,
            methods: [.other, .cashExchange],
            otherNote: "楽天ペイも相談可"
        )

        let profile = SupabasePaymentSettingsPersistence.fallbackProfile(
            userID: userID,
            normalizedSettings: normalized
        )

        XCTAssertEqual(profile.id, userID)
        XCTAssertEqual(profile.handle, "unknown")
        XCTAssertEqual(profile.displayName, "Megrum")
        XCTAssertEqual(profile.paymentMethods, [.cashExchange, .other])
        XCTAssertEqual(profile.paymentNote, "楽天ペイも相談可")
        XCTAssertEqual(profile.accountStatus, .active)
    }
}
