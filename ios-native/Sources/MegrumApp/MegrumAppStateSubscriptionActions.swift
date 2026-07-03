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

    func applyVerifiedMegrumPlusPurchase(_ purchase: MegrumPlusPurchaseSyncInput) async throws {
        do {
            subscriptionState = try await repository.syncMegrumPlusPurchase(purchase)
        } catch {
            subscriptionState = locallyAppliedMegrumPlusPurchase(purchase)
            throw error
        }
    }

    private func locallyAppliedMegrumPlusPurchase(_ purchase: MegrumPlusPurchaseSyncInput) -> UserSubscriptionState {
        var next = subscriptionState
        next.planType = .megrumPlusMonthly
        next.status = .active
        next.currentPeriodEnd = purchase.expiresAt
        next.loadedAt = purchase.verifiedAt
        next.entitlements.removeAll { $0.key == .megrumPlus }
        next.entitlements.append(
            UserEntitlement(
                key: .megrumPlus,
                isActive: true,
                source: .purchase,
                grantedAt: purchase.verifiedAt,
                expiresAt: purchase.expiresAt,
                updatedAt: purchase.verifiedAt
            )
        )
        return next
    }

#if DEBUG
    func debugToggleMegrumPremiumEntitlement(now: Date = Date()) {
        if subscriptionState.isMegrumPlusActive {
            var next = subscriptionState
            next.planType = nil
            next.status = nil
            next.currentPeriodEnd = nil
            next.entitlements.removeAll { $0.key == .megrumPlus }
            next.loadedAt = now
            subscriptionState = next
            return
        }

        var next = subscriptionState
        next.planType = .megrumPlusMonthly
        next.status = .active
        next.currentPeriodEnd = nil
        next.entitlements.removeAll { $0.key == .megrumPlus }
        next.entitlements.append(
            UserEntitlement(
                key: .megrumPlus,
                isActive: true,
                source: .manualOverride,
                grantedAt: now,
                updatedAt: now
            )
        )
        next.loadedAt = now
        subscriptionState = next
    }
#endif
}
