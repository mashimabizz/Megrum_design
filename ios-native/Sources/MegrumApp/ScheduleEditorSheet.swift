import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ScheduleEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal?
    @Environment(\.dismiss) private var dismiss
    @State private var draftState: ScheduleEditorDraftState

    init(appState: MegrumAppState, proposal: TradeProposal?, defaultDate: Date) {
        self.appState = appState
        self.proposal = proposal
        self._draftState = State(initialValue: ScheduleEditorDraftState(defaultDate: defaultDate))
    }

    var body: some View {
        Form {
            Section {
                TextField("予定名", text: $draftState.title)

                TextField("場所", text: $draftState.placeName)
            }

            Section {
                Toggle("終日", isOn: $draftState.allDay)

                if draftState.allDay {
                    DatePicker("開始", selection: $draftState.startAt, displayedComponents: [.date])
                    DatePicker("終了", selection: $draftState.endAt, displayedComponents: [.date])
                } else {
                    DatePicker("開始", selection: $draftState.startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("終了", selection: $draftState.endAt, displayedComponents: [.date, .hourAndMinute])
                }
            } header: {
                Text("日時")
            }

            Section {
                TextEditor(text: $draftState.note)
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
        .onChange(of: draftState.startAt) { _, _ in
            draftState.adjustEndAfterStartChange()
        }
        .onChange(of: draftState.allDay) { _, isAllDay in
            draftState.setAllDay(isAllDay)
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
                .disabled(!draftState.canSave(isCreatingSchedule: appState.isCreatingSchedule))
            }
        }
    }

    private func save() async {
        let input = draftState.makeInput()
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
}
