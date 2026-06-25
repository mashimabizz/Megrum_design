import MegrumCore
import MegrumDesign
import SwiftUI

struct ProfileScheduleScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var displayName: String
    var onClose: (() -> Void)?
    @State private var mode: TradeScheduleCalendarMode = .fiveDays
    @State private var anchorDate = Date()

    private let calendar = Calendar.current

    private var visibleInterval: DateInterval {
        switch mode {
        case .fiveDays:
            let start = calendar.startOfDay(for: anchorDate)
            let end = calendar.date(byAdding: .day, value: 5, to: start) ?? start.addingTimeInterval(86_400 * 5)
            return DateInterval(start: start, end: end)
        case .month:
            return calendar.dateInterval(of: .month, for: anchorDate)
                ?? DateInterval(start: calendar.startOfDay(for: anchorDate), duration: 86_400 * 31)
        }
    }

    private var reloadKey: String {
        "\(userID.uuidString)-\(mode.rawValue)-\(Int(visibleInterval.start.timeIntervalSince1970))"
    }

    private var schedules: [PersonalSchedule] {
        appState.profileSchedules(for: userID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProfileScheduleHeader(displayName: displayName)

                Picker("表示", selection: $mode) {
                    ForEach(TradeScheduleCalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if appState.loadingProfileScheduleUserID == userID {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("スケジュールを読み込んでいます")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                if schedules.isEmpty, appState.loadingProfileScheduleUserID != userID {
                    ContentUnavailableView(
                        "表示できる予定はまだありません",
                        systemImage: "calendar",
                        description: Text("公開されているスケジュールがここに表示されます。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 36)
                } else {
                    switch mode {
                    case .fiveDays:
                        fiveDayView
                    case .month:
                        monthView
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("スケジュール")
        .megrumInlineNavigationTitle()
        .task(id: reloadKey) {
            await appState.loadProfileSchedules(
                userID: userID,
                startAt: visibleInterval.start,
                endAt: visibleInterval.end
            )
        }
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る", action: onClose)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    moveAnchor(by: mode == .month ? 1 : 5)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel(mode == .month ? "次の月" : "次の週")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    moveAnchor(by: mode == .month ? -1 : -5)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel(mode == .month ? "前の月" : "前の週")
            }
        }
    }

    private var fiveDayView: some View {
        VStack(spacing: 12) {
            ForEach(fiveVisibleDays, id: \.self) { day in
                ProfileScheduleDayCard(
                    day: day,
                    schedules: schedules(on: day),
                    viewerID: appState.viewer?.id
                )
            }
        }
    }

    private var monthView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(monthDays, id: \.self) { day in
                ProfileScheduleMonthCell(
                    day: day,
                    schedules: schedules(on: day),
                    viewerID: appState.viewer?.id
                )
            }
        }
    }

    private var fiveVisibleDays: [Date] {
        (0..<5).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: visibleInterval.start)
        }
    }

    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: anchorDate) else {
            return []
        }
        let days = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 0
        return (0..<days).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monthInterval.start)
        }
    }

    private func schedules(on day: Date) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return schedules.filter { $0.overlaps(start: start, end: end) }
    }

    private func moveAnchor(by value: Int) {
        if let next = calendar.date(byAdding: .day, value: value, to: anchorDate) {
            anchorDate = next
        }
    }
}
