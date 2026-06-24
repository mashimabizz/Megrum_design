import Foundation
import MegrumCore

struct HomeMutualMatchPaymentEvaluation: Equatable {
    var signals: HomePaymentConditionSignals
    var attentionKinds: [HomeMutualMatchAttentionKind]
}

extension HomeMutualMatchConditionPolicy {
    static func paymentEvaluation(
        viewerMethods: [String],
        partnerMethods: [String],
        requiresPayment: Bool
    ) -> HomeMutualMatchPaymentEvaluation {
        guard requiresPayment else {
            return HomeMutualMatchPaymentEvaluation(
                signals: HomePaymentConditionSignals(
                    hasCompatiblePaymentMethod: true,
                    requiresPayment: false,
                    status: .skipped,
                    viewerMethods: paymentProfile(from: viewerMethods).rawMethods.orderedForDisplay,
                    partnerMethods: paymentProfile(from: partnerMethods).rawMethods.orderedForDisplay
                ),
                attentionKinds: []
            )
        }

        let viewer = paymentProfile(from: viewerMethods)
        let partner = paymentProfile(from: partnerMethods)
        let status: HomePaymentConditionStatus
        let attentionKind: HomeMutualMatchAttentionKind?

        switch (viewer.isUnset, partner.isUnset) {
        case (true, true):
            status = .unset
            attentionKind = .paymentUnset
        case (true, false):
            status = .viewerUnset
            attentionKind = .viewerPaymentUnset
        case (false, true):
            status = .partnerUnset
            attentionKind = .partnerPaymentUnset
        case (false, false) where !viewer.supportedMethods.isDisjoint(with: partner.supportedMethods):
            status = .compatible
            attentionKind = nil
        case (false, false) where viewer.isOtherOnly || partner.isOtherOnly:
            status = .needsDiscussion
            attentionKind = .paymentMethodNeedsDiscussion
        case (false, false):
            status = .methodMismatch
            attentionKind = .paymentMethodMismatch
        }

        return HomeMutualMatchPaymentEvaluation(
            signals: HomePaymentConditionSignals(
                hasCompatiblePaymentMethod: status == .compatible,
                requiresPayment: true,
                status: status,
                viewerMethods: viewer.rawMethods.orderedForDisplay,
                partnerMethods: partner.rawMethods.orderedForDisplay
            ),
            attentionKinds: attentionKind.map { [$0] } ?? []
        )
    }

    private struct PaymentProfile {
        var rawMethods: Set<UserPaymentMethod>
        var supportedMethods: Set<UserPaymentMethod>

        var isUnset: Bool {
            rawMethods.isEmpty
        }

        var isOtherOnly: Bool {
            rawMethods == [.other]
        }
    }

    private static func paymentProfile(from methods: [String]) -> PaymentProfile {
        let rawMethods = Set(methods.compactMap { method in
            UserPaymentMethod(rawValue: method.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        })
        return PaymentProfile(
            rawMethods: rawMethods,
            supportedMethods: rawMethods.filter(\.isHomeConditionTarget)
        )
    }
}

private extension Set where Element == UserPaymentMethod {
    var orderedForDisplay: [UserPaymentMethod] {
        UserPaymentMethod.allCases.filter { contains($0) }
    }
}
