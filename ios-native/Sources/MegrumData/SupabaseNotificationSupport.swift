import Foundation

func notificationISOTimestamp(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
}

extension String {
    var normalizedNativeDeviceToken: String {
        SupabaseTextNormalizer.trimmed(self)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .lowercased()
    }
}
