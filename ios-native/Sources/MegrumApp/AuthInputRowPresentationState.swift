struct AuthInputRowPresentationState: Equatable {
    var showsPassword = false

    var passwordVisibilityIconName: String {
        showsPassword ? "eye.slash" : "eye"
    }

    mutating func togglePasswordVisibility() {
        showsPassword.toggle()
    }

    func usesSecureInput(for kind: AuthInputRow.FieldKind) -> Bool {
        kind == .password && !showsPassword
    }
}
