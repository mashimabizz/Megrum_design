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
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HomeHeader(viewer: viewer, onOpenSettings: onOpenSettings)

                    HomeGroomRail(
                        grooms: homeGroomPosts,
                        onOpen: onOpenMeguri
                    )

                    MatchSection(
                        shelfKind: .matched,
                        title: "マッチしてるよ！",
                        count: matchedItems.count,
                        items: matchedItems,
                        isLoading: isLoading,
                        viewerID: viewer?.id,
                        onSelectRelationRoute: { route in
                            relationRoute = route
                        },
                        onOpenOwnerProfile: onOpenOwnerProfile
                    )

                    MatchSection(
                        shelfKind: .possible,
                        title: "交換できるかも？",
                        count: possibleItems.count,
                        items: possibleItems,
                        isLoading: isLoading,
                        viewerID: viewer?.id,
                        onSelectRelationRoute: { route in
                            relationRoute = route
                        },
                        onOpenOwnerProfile: onOpenOwnerProfile
                    )

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
                }
                .padding(.horizontal, HomeLayoutMetrics.horizontalPadding)
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

private struct HomeGroomRail: View {
    var grooms: [GroomPost]
    var onOpen: (() -> Void)?

    private var displayGrooms: [HomeGroomRailEntry] {
        let mapped = grooms.prefix(4).enumerated().map { index, groom in
            HomeGroomRailEntry(
                id: groom.id,
                name: HomeGroomRailFallback.names.indices.contains(index) ? HomeGroomRailFallback.names[index] : "めぐ",
                imageURL: groom.imageURL,
                isViewed: index > 1
            )
        }
        if mapped.isEmpty {
            return HomeGroomRailFallback.entries
        }
        return Array((mapped + HomeGroomRailFallback.entries.dropFirst(mapped.count)).prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("グルーム")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 13) {
                    Button(action: { onOpen?() }) {
                        HomeGroomRailAddTile()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("グルームを追加")

                    ForEach(displayGrooms) { groom in
                        Button(action: { onOpen?() }) {
                            HomeGroomRailTile(entry: groom)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(groom.name)のグルームを見る")
                    }
                }
                .padding(.trailing, 18)
            }
        }
    }
}

private struct HomeGroomRailEntry: Identifiable, Equatable {
    var id: UUID
    var name: String
    var imageURL: URL?
    var isViewed: Bool
}

private enum HomeGroomRailFallback {
    static let names = ["みち", "きこ", "ゆい", "まい"]
    static let entries: [HomeGroomRailEntry] = names.enumerated().map { index, name in
        HomeGroomRailEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000008\(String(format: "%02d", index))")!,
            name: name,
            imageURL: nil,
            isViewed: index == 3
        )
    }
}

private struct HomeGroomRailAddTile: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.28))
                .background(MegrumTheme.lavender.opacity(0.08), in: Circle())
                .frame(width: 74, height: 74)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            Text("追加")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(width: 80)
    }
}

private struct HomeGroomRailTile: View {
    var entry: HomeGroomRailEntry

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(entry.isViewed ? Color.gray.opacity(0.28) : MegrumTheme.lavender, lineWidth: 2)
                .background(Color.white.opacity(0.92), in: Circle())
                .frame(width: 74, height: 74)
                .overlay {
                    if let imageURL = entry.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                HomeGroomRailInitial(name: entry.name)
                            }
                        }
                        .clipShape(Circle())
                        .padding(4)
                    } else {
                        HomeGroomRailInitial(name: entry.name)
                    }
                }
                .shadow(color: MegrumTheme.lavender.opacity(0.16), radius: 12, x: 0, y: 5)

            Text(entry.name)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

private struct HomeGroomRailInitial: View {
    var name: String

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [MegrumTheme.lavender.opacity(0.26), MegrumTheme.pink.opacity(0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(String(name.prefix(1)))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(4)
    }
}

private struct MatchSection<Items: RandomAccessCollection>: View where Items.Element == GoodsItem, Items.Index == Int {
    var shelfKind: HomeMatchShelfKind
    var title: String
    var count: Int
    var items: Items
    var isLoading: Bool
    var viewerID: UUID?
    var onSelectRelationRoute: (HomeRelationRoute) -> Void
    var onOpenOwnerProfile: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            if isLoading && items.isEmpty {
                GoodsGridSkeleton()
            } else {
                HomeCandidateGrid(
                    items: Array(items),
                    viewerID: viewerID,
                    shelfKind: shelfKind,
                    onOpenItem: { item in
                        switch HomeGoodsPanelRouteResolver.destination(for: shelfKind) {
                        case .relation(let matchType):
                            onSelectRelationRoute(
                                HomeRelationRoute(item: item, matchType: matchType)
                            )
                        }
                    }
                )
            }
        }
    }
}

