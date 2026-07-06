import MegrumCore
import SwiftUI

struct GoodsEditorStandardSectionsView: View {
    @Binding var draft: GoodsEditorDraft
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding

    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    var members: [OshiCharacter]
    var isLoadingOshiCharacters: Bool
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    var selectedGroupSupportsMemberSelection: Bool
    var includesStatus: Bool
    var tagSuggestions: [String]
    var photoError: String?
    var photoActionTitle: String
    var titlePreview: String
    var wishImageHint: String
    var isItemReadOnly: Bool
    var isWishPhotoRemovalLocked: Bool
    var onShowOshiPicker: () -> Void
    var onShowPhotoSource: () -> Void
    var onClearLocalPhoto: () -> Void
    var onRemoveWishPhoto: () -> Void
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void
    var onAddSuggestedTag: (String) -> Void
    var onOpenTagSheet: (() -> Void)?

    var body: some View {
        if draft.entryKind == .inventory {
            inventoryPhotoSection
            groupPickerSection(title: "グループ")
        } else {
            groupPickerSection(title: "推し")
        }
        if selectedGroupSupportsMemberSelection {
            memberSection
        }
        goodsTypeSection
        quantitySection
        if draft.entryKind == .wish {
            wishPhotoSection
        }
        if includesStatus {
            statusSection
        }
        tagsSection
    }

    private var inventoryPhotoSection: some View {
        GoodsEditorInventoryPhotoSection(
            draft: draft,
            photoError: photoError,
            photoActionTitle: photoActionTitle,
            isItemReadOnly: isItemReadOnly,
            onShowPhotoSource: onShowPhotoSource,
            onClearLocalPhoto: onClearLocalPhoto
        )
    }

    private var wishPhotoSection: some View {
        GoodsEditorWishPhotoSection(
            draft: draft,
            photoError: photoError,
            photoActionTitle: photoActionTitle,
            titlePreview: titlePreview,
            wishImageHint: wishImageHint,
            isItemReadOnly: isItemReadOnly,
            isWishPhotoRemovalLocked: isWishPhotoRemovalLocked,
            onShowPhotoSource: onShowPhotoSource,
            onRemoveWishPhoto: onRemoveWishPhoto
        )
    }

    private func groupPickerSection(title: String) -> some View {
        GoodsCreateOshiPickerRow(
            title: title,
            isLoading: isLoadingOshiGroups,
            selectedGroupName: groups.first { $0.id == draft.groupID }?.name,
            isItemReadOnly: isItemReadOnly,
            action: onShowOshiPicker
        )
    }

    private var memberSection: some View {
        GoodsEditorMemberSelectionSection(
            entryKind: draft.entryKind,
            members: members,
            isLoading: isLoadingOshiCharacters,
            selectedGroupID: draft.groupID,
            selectedMemberID: $draft.memberID,
            isItemReadOnly: isItemReadOnly
        )
    }

    private var goodsTypeSection: some View {
        GoodsEditorGoodsTypeSelectionSection(
            goodsTypes: goodsTypes,
            isLoading: isLoadingGoodsTypes,
            selectedGoodsTypeID: $draft.goodsTypeID,
            isItemReadOnly: isItemReadOnly
        )
    }

    private var quantitySection: some View {
        GoodsEditorQuantitySection(
            quantity: $draft.quantity,
            isItemReadOnly: isItemReadOnly
        )
    }

    private var statusSection: some View {
        GoodsEditorStatusSection(
            entryKind: draft.entryKind,
            selectedStatus: $draft.status,
            isItemReadOnly: isItemReadOnly
        )
    }

    private var tagsSection: some View {
        GoodsEditorTagsSection(
            tagNames: draft.tagNames,
            suggestedTagNames: tagSuggestions,
            tagDraft: $tagDraft,
            isTagFieldFocused: isTagFieldFocused,
            isItemReadOnly: isItemReadOnly,
            // マイグッズ編集でもほしいもの編集と同じシリーズ登録モジュール（シート）を使う
            onOpenTagSheet: onOpenTagSheet,
            onAddSuggestedTag: onAddSuggestedTag,
            onRemoveTag: onRemoveTag,
            onAddTag: onAddTag
        )
    }
}
