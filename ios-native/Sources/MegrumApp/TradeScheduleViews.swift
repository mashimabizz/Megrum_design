import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct PersonalScheduleScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onClose: (() -> Void)?
    @State private var mode: TradeScheduleCalendarMode = .fiveDays
    @State private var anchorDate = Date()
    @State private var isShowingScheduleEditor = false

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
        "\(mode.rawValue)-\(Int(visibleInterval.start.timeIntervalSince1970))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("表示", selection: $mode) {
                    ForEach(TradeScheduleCalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if appState.isLoadingPersonalSchedules {
                    ScheduleLoadingNotice()
                }

                switch mode {
                case .fiveDays:
                    fiveDayView
                case .month:
                    monthView
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
            await appState.loadPersonalSchedules(startAt: visibleInterval.start, endAt: visibleInterval.end)
        }
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る") {
                        onClose()
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingScheduleEditor = true
                } label: {
                    Label("追加", systemImage: "plus")
                }
                .accessibilityLabel("自分のスケジュールを追加")
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
        .sheet(isPresented: $isShowingScheduleEditor) {
            NavigationStack {
                ScheduleEditorSheet(
                    appState: appState,
                    proposal: nil,
                    defaultDate: anchorDate
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var fiveDayView: some View {
        VStack(spacing: 12) {
            ForEach(fiveVisibleDays, id: \.self) { day in
                ScheduleDayCard(
                    day: day,
                    schedules: schedules(on: day),
                    viewerID: appState.viewer?.id
                )
            }
        }
    }

    private var monthView: some View {
        ScheduleMonthGrid(
            monthTitle: monthTitle,
            monthGridDays: monthGridDays,
            calendar: calendar,
            viewerID: appState.viewer?.id,
            schedulesForDay: schedules(on:),
            onPreviousMonth: { moveAnchor(by: -1) },
            onNextMonth: { moveAnchor(by: 1) }
        )
    }

    private var fiveVisibleDays: [Date] {
        let start = calendar.startOfDay(for: anchorDate)
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var monthGridDays: [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = (calendar.component(.weekday, from: month.start) + 6) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private var monthTitle: String {
        anchorDate.formatted(.dateTime.year().month(.wide))
    }

    private func schedules(on day: Date) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return appState.personalSchedules.filter { $0.overlaps(start: start, end: end) }
    }

    private func moveAnchor(by value: Int) {
        let component: Calendar.Component = mode == .month ? .month : .day
        anchorDate = calendar.date(byAdding: component, value: value, to: anchorDate) ?? anchorDate
    }
}

struct TradeScheduleSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var mode: TradeScheduleCalendarMode = .fiveDays
    @State private var anchorDate = Date()
    @State private var isShowingScheduleEditor = false

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
        "\(mode.rawValue)-\(Int(visibleInterval.start.timeIntervalSince1970))"
    }

    private var schedules: [PersonalSchedule] {
        appState.schedules(for: proposal.id)
    }

    private var viewerID: UUID? {
        appState.viewer?.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("表示", selection: $mode) {
                    ForEach(TradeScheduleCalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ScheduleLegend()

                if appState.loadingSchedulesProposalID == proposal.id {
                    ScheduleLoadingNotice()
                }

                switch mode {
                case .fiveDays:
                    fiveDayView
                case .month:
                    monthView
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
            await appState.loadSchedules(for: proposal, startAt: visibleInterval.start, endAt: visibleInterval.end)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingScheduleEditor = true
                } label: {
                    Label("更新", systemImage: "plus")
                }
                .accessibilityLabel("自分のスケジュールを追加")
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
        .sheet(isPresented: $isShowingScheduleEditor) {
            NavigationStack {
                ScheduleEditorSheet(
                    appState: appState,
                    proposal: proposal,
                    defaultDate: anchorDate
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var fiveDayView: some View {
        VStack(spacing: 12) {
            ForEach(fiveVisibleDays, id: \.self) { day in
                ScheduleDayCard(
                    day: day,
                    schedules: schedules(on: day),
                    viewerID: viewerID
                )
            }
        }
    }

    private var monthView: some View {
        ScheduleMonthGrid(
            monthTitle: monthTitle,
            monthGridDays: monthGridDays,
            calendar: calendar,
            viewerID: viewerID,
            schedulesForDay: schedules(on:),
            onPreviousMonth: { moveAnchor(by: -1) },
            onNextMonth: { moveAnchor(by: 1) }
        )
    }

    private var fiveVisibleDays: [Date] {
        let start = calendar.startOfDay(for: anchorDate)
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var monthGridDays: [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = (calendar.component(.weekday, from: month.start) + 6) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private var monthTitle: String {
        anchorDate.formatted(.dateTime.year().month(.wide))
    }

    private func schedules(on day: Date) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return schedules.filter { $0.overlaps(start: start, end: end) }
    }

    private func moveAnchor(by value: Int) {
        let component: Calendar.Component = mode == .month ? .month : .day
        anchorDate = calendar.date(byAdding: component, value: value, to: anchorDate) ?? anchorDate
    }
}
