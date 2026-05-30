import Foundation

public struct SupabaseConfiguration: Equatable, Sendable {
    public var projectURL: URL
    public var publishableKey: String
    public var accessToken: String?

    public init(projectURL: URL, publishableKey: String, accessToken: String? = nil) {
        self.projectURL = projectURL
        self.publishableKey = publishableKey
        self.accessToken = accessToken
    }

    public static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> SupabaseConfiguration? {
        make(
            urlString: environment["MEGRUM_SUPABASE_URL"]
                ?? environment["EXPO_PUBLIC_SUPABASE_URL"]
                ?? environment["NEXT_PUBLIC_SUPABASE_URL"],
            publishableKey: environment["MEGRUM_SUPABASE_PUBLISHABLE_KEY"]
                ?? environment["EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY"]
                ?? environment["NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"],
            accessToken: environment["MEGRUM_SUPABASE_ACCESS_TOKEN"]
        )
    }

    public static func fromInfoDictionary(_ infoDictionary: [String: Any]? = Bundle.main.infoDictionary) -> SupabaseConfiguration? {
        make(
            urlString: infoDictionary?["MegrumSupabaseURL"] as? String,
            publishableKey: infoDictionary?["MegrumSupabasePublishableKey"] as? String,
            accessToken: nil
        )
    }

    private static func make(
        urlString: String?,
        publishableKey: String?,
        accessToken: String?
    ) -> SupabaseConfiguration? {
        guard
            let rawURL = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
            let key = publishableKey?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawURL.isEmpty,
            !key.isEmpty,
            let url = URL(string: rawURL)
        else {
            return nil
        }

        let token = accessToken?.trimmingCharacters(in: .whitespacesAndNewlines)
        return SupabaseConfiguration(
            projectURL: url,
            publishableKey: key,
            accessToken: token?.isEmpty == false ? token : nil
        )
    }
}
