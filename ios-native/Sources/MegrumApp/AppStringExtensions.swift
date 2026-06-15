extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var isBlank: Bool {
        nilIfBlank == nil
    }
}

extension Optional where Wrapped == String {
    var nilIfBlank: String? {
        flatMap(\.nilIfBlank)
    }

    var isBlank: Bool {
        nilIfBlank == nil
    }
}
