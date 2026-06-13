import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarCandidateBlock: View {
    var draft: ProposalMeetupCandidateDraft
    var index: Int
    var isSelected: Bool
    var height: CGFloat
    var onTap: () -> Void
    var onMoveChanged: (DragGesture.Value) -> Void
    var onMoveEnded: (DragGesture.Value) -> Void
    var onResizeChanged: (DragGesture.Value) -> Void
    var onResizeEnded: (DragGesture.Value) -> Void
    var onRemove: () -> Void

    var body: some View {
        let candidateTitle = "候補\(index + 1)"
        let placeLabel = draft.normalizedPlaceName.isEmpty ? "場所未入力" : draft.normalizedPlaceName
        let editButtonHeight = max(18, height - 10)

        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? MegrumTheme.lavender : MegrumTheme.sky)
                .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(isSelected ? 0.9 : 0.62), lineWidth: isSelected ? 1.5 : 1)
                .allowsHitTesting(false)

            Button(action: onTap) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.025))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidateTitle)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(placeLabel)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .buttonStyle(.plain)
            .frame(height: editButtonHeight)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
                    .onChanged(onMoveChanged)
                    .onEnded(onMoveEnded)
            )
            .accessibilityLabel("候補\(index + 1)を編集")
            .zIndex(0)

            Rectangle()
                .fill(Color.white.opacity(0.7))
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .offset(y: max(0, height - 8))
                .overlay {
                    Capsule()
                        .fill(MegrumTheme.lavender.opacity(0.84))
                        .frame(width: 28, height: 4)
                }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
                        .onChanged(onResizeChanged)
                        .onEnded(onResizeEnded)
                )
                .zIndex(2)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 22, height: 22)
                    .background(.white.opacity(0.92), in: Circle())
                    .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .padding(4)
            .accessibilityLabel("候補\(index + 1)を削除")
            .zIndex(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ProposalMeetupCalendarModeToggle: View {
    @Binding var selection: ProposalMeetupCalendarDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProposalMeetupCalendarDisplayMode.allCases) { mode in
                Button {
                    withAnimation(.snappy) {
                        selection = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(selection == mode ? .white : MegrumTheme.muted)
                        .frame(width: 38, height: 30)
                        .background(selection == mode ? MegrumTheme.lavender : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("カレンダー\(mode.title)表示")
            }
        }
        .padding(3)
        .background(MegrumTheme.ink.opacity(0.07), in: Capsule())
    }
}

struct ProposalMeetupMonthCalendar: View {
    var anchorDate: Date
    var scheduleContext: ProposalScheduleContext
    var onShiftMonth: (Int) -> Void
    var onSelectDay: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        let days = ProposalMeetupCalendarModel.monthGridDays(anchorDate: anchorDate, calendar: calendar)
        let rowCount = max(1, days.count / ProposalMeetupCalendarModel.monthColumnCount)

        GeometryReader { geometry in
            let cellWidth = ProposalMeetupCalendarModel.monthDayCellWidth(containerWidth: geometry.size.width)
            let gridWidth = ProposalMeetupCalendarModel.monthGridWidth(containerWidth: geometry.size.width)

            VStack(alignment: .leading, spacing: ProposalMeetupCalendarModel.monthHeaderSpacing) {
                monthNavigationHeader

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(weekdayLabels, id: \.self) { label in
                            Text(label)
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                                .frame(width: cellWidth)
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: 4), count: ProposalMeetupCalendarModel.monthColumnCount), spacing: 4) {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                            if let day {
                                ProposalMeetupMonthDayCell(
                                    day: day,
                                    schedules: scheduleContext.schedules(on: day, calendar: calendar),
                                    isToday: calendar.isDateInToday(day),
                                    scheduleContext: scheduleContext,
                                    onSelect: {
                                        onSelectDay(day)
                                    }
                                )
                            } else {
                                Color.clear
                                    .frame(width: cellWidth, height: 74)
                            }
                        }
                    }
                }
            }
            .frame(width: gridWidth, alignment: .leading)
        }
        .padding(.top, 4)
        .frame(height: ProposalMeetupCalendarModel.monthGridHeight(rowCount: rowCount))
        .clipped()
    }

    private var monthNavigationHeader: some View {
        HStack(spacing: 8) {
            Text(ProposalMeetupCalendarModel.monthTitle(anchorDate: anchorDate, calendar: calendar))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Button("◀︎") {
                onShiftMonth(-1)
            }
            .proposalMeetupMonthNavigationButtonStyle(accessibilityLabel: "前の月へ")

            Button("▶︎") {
                onShiftMonth(1)
            }
            .proposalMeetupMonthNavigationButtonStyle(accessibilityLabel: "次の月へ")

            Spacer(minLength: 0)
        }
        .frame(height: ProposalMeetupCalendarModel.monthHeaderHeight)
    }
}

private extension View {
    func proposalMeetupMonthNavigationButtonStyle(accessibilityLabel: String) -> some View {
        self
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(width: 34, height: 30)
            .background(.white.opacity(0.72), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
            .accessibilityLabel(accessibilityLabel)
    }
}

private struct ProposalMeetupMonthDayCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var scheduleContext: ProposalScheduleContext
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 5) {
                Text(ProposalMeetupCalendarModel.dayNumberLabel(for: day))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(isToday ? MegrumTheme.lavender : MegrumTheme.ink)

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(schedules.prefix(3)) { schedule in
                        Text(monthScheduleLabel(for: schedule))
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                (scheduleContext.isMine(schedule) ? MegrumTheme.lavender : MegrumTheme.sky).opacity(scheduleContext.isMine(schedule) ? 0.22 : 0.34),
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                    }

                    if schedules.count > 3 {
                        Text("+\(schedules.count - 3)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
            .background(
                isToday ? MegrumTheme.lavender.opacity(0.12) : MegrumTheme.ink.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isToday ? MegrumTheme.lavender.opacity(0.34) : MegrumTheme.ink.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.formatted(.dateTime.month().day()))を週表示で開く")
    }

    private func monthScheduleLabel(for schedule: PersonalSchedule) -> String {
        if schedule.allDay {
            return schedule.title
        }
        return "\(schedule.startAt.formatted(.dateTime.hour().minute())) \(schedule.title)"
    }
}

struct ProposalMeetupCalendarCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
    }
}
