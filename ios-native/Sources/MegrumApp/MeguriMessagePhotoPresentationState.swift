import Foundation
import PhotosUI
import SwiftUI

struct MeguriMessagePhotoPresentationState {
    var selectedPhotoItem: PhotosPickerItem?
    var isShowingPhotoLibraryPicker = false
    var isShowingCamera = false
    var selectedRemoteImage: RemoteImageSelection?

    mutating func clearSelectedPhotoItem() {
        selectedPhotoItem = nil
    }

    mutating func selectRemoteImage(_ url: URL) {
        selectedRemoteImage = RemoteImageSelection(url: url)
    }

    mutating func clearSelectedRemoteImage() {
        selectedRemoteImage = nil
    }
}
