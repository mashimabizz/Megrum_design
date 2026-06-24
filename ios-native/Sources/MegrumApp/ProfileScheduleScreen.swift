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

private struct ProfileScheduleHeader: View {
    var displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(displayName)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("公開されている予定")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileScheduleDayCard: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(day.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Spacer()
                if Calendar.current.isDateInToday(day) {
                    Text("今日")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(MegrumTheme.lavender, in: Capsule())
                }
            }

            if schedules.isEmpty {
                Text("予定なし")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(schedules) { schedule in
                    ProfileScheduleRowView(schedule: schedule, isMine: schedule.userID == viewerID)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct ProfileScheduleRowView: View {
    var schedule: PersonalSchedule
    var isMine: Bool

    private var color: Color {
        isMine ? MegrumTheme.lavender : MegrumTheme.sky
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(schedule.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(isMine ? "あなた" : "相手")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.13), in: Capsule())
                }

                Text(timeRangeText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                if let placeName = schedule.placeName {
                    Label(placeName, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var timeRangeText: String {
        if schedule.allDay {
            return "終日"
        }
        let start = schedule.startAt.formatted(.dateTime.hour().minute())
        let end = schedule.endAt.formatted(.dateTime.hour().minute())
        return "\(start) - \(end)"
    }
}

private struct ProfileScheduleMonthCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Calendar.current.isDateInToday(day) ? MegrumTheme.lavender : MegrumTheme.ink)

            ForEach(schedules.prefix(2)) { schedule in
                HStack(spacing: 4) {
                    Circle()
                        .fill(schedule.userID == viewerID ? MegrumTheme.lavender : MegrumTheme.sky)
                        .frame(width: 5, height: 5)
                    Text(schedule.title)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 64, alignment: .topLeading)
        .padding(6)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
