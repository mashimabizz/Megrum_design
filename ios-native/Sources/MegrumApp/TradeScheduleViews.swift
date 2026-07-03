import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeScheduleSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var presentationState = TradeSchedulePresentationState()

    private let calendar = Calendar.current

    private var calendarWindow: TradeScheduleCalendarWindow {
        presentationState.calendarWindow(calendar: calendar)
    }

    private var visibleInterval: DateInterval {
        presentationState.visibleInterval(calendar: calendar)
    }

    private var reloadKey: String {
        presentationState.reloadKey(calendar: calendar)
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
                Picker("表示", selection: $presentationState.mode) {
                    ForEach(TradeScheduleCalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ScheduleLegend()

                if appState.loadingSchedulesProposalID == proposal.id {
                    ScheduleLoadingNotice()
                }

                switch presentationState.mode {
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
                    presentationState.showScheduleEditor()
                } label: {
                    Label("更新", systemImage: "plus")
                }
                .accessibilityLabel("自分のスケジュールを追加")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    moveAnchor(by: presentationState.mode == .month ? 1 : 5)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel(presentationState.mode == .month ? "次の月" : "次の週")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    moveAnchor(by: presentationState.mode == .month ? -1 : -5)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel(presentationState.mode == .month ? "前の月" : "前の週")
            }
        }
        .sheet(isPresented: $presentationState.isShowingScheduleEditor) {
            NavigationStack {
                ScheduleEditorSheet(
                    appState: appState,
                    proposal: proposal,
                    defaultDate: presentationState.anchorDate
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var fiveDayView: some View {
        VStack(spacing: 12) {
            ForEach(calendarWindow.fiveVisibleDays, id: \.self) { day in
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
            monthTitle: calendarWindow.monthTitle,
            monthGridDays: calendarWindow.monthGridDays,
            calendar: calendar,
            viewerID: viewerID,
            schedulesForDay: schedules(on:),
            onPreviousMonth: { moveAnchor(by: -1) },
            onNextMonth: { moveAnchor(by: 1) }
        )
    }

    private func schedules(on day: Date) -> [PersonalSchedule] {
        calendarWindow.schedules(on: day, from: schedules)
    }

    private func moveAnchor(by value: Int) {
        presentationState.moveAnchor(by: value, calendar: calendar)
    }
}
