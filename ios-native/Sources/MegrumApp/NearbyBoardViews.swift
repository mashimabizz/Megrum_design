import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

// =====================================================================
// 圏内チャットルームの導線（iter1226.421 / オーナー要望）
// - ホーム：グルーム列の下にLINE風の行（タイトル・最新メッセージ・サムネ・日時）
// - 一覧：フィルターフッター付き。圏外は無料だと開けずプレミアム誘導ポップアップ
// =====================================================================

/// 絞り込み・並び順の純ロジック（テスト可能）。
enum NearbyBoardListPolicy {
    /// トピック（タイトル・本文）またはシリーズ名にキーワードが含まれるものだけ残す。
    static func filtered(_ threads: [BoardThread], query: String) -> [BoardThread] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return threads
        }
        return threads.filter { thread in
            thread.title.localizedCaseInsensitiveContains(trimmed)
                || (thread.seriesName?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || thread.body.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// シリーズチップで絞り込み（nil = 全件）。
    static func filtered(_ threads: [BoardThread], seriesName: String?) -> [BoardThread] {
        guard let seriesName = seriesName?.nilIfBlank else {
            return threads
        }
        return threads.filter { $0.seriesName?.caseInsensitiveCompare(seriesName) == .orderedSame }
    }

    /// 開けるもの→ロック（圏外×無料）の順。各グループ内は最新アクティビティ降順。
    static func ordered(_ threads: [BoardThread], lockedIDs: Set<UUID>) -> [BoardThread] {
        threads.sorted { lhs, rhs in
            let lhsLocked = lockedIDs.contains(lhs.id)
            let rhsLocked = lockedIDs.contains(rhs.id)
            if lhsLocked != rhsLocked {
                return !lhsLocked && rhsLocked
            }
            return lhs.latestActivityAt > rhs.latestActivityAt
        }
    }

    /// フィルターチップに出すシリーズ名一覧（重複除去・出現順）。
    static func availableSeriesNames(in threads: [BoardThread]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for thread in threads {
            guard let name = thread.seriesName?.nilIfBlank else {
                continue
            }
            let key = name.lowercased()
            if seen.insert(key).inserted {
                result.append(name)
            }
        }
        return result
    }
}

/// LINEのトーク一覧風の1行：サムネ＋タイトル＋最新メッセージ＋最新投稿日時。
struct NearbyBoardThreadRow: View {
    var thread: BoardThread
    var latestMessage: String?
    var isLocked: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                thumbnail

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(thread.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(NotificationRelativeTimeFormatter.text(from: thread.latestActivityAt))
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    HStack(spacing: 6) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                        Text(latestMessageText)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                    }

                    if let seriesName = thread.seriesName?.nilIfBlank {
                        Text("#\(seriesName)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .opacity(isLocked ? 0.62 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(thread.title)\(isLocked ? "、圏外のためプレミアム限定" : "")")
    }

    private var latestMessageText: String {
        if let latestMessage = latestMessage?.nilIfBlank {
            return latestMessage
        }
        let body = thread.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return body.nilIfBlank ?? "まだメッセージはありません"
    }

    private var thumbnail: some View {
        Group {
            if let url = thread.imageURLs?.first {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            MegrumTheme.sky.opacity(0.16)
            Image(systemName: "text.bubble")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MegrumTheme.sky)
        }
    }
}

/// ホーム：グルーム列の下に出す「近くのチャットルーム」セクション。
struct HomeNearbyBoardSection: View {
    var threads: [BoardThread]
    var replyPreviews: [UUID: [String]]
    var lockedIDs: Set<UUID>
    var onOpenThread: (BoardThread) -> Void
    var onOpenLockedThread: () -> Void
    var onSeeAll: () -> Void

    private static let displayLimit = 3

    private var orderedThreads: [BoardThread] {
        NearbyBoardListPolicy.ordered(threads, lockedIDs: lockedIDs)
    }

    var body: some View {
        if !threads.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("近くのチャットルーム")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Spacer()

                    // 複数ある場合は一覧（フィルター付き）への導線を出す。
                    if threads.count > 1 {
                        Button(action: onSeeAll) {
                            HStack(spacing: 2) {
                                Text("すべて見る")
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(orderedThreads.prefix(Self.displayLimit).enumerated()), id: \.element.id) { index, thread in
                        if index > 0 {
                            Divider().opacity(0.5)
                        }
                        NearbyBoardThreadRow(
                            thread: thread,
                            latestMessage: replyPreviews[thread.id]?.first,
                            isLocked: lockedIDs.contains(thread.id),
                            onTap: {
                                if lockedIDs.contains(thread.id) {
                                    onOpenLockedThread()
                                } else {
                                    onOpenThread(thread)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.black.opacity(0.05), lineWidth: 1)
                }
            }
        }
    }
}

/// 圏外チャットルームのプレミアム誘導ポップアップ。
struct BoardLockedPremiumSheet: View {
    var onOpenPremium: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.top, 26)

            Text("圏外のチャットルームです")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("1km圏外のチャットルームの閲覧・参加は\nMegrumプレミアムで利用できます。")
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Megrumプレミアムを見る") {
                dismiss()
                onOpenPremium()
            }
            .buttonStyle(.megrumPrimary)
            .padding(.top, 6)

            Button("閉じる") {
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
    }
}

/// 圏内チャットルーム一覧（ホームの「すべて見る」・めぐりホーム右下アイコンから）。
/// 固定フッターのフィルター（トピック/シリーズ絞り込み）付き。圏外×無料はロック表示＋プレミアム誘導。
struct NearbyBoardListScreen: View {
    /// VisualQA用：起動直後に開いておくオーバーレイ。
    enum QAInitialOverlay {
        case filter
        case lockedPopup
    }

    @ObservedObject var appState: MegrumAppState
    var onClose: () -> Void
    var onOpenThread: (BoardThread) -> Void
    var qaInitialOverlay: QAInitialOverlay?

    @StateObject private var locationState = MegrumLocationState()
    @State private var filterQuery = ""
    @State private var selectedSeriesName: String?
    @State private var isShowingFilterSheet = false
    @State private var isShowingLockedPopup = false
    @State private var isShowingPremium = false

    private var lockedIDs: Set<UUID> {
        let viewerID = appState.viewer?.id
        return Set(
            appState.homeNearbyBoardThreads.filter { thread in
                !MeguriAccessPolicy.canOpenBoard(
                    thread,
                    currentCoordinate: locationState.coordinate,
                    viewerID: viewerID,
                    subscriptionState: appState.subscriptionState
                )
            }.map(\.id)
        )
    }

    private var visibleThreads: [BoardThread] {
        let byQuery = NearbyBoardListPolicy.filtered(appState.homeNearbyBoardThreads, query: filterQuery)
        let bySeries = NearbyBoardListPolicy.filtered(byQuery, seriesName: selectedSeriesName)
        return NearbyBoardListPolicy.ordered(bySeries, lockedIDs: lockedIDs)
    }

    private var hasActiveFilter: Bool {
        !filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSeriesName != nil
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header

                    if hasActiveFilter {
                        activeFilterChips
                    }

                    if visibleThreads.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(visibleThreads.enumerated()), id: \.element.id) { index, thread in
                                if index > 0 {
                                    Divider().opacity(0.5)
                                }
                                NearbyBoardThreadRow(
                                    thread: thread,
                                    latestMessage: appState.boardReplyPreviewsByThreadID[thread.id]?.first,
                                    isLocked: lockedIDs.contains(thread.id),
                                    onTap: {
                                        if lockedIDs.contains(thread.id) {
                                            isShowingLockedPopup = true
                                        } else {
                                            onOpenThread(thread)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.black.opacity(0.05), lineWidth: 1)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }

            filterFooterButton
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .onAppear {
            if locationState.coordinate == nil {
                locationState.requestCurrentLocation()
            }
            switch qaInitialOverlay {
            case .filter:
                isShowingFilterSheet = true
            case .lockedPopup:
                isShowingLockedPopup = true
            case nil:
                break
            }
        }
        .task {
            await reload()
        }
        .task(id: locationState.coordinate?.latitude) {
            await reload()
        }
        .sheet(isPresented: $isShowingFilterSheet) {
            NearbyBoardFilterSheet(
                query: $filterQuery,
                selectedSeriesName: $selectedSeriesName,
                availableSeriesNames: NearbyBoardListPolicy.availableSeriesNames(in: appState.homeNearbyBoardThreads)
            )
            .presentationDetents([.height(360), .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingLockedPopup) {
            BoardLockedPremiumSheet(onOpenPremium: { isShowingPremium = true })
        }
        .sheet(isPresented: $isShowingPremium) {
            NavigationStack {
                SubscriptionSettingsScreen(appState: appState)
            }
        }
    }

    private func reload() async {
        guard let coordinate = locationState.coordinate else {
            return
        }
        await appState.loadHomeNearbyBoardThreads(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private var header: some View {
        ZStack {
            Text("近くのチャットルーム")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 40, height: 40)
                        .background(MegrumTheme.ink.opacity(0.045), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("閉じる")

                Spacer()
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var activeFilterChips: some View {
        HStack(spacing: 8) {
            if let query = filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank {
                filterChip("“\(query)”") {
                    filterQuery = ""
                }
            }
            if let seriesName = selectedSeriesName {
                filterChip("#\(seriesName)") {
                    selectedSeriesName = nil
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func filterChip(_ title: String, onClear: @escaping () -> Void) -> some View {
        Button(action: onClear) {
            HStack(spacing: 5) {
                Text(title)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(MegrumTheme.primaryGradient, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "text.bubble")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(MegrumTheme.sky)
            Text(hasActiveFilter ? "条件に合うチャットルームがありません" : "近くのチャットルームはまだありません")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text(hasActiveFilter ? "フィルターを変更してみてください。" : "めぐりからチャットルームを作成できます。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// 固定フッターのフィルターボタン（右下）。
    private var filterFooterButton: some View {
        Button {
            isShowingFilterSheet = true
        } label: {
            Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(MegrumTheme.primaryGradient, in: Circle())
                .shadow(color: MegrumTheme.primaryShadow, radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 28)
        .accessibilityLabel("チャットルームを絞り込む")
    }
}

/// フィルターシート：トピック（キーワード）＋シリーズ名チップ。
private struct NearbyBoardFilterSheet: View {
    @Binding var query: String
    @Binding var selectedSeriesName: String?
    var availableSeriesNames: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("チャットルームを絞り込む")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("トピック・キーワード")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted)
                    TextField("例：物販列、トレカ交換", text: $query)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(MegrumTheme.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if !availableSeriesNames.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("シリーズで絞り込む")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)

                    WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                        ForEach(availableSeriesNames, id: \.self) { name in
                            seriesChip(name)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Button("この条件で表示") {
                dismiss()
            }
            .buttonStyle(.megrumPrimary)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 22)
    }

    private func seriesChip(_ name: String) -> some View {
        let isSelected = selectedSeriesName?.caseInsensitiveCompare(name) == .orderedSame
        return Button {
            selectedSeriesName = isSelected ? nil : name
        } label: {
            Text("#\(name)")
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background {
                    if isSelected {
                        Capsule().fill(MegrumTheme.primaryGradient)
                    } else {
                        Capsule().fill(.white.opacity(0.94))
                    }
                }
                .overlay {
                    if !isSelected {
                        Capsule().strokeBorder(.black.opacity(0.08), lineWidth: 1)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }
}
