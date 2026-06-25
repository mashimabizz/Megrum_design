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
