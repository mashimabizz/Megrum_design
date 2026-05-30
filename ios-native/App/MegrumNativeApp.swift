import MegrumApp
import SwiftUI

@main
struct MegrumNativeApp: App {
    var body: some Scene {
        WindowGroup {
            MegrumRootView(appState: MegrumAppStateFactory.makeDefault())
        }
    }
}
