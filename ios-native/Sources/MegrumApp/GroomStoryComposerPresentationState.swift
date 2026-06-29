import Foundation
import MegrumCore

struct GroomStoryComposerPresentationState: Equatable {
    var captionText = ""
    var textOverlays: [GroomStoryTextOverlay] = []
    var toastMessage: String?
    var toastID = UUID()

    var captionForPublish: String? {
        let overlayCaption = textOverlays
            .map(\.text)
            .joined(separator: "\n")
            .nilIfBlank
        return overlayCaption ?? captionText.nilIfBlank
    }

    mutating func clearCaptionAfterPhotoReset() {
        captionText = ""
        textOverlays = []
    }

    mutating func showToast(_ message: String, toastID: UUID = UUID()) {
        self.toastID = toastID
        toastMessage = message
    }

    mutating func clearToast(ifMatching toastID: UUID) {
        guard self.toastID == toastID else {
            return
        }
        toastMessage = nil
    }
}
