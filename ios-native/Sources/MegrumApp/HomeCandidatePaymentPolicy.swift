import Foundation
import MegrumCore

enum HomeCandidatePaymentPolicy {
    static func signals(
        viewerMethods: [String]?,
        partnerMethods: [String]?
    ) -> HomePaymentConditionSignals {
        signals(
            viewerMethods: viewerMethods,
            partnerMethodsList: [partnerMethods]
        )
    }

    static func signals(
        viewerMethods: [String]?,
        partnerMethodsList: [[String]?]
    ) -> HomePaymentConditionSignals {
        let viewer = paymentProfile(from: viewerMethods)
        let partners = partnerMethodsList.map(paymentProfile(from:))
        guard !partners.isEmpty else {
            return .none
        }

        let status: HomePaymentConditionStatus
        if viewer.isUnset {
            status = partners.allSatisfy(\.isUnset) ? .unset : .viewerUnset
        } else if partners.contains(where: \.isUnset) {
            status = .partnerUnset
        } else if partners.contains(where: { !viewer.supportedMethods.isDisjoint(with: $0.supportedMethods) }) {
            status = .compatible
        } else if viewer.isOtherOnly || partners.contains(where: \.isOtherOnly) {
            status = .needsDiscussion
        } else {
            status = .methodMismatch
        }

        return HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: status == .compatible,
            status: status,
            viewerMethods: methods(viewer.rawMethods),
            partnerMethods: methods(Set(partners.flatMap(\.rawMethods)))
        )
    }

    static func methods(_ values: [String]) -> [UserPaymentMethod] {
        let normalizedValues = Set(values.map { $0.lowercased() })
        return UserPaymentMethod.allCases.filter { method in
            normalizedValues.contains(method.rawValue)
        }
    }

    private static func methods(_ values: Set<String>) -> [UserPaymentMethod] {
        UserPaymentMethod.allCases.filter { method in
            values.contains(method.rawValue)
        }
    }

    private static func paymentProfile(from methods: [String]?) -> PaymentProfile {
        let rawMethods = Set((methods ?? []).compactMap { value -> String? in
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch normalized {
            case "bank_transfer", "paypay", "cash_exchange", "other":
                return normalized
            default:
                return nil
            }
        })
        let supported: Set<String> = ["bank_transfer", "paypay", "cash_exchange"]
        return PaymentProfile(
            rawMethods: rawMethods,
            supportedMethods: rawMethods.intersection(supported)
        )
    }

    private struct PaymentProfile {
        var rawMethods: Set<String>
        var supportedMethods: Set<String>

        var isUnset: Bool {
            rawMethods.isEmpty
        }

        var isOtherOnly: Bool {
            rawMethods == ["other"]
        }
    }
}
