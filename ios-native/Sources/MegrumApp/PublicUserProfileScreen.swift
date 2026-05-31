import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicProfileRoute: Identifiable, Equatable {
    var userID: UUID
    var id: UUID { userID }
}

struct PublicUserProfileScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var selectedExchangeTab: PublicProfileExchangeTab = .goods
    @State private var proposalTargetItem: GoodsItem?
    @State private var listingProposalTarget: ListingProposalTarget?

    private var publicProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[userID]
    }

    private var evaluations: [UserEvaluation] {
        appState.userEvaluationsByUserID[userID] ?? []
    }

    private var tradeGoods: [GoodsItem] {
        appState.publicTradeGoodsByUserID[userID] ?? []
    }

    private var listings: [IndividualListing] {
        appState.publicListingsByUserID[userID] ?? []
    }

    private var goodsByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: tradeGoods.map { ($0.id, $0) })
    }

    private var isLoadingExchangeContent: Bool {
        appState.loadingPublicExchangeUserID == userID
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let publicProfile {
                    ProfileHero(publicProfile: publicProfile)
                    ProfileStats(appState: appState, userID: userID, publicProfile: publicProfile)
                    PublicProfileExchangeSection(
                        selectedTab: $selectedExchangeTab,
                        tradeGoods: tradeGoods,
                        listings: listings,
                        goodsByID: goodsByID,
                        isLoading: isLoadingExchangeContent,
                        viewerID: appState.viewer?.id,
                        onStartGoodsProposal: { item in
                            proposalTargetItem = item
                        },
                        onStartListingProposal: { target in
                            listingProposalTarget = target
                        },
                        onReportItem: { item, reason, note in
                            reportItem(item, reason: reason, note: note)
                        }
                    )
                } else {
                    ProfileSkeleton()
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 42)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("プロフィール")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task(id: userID) {
            await appState.loadPublicUserProfile(userID: userID)
            await appState.loadPublicExchangeContent(userID: userID)
            await appState.loadUserEvaluations(userID: userID)
        }
        .sheet(item: $proposalTargetItem) { item in
            NavigationStack {
                ProposalCreateFlow(appState: appState, targetItem: item)
            }
        }
        .sheet(item: $listingProposalTarget) { target in
            NavigationStack {
                ProposalCreateFlow(
                    appState: appState,
                    targetItem: target.targetItem,
                    listingID: target.listing.id,
                    receiverGoodsIDs: target.listing.haves.map(\.itemID)
                )
            }
        }
    }

    private func reportItem(_ item: GoodsItem, reason: GoodsReportReason, note: String) {
        Task {
            _ = await appState.reportGoods(
                itemID: item.id,
                reportedUserID: item.ownerID,
                reason: reason,
                note: note
            )
        }
    }
}

private enum PublicProfileExchangeTab: String, CaseIterable, Identifiable {
    case goods = "譲る候補"
    case listings = "個別募集"

    var id: String { rawValue }
}

private struct ListingProposalTarget: Identifiable {
    var listing: IndividualListing
    var targetItem: GoodsItem

    var id: UUID { listing.id }
}

private struct ProfileHero: View {
    var publicProfile: PublicUserProfile

    private var profile: UserProfile {
        publicProfile.profile
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProfileAvatar(profile: profile, size: 92)

            VStack(alignment: .leading, spacing: 7) {
                Text(profile.displayName)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text("@\(profile.handle)")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                if let prefecture = profile.prefecture, !prefecture.isEmpty {
                    Text(prefecture)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.64), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: 10)
    }
}

private struct ProfileStats: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var publicProfile: PublicUserProfile

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                EvaluationListScreen(
                    appState: appState,
                    userID: userID,
                    profile: publicProfile.profile
                )
            } label: {
                ProfileStatCard(
                    title: "評価",
                    value: publicProfile.ratingSummary,
                    caption: "\(publicProfile.evaluationCount)件",
                    symbolName: "star.fill"
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("評価一覧を開く")
            .accessibilityValue("\(publicProfile.evaluationCount)件")

            ProfileStatCard(
                title: "取引",
                value: "\(publicProfile.completedTradeCount)",
                caption: "完了",
                symbolName: "checkmark.seal.fill"
            )
        }
    }
}

