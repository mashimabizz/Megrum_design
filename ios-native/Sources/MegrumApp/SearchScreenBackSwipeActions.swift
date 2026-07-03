import Foundation
import SwiftUI

extension SearchScreen {
    var searchBackSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard SearchBackSwipeResolver.shouldDismiss(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    isSuppressedByNestedHorizontalScroll: presentationState.isBackSwipeSuppressed()
                ) else {
                    return
                }
                closeSearch()
            }
    }

    func closeSearch() {
        if let onDismissRequest {
            onDismissRequest()
        } else {
            dismiss()
        }
    }

    func markWishSuggestionHorizontalScroll() {
        presentationState.markWishSuggestionHorizontalScroll()
    }
}
