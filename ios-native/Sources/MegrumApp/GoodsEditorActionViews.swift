import Foundation
import MegrumCore
import MegrumDesign
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
                closeButton
            } else {
                saveButton
                if entryKind == .inventory, mode == .edit {
                    deleteButton
                }
            }
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Text("戻る")
                .font(.headline.weight(.black))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .tint(MegrumTheme.lavender)
    }

    private var saveButton: some View {
        Button(action: onSave) {
            HStack(spacing: 10) {
                if isSavingCurrentItem {
                    ProgressView()
                        .tint(.white)
                }
                Text(saveButtonTitle)
                    .font(.headline.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .tint(MegrumTheme.lavender)
        .disabled(!canSave)
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: onConfirmDelete) {
            HStack(spacing: 8) {
                if isMutatingCurrentItem {
                    ProgressView()
                }
                Text("このマイグッズを削除")
                    .font(.headline.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.bordered)
        .disabled(existingItemID == nil || isMutatingCurrentItem)
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
