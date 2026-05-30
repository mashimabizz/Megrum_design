import Foundation
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
        if
            let configuration = SupabaseConfiguration.fromEnvironment(environment),
            let viewerID = viewerID(from: environment)
        {
            return liveState(configuration: configuration, viewerID: viewerID)
        }

        if
            let configuration = SupabaseConfiguration.fromInfoDictionary(infoDictionary),
            let viewerID = viewerID(from: infoDictionary)
        {
            return liveState(configuration: configuration, viewerID: viewerID)
        }

        return MegrumAppState(repository: PreviewMegrumRepository())
    }

    private static func viewerID(from environment: [String: String]) -> UUID? {
        environment["MEGRUM_SUPABASE_VIEWER_ID"].flatMap(UUID.init(uuidString:))
    }

    private static func viewerID(from infoDictionary: [String: Any]?) -> UUID? {
        (infoDictionary?["MegrumSupabaseViewerID"] as? String).flatMap(UUID.init(uuidString:))
    }

    @MainActor
    private static func liveState(configuration: SupabaseConfiguration, viewerID: UUID) -> MegrumAppState {
        MegrumAppState(
            repository: SupabaseMegrumRepository(
                client: SupabaseRESTClient(configuration: configuration),
                viewerID: viewerID
            )
        )
    }
}
