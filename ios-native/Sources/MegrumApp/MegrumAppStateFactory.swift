import Foundation
import MegrumCore
import MegrumData

public enum MegrumAppStateFactory {
    @MainActor
    public static func makeDefault() -> MegrumAppState {
        make(environment: ProcessInfo.processInfo.environment, infoDictionary: Bundle.main.infoDictionary)
    }

    @MainActor
    public static func make(
        environment: [String: String],
        infoDictionary: [String: Any]? = nil
    ) -> MegrumAppState {
        MegrumAppState(repository: repository(environment: environment, infoDictionary: infoDictionary))
    }

    public static func repository(
        authSession: AuthSession? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary
    ) -> any MegrumRepository {
        if VisualQAPreviewMode.isEnabled(environment: environment) {
            return PreviewMegrumRepository()
        }

        if let authSession {
            if let configuration = SupabaseConfiguration.fromEnvironment(environment) {
                return liveRepository(configuration: configuration.withAccessToken(authSession.accessToken), viewerID: authSession.user.id)
            }

            if let configuration = SupabaseConfiguration.fromInfoDictionary(infoDictionary) {
                return liveRepository(configuration: configuration.withAccessToken(authSession.accessToken), viewerID: authSession.user.id)
            }
        }

        if
            let configuration = SupabaseConfiguration.fromEnvironment(environment),
            let viewerID = viewerID(from: environment)
        {
            return liveRepository(configuration: configuration, viewerID: viewerID)
        }

        if
            let configuration = SupabaseConfiguration.fromInfoDictionary(infoDictionary),
            let viewerID = viewerID(from: infoDictionary)
        {
            return liveRepository(configuration: configuration, viewerID: viewerID)
        }

        return PreviewMegrumRepository()
    }

    private static func viewerID(from environment: [String: String]) -> UUID? {
        environment["MEGRUM_SUPABASE_VIEWER_ID"].flatMap(UUID.init(uuidString:))
    }

    private static func viewerID(from infoDictionary: [String: Any]?) -> UUID? {
        (infoDictionary?["MegrumSupabaseViewerID"] as? String).flatMap(UUID.init(uuidString:))
    }

    private static func liveRepository(configuration: SupabaseConfiguration, viewerID: UUID) -> any MegrumRepository {
        SupabaseMegrumRepository(
            client: SupabaseRESTClient(configuration: configuration),
            viewerID: viewerID
        )
    }
}
