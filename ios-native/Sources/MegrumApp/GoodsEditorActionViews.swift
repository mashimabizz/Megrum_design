import Foundation
import MegrumCore
import SwiftUI

struct GoodsEditorActionButtons: View {
    var entryKind: GoodsEntryKind
    var mode: GoodsEditorMode
    var existingItemID: UUID?
    var isItemReadOnly: Bool
    var isSavingCurrentItem: Bool
    var isMutatingCurrentItem: Bool
    var canSave: Bool
    var saveButtonTitle: String
    var onClose: () -> Void
    var onSave: () -> Void
    var onConfirmDelete: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if isItemReadOnly {
                GoodsEditorCloseButton(onClose: onClose)
            } else {
                GoodsEditorSaveButton(
                    title: saveButtonTitle,
                    isSaving: isSavingCurrentItem,
                    canSave: canSave,
                    onSave: onSave
                )

                if entryKind == .inventory, mode == .edit {
                    GoodsEditorDeleteButton(
                        hasExistingItem: existingItemID != nil,
                        isMutating: isMutatingCurrentItem,
                        onConfirmDelete: onConfirmDelete
                    )
                }
            }
        }
    }
}

struct GoodsEditorFeedbackActionSection: View {
    var blockingReasons: [GoodsEditorSaveBlocker]
    var lastSaveFailure: GoodsEditorSaveFailure?
    var usesInventoryCreateFlow: Bool
    var entryKind: GoodsEntryKind
    var mode: GoodsEditorMode
    var existingItemID: UUID?
    var isItemReadOnly: Bool
    var isSavingCurrentItem: Bool
    var isMutatingCurrentItem: Bool
    var canSave: Bool
    var saveButtonTitle: String
    var onRetrySave: () -> Void
    var onRequestPhotoRemoval: () -> Void
    var onClose: () -> Void
    var onSave: () -> Void
    var onConfirmDelete: () -> Void

    var body: some View {
        Group {
            if !blockingReasons.isEmpty {
                GoodsEditorUnsupportedNotice(reasons: blockingReasons)
            }
            if let lastSaveFailure {
                GoodsEditorSaveFailureNotice(
                    failure: lastSaveFailure,
                    onRetry: onRetrySave,
                    onRemovePhoto: onRequestPhotoRemoval
                )
            }
            if !usesInventoryCreateFlow {
                GoodsEditorActionButtons(
                    entryKind: entryKind,
                    mode: mode,
                    existingItemID: existingItemID,
                    isItemReadOnly: isItemReadOnly,
                    isSavingCurrentItem: isSavingCurrentItem,
                    isMutatingCurrentItem: isMutatingCurrentItem,
                    canSave: canSave,
                    saveButtonTitle: saveButtonTitle,
                    onClose: onClose,
                    onSave: onSave,
                    onConfirmDelete: onConfirmDelete
                )
            }
        }
    }
}
