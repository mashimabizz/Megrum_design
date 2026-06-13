import MegrumCore
import MegrumDesign
import SwiftUI

enum HomeMatchShelfKind: Equatable {
    case matched
    case possible
}

enum HomeGoodsPanelDestination: Equatable {
    case relation(ProposalMatchType)
}

enum HomeGoodsPanelRouteResolver {
    static func destination(for shelfKind: HomeMatchShelfKind) -> HomeGoodsPanelDestination {
        switch shelfKind {
        case .matched:
            .relation(.perfect)
        case .possible:
            .relation(.forward)
        }
    }
}

enum HomeGroomRailPolicy {
    static let isVisibleOnHome = false
}

enum HomeRelationVisualQARouteResolver {
    static func targetItem(candidates: [GoodsItem], viewerID: UUID?) -> GoodsItem? {
        candidates.first { item in
            guard let viewerID else {
                return false
            }
            return item.ownerID != viewerID
        } ?? candidates.first
    }
}

struct HomeRelationRoute: Identifiable, Equatable {
    var item: GoodsItem
    var matchType: ProposalMatchType

    var id: UUID { item.id }
}

@MainActor
struct HomeScreen: View {
    var viewer: UserProfile?
    var matchedItems: [GoodsItem]
    var possibleItems: [GoodsItem]
    var isLoading: Bool
    @Binding var showsSearch: Bool
    var onRefresh: () async -> Void
    var appState: MegrumAppState? = nil
    var onOpenSettings: () -> Void = {}
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }
    var onOpenMeguri: (() -> Void)? = nil
    var onOpenTrades: (() -> Void)? = nil
    var visualQAInitialScreen: VisualQAInitialScreen? = nil

    @AppStorage("megrum.home.localMode.activityWindowID") private var localModeActivityWindowID = ""
    @AppStorage("megrum.home.localMode.enabled") private var localModeEnabled = false
    @AppStorage("megrum.home.localMode.venue") private var localModeVenue = ""
    @AppStorage("megrum.home.localMode.latitude") private var localModeLatitude = ""
    @AppStorage("megrum.home.localMode.longitude") private var localModeLongitude = ""
    @AppStorage("megrum.home.localMode.startedAt") private var localModeStartedAt = 0.0
    @AppStorage("megrum.home.localMode.durationMinutes") private var localModeDurationMinutes = HomeLocalActivitySettings.defaultDurationMinutes
    @AppStorage("megrum.home.localMode.radiusMeters") private var localModeRadiusMeters = HomeLocalActivitySettings.defaultRadiusMeters
    @AppStorage("megrum.home.localMode.selectedCarryingIDs") private var localModeSelectedCarryingIDs = ""
    @State private var loadedLocalActivitySettings: HomeLocalActivitySettings?
    @State private var showsLocalModeSettings = false
    @State private var relationRoute: HomeRelationRoute?
    @State private var didOpenVisualQAInitialRoute = false

    var body: some View {
        HomeDiscoveryExperience(
            viewer: viewer,
            inventoryItems: appState?.inventory ?? [],
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            goodsTypes: appState?.goodsTypes ?? [],
            conditionSignalsByItemID: appState?.homeCandidateConditionSignals ?? [:],
            isLoading: isLoading,
            opensInitialHavesLookup: visualQAInitialScreen == .homeHavesLookup,
            onOpenSettings: onOpenSettings,
            onOpenSearch: {
                showsSearch = true
            },
            onRefresh: {
                await onRefresh()
                await loadLocalActivitySettings()
            }
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .sheet(isPresented: $showsLocalModeSettings) {
            HomeLocalModeSettingsSheet(
                viewer: viewer,
                settings: localActivitySettings,
                carryingCandidates: localCarryingCandidates,
                onSave: saveLocalActivitySettings
            )
        }
        .homeRelationPresentation(item: $relationRoute) { route in
            if let relationState = localModeState {
                NavigationStack {
                    MatchRelationScreen(
                        appState: relationState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            relationRoute = nil
                            if action == .openTrades {
                                onOpenTrades?()
                            }
                        }
                    )
                }
            }
        }
        .task(id: viewer?.id) {
            await loadLocalActivitySettings()
            openVisualQAInitialRouteIfNeeded()
        }
        .onChange(of: matchedItems.map(\.id), initial: true) { _, _ in
            openVisualQAInitialRouteIfNeeded()
        }
    }

    private var localActivitySettings: HomeLocalActivitySettings {
        localModeState?.homeLocalModeSettings ?? loadedLocalActivitySettings ?? localStorageActivitySettings
    }

    private var localStorageActivitySettings: HomeLocalActivitySettings {
        HomeLocalActivitySettings(
            activityWindowID: UUID(uuidString: localModeActivityWindowID),
            isEnabled: localModeEnabled,
            venue: localModeVenue,
            coordinate: HomeLocalCoordinateStorageCodec.decode(
                latitudeText: localModeLatitude,
                longitudeText: localModeLongitude
            ) ?? HomeLocalLocationLabel.coordinate(in: localModeVenue),
            startedAt: localModeStartedAt > 0 ? Date(timeIntervalSince1970: localModeStartedAt) : nil,
            durationMinutes: normalizedDurationMinutes,
            radiusMeters: normalizedRadiusMeters,
            selectedCarryingIDs: HomeLocalCarryingSelectionCodec.decode(localModeSelectedCarryingIDs)
        )
    }

    private var localModeState: MegrumAppState? {
        appState ?? MegrumAppState.activeInstance
    }

    private var localCarryingCandidates: [HomeLocalCarryingCandidate] {
        let sourceItems = HomeLocalCarryingCandidate.sourceItems(
            inventory: localModeState?.inventory ?? [],
            matchedItems: matchedItems,
            possibleItems: possibleItems
        )
        return HomeLocalCarryingCandidate.candidates(
            from: sourceItems,
            viewerID: viewer?.id
        )
    }

    private var normalizedDurationMinutes: Int {
        HomeLocalActivitySettings.normalizedDurationMinutes(localModeDurationMinutes)
    }

    private var normalizedRadiusMeters: Int {
        HomeLocalActivitySettings.normalizedRadiusMeters(localModeRadiusMeters)
    }

    private var homeGroomEntrySummary: HomeGroomEntrySummary? {
        guard let localModeState else {
            return nil
        }
        return HomeGroomEntrySummary(
            groomCount: localModeState.grooms.count,
            localStatus: localActivitySettings.status(),
            venue: localActivitySettings.displayVenue(fallbackPrefecture: viewer?.prefecture)
        )
    }

    private var homeGroomPosts: [GroomPost] {
        localModeState?.grooms ?? []
    }

    private func saveLocalActivitySettings(_ settings: HomeLocalActivitySettings) {
        let availableIDs = Set(localCarryingCandidates.map(\.id))
        let sanitized = settings
            .normalizedForPersistence(fallbackActivityWindowID: localActivitySettings.activityWindowID)
            .replacingSelectedCarryingIDs(settings.selectedCarryingIDs.intersection(availableIDs))

        loadedLocalActivitySettings = sanitized
        persistLocalActivitySettings(sanitized)

        guard let localModeState else {
            return
        }

        Task { @MainActor in
            guard let saved = await localModeState.saveHomeLocalModeSettings(sanitized) else {
                return
            }
            let persisted = saved
                .replacingSelectedCarryingIDs(saved.selectedCarryingIDs.intersection(availableIDs))
                .mergingMissingLocalCoordinate(from: sanitized)
            loadedLocalActivitySettings = persisted
            persistLocalActivitySettings(persisted)
        }
    }

    private func loadLocalActivitySettings() async {
        guard let localModeState else {
            return
        }
        guard let settings = await localModeState.loadHomeLocalModeSettings(fallback: localStorageActivitySettings) else {
            return
        }
        let loaded = settings.mergingMissingLocalCoordinate(from: localStorageActivitySettings)
        loadedLocalActivitySettings = loaded
        persistLocalActivitySettings(loaded)
    }

    private func persistLocalActivitySettings(_ settings: HomeLocalActivitySettings) {
        localModeActivityWindowID = settings.activityWindowID?.uuidString.lowercased() ?? ""
        localModeEnabled = settings.isEnabled
        localModeVenue = settings.venue
        localModeLatitude = HomeLocalCoordinateStorageCodec.latitudeText(settings.coordinate)
        localModeLongitude = HomeLocalCoordinateStorageCodec.longitudeText(settings.coordinate)
        localModeStartedAt = settings.startedAt?.timeIntervalSince1970 ?? localModeStartedAt
        localModeDurationMinutes = settings.durationMinutes
        localModeRadiusMeters = settings.radiusMeters
        localModeSelectedCarryingIDs = HomeLocalCarryingSelectionCodec.encode(settings.selectedCarryingIDs)
    }

    private func openVisualQAInitialRouteIfNeeded() {
        guard !didOpenVisualQAInitialRoute,
              visualQAInitialScreen == .matchRelation || visualQAInitialScreen == .matchRelationCandidates
        else {
            return
        }
        guard let item = HomeRelationVisualQARouteResolver.targetItem(
            candidates: matchedItems,
            viewerID: viewer?.id
        ) else {
            return
        }
        didOpenVisualQAInitialRoute = true
        relationRoute = HomeRelationRoute(item: item, matchType: .perfect)
    }
}

private extension View {
    @ViewBuilder
    func homeRelationPresentation<Content: View>(
        item: Binding<HomeRelationRoute?>,
        @ViewBuilder content: @escaping (HomeRelationRoute) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

private extension HomeLocalActivitySettings {
    func mergingMissingLocalCoordinate(from fallback: HomeLocalActivitySettings) -> HomeLocalActivitySettings {
        coordinate == nil ? replacingCoordinate(fallback.coordinate) : self
    }
}
