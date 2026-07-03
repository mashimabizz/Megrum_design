import Foundation
import MegrumCore
import PhotosUI
import SwiftUI

struct TradeDetailPhotoPresentationState {
    var selectedEvidencePhotoItem: PhotosPickerItem?
    var selectedChatPhotoItem: PhotosPickerItem?
    var selectedOutfitPhotoItem: PhotosPickerItem?
    var isShowingEvidenceSourceDialog = false
    var isShowingEvidencePhotoLibraryPicker = false
    var isShowingChatPhotoLibraryPicker = false
    var isShowingOutfitPhotoLibraryPicker = false
    var isShowingEvidenceCamera = false
    var isShowingChatCamera = false
    var isShowingOutfitCamera = false

    mutating func showEvidenceSourceDialog() {
        isShowingEvidenceSourceDialog = true
    }

    mutating func showEvidencePhotoLibraryPicker() {
        isShowingEvidencePhotoLibraryPicker = true
    }

    mutating func showEvidenceCamera() {
        isShowingEvidenceCamera = true
    }

    mutating func clearEvidencePhotoItem() {
        selectedEvidencePhotoItem = nil
    }

    mutating func clearPhotoItem(for messageType: TradeMessageType) {
        switch messageType {
        case .outfitPhoto:
            selectedOutfitPhotoItem = nil
        case .photo:
            selectedChatPhotoItem = nil
        case .text, .location, .arrivalStatus, .system:
            break
        }
    }
}