private struct HomeCandidateGrid: View {
    var items: [GoodsItem]
    var viewerID: UUID?
    var shelfKind: HomeMatchShelfKind
    var onOpenItem: (GoodsItem) -> Void

    var body: some View {
        LazyVGrid(
            columns: HomeCandidateGridMetrics.columns,
            alignment: .leading,
            spacing: HomeCandidateGridMetrics.spacing
        ) {
                ForEach(items) { item in
                    Button(action: { onOpenItem(item) }) {
                        HomeCandidateTile(
                            item: item,
                            shelfKind: shelfKind,
                            localMode: shelfKind == .matched && item.ownerID != viewerID
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.title)の関係図を開く")
                }
        }
    }
}

enum HomeLayoutMetrics {
    static let horizontalPadding: CGFloat = 18
}

enum HomeCandidateGridMetrics {
    static let columnCount = 3
    static let spacing: CGFloat = 10
    static let cardHeightRatio: CGFloat = 1.34
    static let localAuraCornerRadius: CGFloat = 22
    static let localAuraOutset: CGFloat = 5
    static let localAuraShadowRadius: CGFloat = 18
    static let tagFontSize: CGFloat = 9
    static let tagHorizontalPadding: CGFloat = 6
    static let tagVerticalPadding: CGFloat = 3
    static let liveTopOffset: CGFloat = 31
    static let fakeImageGlowSize: CGFloat = 58
    static let fakeImageGlowOffsetX: CGFloat = 17
    static let fakeImageGlowOffsetY: CGFloat = -12
    static let fakeImageLetterFontSize: CGFloat = 32
    static let fakeImageLetterShadowRadius: CGFloat = 5
    static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: spacing, alignment: .top),
        count: columnCount
    )

    static func tileWidth(containerWidth: CGFloat) -> CGFloat {
        guard containerWidth > 0 else {
            return 0
        }
        return (containerWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    static func cardHeight(tileWidth: CGFloat) -> CGFloat {
        tileWidth * cardHeightRatio
    }
}

private struct HomeCandidateTile: View {
    var item: GoodsItem
    var shelfKind: HomeMatchShelfKind
    var localMode: Bool

    private var frameStyle: HomeCandidatePriorityFrameStyle {
        HomeCandidatePriorityFrameStyle.style(for: shelfKind)
    }

    var body: some View {
        ZStack {
            if localMode {
                RoundedRectangle(cornerRadius: HomeCandidateGridMetrics.localAuraCornerRadius, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.16))
                    .overlay {
                        RoundedRectangle(cornerRadius: HomeCandidateGridMetrics.localAuraCornerRadius, style: .continuous)
                            .stroke(MegrumTheme.lavender.opacity(0.52), lineWidth: 1)
                    }
                    .shadow(color: MegrumTheme.lavender.opacity(0.42), radius: HomeCandidateGridMetrics.localAuraShadowRadius, x: 0, y: 0)
                    .padding(-HomeCandidateGridMetrics.localAuraOutset)
            }

            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(HomeCandidateTileStyle.hue(for: item))
                .overlay {
                    ZStack {
                        if let imageURL = item.imageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    fallback
                                }
                            }
                        } else {
                            fallback
                        }

                        if let tagLine = HomeCandidateTileStyle.tagLine(for: item) {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text(tagLine)
                                        .font(.system(size: HomeCandidateGridMetrics.tagFontSize, weight: .black, design: .rounded))
                                        .foregroundStyle(MegrumTheme.ink.opacity(0.74))
                                        .lineLimit(1)
                                        .padding(.horizontal, HomeCandidateGridMetrics.tagHorizontalPadding)
                                        .padding(.vertical, HomeCandidateGridMetrics.tagVerticalPadding)
                                        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                Spacer()
                            }
                            .padding(.top, 6)
                            .padding(.trailing, 6)
                        }

                        if localMode {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("LIVE")
                                        .font(.system(size: HomeCandidateGridMetrics.tagFontSize, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, HomeCandidateGridMetrics.tagHorizontalPadding)
                                        .padding(.vertical, HomeCandidateGridMetrics.tagVerticalPadding)
                                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                                Spacer()
                            }
                            .padding(.top, HomeCandidateGridMetrics.liveTopOffset)
                            .padding(.trailing, 8)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(frameStyle.borderColor, lineWidth: frameStyle.borderWidth)
                }
                .shadow(color: frameStyle.shadowColor, radius: frameStyle.shadowRadius, x: frameStyle.shadowX, y: frameStyle.shadowY)
        }
        .aspectRatio(1 / HomeCandidateGridMetrics.cardHeightRatio, contentMode: .fit)
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(
                    width: HomeCandidateGridMetrics.fakeImageGlowSize,
                    height: HomeCandidateGridMetrics.fakeImageGlowSize
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(
                    x: HomeCandidateGridMetrics.fakeImageGlowOffsetX,
                    y: HomeCandidateGridMetrics.fakeImageGlowOffsetY
                )

            Text(HomeCandidateTileStyle.letter(for: item))
                .font(.system(size: HomeCandidateGridMetrics.fakeImageLetterFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(
                    color: MegrumTheme.ink.opacity(0.16),
                    radius: HomeCandidateGridMetrics.fakeImageLetterShadowRadius,
                    x: 0,
                    y: 2
                )
        }
    }
}

