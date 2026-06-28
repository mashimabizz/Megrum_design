import SwiftUI

private struct MegrumBackSwipeHandledBySlidePresentationKey: EnvironmentKey {
    static let defaultValue = false
}

struct MegrumSlidePresentationDismissAction: Sendable {
    var action: @MainActor @Sendable () -> Void

    @MainActor
    func callAsFunction() {
        action()
    }
}

private struct MegrumSlidePresentationDismissKey: EnvironmentKey {
    static let defaultValue: MegrumSlidePresentationDismissAction? = nil
}

extension EnvironmentValues {
    var megrumBackSwipeHandledBySlidePresentation: Bool {
        get { self[MegrumBackSwipeHandledBySlidePresentationKey.self] }
        set { self[MegrumBackSwipeHandledBySlidePresentationKey.self] = newValue }
    }

    var megrumSlidePresentationDismiss: MegrumSlidePresentationDismissAction? {
        get { self[MegrumSlidePresentationDismissKey.self] }
        set { self[MegrumSlidePresentationDismissKey.self] = newValue }
    }
}
