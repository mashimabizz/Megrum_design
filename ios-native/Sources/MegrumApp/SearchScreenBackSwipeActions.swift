import Foundation
import SwiftUI

extension SearchScreen {
    var searchBackSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard SearchBackSwipeResolver.shouldDismiss(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    isSuppressedByNestedHorizontalScroll: SearchBackSwipeResolver.isSuppressedByNestedHorizontalScroll(
                        lastNestedHorizontalScrollDate: lastWishSuggestionHorizontalScrollDate
                    )
                ) else {
                    return
                }
                dismiss()
            }
    }

    func markWishSuggestionHorizontalScroll() {
        lastWishSuggestionHorizontalScrollDate = Date()
    }
}
