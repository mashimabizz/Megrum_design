import MegrumCore
import MegrumDesign
import SwiftUI

struct ProfileScheduleScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var displayName: String
    var onClose: (() -> Void)?
    @State private var presentationState = ProfileSchedulePresentationState()

    private let calendar = Calendar.current

    private var visibleInterval: DateInterval {
        presentationState.visibleInterval(calendar: calendar)
    }

    private var reloadKey: String {
        presentationState.reloadKey(userID: userID, calendar: calendar)
    }

    private var schedules: [PersonalSchedule] {
        appState.profileSchedules(for: userID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProfileScheduleHeader(displayName: displayName)

                Picker("表示", selection: $presentationState.mode) {
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
                    switch presentationState.mode {
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
        presentationState.fiveVisibleDays(calendar: calendar)
    }

    private var monthDays: [Date] {
        presentationState.monthDays(calendar: calendar)
    }

    private func schedules(on day: Date) -> [PersonalSchedule] {
        presentationState.schedules(on: day, from: schedules, calendar: calendar)
    }

    private func moveAnchor(by value: Int) {
        presentationState.moveAnchor(by: value, calendar: calendar)
    }
}
