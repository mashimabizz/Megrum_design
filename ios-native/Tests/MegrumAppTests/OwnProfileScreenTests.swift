@testable import MegrumApp
import MegrumCore
import XCTest

final class OwnProfileScreenTests: XCTestCase {
    func testOwnProfileUsesCompactHeaderMetrics() {
        XCTAssertEqual(OwnProfileLayoutMetrics.contentSpacing, 10)
        XCTAssertEqual(OwnProfileLayoutMetrics.horizontalPadding, 14)
        XCTAssertEqual(OwnProfileLayoutMetrics.topPadding, 12)
        XCTAssertEqual(OwnProfileLayoutMetrics.compactHeroAvatarSize, 70)

        XCTAssertEqual(ProfileVisualHeroDensity.compact.verticalSpacing, 9)
        XCTAssertEqual(ProfileVisualHeroDensity.compact.displayNameFontSize, 20)
        XCTAssertEqual(ProfileVisualHeroDensity.compact.handleFontSize, 13)
        XCTAssertEqual(ProfileVisualHeroDensity.compact.actionHeight, 44)
        XCTAssertEqual(ProfileVisualHeroDensity.compact.scheduleActionHeight, 38)
        XCTAssertLessThan(ProfileVisualHeroDensity.compact.actionHeight, ProfileVisualHeroDensity.regular.actionHeight)
        XCTAssertLessThan(ProfileVisualHeroDensity.compact.displayNameFontSize, ProfileVisualHeroDensity.regular.displayNameFontSize)
    }

    func testOwnProfileOshiTagsRenderL1ThenL2Separately() {
        let groupID = UUID(uuidString: "20000000-0000-0000-0000-000000000101")!
        let userID = UUID(uuidString: "20000000-0000-0000-0000-000000000102")!
        let selections = [
            UserOshiSelection(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000103")!,
                userID: userID,
                groupID: groupID,
                characterID: UUID(uuidString: "20000000-0000-0000-0000-000000000104")!,
                kind: .specific,
                priority: 1,
                groupName: "TWICE",
                characterName: "モモ"
            )
        ]

        let tags = OwnProfileOshiTagPresentation.tagItems(from: selections)

        XCTAssertEqual(tags.map(\.title), ["TWICE", "モモ"])
        XCTAssertEqual(tags[0].colorKey, tags[1].colorKey)
    }

    func testOwnProfileOshiTagsPreservePriorityAndDeduplicateL1() {
        let twiceID = UUID(uuidString: "20000000-0000-0000-0000-000000000201")!
        let iveID = UUID(uuidString: "20000000-0000-0000-0000-000000000202")!
        let userID = UUID(uuidString: "20000000-0000-0000-0000-000000000203")!
        let selections = [
            UserOshiSelection(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000204")!,
                userID: userID,
                groupID: iveID,
                characterID: UUID(uuidString: "20000000-0000-0000-0000-000000000205")!,
                kind: .specific,
                priority: 3,
                groupName: "IVE",
                characterName: "レイ"
            ),
            UserOshiSelection(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000206")!,
                userID: userID,
                groupID: twiceID,
                characterID: UUID(uuidString: "20000000-0000-0000-0000-000000000207")!,
                kind: .specific,
                priority: 1,
                groupName: "TWICE",
                characterName: "モモ"
            ),
            UserOshiSelection(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000208")!,
                userID: userID,
                groupID: twiceID,
                characterID: UUID(uuidString: "20000000-0000-0000-0000-000000000209")!,
                kind: .specific,
                priority: 2,
                groupName: "TWICE",
                characterName: "サナ"
            )
        ]

        let tags = OwnProfileOshiTagPresentation.tagItems(from: selections)

        XCTAssertEqual(tags.map(\.title), ["TWICE", "モモ", "サナ", "IVE", "レイ"])
    }

    func testOwnProfileOshiTagsShowFallbackWhenUnset() {
        let tags = OwnProfileOshiTagPresentation.tagItems(from: [])

        XCTAssertEqual(tags.map(\.title), ["推し未設定"])
    }

    func testProfileDraftNormalizesEditableFields() {
        let draft = OwnProfileEditDraft(
            handle: " @Michi_Lion ",
            displayName: " みちりおん ",
            prefecture: " 東京都 ",
            gender: .noAnswer,
            paymentMethods: [.cashExchange, .paypay, .paypay]
        )

        let normalized = draft.normalized

        XCTAssertEqual(normalized.handle, "michi_lion")
        XCTAssertEqual(normalized.displayName, "みちりおん")
        XCTAssertEqual(normalized.prefecture, "東京都")
        XCTAssertEqual(normalized.gender, .noAnswer)
        XCTAssertEqual(normalized.paymentMethods, [.paypay, .cashExchange])
        XCTAssertNil(normalized.validationError)
    }

    func testProfileDraftTogglesPaymentMethods() {
        var draft = OwnProfileEditDraft(
            handle: "michi",
            displayName: "みち",
            prefecture: "東京都",
            gender: nil,
            paymentMethods: [.bankTransfer]
        )

        draft.setPaymentMethod(.cashExchange, isSelected: true)
        draft.setPaymentMethod(.bankTransfer, isSelected: false)

        XCTAssertFalse(draft.containsPaymentMethod(.bankTransfer))
        XCTAssertTrue(draft.containsPaymentMethod(.cashExchange))
        XCTAssertEqual(draft.normalized.paymentMethods, [.cashExchange])
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
            gender: .female,
            paymentMethods: [.paypay, .cashExchange]
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
        XCTAssertEqual(summary?.paymentMethodsText, "PayPay / 現金交換")
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
