@testable import MegrumApp
import CoreGraphics
import Foundation
import ImageIO
import MegrumCore
import UniformTypeIdentifiers
import XCTest

final class GoodsEditorDraftTests: XCTestCase {
    func testGoodsEditorPresentationTextPreservesExistingCopy() {
        XCTAssertEqual(
            GoodsEditorPresentationText.navigationTitle(mode: .create, entryKind: .inventory),
            "マイグッズに追加"
        )
        XCTAssertEqual(
            GoodsEditorPresentationText.navigationTitle(mode: .create, entryKind: .wish),
            "ほしいものを追加"
        )
        XCTAssertEqual(
            GoodsEditorPresentationText.navigationTitle(mode: .edit, entryKind: .wish),
            "ほしいものを編集"
        )
        XCTAssertEqual(GoodsEditorMode.edit.badgeTitle, "更新")
        XCTAssertEqual(
            GoodsEditorPresentationText.headerDescription(usesInventoryCreateFlow: true, entryKind: .inventory),
            "推し・種別、写真、写真ごとの詳細の順に登録できます。"
        )
        XCTAssertEqual(
            GoodsEditorPresentationText.saveButtonTitle(
                mode: .edit,
                entryKind: .inventory,
                isMutatingCurrentItem: true,
                isCreatingGoodsEntry: false
            ),
            "更新しています"
        )
        XCTAssertEqual(
            GoodsEditorPresentationText.saveButtonTitle(
                mode: .create,
                entryKind: .wish,
                isMutatingCurrentItem: false,
                isCreatingGoodsEntry: false
            ),
            "ほしいものを登録"
        )
        XCTAssertEqual(
            GoodsEditorPresentationText.photoActionTitle(entryKind: .inventory, hasDisplayPhoto: true),
            "撮り直す / 差し替え"
        )
        XCTAssertEqual(GoodsEditorPresentationText.wishImageHint(hasDisplayPhoto: false), "任意")
    }

    func testGoodsEditorTagSuggestionBuilderRanksHistoryAndExcludesSelectedTags() {
        let groupID = UUID()
        let otherGroupID = UUID()
        let ownerID = UUID()
        let inventory = [
            makeGoodsItem(ownerID: ownerID, groupID: groupID, tagNames: ["LIVE", "zeta"]),
            makeGoodsItem(ownerID: ownerID, groupID: otherGroupID, tagNames: ["otherOnly"])
        ]
        let wishes = [
            makeWishItem(ownerID: ownerID, groupID: groupID, tagNames: ["LIVE", "alpha"])
        ]

        let suggestions = GoodsEditorTagSuggestionBuilder.suggestions(
            groupID: groupID,
            selectedTags: ["live"],
            inventory: inventory,
            wishes: wishes,
            limit: 4
        )

        // ①同グループ頻度順 → ②他グループ含む自分の使用タグ → ③定番（iter1226.413で3層化）。
        XCTAssertEqual(Array(suggestions.prefix(2)), ["alpha", "zeta"])
        XCTAssertFalse(suggestions.contains("LIVE"))
        XCTAssertEqual(suggestions[2], "otherOnly")
        XCTAssertEqual(suggestions.count, 4)
    }

    func testGoodsEditorTagSuggestionBuilderReturnsOwnUsageWithoutGroup() {
        let ownerID = UUID()
        let inventory = [
            makeGoodsItem(ownerID: ownerID, groupID: UUID(), tagNames: ["会場ガチャ"])
        ]

        // グループ未選択でも自分の使用タグ＋定番を返す（従来は空だった）。
        let suggestions = GoodsEditorTagSuggestionBuilder.suggestions(
            groupID: nil,
            selectedTags: [],
            inventory: inventory,
            wishes: [],
            limit: 3
        )

        XCTAssertEqual(suggestions, ["会場ガチャ", "会場限定", "未開封"])
    }

    func testGoodsEditorTagSuggestionBuilderUsesFallbackOrderWhenHistoryIsEmpty() {
        let suggestions = GoodsEditorTagSuggestionBuilder.suggestions(
            groupID: UUID(),
            selectedTags: ["会場限定"],
            inventory: [],
            wishes: [],
            limit: 3
        )

        XCTAssertEqual(suggestions, ["未開封", "トレカ", "ラキドロ"])
    }

