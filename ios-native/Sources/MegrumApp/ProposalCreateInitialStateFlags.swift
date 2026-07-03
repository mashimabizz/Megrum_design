import Foundation

struct ProposalCreateInitialStateFlags: Equatable, Sendable {
    private(set) var hasAppliedExchangeMethod = false
    private(set) var hasAppliedInitialStep = false
    private(set) var hasAppliedVisualQAState = false

    mutating func claimExchangeMethodApplication() -> Bool {
        guard !hasAppliedExchangeMethod else {
            return false
        }
        hasAppliedExchangeMethod = true
        return true
    }

    mutating func claimVisualQAStateApplication() -> Bool {
        guard !hasAppliedVisualQAState else {
            return false
        }
        hasAppliedVisualQAState = true
        return true
    }

    mutating func canApplyInitialStep() -> Bool {
        !hasAppliedInitialStep
    }

    mutating func markInitialStepApplied() {
        hasAppliedInitialStep = true
    }
}
