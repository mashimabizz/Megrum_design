import CoreGraphics

struct AppDrawerOverlayPresentationState: Equatable {
    var isClosing = false
    var isSuppressingDrawerItemTap = false

    var canSelectDestination: Bool {
        !isClosing && !isSuppressingDrawerItemTap
    }

    mutating func handlePresentationChange(isPresented: Bool) {
        if isPresented {
            isClosing = false
        }
    }

    mutating func beginClosing() -> Bool {
        guard !isClosing else {
            return false
        }
        isClosing = true
        return true
    }

    mutating func finishClosing() {
        isClosing = false
    }

    mutating func updateDrawerItemTapSuppression(translation: CGSize) {
        guard AppDrawerGestureResolver.shouldSuppressDrawerItemTap(translation: translation) else {
            return
        }
        isSuppressingDrawerItemTap = true
    }

    mutating func finishDrawerItemTapSuppression(translation: CGSize) -> Bool {
        guard AppDrawerGestureResolver.shouldSuppressDrawerItemTap(translation: translation) else {
            isSuppressingDrawerItemTap = false
            return false
        }
        isSuppressingDrawerItemTap = true
        return true
    }

    mutating func clearDrawerItemTapSuppression() {
        isSuppressingDrawerItemTap = false
    }
}
