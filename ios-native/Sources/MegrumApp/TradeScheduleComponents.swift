import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ScheduleEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var placeName: String
    @State private var startAt: Date
    @State private var endAt: Date
    @State private var allDay: Bool
    @State private var note: String

    init(appState: MegrumAppState, proposal: TradeProposal?, defaultDate: Date) {
        self.appState = appState
        self.proposal = proposal
        let start = Self.defaultStartDate(defaultDate)
        self._title = State(initialValue: "")
        self._placeName = State(initialValue: "")
        self._startAt = State(initialValue: start)
        self._endAt = State(initialValue: start.addingTimeInterval(3_600))
        self._allDay = State(initialValue: false)
        self._note = State(initialValue: "")
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && startAt < endAt && !appState.isCreatingSchedule
    }

    var body: some View {
        Form {
            Section {
                TextField("予定名", text: $title)

                TextField("場所", text: $placeName)
            }

            Section {
                Toggle("終日", isOn: $allDay)

                if allDay {
                    DatePicker("開始", selection: $startAt, displayedComponents: [.date])
                    DatePicker("終了", selection: $endAt, displayedComponents: [.date])
                } else {
                    DatePicker("開始", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("終了", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                }
            } header: {
                Text("日時")
            }

            Section {
                TextEditor(text: $note)
                    .frame(minHeight: 96)
            } header: {
                Text("メモ")
            } footer: {
                Text(footerText)
            }
        }
        .navigationTitle("スケジュールを更新")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: startAt) { _, newValue in
            if endAt <= newValue {
                endAt = newValue.addingTimeInterval(allDay ? 86_400 : 3_600)
            }
        }
        .onChange(of: allDay) { _, isAllDay in
            if isAllDay {
                let day = Calendar.current.startOfDay(for: startAt)
                startAt = day
                endAt = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
            } else if endAt <= startAt {
                endAt = startAt.addingTimeInterval(3_600)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await save()
                    }
                } label: {
                    if appState.isCreatingSchedule {
                        ProgressView()
                    } else {
                        Text("保存")
                    }
                }
                .disabled(!canSave)
            }
        }
    }

    private func save() async {
        let input = PersonalScheduleCreateInput(
            title: title,
            placeName: placeName,
            startAt: startAt,
            endAt: endAt,
            allDay: allDay,
            note: note
        )
        if await appState.createSchedule(input, for: proposal) {
            dismiss()
        }
    }

    private var footerText: String {
        if proposal == nil {
            return "保存した予定は、自分のスケジュール画面に表示されます。"
        }
        return "保存した予定は、取引相手がスケジュール共有を許可している時だけ重ねて表示されます。"
    }

    private static func defaultStartDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let now = Date()
            let minute = calendar.component(.minute, from: now)
            let minutesToAdd = minute < 30 ? 30 - minute : 60 - minute
            let next = calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now.addingTimeInterval(1_800)
            return calendar.dateInterval(of: .minute, for: next)?.start ?? next
        }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}

struct ScheduleLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem(title: "あなた", color: MegrumTheme.lavender)
            legendItem(title: "相手", color: MegrumTheme.sky)
            Spacer()
        }
        .font(.system(size: 13, weight: .heavy, design: .rounded))
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text(title)
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

struct ScheduleDayCard: View {
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
                    ScheduleRowView(schedule: schedule, isMine: schedule.userID == viewerID)
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

private struct ScheduleRowView: View {
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

struct ScheduleMonthCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(isToday ? .white : MegrumTheme.ink)
                .frame(width: 26, height: 26)
                .background(isToday ? MegrumTheme.lavender : Color.clear, in: Circle())

            ForEach(schedules.prefix(3)) { schedule in
                HStack(spacing: 3) {
                    Circle()
                        .fill(schedule.userID == viewerID ? MegrumTheme.lavender : MegrumTheme.sky)
                        .frame(width: 5, height: 5)
                    Text(schedule.title)
                        .lineLimit(1)
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .padding(6)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}
