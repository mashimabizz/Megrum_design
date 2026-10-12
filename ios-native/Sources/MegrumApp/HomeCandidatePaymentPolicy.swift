import Foundation
import MegrumCore

enum HomeCandidatePaymentPolicy {
    static func signals(
        viewerMethods: [String]?,
        partnerMethods: [String]?,
        viewerBankNames: [String] = [],
        partnerBankNames: [String] = []
    ) -> HomePaymentConditionSignals {
        signals(
            viewerMethods: viewerMethods,
            partnerMethodsList: [partnerMethods],
            viewerBankNames: viewerBankNames,
            partnerBankNames: partnerBankNames
        )
    }

    static func signals(
        viewerMethods: [String]?,
        partnerMethodsList: [[String]?],
        viewerBankNames: [String] = [],
        partnerBankNames: [String] = []
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
        } else if partners.contains(where: { viewer.hasSharedSupportedMethod(with: $0) }) {
            status = .compatible
        } else if partners.contains(where: { viewer.hasOnlyOtherInCommon(with: $0) }) {
            status = .needsDiscussion
        } else {
            status = .methodMismatch
        }

        return HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: status == .compatible,
            status: status,
            viewerMethods: methods(viewer.rawMethods),
            partnerMethods: methods(Set(partners.flatMap(\.rawMethods))),
            partnerBankNames: partnerBankNames,
            viewerBankNames: viewerBankNames
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

        func hasSharedSupportedMethod(with other: PaymentProfile) -> Bool {
            !supportedMethods.isDisjoint(with: other.supportedMethods)
        }

        func hasOnlyOtherInCommon(with other: PaymentProfile) -> Bool {
            rawMethods.intersection(other.rawMethods) == ["other"]
        }
    }
}
