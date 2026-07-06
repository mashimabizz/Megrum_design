import Foundation
import MegrumCore
import Testing
@testable import MegrumApp

@Suite("UserProfileFieldMerging")
struct UserProfileFieldMergingTests {
    private let birthDate = Calendar(identifier: .gregorian)
        .date(from: DateComponents(year: 1998, month: 12, day: 25))!

    private func existingViewer() -> UserProfile {
        UserProfile(
            id: UUID(),
            handle: "michitaka",
            displayName: "みちたか",
            bio: "よろしくお願いします",
            birthDate: birthDate,
            age: 27,
            paymentMethods: [.paypay]
        )
    }

    @Test("部分selectで欠けた生年月日・年齢・自己紹介は既存viewerから補完される")
    func fillsMissingFields() {
        let existing = existingViewer()
        // 支払い保存の返却相当：birth_date / bio を含まないプロフィール
        let partial = UserProfile(
            id: existing.id,
            handle: existing.handle,
            displayName: existing.displayName,
            paymentMethods: [.cashExchange]
        )

        let merged = partial.fillingMissingProfileFields(from: existing)

        #expect(merged.birthDate == birthDate)
        #expect(merged.age == 27)
        #expect(merged.bio == "よろしくお願いします")
        #expect(merged.paymentMethods == [.cashExchange])
    }

    @Test("返却側に値があればそちらを優先する")
    func prefersReturnedValues() {
        let existing = existingViewer()
        let newBirthDate = Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: 2000, month: 1, day: 2))!
        let returned = UserProfile(
            id: existing.id,
            handle: existing.handle,
            displayName: existing.displayName,
            bio: "更新後の自己紹介",
            birthDate: newBirthDate,
            age: 26
        )

        let merged = returned.fillingMissingProfileFields(from: existing)

        #expect(merged.birthDate == newBirthDate)
        #expect(merged.age == 26)
        #expect(merged.bio == "更新後の自己紹介")
    }
}
