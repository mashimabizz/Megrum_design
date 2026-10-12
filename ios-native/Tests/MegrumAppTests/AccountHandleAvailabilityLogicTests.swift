import Foundation
import MegrumCore
import MegrumData
import XCTest
@testable import MegrumApp

final class AccountHandleAvailabilityLogicTests: XCTestCase {
    func testCandidatesAppendNumericSuffixesWithoutDuplicates() {
        let candidates = AccountHandleSuggestionLogic.candidates(for: "megrum")

        XCTAssertTrue(candidates.contains("megrum1"))
        XCTAssertTrue(candidates.contains("megrum01"))
        XCTAssertTrue(candidates.contains("megrum2026"))
        XCTAssertFalse(candidates.contains("megrum"))
        XCTAssertEqual(candidates.count, Set(candidates).count)
    }

    func testCandidatesRespectMaxHandleLength() {
        let base = String(repeating: "a", count: 20)
        let candidates = AccountHandleSuggestionLogic.candidates(for: base)

        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.allSatisfy { $0.count <= AccountHandleSuggestionLogic.maxHandleLength })
    }

    func testAvailableSuggestionsFilterTakenAndLimitToThree() {
        let suggestions = AccountHandleSuggestionLogic.availableSuggestions(
            for: "megrum",
            takenLowercased: ["megrum", "megrum1", "megrum2"]
        )

        XCTAssertEqual(suggestions, ["megrum3", "megrum4", "megrum5"])
    }

    /// 打ったIDを勝手に megrum_xxxx へ差し替えない（iter1226.422 の回帰防止）。
    func testAccountSetupHandleKeepsTypedMegrumStyleHandles() {
        let userID = UUID()

        XCTAssertEqual(MegrumAppStateInputNormalizer.accountSetupHandle("megrum", userID: userID), "megrum")
        XCTAssertEqual(MegrumAppStateInputNormalizer.accountSetupHandle("megrum_fan", userID: userID), "megrum_fan")
        // 空・無効入力は従来通り自動生成IDへフォールバック（保存を止めない安全網）。
        XCTAssertEqual(
            MegrumAppStateInputNormalizer.accountSetupHandle("", userID: userID),
            MegrumAppStateInputNormalizer.generatedProfileHandle(userID: userID)
        )
    }

    @MainActor
    func testAccountSetupSaveErrorMessageMapsDuplicateHandle() {
        let duplicate = SupabaseRESTError.serverRejected(
            status: 409,
            message: "duplicate key value violates unique constraint \"users_handle_key\""
        )
        XCTAssertEqual(
            MegrumAppState.accountSetupSaveErrorMessage(from: duplicate),
            MegrumAppState.handleTakenErrorMessage
        )

        let constraint = SupabaseRESTError.serverRejected(
            status: 400,
            message: "new row for relation \"users\" violates check constraint \"users_age_range_check\""
        )
        XCTAssertTrue(
            MegrumAppState.accountSetupSaveErrorMessage(from: constraint).contains("users_age_range_check")
        )

        XCTAssertEqual(
            MegrumAppState.accountSetupSaveErrorMessage(from: URLError(.timedOut)),
            "プロフィールを保存できませんでした"
        )
    }

    /// レガシー（birth_date列なし）フォールバックは列不存在エラーの時だけ。
    /// 制約違反・重複を握りつぶすと生年月日が黙って消える（iter1226.422 の根本原因）。
    func testSchemaMismatchDetectionOnlyMatchesMissingColumnErrors() {
        XCTAssertTrue(
            SupabaseAccountProfilePersistence.isSchemaMismatchError(
                SupabaseRESTError.serverRejected(
                    status: 400,
                    message: "Could not find the 'birth_date' column of 'users' in the schema cache"
                )
            )
        )
        XCTAssertFalse(
            SupabaseAccountProfilePersistence.isSchemaMismatchError(
                SupabaseRESTError.serverRejected(
                    status: 400,
                    message: "new row for relation \"users\" violates check constraint \"users_age_range_check\""
                )
            )
        )
        XCTAssertFalse(
            SupabaseAccountProfilePersistence.isSchemaMismatchError(
                SupabaseRESTError.serverRejected(status: 409, message: "duplicate key value violates unique constraint")
            )
        )
        XCTAssertFalse(SupabaseAccountProfilePersistence.isSchemaMismatchError(URLError(.timedOut)))
    }

    func testDraftsFillingWholeGroupForUnselectedAddsGroupLevelDrafts() {
        let bts = OshiGroup(id: UUID(), name: "BTS")
        let snowMan = OshiGroup(id: UUID(), name: "Snow Man")
        let memberDraft = OnboardingOshiDraft(
            groupID: bts.id,
            groupName: bts.name,
            characterID: UUID(),
            characterName: "RM"
        )

        let filled = OnboardingOshiSelectionLogic.draftsFillingWholeGroupForUnselected(
            selectedGroups: [bts, snowMan],
            currentDrafts: [memberDraft]
        )

        XCTAssertEqual(filled.count, 2)
        let snowManDrafts = filled.filter { $0.groupID == snowMan.id }
        XCTAssertEqual(snowManDrafts.count, 1)
        XCTAssertNil(snowManDrafts.first?.characterID)
        // 既にメンバー選択があるグループには全体ドラフトを足さない。
        let btsDrafts = filled.filter { $0.groupID == bts.id }
        XCTAssertEqual(btsDrafts.count, 1)
    }
}
