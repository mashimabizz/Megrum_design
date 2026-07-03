import SwiftUI

extension MeguriScreen {
    func resetToHome() {
        pendingCreatedThread = nil
        selectedGroom = nil
        selectedGroomPhotoItem = nil
        resetGroomDraft()
        isShowingGroomComposer = false
        isShowingGroomCamera = false
        isShowingGroomArchive = false
        isShowingMeguriProfileSettings = false
        activeMap = nil
        isShowingThreadComposer = false
        threadCreationCoordinate = nil
        pendingMapCreationCoordinate = nil
        isShowingPrefecturePicker = false
        isShowingOutOfRangeAlert = false
        boardSheetDetent = .compact
        withAnimation(.smooth(duration: 0.18)) {
            toastMessage = nil
        }
    }
}
