import Foundation
import MegrumCore
import SwiftUI

struct GoodsEditorFormContentView: View {
    @Binding var draft: GoodsEditorDraft
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    @Binding var createMetas: [GoodsCreateMetaDraft]

    var navigationTitle: String
    var headerDescription: String
    var usesInventoryCreateFlow: Bool
    var isItemReadOnly: Bool
    var createStep: GoodsCreateStep
    var createPhotos: [GoodsCreatePhotoDraft]
    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    var members: [OshiCharacter]
    var isLoadingOshiCharacters: Bool
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    var selectedGroupName: String?
    var selectedGoodsTypeName: String?
    var createError: String?
    var canAdvanceFromCreateCommon: Bool
    var isTradingCardType: Bool
    var isProcessingTradingCardBulk: Bool
    var tradingCardBulkStatusMessage: String?
    var canSaveInventoryCreateMetas: Bool
    var isCreatingGoodsEntry: Bool
    var photoError: String?
    var photoActionTitle: String
    var titlePreview: String
    var wishImageHint: String
    var isWishPhotoRemovalLocked: Bool
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void
    var onCommonNext: () -> Void
    var onPickCamera: () -> Void
    var onPickPhotos: () -> Void
    var onStartTradingCardBulk: () -> Void
    var onRemovePhoto: (UUID) -> Void
    var onShootBack: () -> Void
    var onShootNext: () -> Void
    var onContinueWithoutPhoto: () -> Void
    var onMetaBack: () -> Void
    var onSaveMetas: () -> Void
    var onShowPhotoSource: () -> Void
    var onClearLocalPhoto: () -> Void
    var onRemoveWishPhoto: () -> Void

    var body: some View {
        if draft.mode == .create {
            GoodsEditorHeaderCard(
                entryKind: draft.entryKind,
                title: navigationTitle,
                badgeTitle: draft.mode.badgeTitle,
                description: headerDescription
            )
        }

        if isItemReadOnly {
            GoodsEditorReadOnlyNotice()
        }

        if usesInventoryCreateFlow {
            GoodsInventoryCreateFlowView(
                draft: $draft,
                tagDraft: $tagDraft,
                isTagFieldFocused: isTagFieldFocused,
                createMetas: $createMetas,
                createStep: createStep,
                createPhotos: createPhotos,
                groups: groups,
                isLoadingOshiGroups: isLoadingOshiGroups,
                goodsTypes: goodsTypes,
                isLoadingGoodsTypes: isLoadingGoodsTypes,
                oshiCharacters: members,
                selectedGroupName: selectedGroupName,
                selectedGoodsTypeName: selectedGoodsTypeName,
                createError: createError,
                canAdvanceFromCommon: canAdvanceFromCreateCommon,
                isTradingCardType: isTradingCardType,
                isProcessingTradingCardBulk: isProcessingTradingCardBulk,
                tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
                canSaveMetas: canSaveInventoryCreateMetas,
                isItemReadOnly: isItemReadOnly,
                isCreatingGoodsEntry: isCreatingGoodsEntry,
                onRemoveTag: onRemoveTag,
                onAddTag: onAddTag,
                onCommonNext: onCommonNext,
                onPickCamera: onPickCamera,
                onPickPhotos: onPickPhotos,
                onStartTradingCardBulk: onStartTradingCardBulk,
                onRemovePhoto: onRemovePhoto,
                onShootBack: onShootBack,
                onShootNext: onShootNext,
                onContinueWithoutPhoto: onContinueWithoutPhoto,
                onMetaBack: onMetaBack,
                onSaveMetas: onSaveMetas
            )
        } else {
            GoodsEditorStandardSectionsView(
                draft: $draft,
                tagDraft: $tagDraft,
                isTagFieldFocused: isTagFieldFocused,
                groups: groups,
                isLoadingOshiGroups: isLoadingOshiGroups,
                members: members,
                isLoadingOshiCharacters: isLoadingOshiCharacters,
                goodsTypes: goodsTypes,
                isLoadingGoodsTypes: isLoadingGoodsTypes,
                includesStatus: draft.mode == .create,
                photoError: photoError,
                photoActionTitle: photoActionTitle,
                titlePreview: titlePreview,
                wishImageHint: wishImageHint,
                isItemReadOnly: isItemReadOnly,
                isWishPhotoRemovalLocked: isWishPhotoRemovalLocked,
                onShowPhotoSource: onShowPhotoSource,
                onClearLocalPhoto: onClearLocalPhoto,
                onRemoveWishPhoto: onRemoveWishPhoto,
                onRemoveTag: onRemoveTag,
                onAddTag: onAddTag
            )
        }
    }
}

