import MegrumDesign
import SwiftUI

@MainActor
struct PrivacySettingsScreen: View {
    @ObservedObject var appState: MegrumAppState

    var body: some View {
        PrivacySettingsContent(appState: appState)
        .navigationTitle("プライバシーと安全")
        .megrumInlineNavigationTitle()
    }
}
