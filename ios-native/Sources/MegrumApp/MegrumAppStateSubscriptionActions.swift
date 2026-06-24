import Foundation
import MegrumCore

@MainActor
public extension MegrumAppState {
    func loadSubscriptionState(reportsFailure: Bool = true) async {
        guard !isLoadingSubscriptionState else {
            return
        }

        isLoadingSubscriptionState = true
        do {
            subscriptionState = try await repository.loadSubscriptionState()
        } catch {
            subscriptionState = .free
            if reportsFailure {
                errorMessage = "課金プランを確認できませんでした"
            }
        }
        isLoadingSubscriptionState = false
    }
}
