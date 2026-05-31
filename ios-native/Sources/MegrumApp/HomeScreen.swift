import MegrumCore
import MegrumDesign
import SwiftUI

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
    @State private var relationTargetItem: GoodsItem?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HomeHeader(viewer: viewer, onOpenSettings: onOpenSettings)

                    HomeLocalModeSurface(
                        viewer: viewer,
                        settings: localActivitySettings,
                        carryingCandidates: localCarryingCandidates,
                        isLoadingSettings: localModeState?.isLoadingHomeLocalModeSettings ?? false,
                        isSavingSettings: localModeState?.isSavingHomeLocalModeSettings ?? false,
                        onEdit: {
                            showsLocalModeSettings = true
                        }
                    )

                    if let homeGroomEntrySummary {
                        HomeGroomEntrySurface(
                            summary: homeGroomEntrySummary,
                            onOpen: onOpenMeguri
                        )
                    }

                    MatchSection(
                        title: "マッチしてるよ！",
                        count: matchedItems.count,
                        items: matchedItems,
                        isLoading: isLoading,
                        viewerID: viewer?.id,
                        onOpenItem: { item in
                            relationTargetItem = item
                        },
                        onOpenOwnerProfile: onOpenOwnerProfile
                    )

                    MatchSection(
                        title: "交換できるかも？",
                        count: possibleItems.count,
                        items: possibleItems,
                        isLoading: isLoading,
                        viewerID: viewer?.id,
                        onOpenOwnerProfile: onOpenOwnerProfile
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 104)
            }
            .refreshable {
                await onRefresh()
                await loadLocalActivitySettings()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            LiquidGlassSearchButton {
                showsSearch = true
            }
            .padding(.leading, 24)
            .padding(.bottom, 92)
        }
        .sheet(isPresented: $showsLocalModeSettings) {
            HomeLocalModeSettingsSheet(
                viewer: viewer,
                settings: localActivitySettings,
                carryingCandidates: localCarryingCandidates,
                onSave: saveLocalActivitySettings
            )
        }
        .sheet(item: $relationTargetItem) { item in
            if let relationState = localModeState {
                NavigationStack {
                    MatchRelationScreen(
                        appState: relationState,
                        targetItem: item,
                        matchType: .perfect,
                        onCompletionAction: { action in
                            relationTargetItem = nil
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
}

private extension HomeLocalActivitySettings {
    func mergingMissingLocalCoordinate(from fallback: HomeLocalActivitySettings) -> HomeLocalActivitySettings {
        coordinate == nil ? replacingCoordinate(fallback.coordinate) : self
    }
}

private struct HomeHeader: View {
    var viewer: UserProfile?
    var onOpenSettings: () -> Void

    var body: some View {
        HStack {
            Button(action: onOpenSettings) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MegrumTheme.lavender, MegrumTheme.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initial)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("設定を開く")

            Spacer()

            Text("Megrum")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
    }

    private var initial: String {
        guard let first = viewer?.displayName.first else {
            return "M"
        }
        return String(first)
    }
}

private struct MatchSection<Items: RandomAccessCollection>: View where Items.Element == GoodsItem, Items.Index == Int {
    var title: String
    var count: Int
    var items: Items
    var isLoading: Bool
    var viewerID: UUID?
    var onOpenItem: ((GoodsItem) -> Void)? = nil
    var onOpenOwnerProfile: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()

                Text("\(count)件")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            if isLoading && items.isEmpty {
                GoodsGridSkeleton()
            } else {
                GoodsGrid(
                    items: Array(items),
                    viewerID: viewerID,
                    onOpenItem: onOpenItem,
                    onOpenOwnerProfile: onOpenOwnerProfile
                )
            }
        }
    }
}

private struct GoodsGridSkeleton: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.76), lineWidth: 1)
                    )
                    .aspectRatio(0.78, contentMode: .fit)
                    .redacted(reason: .placeholder)
            }
        }
    }
}
