import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriUserProfileRoute: Identifiable, Equatable {
    var userID: UUID
    var id: UUID { userID }
}

struct MeguriUserProfileRouteScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var onClose: () -> Void
    var onOpenMessage: (UUID) -> Void
    @State private var hasLoadedIdentity = false

    var body: some View {
        Group {
            if shouldShowPublicProfile {
                PublicUserProfileScreen(
                    appState: appState,
                    userID: userID,
                    adDisplayContext: adDisplayContext,
                    adPlacement: .publicProfileFooterBanner
                )
            } else if hasLoadedIdentity || appState.meguriProfile(for: userID) != nil {
                MeguriUserProfileSummaryScreen(
                    appState: appState,
                    userID: userID,
                    onClose: onClose,
                    onOpenMessage: onOpenMessage
                )
            } else {
                MeguriUserProfileLoadingScreen(onClose: onClose)
            }
        }
        .task(id: userID) {
            await loadIdentity()
        }
    }

    private var shouldShowPublicProfile: Bool {
        appState.meguriProfile(for: userID)?.usesPublicProfile == true
    }

    private func loadIdentity() async {
        if userID == appState.viewer?.id {
            await appState.loadMeguriProfile(reportsFailure: false)
            if appState.userOshiSelections.isEmpty {
                await appState.loadUserOshiSelections()
            }
        } else {
            await appState.loadMeguriProfiles(userIDs: [userID], reportsFailure: false)
        }
        if appState.publicProfilesByUserID[userID] == nil {
            await appState.loadPublicUserProfile(userID: userID, reportsFailure: false)
        }
        hasLoadedIdentity = true
    }
}

private struct MeguriUserProfileSummaryScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var onClose: () -> Void
    var onOpenMessage: (UUID) -> Void

    private var identity: MeguriProfileIdentity {
        appState.meguriIdentity(for: userID)
    }

    private var isViewer: Bool {
        appState.viewer?.id == userID
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProfileVisualHero(
                    displayName: identity.displayName,
                    handle: "",
                    bio: "",
                    avatarURL: identity.avatarURL,
                    tradeCount: "",
                    ratingText: "",
                    chips: [],
                    tagItems: oshiTags,
                    tagSize: .compact,
                    avatarSize: 94,
                    density: .compact,
                    showsStats: false,
                    actionTitle: "メッセージを送る",
                    showsAction: !isViewer,
                    isPrimaryAction: true,
                    onAction: { onOpenMessage(userID) }
                )
                .padding(18)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.74), lineWidth: 1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 32)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("めぐりプロフィール")
        .megrumInlineNavigationTitle()
        .megrumVisibleNavigationBar()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる", action: onClose)
            }
        }
    }

    private var oshiTags: [ProfileVisualTagItem] {
        if isViewer {
            return OwnProfileOshiTagPresentation.tagItems(from: appState.userOshiSelections)
        }
        let tags = appState.publicProfilesByUserID[userID]?.oshiTags ?? []
        return tags.map { tag in
            ProfileVisualTagItem(title: tag.title, colorKey: tag.colorKey)
        }
    }
}

private struct MeguriUserProfileLoadingScreen: View {
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text("プロフィールを読み込んでいます")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("めぐりプロフィール")
        .megrumInlineNavigationTitle()
        .megrumVisibleNavigationBar()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる", action: onClose)
            }
        }
    }
}
