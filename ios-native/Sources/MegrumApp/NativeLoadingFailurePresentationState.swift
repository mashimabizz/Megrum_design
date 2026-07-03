struct NativeLoadingFailurePresentationState: Equatable {
    var isRetrying = false
    var isSigningOut = false

    var retryTitle: String {
        isRetrying ? "再読み込み中" : "再読み込み"
    }

    var signOutTitle: String {
        isSigningOut ? "ログアウト中" : "ログアウトしてやり直す"
    }

    var actionsDisabled: Bool {
        isRetrying || isSigningOut
    }

    mutating func beginRetry() {
        isRetrying = true
    }

    mutating func finishRetry() {
        isRetrying = false
    }

    mutating func beginSignOut() {
        isSigningOut = true
    }

    mutating func finishSignOut() {
        isSigningOut = false
    }
}