private struct PublicProfileExchangeSection: View {
    @Binding var selectedTab: PublicProfileExchangeTab
    var tradeGoods: [GoodsItem]
    var listings: [IndividualListing]
    var goodsByID: [UUID: GoodsItem]
    var isLoading: Bool
    var viewerID: UUID?
    var onStartGoodsProposal: (GoodsItem) -> Void
    var onStartListingProposal: (ListingProposalTarget) -> Void
    var onReportItem: (GoodsItem, GoodsReportReason, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("表示", selection: $selectedTab) {
                ForEach(PublicProfileExchangeTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            if isLoading && tradeGoods.isEmpty && listings.isEmpty {
                PublicProfileExchangeSkeleton()
            } else {
                switch selectedTab {
                case .goods:
                    if tradeGoods.isEmpty {
                        PublicProfileEmptyExchangeMessage(text: "譲る候補はまだありません")
                    } else {
                        GoodsGrid(
                            items: tradeGoods,
                            viewerID: viewerID,
                            onAddToExchangeList: onStartGoodsProposal,
                            onReportItem: onReportItem
                        )
                    }
                case .listings:
                    if listings.isEmpty {
                        PublicProfileEmptyExchangeMessage(text: "個別募集はまだありません")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(listings) { listing in
                                PublicProfileListingCard(
                                    listing: listing,
                                    goodsByID: goodsByID,
                                    onStartProposal: onStartListingProposal
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PublicProfileListingCard: View {
    var listing: IndividualListing
    var goodsByID: [UUID: GoodsItem]
    var onStartProposal: (ListingProposalTarget) -> Void

    private var targetItems: [GoodsItem] {
        listing.haves.compactMap { goodsByID[$0.itemID] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(listing.status.displayName)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(MegrumTheme.lavender, in: Capsule())

                Spacer()

                Text(listing.haveLogic == .all ? "全部セット" : "どれか1つ")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("相手が出す")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                ForEach(listing.haves) { quantity in
                    HStack(spacing: 8) {
                        Text(goodsByID[quantity.itemID]?.title ?? "グッズ")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        if quantity.quantity > 1 {
                            Text("×\(quantity.quantity)")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                        }
                    }
                }
            }

            if let note = listing.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                Text(note)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }

            Button {
                guard let targetItem = targetItems.first else {
                    return
                }
                onStartProposal(ListingProposalTarget(listing: listing, targetItem: targetItem))
            } label: {
                Text("この募集に打診する")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(targetItems.isEmpty)
            .opacity(targetItems.isEmpty ? 0.48 : 1)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.58), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: 10)
    }
}

private struct PublicProfileExchangeSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .frame(height: 136)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

private struct PublicProfileEmptyExchangeMessage: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 1)
            }
    }
}

private struct ProfileStatCard: View {
    var title: String
    var value: String
    var caption: String
    var symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 5) {
                Text(title)
                Text(caption)
            }
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
    }
}

struct PublicProfileEvaluationListState: Equatable {
    var evaluationCount: Int
    var isLoading: Bool

    init(evaluations: [UserEvaluation], isLoading: Bool) {
        self.evaluationCount = evaluations.count
        self.isLoading = isLoading
    }

    var showsLoading: Bool {
        isLoading && evaluationCount == 0
    }

    var showsEmpty: Bool {
        !isLoading && evaluationCount == 0
    }
}

private struct EvaluationListScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var profile: UserProfile

    private var evaluations: [UserEvaluation] {
        appState.userEvaluationsByUserID[userID] ?? []
    }

    private var listState: PublicProfileEvaluationListState {
        PublicProfileEvaluationListState(
            evaluations: evaluations,
            isLoading: appState.loadingEvaluationsUserID == userID
        )
    }

    var body: some View {
        List {
            if listState.showsLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("評価を読み込んでいます")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 28)
                .listRowBackground(Color.clear)
            } else if listState.showsEmpty {
                ContentUnavailableView(
                    "まだ評価はありません",
                    systemImage: "star",
                    description: Text("取引完了後の評価がここに表示されます")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(evaluations) { evaluation in
                    EvaluationRow(evaluation: evaluation)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("\(profile.displayName)の評価")
        .megrumInlineNavigationTitle()
        .task(id: userID) {
            if evaluations.isEmpty {
                await appState.loadUserEvaluations(userID: userID)
            }
        }
        .refreshable {
            await appState.loadUserEvaluations(userID: userID)
        }
    }
}

private struct EvaluationRow: View {
    var evaluation: UserEvaluation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ProfileAvatar(
                    profile: UserProfile(
                        id: evaluation.raterID,
                        handle: evaluation.raterHandle,
                        displayName: evaluation.raterDisplayName,
                        avatarURL: evaluation.raterAvatarURL
                    ),
                    size: 44
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(evaluation.raterDisplayName)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("@\(evaluation.raterHandle) ・ \(Self.dateFormatter.string(from: evaluation.createdAt))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer()

                StarRating(stars: evaluation.stars)
            }

            if let comment = evaluation.comment?.trimmingCharacters(in: .whitespacesAndNewlines), !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                    .lineSpacing(3)
            }
        }
        .padding(.vertical, 8)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()
}

private struct StarRating: View {
    var stars: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(index <= stars ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.42))
            }
        }
        .accessibilityLabel("星\(stars)")
    }
}

private struct ProfileAvatar: View {
    var profile: UserProfile
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                if let avatarURL = profile.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }
                    .clipShape(Circle())
                } else {
                    Text(initial)
                        .font(.system(size: max(17, size * 0.42), weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                Circle().stroke(.white.opacity(0.72), lineWidth: 1)
            }
    }

    private var initial: String {
        profile.displayName.first.map(String.init) ?? "M"
    }
}

private struct ProfileSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Circle()
                .fill(.white.opacity(0.74))
                .frame(width: 92, height: 92)
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.74))
                .frame(width: 190, height: 34)
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.64))
                .frame(width: 124, height: 20)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .redacted(reason: .placeholder)
    }
}
