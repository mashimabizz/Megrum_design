import Foundation

struct ProposalCreateInitialStateFlags: Equatable, Sendable {
    private(set) var hasAppliedExchangeMethod = false
    private(set) var hasAppliedInitialStep = false
    private(set) var hasAppliedVisualQAState = false
    private(set) var hasAppliedInitialMessage = false
    private(set) var hasAppliedInitialMeetup = false
    private(set) var hasAppliedInitialCash = false

    mutating func claimExchangeMethodApplication() -> Bool {
        guard !hasAppliedExchangeMethod else {
            return false
        }
        hasAppliedExchangeMethod = true
        return true
    }

    mutating func claimInitialMessageApplication() -> Bool {
        guard !hasAppliedInitialMessage else {
            return false
        }
        hasAppliedInitialMessage = true
        return true
    }

    mutating func claimInitialMeetupApplication() -> Bool {
        guard !hasAppliedInitialMeetup else {
            return false
        }
        hasAppliedInitialMeetup = true
        return true
    }

    mutating func claimInitialCashApplication() -> Bool {
        guard !hasAppliedInitialCash else {
            return false
        }
        hasAppliedInitialCash = true
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
