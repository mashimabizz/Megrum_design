import Foundation
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI

extension GoodsEditorSheet {
    func dismissEditor() {
        dismiss()
    }

    func startSave() {
        Task {
            await save()
        }
    }

    func retrySave() {
        startSave()
    }

    func requestPhotoRemoval() {
        isShowingPhotoRemovalDialog = true
    }

    func requestInventoryDeleteConfirmation() {
        isConfirmingInventoryDelete = true
    }

    func startDeleteInventoryItem() {
        Task {
            await deleteInventoryItem()
        }
    }

    func startInventoryCreateCamera() {
        photoCaptureTarget = .inventoryCreate
        isShowingCameraCapture = true
    }

    func showInventoryCreatePhotoLibrary() {
        isShowingCreatePhotoLibraryPicker = true
    }

    func returnToCreateCommonStep() {
        createStep = .common
    }

    func returnFromCreateMetaStep() {
        createStep = createPhotos.isEmpty ? .common : .shoot
    }

    func startSaveInventoryCreateFlow() {
        guard !GoodsInventoryCreateValidation.hasMissingMemberAssignments(
            metas: createMetas,
            requiresMemberAssignment: inventoryCreateAllowsMemberAssignment
        ) else {
            createError = "メンバーがある推しは、すべての画像にメンバーを登録してください"
            return
        }
        if GoodsInventoryCreateValidation.hasMissingTags(metas: createMetas) {
            isConfirmingInventoryCreateWithoutTags = true
            return
        }
        Task {
            await saveInventoryCreateFlow()
        }
    }

    func handleSelectedGroupChange(_ groupID: UUID?) {
        resetCreateMetaMembers()
        Task {
            await loadMembers(for: groupID)
        }
    }

    func clearTransientEditorFeedback() {
        lastSaveFailure = nil
        createError = nil
    }

    #if canImport(PhotosUI)
    func handleSelectedPhotoItemChange(_ item: PhotosPickerItem?) {
        Task {
            await loadSelectedPhoto(item)
        }
    }

    func handleSelectedCreatePhotoItemsChange(_ items: [PhotosPickerItem]) {
        Task {
            await loadSelectedCreatePhotos(items)
        }
    }

    func handleSelectedTradingCardBulkPhotoItemChange(_ item: PhotosPickerItem?) {
        Task {
            await loadSelectedTradingCardBulkPhoto(item)
        }
    }
    #endif
}
