extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