struct HomeCandidatePriorityFrameStyle: Equatable {
    var borderColor: Color
    var borderWidth: CGFloat
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowX: CGFloat
    var shadowY: CGFloat

    static func style(for shelfKind: HomeMatchShelfKind) -> HomeCandidatePriorityFrameStyle {
        switch shelfKind {
        case .matched:
            return HomeCandidatePriorityFrameStyle(
                borderColor: MegrumTheme.lavender.opacity(HomeCandidatePriorityFrameMetrics.bothBorderOpacity),
                borderWidth: HomeCandidatePriorityFrameMetrics.bothBorderWidth,
                shadowColor: MegrumTheme.lavender.opacity(HomeCandidatePriorityFrameMetrics.bothShadowOpacity),
                shadowRadius: HomeCandidatePriorityFrameMetrics.bothShadowRadius,
                shadowX: 0,
                shadowY: HomeCandidatePriorityFrameMetrics.bothShadowY
            )
        case .possible:
            return HomeCandidatePriorityFrameStyle(
                borderColor: MegrumTheme.sky.opacity(HomeCandidatePriorityFrameMetrics.oneSideBorderOpacity),
                borderWidth: HomeCandidatePriorityFrameMetrics.oneSideBorderWidth,
                shadowColor: MegrumTheme.sky.opacity(HomeCandidatePriorityFrameMetrics.oneSideShadowOpacity),
                shadowRadius: HomeCandidatePriorityFrameMetrics.oneSideShadowRadius,
                shadowX: 0,
                shadowY: HomeCandidatePriorityFrameMetrics.oneSideShadowY
            )
        }
    }
}

enum HomeCandidatePriorityFrameMetrics {
    static let bothBorderWidth: CGFloat = 2
    static let bothBorderOpacity: CGFloat = 0.72
    static let bothShadowOpacity: CGFloat = 0.22
    static let bothShadowRadius: CGFloat = 16
    static let bothShadowY: CGFloat = 8
    static let oneSideBorderWidth: CGFloat = 1.5
    static let oneSideBorderOpacity: CGFloat = 0.78
    static let oneSideShadowOpacity: CGFloat = 0.18
    static let oneSideShadowRadius: CGFloat = 12
    static let oneSideShadowY: CGFloat = 7
}

enum HomeCandidateTileStyle {
    static func tagLine(for item: GoodsItem) -> String? {
        let tags = item.tags.prefix(2).map { "# \($0.name)" }
        guard !tags.isEmpty else {
            return nil
        }
        return tags.joined(separator: " ")
    }

    static func letter(for item: GoodsItem) -> String {
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.contains("スア") {
            return "S"
        }
        if title.contains("ニンニン") {
            return "N"
        }
        if title.contains("ジョンウ") {
            return "J"
        }
        if title.contains("カリナ") {
            return "K"
        }
        return title.first.map { String($0) } ?? "?"
    }

    static func hue(for item: GoodsItem) -> Color {
        switch letter(for: item) {
        case "S":
            return MegrumTheme.lavender.opacity(0.34)
        case "K":
            return MegrumTheme.pink.opacity(0.34)
        case "J":
            return MegrumTheme.sky.opacity(0.34)
        case "N":
            return MegrumTheme.pink.opacity(0.28)
        default:
            switch abs(item.id.hashValue) % 4 {
            case 0:
                return MegrumTheme.lavender.opacity(0.34)
            case 1:
                return MegrumTheme.pink.opacity(0.34)
            case 2:
                return MegrumTheme.sky.opacity(0.34)
            default:
                return Color(red: 0.80, green: 0.87, blue: 1.0).opacity(0.62)
            }
        }
    }
}

private struct GoodsGridSkeleton: View {
    var body: some View {
        LazyVGrid(
            columns: HomeCandidateGridMetrics.columns,
            alignment: .leading,
            spacing: HomeCandidateGridMetrics.spacing
        ) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.76), lineWidth: 1)
                    )
                    .aspectRatio(1 / HomeCandidateGridMetrics.cardHeightRatio, contentMode: .fit)
                    .redacted(reason: .placeholder)
            }
        }
    }
}
