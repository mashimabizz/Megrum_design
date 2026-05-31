@testable import MegrumApp
import MegrumCore
import XCTest

final class OwnProfileScreenTests: XCTestCase {
    func testProfileDraftNormalizesEditableFields() {
        let draft = OwnProfileEditDraft(
            handle: " @Michi_Lion ",
            displayName: " みちりおん ",
            prefecture: " 東京都 ",
            gender: .noAnswer
        )

        let normalized = draft.normalized

        XCTAssertEqual(normalized.handle, "michi_lion")
        XCTAssertEqual(normalized.displayName, "みちりおん")
        XCTAssertEqual(normalized.prefecture, "東京都")
        XCTAssertEqual(normalized.gender, .noAnswer)
        XCTAssertNil(normalized.validationError)
    }

    func testProfileDraftHoldsLocalAvatarUpload() {
        var draft = OwnProfileEditDraft(
            handle: "michi",
            displayName: "みち",
            prefecture: "東京都",
            gender: nil,
            existingAvatarURL: URL(string: "https://example.com/current.jpg")
        )
        let upload = GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")

        draft.setLocalAvatarUpload(upload)
        let normalized = draft.normalized

        XCTAssertTrue(normalized.hasLocalAvatarUpload)
        XCTAssertEqual(normalized.avatarUpload?.data, upload.data)
        XCTAssertEqual(normalized.avatarUpload?.contentType, "image/jpeg")
        XCTAssertFalse(normalized.clearsAvatar)
        XCTAssertNil(normalized.visibleAvatarURL)
    }

    func testProfileDraftCanDeleteAvatar() {
        var draft = OwnProfileEditDraft(
            handle: "michi",
            displayName: "みち",
            prefecture: "東京都",
            gender: nil,
            existingAvatarURL: URL(string: "https://example.com/current.jpg")
        )

        draft.deleteAvatar()

        XCTAssertTrue(draft.clearsAvatar)
        XCTAssertNil(draft.avatarUpload)
        XCTAssertNil(draft.visibleAvatarURL)
        XCTAssertFalse(draft.hasVisibleAvatar)
    }

    func testProfileAvatarUploadRejectsOversizedImage() {
        let upload = GoodsPhotoUpload(
            data: Data(repeating: 0, count: goodsEditorMaxPhotoUploadBytes + 1),
            contentType: "image/jpeg"
        )

        XCTAssertEqual(ownProfileAvatarUploadError(for: upload), "アイコン画像は10MB以下にしてください")
    }

    func testPreviewRepositoryChangesAvatarURLAfterProfileUpload() async throws {
        let repository = PreviewMegrumRepository()

        let saved = try await repository.updateOwnProfile(
            OwnProfileUpdateInput(
                handle: "michi",
                displayName: "みち",
                avatarURL: URL(string: "https://preview.megrum.jp/current-avatar.jpg"),
                avatarUpload: GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")
            )
        )

        XCTAssertEqual(saved.avatarURL?.absoluteString, "https://preview.megrum.jp/profile-photo.jpg")
    }

    func testPreviewRepositoryClearsAvatarURL() async throws {
        let repository = PreviewMegrumRepository()

        let saved = try await repository.updateOwnProfile(
            OwnProfileUpdateInput(
                handle: "michi",
                displayName: "みち",
                avatarURL: URL(string: "https://preview.megrum.jp/current-avatar.jpg"),
                clearsAvatar: true
            )
        )

        XCTAssertNil(saved.avatarURL)
    }

    func testProfileDraftValidationMatchesRNParityFields() {
        XCTAssertEqual(
            OwnProfileEditDraft(handle: "mi", displayName: "みち", prefecture: "東京都", gender: nil).validationError,
            "ユーザーIDは半角英数字・_ の3〜20文字で入力してください"
        )
        XCTAssertEqual(
            OwnProfileEditDraft(
                handle: "michi",
                displayName: String(repeating: "あ", count: 51),
                prefecture: "東京都",
                gender: nil
            ).validationError,
            "表示名は1〜50文字で入力してください"
        )
        XCTAssertEqual(
            OwnProfileEditDraft(handle: "michi", displayName: "みち", prefecture: "東京", gender: nil).validationError,
            "活動エリアは都道府県から選択してください"
        )
    }

    func testSummaryUsesLocalProfileDraftForExpandedFields() {
        let viewer = UserProfile(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            handle: "old_handle",
            displayName: "古い表示名",
            prefecture: "千葉県"
        )
        let localDraft = OwnProfileEditDraft(
            handle: "new_handle",
            displayName: "新しい表示名",
            prefecture: "東京都",
            gender: .female
        )

        let summary = OwnProfileSummary(
            viewer: viewer,
            inventoryCount: 2,
            wishCount: 3,
            proposals: [],
            localDraft: localDraft
        )

        XCTAssertEqual(summary?.handleText, "@new_handle")
        XCTAssertEqual(summary?.displayName, "新しい表示名")
        XCTAssertEqual(summary?.prefectureText, "東京都")
        XCTAssertEqual(summary?.genderText, "女性")
    }

    func testSummaryAllowsLocalDraftToClearPrefecture() {
        let viewer = UserProfile(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            handle: "michi",
            displayName: "みち",
            prefecture: "千葉県"
        )
        let localDraft = OwnProfileEditDraft(
            handle: "michi",
            displayName: "みち",
            prefecture: "",
            gender: nil
        )

        let summary = OwnProfileSummary(
            viewer: viewer,
            inventoryCount: 0,
            wishCount: 0,
            proposals: [],
            localDraft: localDraft
        )

        XCTAssertEqual(summary?.prefectureText, "未設定")
        XCTAssertEqual(summary?.genderText, "未設定")
    }
}
