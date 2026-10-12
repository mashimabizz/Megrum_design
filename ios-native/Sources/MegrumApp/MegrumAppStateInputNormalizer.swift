import Foundation
import MegrumData

enum MegrumAppStateInputNormalizer {
    static func trimmedText(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func optionalText(_ value: String?) -> String? {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalized.isEmpty ? nil : normalized
    }

    static func prefecture(_ value: String?) -> String? {
        optionalText(value)
    }

    static func goodsQuantity(_ quantity: Int) -> Int {
        max(1, min(quantity, 999))
    }

    static func tagNames(_ tagNames: [String]) -> [String] {
        tagNames.reduce(into: []) { result, raw in
            guard result.count < 5 else {
                return
            }
            let normalized = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else {
                return
            }
            let clipped = String(normalized.prefix(50))
            if !result.contains(where: { $0.caseInsensitiveCompare(clipped) == .orderedSame }) {
                result.append(clipped)
            }
        }
    }

    static func photoURLs(_ photoURLs: [String]) -> [String] {
        photoURLs.reduce(into: []) { result, raw in
            let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard result.count < 6,
                  let url = URL(string: normalized),
                  url.scheme?.isEmpty == false,
                  url.host?.isEmpty == false
            else {
                return
            }
            let value = url.absoluteString
            if !result.contains(value) {
                result.append(value)
            }
        }
    }

    static func profileHandle(_ handle: String) -> String? {
        var normalized = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.first == "@" {
            normalized.removeFirst()
        }
        return normalized.isEmpty ? nil : normalized
    }

    static func isValidProfileHandle(_ handle: String) -> Bool {
        handle.range(of: #"^[a-z0-9_]{3,20}$"#, options: .regularExpression) != nil
    }

    static func accountSetupHandle(_ handle: String, userID: UUID?) -> String? {
        // iter1226.422：ユーザーが打った有効なIDはそのまま使う（megrum等を勝手に
        // megrum_xxxx へ差し替えない）。重複はDB照会でNG＋候補提示する。
        if let normalized = profileHandle(handle), isValidProfileHandle(normalized) {
            return normalized
        }
        guard let userID else {
            return nil
        }
        return generatedProfileHandle(userID: userID)
    }

    static func accountSetupDisplayName(_ displayName: String, fallbackHandle: String) -> String {
        let normalized = trimmedText(displayName)
        if !normalized.isEmpty, !isGeneratedPlaceholderDisplayName(normalized) {
            return String(normalized.prefix(50))
        }
        if !isGeneratedPlaceholderHandle(fallbackHandle) {
            return String(fallbackHandle.prefix(50))
        }
        return "Megrumユーザー"
    }

    static func generatedProfileHandle(userID: UUID) -> String {
        let stableID = userID.uuidString
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
        return "megrum_\(stableID.prefix(12))"
    }

    private static func isGeneratedPlaceholderHandle(_ handle: String) -> Bool {
        handle == "megrum" || handle == "unknown" || handle.hasPrefix("megrum_")
    }

    private static func isGeneratedPlaceholderDisplayName(_ displayName: String) -> Bool {
        displayName == "Megrum" || displayName == "unknown"
    }

    static func postalCode(_ value: String) -> String {
        PostalCodeAddressClient.normalizedPostalCode(value)
    }
}