    func testGoodsBulkTagSheetStateTrimsDraftAndTracksApplyAvailability() {
        var state = GoodsBulkTagSheetState()

        XCTAssertFalse(state.canApply)

        state.tagDraft = "  会場限定  \n"

        XCTAssertEqual(state.trimmedTag, "会場限定")
        XCTAssertTrue(state.canApply)
    }

    func testGoodsBulkTagSheetStateFiltersCandidatesIncrementally() {
        var state = GoodsBulkTagSheetState()
        let candidates = ["会場限定", "ラキドロ", "Ready to be 会場ガチャ"]

        XCTAssertEqual(state.filteredCandidates(from: candidates), candidates)

        state.tagDraft = "会場"
        XCTAssertEqual(state.filteredCandidates(from: candidates), ["会場限定", "Ready to be 会場ガチャ"])

        // 全滅時は全候補に戻す（選び直しやすさ優先）。
        state.tagDraft = "存在しない名前"
        XCTAssertEqual(state.filteredCandidates(from: candidates), candidates)
    }

    func testGoodsBulkTagSheetStateShowsNewSeriesRowOnlyWhenNoExactMatch() {
        var state = GoodsBulkTagSheetState()
        let candidates = ["会場限定", "ラキドロ"]

        XCTAssertFalse(state.showsNewSeriesRow(in: candidates))

        state.tagDraft = "会場限定"
        XCTAssertFalse(state.showsNewSeriesRow(in: candidates))

        state.tagDraft = "会場限定 A賞"
        XCTAssertTrue(state.showsNewSeriesRow(in: candidates))
    }

    func testGoodsBulkTagSheetStateTogglesCandidateIntoDraft() {
        var state = GoodsBulkTagSheetState()

        state.toggleCandidateTag("ラキドロ")

        XCTAssertEqual(state.selectedCandidateNames, ["ラキドロ"])
        XCTAssertEqual(state.tagDraft, "ラキドロ")

        state.toggleCandidateTag("ラキドロ")

        XCTAssertTrue(state.selectedCandidateNames.isEmpty)
        XCTAssertEqual(state.tagDraft, "")
    }

    func testGoodsBulkTagSheetStateKeepsEditedDraftWhenCandidateIsCleared() {
        var state = GoodsBulkTagSheetState()

        state.toggleCandidateTag("会場限定")
        state.tagDraft = "会場限定 A賞"
        state.toggleCandidateTag("会場限定")

        XCTAssertTrue(state.selectedCandidateNames.isEmpty)
        XCTAssertEqual(state.tagDraft, "会場限定 A賞")
    }

    func testGoogleLensSearchURLBuilderEncodesImageURL() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://storage.example.com/goods photos/a+b.jpg?token=abc 123"))

