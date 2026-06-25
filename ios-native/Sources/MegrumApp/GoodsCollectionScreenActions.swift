import SwiftUI

extension GoodsCollectionScreen {
    func openAddForm() {
        if appState == nil {
            isShowingUnavailableAlert = true
        } else {
            editorRoute = .create(entryKind)
        }
    }
}
