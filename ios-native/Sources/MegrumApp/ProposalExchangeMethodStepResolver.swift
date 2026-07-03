enum ProposalExchangeMethodStepResolver {
    static func resolvedStepAfterExchangeMethodChange(
        currentStep: ProposalCreateStep,
        requiresMeetupBeforeSubmit: Bool,
        requiresShippingBeforeSubmit: Bool,
        requiresPaymentSelection: Bool
    ) -> ProposalCreateStep {
        var resolvedStep = currentStep
        if resolvedStep == .meetup && !requiresMeetupBeforeSubmit {
            resolvedStep = requiresShippingBeforeSubmit ? .shipping : .confirm
        }
        if resolvedStep == .shipping && !requiresShippingBeforeSubmit {
            resolvedStep = requiresMeetupBeforeSubmit ? .meetup : .confirm
        }
        if resolvedStep == .payment && !requiresPaymentSelection {
            resolvedStep = .confirm
        }
        return resolvedStep
    }
}
