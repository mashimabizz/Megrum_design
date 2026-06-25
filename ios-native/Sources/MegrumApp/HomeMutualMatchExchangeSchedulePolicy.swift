import Foundation

extension HomeMutualMatchConditionPolicy {
    static func schedulesMatch(_ lhs: String, _ rhs: String) -> Bool {
        if isFlexibleSchedule(lhs) || isFlexibleSchedule(rhs) {
            return true
        }
        let lhsTokens = scheduleTokens(lhs)
        let rhsTokens = scheduleTokens(rhs)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else {
            return normalizedText(lhs) == normalizedText(rhs)
        }
        return !lhsTokens.isDisjoint(with: rhsTokens)
    }

    static func schedulesNeedDiscussion(_ lhs: String, _ rhs: String) -> Bool {
        if isFlexibleSchedule(lhs) || isFlexibleSchedule(rhs) {
            return true
        }
        let lhsTokens = scheduleTokens(lhs)
        let rhsTokens = scheduleTokens(rhs)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else {
            return normalizedText(lhs) != normalizedText(rhs)
        }
        return lhsTokens.intersection(rhsTokens).count != 1
    }

    static func isFlexibleSchedule(_ value: String) -> Bool {
        guard let normalized = normalizedText(value) else {
            return true
        }
        return normalized == normalizedText(IndividualListingExchangeSummary.defaultLocalSchedule)
    }

    static func scheduleTokens(_ value: String) -> Set<String> {
        Set(
            value
                .components(separatedBy: CharacterSet(charactersIn: "、,\n"))
                .compactMap(normalizedText)
        )
    }

    static func normalizedText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacing("　", with: "")
            .replacing(" ", with: "")
            .lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    static func normalizedSettingText(
        _ value: String?,
        emptyMarkers: Set<String>
    ) -> String? {
        guard let normalized = normalizedText(value) else {
            return nil
        }
        let normalizedMarkers = Set(emptyMarkers.compactMap(normalizedText))
        return normalizedMarkers.contains(normalized) ? nil : normalized
    }
}
