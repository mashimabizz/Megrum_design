struct AuthVisualFeedback: Equatable {
    enum Style {
        case error
        case success
        case info
    }

    var message: String
    var style: Style
}
