import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeScreen: View {
    var viewer: UserProfile?
    var matchedItems: [GoodsItem]
    var possibleItems: [GoodsItem]
    var isLoading: Bool
    @Binding var showsSearch: Bool
    var onRefresh: () async -> Void
    var onOpenSettings: () -> Void = {}
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }

    @AppStorage("megrum.home.localMode.enabled") private var localModeEnabled = false
    @AppStorage("megrum.home.localMode.venue") private var localModeVenue = ""
    @AppStorage("megrum.home.localMode.startedAt") private var localModeStartedAt = 0.0
    @AppStorage("megrum.home.localMode.durationMinutes") private var localModeDurationMinutes = HomeLocalActivitySettings.defaultDurationMinutes
    @AppStorage("megrum.home.localMode.radiusMeters") private var localModeRadiusMeters = HomeLocalActivitySettings.defaultRadiusMeters
    @AppStorage("megrum.home.localMode.selectedCarryingIDs") private var localModeSelectedCarryingIDs = ""
    @State private var showsLocalModeSettings = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HomeHeader(viewer: viewer, onOpenSettings: onOpenSettings)

                    HomeLocalModeSurface(
                        viewer: viewer,
                        settings: localActivitySettings,
                        carryingCandidates: localCarryingCandidates,
                        onEdit: {
                            showsLocalModeSettings = true
                        }
                    )

                    MatchSection(
                        title: "マッチしてるよ！",
                        count: matchedItems.count,
                        items: matchedItems,
                        isLoading: isLoading,
                        viewerID: viewer?.id,
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
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            LiquidGlassSearchButton {
                showsSearch = true
            }
            .padding(.leading, 24)
            .padding(.bottom, 22)
        }
        .sheet(isPresented: $showsLocalModeSettings) {
            HomeLocalModeSettingsSheet(
                viewer: viewer,
                settings: localActivitySettings,
                carryingCandidates: localCarryingCandidates,
                onSave: saveLocalActivitySettings
            )
        }
    }

    private var localActivitySettings: HomeLocalActivitySettings {
        HomeLocalActivitySettings(
            isEnabled: localModeEnabled,
            venue: localModeVenue,
            startedAt: localModeStartedAt > 0 ? Date(timeIntervalSince1970: localModeStartedAt) : nil,
            durationMinutes: normalizedDurationMinutes,
            radiusMeters: normalizedRadiusMeters,
            selectedCarryingIDs: HomeLocalCarryingSelectionCodec.decode(localModeSelectedCarryingIDs)
        )
    }

    private var localCarryingCandidates: [HomeLocalCarryingCandidate] {
        HomeLocalCarryingCandidate.candidates(
            from: matchedItems + possibleItems,
            viewerID: viewer?.id
        )
    }

    private var normalizedDurationMinutes: Int {
        HomeLocalActivitySettings.durationOptions.contains(localModeDurationMinutes)
            ? localModeDurationMinutes
            : HomeLocalActivitySettings.defaultDurationMinutes
    }

    private var normalizedRadiusMeters: Int {
        HomeLocalActivitySettings.radiusOptions.contains(localModeRadiusMeters)
            ? localModeRadiusMeters
            : HomeLocalActivitySettings.defaultRadiusMeters
    }

    private func saveLocalActivitySettings(_ settings: HomeLocalActivitySettings) {
        let availableIDs = Set(localCarryingCandidates.map(\.id))
        localModeEnabled = settings.isEnabled
        localModeVenue = settings.venue
        localModeStartedAt = settings.startedAt?.timeIntervalSince1970 ?? localModeStartedAt
        localModeDurationMinutes = settings.durationMinutes
        localModeRadiusMeters = settings.radiusMeters
        localModeSelectedCarryingIDs = HomeLocalCarryingSelectionCodec.encode(
            settings.selectedCarryingIDs.intersection(availableIDs)
        )
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
                GoodsGrid(items: Array(items), viewerID: viewerID, onOpenOwnerProfile: onOpenOwnerProfile)
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
