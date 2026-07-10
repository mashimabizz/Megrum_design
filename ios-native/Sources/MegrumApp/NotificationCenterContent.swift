import MegrumCore
import MegrumDesign
import SwiftUI

/// 通知一覧（iter1226.408 刷新）：
/// 「今日/今週/それ以前」の時系列セクション＋未読行は淡いラベンダー背景（未読チップ廃止）。
struct NotificationCenterContent: View {
    @Binding var presentationState: NotificationCenterPresentationState
    var isLoading: Bool
    var notifications: [MegrumNotification]
    /// 右端サムネの表示URL（appState側で署名URL解決済み）。iter1226.415。
    var thumbnailURLByID: [UUID: URL] = [:]
    var onSelectNotification: (MegrumNotification) -> Void
    /// いいね集約行のタップ（束ねた全通知を渡す。既読化は呼び出し側の責務）。iter1226.413。
    var onSelectLikeGroup: ([MegrumNotification]) -> Void = { _ in }

    var body: some View {
        List {
            Section {
                Picker("表示", selection: $presentationState.filter) {
                    ForEach(NotificationCenterFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            if isLoading {
                Section {
                    NotificationCenterLoadingRow()
                }
            } else if sections.isEmpty {
                Section {
                    NotificationCenterEmptyRow(title: emptyTitle)
                }
            } else {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.displayItems) { item in
                            Group {
                                switch item {
                                case .single(let notification):
                                    NotificationCenterRow(
                                        notification: notification,
                                        thumbnailURL: thumbnailURLByID[notification.id]
                                    ) {
                                        onSelectNotification(notification)
                                    }
                                case .groomLikeGroup(let group):
                                    NotificationCenterLikeGroupRow(
                                        group: group,
                                        thumbnailURL: group.newest.flatMap { thumbnailURLByID[$0.id] }
                                    ) {
                                        onSelectLikeGroup(group.notifications)
                                    }
                                }
                            }
                            .listRowBackground(
                                item.isUnread
                                    ? MegrumTheme.lavender.opacity(0.07)
                                    : Color.clear
                            )
                        }
                    } header: {
                        Text(section.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                            .textCase(nil)
                    }
                }
            }
        }
    }
}

private struct NotificationCenterLoadingRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("通知を読み込んでいます")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private struct NotificationCenterEmptyRow: View {
    var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.bold))
            Text("打診、取引チャット、チャットルームの更新がここにまとまります。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 8)
    }
}

private extension NotificationCenterContent {
    private var sections: [NotificationCenterSection] {
        presentationState.sections(in: notifications)
    }

    private var emptyTitle: String {
        presentationState.emptyTitle
    }
}
