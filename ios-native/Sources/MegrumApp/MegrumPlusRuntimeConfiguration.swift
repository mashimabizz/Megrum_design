import Foundation

struct MegrumPlusRuntimeConfiguration: Equatable, Sendable {
    var isIAPEnabled: Bool

    static let disabled = MegrumPlusRuntimeConfiguration(isIAPEnabled: false)

    static func current(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary
    ) -> MegrumPlusRuntimeConfiguration {
        MegrumPlusRuntimeConfiguration(
            isIAPEnabled: bool(
                environment["MEGRUM_PLUS_IAP_ENABLED"]
                    ?? infoDictionary?["MegrumPlusIAPEnabled"] as? String
            )
        )
    }

    private static func bool(_ value: String?) -> Bool {
        switch cleaned(value)?.lowercased() {
        case "1", "true", "yes", "on":
            true
        default:
            false
        }
    }

    private static func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty, !trimmed.contains("$(") else {
            return nil
        }
        return trimmed
    }
}
