struct GoodsEditorImageSeriesSuggestionState {
    var names: [String] = []
    var isLoading = false
    var errorMessage: String?

    mutating func reset() {
        names = []
        isLoading = false
        errorMessage = nil
    }
}
