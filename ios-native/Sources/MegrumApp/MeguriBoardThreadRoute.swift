import Foundation
import MegrumCore

struct MeguriBoardThreadRoute: Identifiable {
    var thread: BoardThread
    var selectedPrefecture: String?
    var coordinate: MegrumLocationCoordinate?

    var id: UUID { thread.id }
}
