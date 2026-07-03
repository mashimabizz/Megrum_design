enum ProposalPaymentOptionSelectionResolver {
    static func resolvedSelectionID(
        currentID: String?,
        requiresPaymentStep: Bool,
        options: [ProposalPaymentOption]
    ) -> String? {
        guard requiresPaymentStep, !options.isEmpty else {
            return nil
        }
        if let currentID, options.contains(where: { $0.id == currentID }) {
            return currentID
        }
        return options.first?.id
    }
}