struct GoodsInventoryCreateFlowView: View {
    @Binding var draft: GoodsEditorDraft
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    @Binding var createMetas: [GoodsCreateMetaDraft]

    var createStep: GoodsCreateStep
    var createPhotos: [GoodsCreatePhotoDraft]
    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    var oshiCharacters: [OshiCharacter]
    var selectedGroupName: String?
    var selectedGoodsTypeName: String?
    var createError: String?
    var canAdvanceFromCommon: Bool
    var isTradingCardType: Bool
    var isProcessingTradingCardBulk: Bool
    var tradingCardBulkStatusMessage: String?
    var canSaveMetas: Bool
    var isItemReadOnly: Bool
    var isCreatingGoodsEntry: Bool
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void
    var onCommonNext: () -> Void
    var onPickCamera: () -> Void
    var onPickPhotos: () -> Void
    var onStartTradingCardBulk: () -> Void
    var onRemovePhoto: (UUID) -> Void
    var onShootBack: () -> Void
    var onShootNext: () -> Void
    var onContinueWithoutPhoto: () -> Void
    var onMetaBack: () -> Void
    var onSaveMetas: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GoodsCreateStepProgressView(currentStep: createStep)

            switch createStep {
            case .common:
                GoodsInventoryCreateCommonStepView(
                    groups: groups,
                    isLoadingOshiGroups: isLoadingOshiGroups,
                    selectedGroupID: $draft.groupID,
                    goodsTypes: goodsTypes,
                    isLoadingGoodsTypes: isLoadingGoodsTypes,
                    selectedGoodsTypeID: $draft.goodsTypeID,
                    tagNames: draft.tagNames,
                    tagDraft: $tagDraft,
                    isTagFieldFocused: isTagFieldFocused,
                    createError: createError,
                    canAdvance: canAdvanceFromCommon,
                    isItemReadOnly: isItemReadOnly,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    onRemoveTag: onRemoveTag,
                    onAddTag: onAddTag,
                    onNext: onCommonNext
                )
            case .shoot:
                GoodsInventoryCreateShootStepView(
                    createPhotos: createPhotos,
                    isTradingCardType: isTradingCardType,
                    isProcessingTradingCardBulk: isProcessingTradingCardBulk,
                    tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
                    createError: createError,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    onPickCamera: onPickCamera,
                    onPickPhotos: onPickPhotos,
                    onStartTradingCardBulk: onStartTradingCardBulk,
                    onRemovePhoto: onRemovePhoto,
                    onBack: onShootBack,
                    onNext: onShootNext,
                    onContinueWithoutPhoto: onContinueWithoutPhoto
                )
            case .meta:
                GoodsInventoryCreateMetaStepView(
                    createMetas: $createMetas,
                    createPhotos: createPhotos,
                    oshiCharacters: oshiCharacters,
                    draftGroupID: draft.groupID,
                    selectedGroupName: selectedGroupName,
                    selectedGoodsTypeName: selectedGoodsTypeName,
                    createError: createError,
                    canSaveMetas: canSaveMetas,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    onBack: onMetaBack,
                    onSave: onSaveMetas
                )
            }
        }
    }
}

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
    var includesStatus: Bool
    var photoError: String?
    var photoActionTitle: String
    var titlePreview: String
    var wishImageHint: String
    var isItemReadOnly: Bool
    var isWishPhotoRemovalLocked: Bool
    var onShowPhotoSource: () -> Void
    var onClearLocalPhoto: () -> Void
    var onRemoveWishPhoto: () -> Void
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void

    var body: some View {
        if draft.entryKind == .inventory {
            inventoryPhotoSection
            groupSection(title: "グループ", required: true)
        } else {
            groupSection(title: "推し", required: true)
        }
        memberSection
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

    private func groupSection(title: String, required: Bool) -> some View {
        GoodsEditorGroupSelectionSection(
            title: title,
            required: required,
            groups: groups,
            isLoading: isLoadingOshiGroups,
            selectedGroupID: $draft.groupID,
            isItemReadOnly: isItemReadOnly
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
            tagDraft: $tagDraft,
            isTagFieldFocused: isTagFieldFocused,
            isItemReadOnly: isItemReadOnly,
            onRemoveTag: onRemoveTag,
            onAddTag: onAddTag
        )
    }
}
