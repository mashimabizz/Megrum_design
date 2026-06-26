import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

extension GoodsEditorSheet {
    @ToolbarContentBuilder
    var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("閉じる", action: dismissEditor)
        }
        if draft.mode != .create {
            ToolbarItem(placement: .confirmationAction) {
                Text(draft.mode.badgeTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
            }
        }
    }

    var navigationTitle: String {
        GoodsEditorPresentationText.navigationTitle(mode: draft.mode, entryKind: draft.entryKind)
    }

    var selectedGroup: OshiGroup? {
        guard let groupID = draft.groupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == groupID }
    }

    var selectedMember: OshiCharacter? {
        guard let memberID = draft.memberID else {
            return nil
        }
        return scopedOshiCharacters.first { $0.id == memberID }
    }

    var selectedGroupSupportsMemberSelection: Bool {
        selectedGroup?.supportsMemberSelection == true
    }

    var inventoryCreateAllowsMemberAssignment: Bool {
        selectedGroupSupportsMemberSelection && !scopedOshiCharacters.isEmpty
    }

    var scopedOshiCharacters: [OshiCharacter] {
        GoodsEditorMemberScope.members(for: selectedGroup, from: appState.oshiCharacters)
    }

    var faceTaggingMemberOptions: [FaceTaggingMemberOption] {
        scopedOshiCharacters.map { member in
            FaceTaggingMemberOption(memberID: member.id, name: member.name)
        }
    }

    var selectedGoodsType: GoodsType? {
        guard let goodsTypeID = draft.goodsTypeID else {
            return nil
        }
        return appState.goodsTypes.first { $0.id == goodsTypeID }
    }

    var resolvedTitlePreview: String {
        draft.resolvedTitle(
            groupName: selectedGroup?.name,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    var canSave: Bool {
        guard !isItemReadOnly else {
            return false
        }
        switch draft.mode {
        case .create:
            return draft.createInput(
                groupName: selectedGroup?.name,
                memberName: selectedMember?.name,
                goodsTypeName: selectedGoodsType?.name
            ) != nil && !appState.isCreatingGoodsEntry
        case .edit:
            return draft.existingItemID != nil
                && draft.updateInput(
                    groupName: selectedGroup?.name,
                    memberName: selectedMember?.name,
                    goodsTypeName: selectedGoodsType?.name
                ) != nil
                && appState.mutatingGoodsItemID != draft.existingItemID
        case .readonly:
            return false
        }
    }

    var isItemReadOnly: Bool {
        draft.mode == .readonly || (draft.entryKind == .inventory && draft.status == .traded)
    }

    var isSavingCurrentItem: Bool {
        switch draft.mode {
        case .create:
            appState.isCreatingGoodsEntry
        case .edit:
            appState.mutatingGoodsItemID == draft.existingItemID
        case .readonly:
            false
        }
    }

    var usesInventoryCreateFlow: Bool {
        draft.mode == .create
    }

    var canAdvanceFromCreateCommon: Bool {
        draft.groupID != nil && draft.goodsTypeID != nil
    }

    var isTradingCardType: Bool {
        selectedGoodsType?.name == "トレカ"
    }

    var editorTagSuggestions: [String] {
        GoodsEditorTagSuggestionBuilder.suggestions(
            groupID: draft.groupID,
            selectedTags: draft.tagNames,
            inventory: appState.inventory,
            wishes: appState.wishes
        )
    }

    var photoSourceDialogTitle: String {
        draft.hasDisplayPhoto ? "写真を差し替え" : "写真を追加"
    }

    var photoActionTitle: String {
        GoodsEditorPresentationText.photoActionTitle(
            entryKind: draft.entryKind,
            hasDisplayPhoto: draft.hasDisplayPhoto
        )
    }

    var wishImageHint: String {
        GoodsEditorPresentationText.wishImageHint(hasDisplayPhoto: draft.hasDisplayPhoto)
    }

    var isWishPhotoRemovalLocked: Bool {
        GoodsEditorWishPhotoRemovalPolicy.isRemovalLocked(
            itemID: draft.existingItemID,
            entryKind: draft.entryKind,
            listings: appState.listings
        )
    }
}
