import Foundation
import MegrumCore
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif

extension GoodsEditorSheet {
    func clearLocalPhotoSelection() {
        draft.clearLocalPhotoSelection()
        photoError = nil
        #if canImport(PhotosUI)
        selectedPhotoItem = nil
        #endif
    }

    func showDraftPhotoSourceDialog() {
        photoCaptureTarget = .draft
        isShowingPhotoSourceDialog = true
    }

    func showTradingCardBulkSourceDialog() {
        isShowingTradingCardBulkSourceDialog = true
    }

    func startTradingCardBulkCamera() {
        photoCaptureTarget = .tradingCardBulk
        isShowingCameraCapture = true
    }

    func showTradingCardBulkPhotoLibrary() {
        isShowingTradingCardBulkPhotoLibraryPicker = true
    }

    func removeWishPhoto() {
        guard draft.entryKind == .wish, !isItemReadOnly else {
            return
        }
        if isWishPhotoRemovalLocked {
            photoError = "この WISH は個別募集で使用中のため画像を削除できません（差し替えは可能）"
            return
        }
        draft.removeDisplayPhoto()
        photoError = nil
        #if canImport(PhotosUI)
        selectedPhotoItem = nil
        #endif
    }

    func loadCapturedCameraPhoto(_ data: Data) {
        if photoCaptureTarget == .tradingCardBulk {
            Task {
                await processTradingCardBulkImage(data)
            }
            return
        }

        let upload = GoodsPhotoUpload(data: data, contentType: "image/jpeg")
        if let uploadError = goodsEditorPhotoUploadError(for: upload) {
            if photoCaptureTarget == .draft {
                draft.clearLocalPhotoSelection()
            }
            photoError = uploadError
            createError = uploadError
            return
        }
        if photoCaptureTarget == .inventoryCreate {
            let photo = GoodsCreatePhotoDraft(upload: upload)
            createPhotos.append(photo)
            if createStep == .meta {
                syncCreateMetasWithPhotos()
            }
            analyzeFaceTagsIfNeeded(upload: upload, target: .createPhoto(photo.id))
            createError = nil
            photoError = nil
            return
        }
        draft.setLocalPhotoUpload(upload)
        analyzeFaceTagsIfNeeded(upload: upload, target: .draft)
        photoError = nil
        #if canImport(PhotosUI)
        selectedPhotoItem = nil
        #endif
    }

    #if canImport(PhotosUI)
    func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            draft.hasLocalPhoto = false
            draft.localPhotoData = nil
            draft.localPhotoContentType = nil
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                draft.hasLocalPhoto = false
                draft.localPhotoData = nil
                draft.localPhotoContentType = nil
                return
            }
            let upload = normalizedPhotoUpload(from: data)
            if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                draft.hasLocalPhoto = false
                draft.localPhotoData = nil
                draft.localPhotoContentType = nil
                photoError = uploadError
                return
            }
            draft.setLocalPhotoUpload(upload)
            analyzeFaceTagsIfNeeded(upload: upload, target: .draft)
            photoError = nil
        } catch {
            draft.hasLocalPhoto = false
            draft.localPhotoData = nil
            draft.localPhotoContentType = nil
            photoError = "写真を読み込めませんでした"
        }
    }

    func loadSelectedCreatePhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            return
        }

        var nextPhotos: [GoodsCreatePhotoDraft] = []
        var lastError: String?
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    lastError = "写真を読み込めませんでした"
                    continue
                }
                let upload = normalizedPhotoUpload(from: data)
                if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                    lastError = uploadError
                    continue
                }
                nextPhotos.append(GoodsCreatePhotoDraft(upload: upload))
            } catch {
                lastError = "写真を読み込めませんでした"
            }
        }

        if nextPhotos.isEmpty {
            createError = lastError ?? "写真を読み込めませんでした"
        } else {
            createPhotos.append(contentsOf: nextPhotos)
            if createStep == .meta {
                syncCreateMetasWithPhotos()
            }
            nextPhotos.forEach { photo in
                analyzeFaceTagsIfNeeded(upload: photo.upload, target: .createPhoto(photo.id))
            }
            createError = lastError
        }
        selectedCreatePhotoItems = []
    }

    func loadSelectedTradingCardBulkPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                createError = "写真を読み込めませんでした"
                selectedTradingCardBulkPhotoItem = nil
                return
            }
            await processTradingCardBulkImage(data)
        } catch {
            createError = "写真を読み込めませんでした"
        }
        selectedTradingCardBulkPhotoItem = nil
    }
    #endif

    func processTradingCardBulkImage(_ data: Data) async {
        guard isTradingCardType else {
            createError = "トレカ種別を選択した時だけAI一括登録を使えます"
            return
        }

        createError = nil
        tradingCardBulkStatusMessage = nil
        isProcessingTradingCardBulk = true
        defer {
            isProcessingTradingCardBulk = false
        }

        do {
            let upload = normalizedPhotoUpload(from: data)
            if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                createError = uploadError
                return
            }
            let frames = try await TradingCardBulkRecognizer.detectCropFrames(in: upload.data)
            cropSession = GoodsPhotoCropSession(
                source: .tradingCardBulk,
                upload: upload,
                initialFrames: frames
            )
            tradingCardBulkStatusMessage = frames.isEmpty
                ? "カード枠を検出できませんでした。写真上をドラッグして手動で切り取り枠を追加してください。"
                : "\(frames.count)件の候補を検出しました。黄色い枠を確認してから追加してください。"
        } catch {
            createError = error.localizedDescription
        }
    }
}