        let url = try XCTUnwrap(GoogleLensSearchURLBuilder.url(forImageURL: imageURL))

        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "lens.google.com")
        XCTAssertEqual(url.path, "/uploadbyurl")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "url" })?.value, imageURL.absoluteString)
    }

    func testGoodsGoogleLensSearchItemFactoryBuildsItemsFromSelectedPhotos() {
        let groupID = UUID()
        let memberID = UUID()
        let photoID = UUID()
        let upload = GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")
        let metas = [
            GoodsCreateMetaDraft(
                id: UUID(),
                photoID: photoID,
                memberID: memberID,
                title: "",
                tagNames: ["会場限定"]
            ),
            GoodsCreateMetaDraft(id: UUID(), photoID: nil, title: "画像なし")
        ]
        let items = GoodsGoogleLensSearchItemFactory.items(
            metas: metas,
            photos: [GoodsCreatePhotoDraft(id: photoID, upload: upload)],
            groupName: "TWICE",
            members: [OshiCharacter(id: memberID, groupID: groupID, name: "SANA")],
            goodsTypeName: "トレカ"
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "SANA TWICE トレカ")
        XCTAssertEqual(items[0].detailText, "SANA ・ トレカ ・ 会場限定")
        XCTAssertEqual(items[0].source, .upload(upload))
    }

    func testTagCandidatePreviewSelectionStateTracksPreviewAndSelectionLimit() {
        var state = TagCandidatePreviewSelectionState()

        XCTAssertFalse(state.isPreviewing("会場限定"))
        XCTAssertTrue(state.isSelected("live", selectedNames: ["LIVE"]))
        XCTAssertTrue(state.isDisabled("未選択", selectedNames: ["会場限定"], maxSelection: 1))
        XCTAssertFalse(state.isDisabled("会場限定", selectedNames: ["会場限定"], maxSelection: 1))

        state.preview("会場限定")
        XCTAssertTrue(state.isPreviewing("会場限定"))

        state.clearPreview(ifMatches: "別シリーズ")
        XCTAssertTrue(state.isPreviewing("会場限定"))

        state.clearPreview(ifMatches: "会場限定")
        XCTAssertFalse(state.isPreviewing("会場限定"))
    }

    func testGoodsReportDraftStateKeepsReasonAndRawNoteForSubmission() {
        var state = GoodsReportDraftState()

        XCTAssertEqual(state.reason, .fakeItem)

        state.reason = .privacy
        state.note = "  写り込みがあります  "

        XCTAssertEqual(state.submission.reason, .privacy)
        XCTAssertEqual(state.submission.note, "  写り込みがあります  ")
    }

    func testGoodsEditorMemberScopeKeepsMembersInsideSelectedGroupOrWork() {
        let selectedGroupID = UUID()
        let otherGroupID = UUID()
        let selectedGroup = OshiGroup(id: selectedGroupID, name: "TWICE", kind: .group)
        let selectedMember = OshiCharacter(id: UUID(), groupID: selectedGroupID, name: "SANA")
        let otherMember = OshiCharacter(id: UUID(), groupID: otherGroupID, name: "KARINA")

        let members = GoodsEditorMemberScope.members(
            for: selectedGroup,
            from: [selectedMember, otherMember]
        )

        XCTAssertEqual(members, [selectedMember])
        XCTAssertTrue(
            GoodsEditorMemberScope.canUseMemberID(
                selectedMember.id,
                group: selectedGroup,
                members: [selectedMember, otherMember]
            )
        )
        XCTAssertFalse(
            GoodsEditorMemberScope.canUseMemberID(
                otherMember.id,
                group: selectedGroup,
                members: [selectedMember, otherMember]
            )
        )
    }

    func testGoodsEditorMemberScopeHidesMembersForSoloOshi() {
        let soloGroup = OshiGroup(id: UUID(), name: "IU", kind: .solo)
        let soloCharacter = OshiCharacter(id: UUID(), groupID: soloGroup.id, name: "IU")

        XCTAssertTrue(GoodsEditorMemberScope.members(for: soloGroup, from: [soloCharacter]).isEmpty)
        XCTAssertTrue(GoodsEditorMemberScope.memberIDs(for: soloGroup, from: [soloCharacter]).isEmpty)
        XCTAssertFalse(
            GoodsEditorMemberScope.canUseMemberID(
                soloCharacter.id,
                group: soloGroup,
                members: [soloCharacter]
            )
        )
        XCTAssertTrue(
            GoodsEditorMemberScope.canUseMemberID(
                nil,
                group: soloGroup,
                members: [soloCharacter]
            )
        )
    }

    func testInventoryCreateMetaBuildsInputPerPhoto() throws {
        let groupID = UUID()
        let memberID = UUID()
        let goodsTypeID = UUID()
        let photoUpload = GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID

        var meta = GoodsCreateMetaDraft(photoID: UUID(), memberID: memberID, quantity: 2)
        meta.addTag("会場限定")
        let input = try XCTUnwrap(
            meta.createInput(
                sharedDraft: draft,
                photoUpload: photoUpload,
                groupName: "aespa",
                memberName: "KARINA",
                goodsTypeName: "トレカ"
            )
        )

        XCTAssertEqual(input.kind, .inventory)
        XCTAssertEqual(input.title, "KARINA aespa トレカ")
        XCTAssertEqual(input.memberID, memberID)
        XCTAssertEqual(input.quantity, 2)
        XCTAssertEqual(input.tagNames, ["会場限定"])
        XCTAssertEqual(input.photoUpload, photoUpload)
    }

    func testInventoryCreateInputBuilderResolvesPhotoAndMemberPerMeta() throws {
        let groupID = UUID()
        let memberID = UUID()
        let goodsTypeID = UUID()
        let photoID = UUID()
        let photoUpload = GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID
        draft.addTag("共有シリーズは画像単位登録へ流れない")

        let inputs = GoodsInventoryCreateInputBuilder.inputs(
            metas: [GoodsCreateMetaDraft(photoID: photoID, memberID: memberID, quantity: 3, tagNames: ["ラキドロ"])],
            photos: [GoodsCreatePhotoDraft(id: photoID, upload: photoUpload)],
            sharedDraft: draft,
            groupName: "TWICE",
            members: [OshiCharacter(id: memberID, groupID: groupID, name: "MOMO")],
            goodsTypeName: "トレカ"
        )

        let input = try XCTUnwrap(inputs.first)
        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(input.title, "MOMO TWICE トレカ")
        XCTAssertEqual(input.memberID, memberID)
        XCTAssertEqual(input.quantity, 3)
        XCTAssertEqual(input.tagNames, ["ラキドロ"])
        XCTAssertEqual(input.photoUpload, photoUpload)
    }

    func testSharedCreateInputBuilderCanCreateWishFromPhotoMeta() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let photoID = UUID()
        let photoUpload = GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID

        let inputs = GoodsInventoryCreateInputBuilder.inputs(
            metas: [GoodsCreateMetaDraft(photoID: photoID, quantity: 1, tagNames: ["求む"])],
            photos: [GoodsCreatePhotoDraft(id: photoID, upload: photoUpload)],
            sharedDraft: draft,
            groupName: "BTS",
            members: [],
            goodsTypeName: "トレカ"
        )

        let input = try XCTUnwrap(inputs.first)
        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(input.kind, .wish)
        XCTAssertEqual(input.title, "BTS トレカ")
        XCTAssertEqual(input.status, .active)
        XCTAssertEqual(input.tagNames, ["求む"])
        XCTAssertEqual(input.photoUpload, photoUpload)
    }

    func testInventoryCreateValidationRequiresPhotosAndMembersButOnlyWarnsForTags() {
        let photoID = UUID()
        let photo = GoodsCreatePhotoDraft(
            id: photoID,
            upload: GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")
        )
        let missingMember = GoodsCreateMetaDraft(photoID: photoID)
        let complete = GoodsCreateMetaDraft(photoID: photoID, memberID: UUID(), tagNames: ["会場限定"])

        XCTAssertTrue(GoodsInventoryCreateValidation.hasMissingPhotos(metas: [missingMember], photos: []))
        XCTAssertFalse(GoodsInventoryCreateValidation.hasMissingPhotos(metas: [missingMember], photos: [photo]))
        XCTAssertTrue(
            GoodsInventoryCreateValidation.hasMissingMemberAssignments(
                metas: [missingMember],
                requiresMemberAssignment: true
            )
        )
        XCTAssertFalse(
            GoodsInventoryCreateValidation.hasMissingMemberAssignments(
                metas: [missingMember],
                requiresMemberAssignment: false
            )
        )
        XCTAssertTrue(GoodsInventoryCreateValidation.hasMissingTags(metas: [missingMember]))
        XCTAssertFalse(GoodsInventoryCreateValidation.hasMissingTags(metas: [complete]))
    }

    func testInventoryCreateMetaAutoResolvesTitleForOtherGoodsType() throws {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = UUID()
        draft.goodsTypeID = UUID()
        let blankMeta = GoodsCreateMetaDraft(memberID: UUID(), title: "   ")

        XCTAssertEqual(
            blankMeta.createInput(
                sharedDraft: draft,
                photoUpload: nil,
                groupName: "aespa",
                memberName: "KARINA",
                goodsTypeName: "その他"
            )?.title,
            "KARINA aespa その他"
        )

        let titledMeta = GoodsCreateMetaDraft(memberID: UUID(), title: "ランダム封入ミニカード")
        XCTAssertEqual(
            titledMeta.createInput(
                sharedDraft: draft,
                photoUpload: nil,
                groupName: "aespa",
                memberName: "KARINA",
                goodsTypeName: "その他"
            )?.title,
            "ランダム封入ミニカード"
        )
    }

    func testInventoryCreateMetaBoundsQuantity() throws {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = UUID()
        draft.goodsTypeID = UUID()
        let meta = GoodsCreateMetaDraft(quantity: 2_000)

        let input = try XCTUnwrap(
            meta.createInput(
                sharedDraft: draft,
                photoUpload: nil,
                groupName: "NCT",
                memberName: nil,
                goodsTypeName: "アクスタ"
            )
        )

        XCTAssertEqual(input.quantity, 999)
    }

    func testCreateInputUsesResolvedTitleAndBoundsQuantity() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID
        draft.quantity = 1_200

        let input = try XCTUnwrap(
            draft.createInput(groupName: "TWICE", memberName: nil, goodsTypeName: "トレカ")
        )

        XCTAssertEqual(input.kind, .inventory)
        XCTAssertEqual(input.title, "TWICE トレカ")
        XCTAssertEqual(input.groupID, groupID)
        XCTAssertNil(input.memberID)
        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
        XCTAssertEqual(input.quantity, 999)
        XCTAssertEqual(input.status, .active)
    }

    func testSwitchingEntryKindResetsInvalidStatus() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.status = .keep

        draft.setEntryKind(.wish)

        XCTAssertEqual(draft.entryKind, .wish)
        XCTAssertEqual(draft.status, .wishActive)
    }

    func testTagsAndPhotoAreIncludedInCreateInput() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.title = "ランダムトレカ"
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID
        draft.memberID = UUID()
        draft.setLocalPhotoUpload(GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg"))
        draft.addTag("#会場限定")

        let input = try XCTUnwrap(draft.createInput(groupName: "TWICE", memberName: "SANA", goodsTypeName: "トレカ"))
        XCTAssertTrue(draft.blockingReasons.isEmpty)
        XCTAssertEqual(input.tagNames, ["会場限定"])
        XCTAssertEqual(input.photoUpload?.contentType, "image/jpeg")
        XCTAssertEqual(input.photoUpload?.data, Data([0xFF, 0xD8, 0xFF]))
    }

    func testCameraCapturedJPEGIsHeldAsLocalPhotoUpload() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let cameraJPEG = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)
        draft.title = "探しているトレカ"
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID

        draft.setLocalPhotoUpload(GoodsPhotoUpload(data: cameraJPEG, contentType: "image/jpeg"))

        XCTAssertTrue(draft.hasLocalPhoto)
        XCTAssertTrue(draft.hasUnsavedLocalPhoto)
        XCTAssertEqual(draft.photoStatusText, "選択済み（保存前）")

        let input = try XCTUnwrap(draft.createInput(groupName: "TWICE", memberName: nil, goodsTypeName: "トレカ"))
        XCTAssertEqual(input.kind, .wish)
        XCTAssertEqual(input.photoUpload?.contentType, "image/jpeg")
        XCTAssertEqual(input.photoUpload?.data, cameraJPEG)
    }

    func testEditModeBuildsUpdateInput() throws {
        let groupID = UUID()
        let memberID = UUID()
        let goodsTypeID = UUID()
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            title: "既存グッズ",
            quantity: 2
        )

        var draft = GoodsEditorDraft(mode: .edit, entryKind: .inventory, item: item)
        draft.title = "  変更後  "
        draft.quantity = 4
        draft.status = .keep

        let input = try XCTUnwrap(draft.updateInput(groupName: "TWICE", memberName: "SANA", goodsTypeName: "トレカ"))
        XCTAssertNil(draft.createInput(groupName: "TWICE", memberName: nil, goodsTypeName: "トレカ"))
        XCTAssertEqual(input.title, "変更後")
        XCTAssertEqual(input.groupID, groupID)
        XCTAssertEqual(input.memberID, memberID)
        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
        XCTAssertEqual(input.quantity, 4)
        XCTAssertEqual(input.status, .keep)
        XCTAssertEqual(input.tagNames, [])
    }

    func testTagsAreNormalizedDeduplicatedAndLimited() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)

        ["#会場限定", " 会場限定 ", "トレカ", "生写真", "Type A", "横アリ", "追加不可"].forEach {
            draft.addTag($0)
        }

        XCTAssertEqual(draft.tagNames, ["会場限定", "トレカ", "生写真", "Type A", "横アリ"])
    }

    func testClearingLocalPhotoSelectionKeepsExistingImageURL() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://example.com/goods.jpg"))
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "既存グッズ",
            imageURL: imageURL
        )
        var draft = GoodsEditorDraft(mode: .edit, entryKind: .inventory, item: item)
        draft.setLocalPhotoUpload(GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg"))

        XCTAssertTrue(draft.hasUnsavedLocalPhoto)

        draft.clearLocalPhotoSelection()
        let input = try XCTUnwrap(draft.updateInput(groupName: "TWICE", goodsTypeName: "トレカ"))

        XCTAssertFalse(draft.hasUnsavedLocalPhoto)
        XCTAssertEqual(input.photoURLs, [imageURL.absoluteString])
        XCTAssertNil(input.photoUpload)
    }

    func testRemovingExistingWishPhotoEmitsEmptyPhotoURLs() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://example.com/wish.jpg"))
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "既存Wish",
            imageURL: imageURL
        )
        var draft = GoodsEditorDraft(mode: .edit, entryKind: .wish, item: item)

        draft.removeDisplayPhoto()
        let input = try XCTUnwrap(draft.updateInput(groupName: "TWICE", goodsTypeName: "トレカ"))

        XCTAssertTrue(draft.didRemoveExistingPhoto)
        XCTAssertNil(draft.existingImageURL)
        XCTAssertEqual(input.photoURLs, [])
        XCTAssertNil(input.photoUpload)
        XCTAssertEqual(draft.photoStatusText, "削除予定（保存前）")
    }

    func testSaveFailureMessageMentionsPhotoAndTagRecovery() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)
        draft.addTag("会場限定")
        draft.hasLocalPhoto = true
        draft.localPhotoData = Data([0xFF, 0xD8, 0xFF])

        let failure = GoodsEditorSaveFailure.make(draft: draft, appMessage: "グッズを保存できませんでした")

        XCTAssertTrue(failure.includesPhotoUpload)
        XCTAssertTrue(failure.includesTagChanges)
        XCTAssertTrue(failure.message.contains("写真を外して保存"))
        XCTAssertTrue(failure.message.contains("シリーズは画面に残っている"))
        XCTAssertTrue(failure.message.contains("入力内容はこの画面に残しています"))
    }

    func testNormalizedPhotoUploadKeepsSupportedImageContentTypes() {
        let jpeg = normalizedPhotoUpload(from: Data([0xFF, 0xD8, 0xFF]))
        XCTAssertEqual(jpeg.contentType, "image/jpeg")

        let png = normalizedPhotoUpload(from: Data([0x89, 0x50, 0x4E, 0x47]))
        XCTAssertEqual(png.contentType, "image/png")

        let gif = normalizedPhotoUpload(from: Data([0x47, 0x49, 0x46, 0x38]))
        XCTAssertEqual(gif.contentType, "image/gif")

        let webp = normalizedPhotoUpload(from: Data("RIFFxxxxWEBP".utf8))
        XCTAssertEqual(webp.contentType, "image/webp")
    }

    func testPhotoUploadSizeErrorUsesLocalUploadLimit() {
        let upload = GoodsPhotoUpload(
            data: Data(repeating: 0x00, count: goodsEditorMaxPhotoUploadBytes + 1),
            contentType: "image/jpeg"
        )

        XCTAssertEqual(goodsEditorPhotoUploadError(for: upload), "写真は10MB以下にしてください")
    }

    func testTradingCardBulkRecognizerSortsTopToBottomThenLeftToRight() {
        let centers = [
            CGPoint(x: 0.72, y: 0.42),
            CGPoint(x: 0.68, y: 0.18),
            CGPoint(x: 0.18, y: 0.19),
            CGPoint(x: 0.22, y: 0.43)
        ]

        let sorted = TradingCardBulkRecognizer.sortedTopLeftCenters(centers)

        zip(sorted.map(\.x), [0.18, 0.68, 0.22, 0.72]).forEach { actual, expected in
            XCTAssertEqual(actual, expected, accuracy: 0.001)
        }
        zip(sorted.map(\.y), [0.19, 0.18, 0.43, 0.42]).forEach { actual, expected in
            XCTAssertEqual(actual, expected, accuracy: 0.001)
        }
    }

    func testTradingCardBulkRecognizerFallsBackToOriginalWhenNoCardIsDetected() async throws {
        let data = try makeSolidJPEGData()

        let results = try await TradingCardBulkRecognizer.recognizeCards(in: data, maximumCards: 3)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.source, .fallbackOriginal)
        XCTAssertEqual(results.first?.contentType, "image/jpeg")
        XCTAssertFalse(results.first?.data.isEmpty ?? true)
    }

    func testTradingCardBulkRecognizerCropsManualFrames() throws {
        let data = try makeSolidJPEGData(width: 80, height: 100)
        let frame = TradingCardCropFrame(
            rect: CGRect(x: 0.25, y: 0.20, width: 0.50, height: 0.60),
            source: .detected
        )

        let results = try TradingCardBulkRecognizer.cropFramesSynchronously([frame], in: data)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, frame.id)
        XCTAssertEqual(results.first?.source, .detected)
        XCTAssertEqual(results.first?.contentType, "image/jpeg")
        XCTAssertFalse(results.first?.data.isEmpty ?? true)
    }

    func testGoodsPhotoCropSheetPresentationStateTracksFramesSelectionAndMessages() {
        let first = TradingCardCropFrame(id: UUID(), rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3))
        let second = TradingCardCropFrame(id: UUID(), rect: CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2))
        var state = GoodsPhotoCropSheetPresentationState(initialFrames: [first, second])

        XCTAssertTrue(state.canApply)
        XCTAssertEqual(state.selectedFrameID, first.id)

        state.selectedFrameID = second.id
        state.deleteFrame(second.id)

        XCTAssertEqual(state.frames.map(\.id), [first.id])
        XCTAssertEqual(state.selectedFrameID, first.id)

        state.showFailureMessage("画像を読み込めませんでした。")
        XCTAssertEqual(state.message, "画像を読み込めませんでした。")

        state.clearFrames()
        XCTAssertFalse(state.canApply)
        XCTAssertNil(state.selectedFrameID)

        state.reset(to: [first, second])
        XCTAssertEqual(state.frames.map(\.id), [first.id, second.id])
        XCTAssertEqual(state.selectedFrameID, first.id)
        XCTAssertNil(state.message)
    }

    func testGoodsPhotoCropCanvasDragStateBuildsFrameAndResetsDraft() {
        let displayRect = CGRect(x: 10, y: 20, width: 100, height: 200)
        var state = GoodsPhotoCropCanvasDragState()

        // 枠の外からの開始 → 新規描画モード
        let selection = state.begin(
            at: CGPoint(x: -5, y: 10),
            frames: [],
            selectedFrameID: nil,
            in: displayRect
        )
        XCTAssertNil(selection)
        XCTAssertEqual(state.mode, .draw)

        XCTAssertNil(state.update(location: CGPoint(x: 60, y: 120), in: displayRect))
        XCTAssertEqual(state.draftRect, CGRect(x: 10, y: 20, width: 50, height: 100))

        let frame = state.finish(location: CGPoint(x: 60, y: 120), in: displayRect)

        XCTAssertEqual(frame?.rect.minX ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(frame?.rect.minY ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(frame?.rect.width ?? -1, 0.5, accuracy: 0.001)
        XCTAssertEqual(frame?.rect.height ?? -1, 0.5, accuracy: 0.001)
        XCTAssertNil(state.mode)
        XCTAssertNil(state.dragStart)
        XCTAssertNil(state.draftRect)
    }

    func testGoodsPhotoCropCanvasDragStateRejectsSmallDrag() {
        let displayRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        var state = GoodsPhotoCropCanvasDragState()

        _ = state.begin(at: CGPoint(x: 10, y: 10), frames: [], selectedFrameID: nil, in: displayRect)
        _ = state.update(location: CGPoint(x: 24, y: 24), in: displayRect)

        XCTAssertNil(state.finish(location: CGPoint(x: 24, y: 24), in: displayRect))
        XCTAssertNil(state.mode)
        XCTAssertNil(state.dragStart)
        XCTAssertNil(state.draftRect)
    }

    func testGoodsPhotoCropCanvasDragStateMovesFrameInsideBounds() {
        let displayRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let frame = TradingCardCropFrame(rect: CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.4))
        var state = GoodsPhotoCropCanvasDragState()

        // 枠内からの開始 → 移動モード＋その枠を選択
        let selection = state.begin(
            at: CGPoint(x: 30, y: 30),
            frames: [frame],
            selectedFrameID: nil,
            in: displayRect
        )
        XCTAssertEqual(selection, frame.id)

        let update = state.update(location: CGPoint(x: 50, y: 40), in: displayRect)
        XCTAssertEqual(update?.frameID, frame.id)
        XCTAssertEqual(update?.rect ?? .zero, CGRect(x: 30, y: 20, width: 40, height: 40))

        // 端を超えるドラッグは表示領域内へクランプされる
        let clamped = state.update(location: CGPoint(x: 500, y: 500), in: displayRect)
        XCTAssertEqual(clamped?.rect ?? .zero, CGRect(x: 60, y: 60, width: 40, height: 40))

        XCTAssertNil(state.finish(location: CGPoint(x: 500, y: 500), in: displayRect))
    }

    func testGoodsPhotoCropCanvasDragStateResizesSelectedFrameFromCorner() {
        let displayRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let frame = TradingCardCropFrame(rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4))
        var state = GoodsPhotoCropCanvasDragState()

        // 選択枠の右下コーナー付近からの開始 → リサイズモード
        let selection = state.begin(
            at: CGPoint(x: 60, y: 60),
            frames: [frame],
            selectedFrameID: frame.id,
            in: displayRect
        )
        XCTAssertNil(selection)
        guard case .resize(let frameID, let corner, let originalRect) = state.mode else {
            XCTFail("Expected resize mode, got \(String(describing: state.mode))")
            return
        }
        XCTAssertEqual(frameID, frame.id)
        XCTAssertEqual(corner, .bottomTrailing)
        XCTAssertEqual(originalRect.minX, 20, accuracy: 0.001)
        XCTAssertEqual(originalRect.minY, 20, accuracy: 0.001)
        XCTAssertEqual(originalRect.width, 40, accuracy: 0.001)
        XCTAssertEqual(originalRect.height, 40, accuracy: 0.001)

        let update = state.update(location: CGPoint(x: 90, y: 80), in: displayRect)
        XCTAssertEqual(update?.rect.minX ?? -1, 20, accuracy: 0.001)
        XCTAssertEqual(update?.rect.minY ?? -1, 20, accuracy: 0.001)
        XCTAssertEqual(update?.rect.width ?? -1, 70, accuracy: 0.001)
        XCTAssertEqual(update?.rect.height ?? -1, 60, accuracy: 0.001)

        // 最小サイズを下回るリサイズは 28pt 辺で止まる
        let tiny = state.update(location: CGPoint(x: 22, y: 22), in: displayRect)
        XCTAssertEqual(tiny?.rect.width ?? 0, GoodsPhotoCropCanvasDragState.minFrameSide)
        XCTAssertEqual(tiny?.rect.height ?? 0, GoodsPhotoCropCanvasDragState.minFrameSide)
    }

    func testGoodsPhotoCropSheetDetectsEffectivelyFullFrame() {
        XCTAssertTrue(GoodsPhotoCropSheet.isEffectivelyFullFrame(CGRect(x: 0, y: 0, width: 1, height: 1)))
        XCTAssertTrue(GoodsPhotoCropSheet.isEffectivelyFullFrame(CGRect(x: 0.01, y: 0.015, width: 0.98, height: 0.98)))
        XCTAssertFalse(GoodsPhotoCropSheet.isEffectivelyFullFrame(CGRect(x: 0.1, y: 0, width: 0.9, height: 1)))
        XCTAssertFalse(GoodsPhotoCropSheet.isEffectivelyFullFrame(CGRect(x: 0, y: 0, width: 0.8, height: 1)))
    }

    func testTradingCardBulkRecognizerRejectsInvalidImageData() async {
        do {
            _ = try await TradingCardBulkRecognizer.recognizeCards(in: Data([0x00, 0x01, 0x02]))
            XCTFail("Invalid image data should not be recognized")
        } catch let error as TradingCardBulkRecognitionError {
            XCTAssertEqual(error.errorDescription, "画像を読み込めませんでした。")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSolidJPEGData(width: Int = 40, height: Int = 40) throws -> Data {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let pixels = Data(repeating: 0xF5, count: width * height * bytesPerPixel)
        guard let provider = CGDataProvider(data: pixels as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            XCTFail("Failed to create test image")
            return Data()
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            XCTFail("Failed to create JPEG destination")
            return Data()
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            XCTFail("Failed to write JPEG")
            return Data()
        }
        return output as Data
    }

    private func makeGoodsItem(ownerID: UUID, groupID: UUID, tagNames: [String]) -> GoodsItem {
        GoodsItem(
            id: UUID(),
            ownerID: ownerID,
            groupID: groupID,
            title: "シリーズ候補テスト",
            tags: tagNames.map { GoodsTag(id: UUID(), name: $0) }
        )
    }

    private func makeWishItem(ownerID: UUID, groupID: UUID, tagNames: [String]) -> WishItem {
        WishItem(
            id: UUID(),
            ownerID: ownerID,
            groupID: groupID,
            title: "シリーズ候補テスト",
            tags: tagNames.map { GoodsTag(id: UUID(), name: $0) }
        )
    }
}
