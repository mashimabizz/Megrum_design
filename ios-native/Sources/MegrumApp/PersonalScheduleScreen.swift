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

    private var calendarWindow: TradeScheduleCalendarWindow {
        TradeScheduleCalendarWindow(mode: mode, anchorDate: anchorDate, calendar: calendar)
    }

    private var visibleInterval: DateInterval {
        calendarWindow.visibleInterval
    }

    private var reloadKey: String {
        calendarWindow.reloadKey
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
            ForEach(calendarWindow.fiveVisibleDays, id: \.self) { day in
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
            monthTitle: calendarWindow.monthTitle,
            monthGridDays: calendarWindow.monthGridDays,
            calendar: calendar,
            viewerID: appState.viewer?.id,
            schedulesForDay: schedules(on:),
            onPreviousMonth: { moveAnchor(by: -1) },
            onNextMonth: { moveAnchor(by: 1) }
        )
    }

    private func schedules(on day: Date) -> [PersonalSchedule] {
        calendarWindow.schedules(on: day, from: appState.personalSchedules)
    }

    private func moveAnchor(by value: Int) {
        anchorDate = calendarWindow.movedAnchor(by: value)
    }
}
