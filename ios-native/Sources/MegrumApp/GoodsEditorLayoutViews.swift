import Foundation
import MegrumCore
import SwiftUI

struct GoodsEditorFlowLayout<Content: View>: View {
    var spacing: CGFloat = 8
    var content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: spacing)], alignment: .leading, spacing: spacing) {
            content
        }
    }
}

struct GoodsEditorSheetScrollContent<FormContent: View>: View {
    var formContent: FormContent
    var fixedFooter: AnyView?
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

    init(
        blockingReasons: [GoodsEditorSaveBlocker],
        lastSaveFailure: GoodsEditorSaveFailure?,
        usesInventoryCreateFlow: Bool,
        entryKind: GoodsEntryKind,
        mode: GoodsEditorMode,
        existingItemID: UUID?,
        isItemReadOnly: Bool,
        isSavingCurrentItem: Bool,
        isMutatingCurrentItem: Bool,
        canSave: Bool,
        saveButtonTitle: String,
        onRetrySave: @escaping () -> Void,
        onRequestPhotoRemoval: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onConfirmDelete: @escaping () -> Void,
        fixedFooter: AnyView? = nil,
        @ViewBuilder formContent: () -> FormContent
    ) {
        self.formContent = formContent()
        self.fixedFooter = fixedFooter
        self.blockingReasons = blockingReasons
        self.lastSaveFailure = lastSaveFailure
        self.usesInventoryCreateFlow = usesInventoryCreateFlow
        self.entryKind = entryKind
        self.mode = mode
        self.existingItemID = existingItemID
        self.isItemReadOnly = isItemReadOnly
        self.isSavingCurrentItem = isSavingCurrentItem
        self.isMutatingCurrentItem = isMutatingCurrentItem
        self.canSave = canSave
        self.saveButtonTitle = saveButtonTitle
        self.onRetrySave = onRetrySave
        self.onRequestPhotoRemoval = onRequestPhotoRemoval
        self.onClose = onClose
        self.onSave = onSave
        self.onConfirmDelete = onConfirmDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                formContent
                GoodsEditorFeedbackActionSection(
                    blockingReasons: blockingReasons,
                    lastSaveFailure: lastSaveFailure,
                    usesInventoryCreateFlow: usesInventoryCreateFlow,
                    entryKind: entryKind,
                    mode: mode,
                    existingItemID: existingItemID,
                    isItemReadOnly: isItemReadOnly,
                    isSavingCurrentItem: isSavingCurrentItem,
                    isMutatingCurrentItem: isMutatingCurrentItem,
                    canSave: canSave,
                    saveButtonTitle: saveButtonTitle,
                    onRetrySave: onRetrySave,
                    onRequestPhotoRemoval: onRequestPhotoRemoval,
                    onClose: onClose,
                    onSave: onSave,
                    onConfirmDelete: onConfirmDelete
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .safeAreaInset(edge: .bottom) {
            if let fixedFooter {
                fixedFooter
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)
            }
        }
    }
}
