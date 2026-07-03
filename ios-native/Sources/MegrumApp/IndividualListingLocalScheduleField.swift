import Foundation
import MegrumDesign
import SwiftUI

struct IndividualListingLocalScheduleField: View {
    @Binding var localSchedule: String
    @State private var scheduleState: IndividualListingLocalScheduleState

    init(localSchedule: Binding<String>) {
        _localSchedule = localSchedule
        _scheduleState = State(initialValue: IndividualListingLocalScheduleState(localSchedule: localSchedule.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("日程")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
            }

            Picker("日程", selection: $scheduleState.mode) {
                ForEach(IndividualListingLocalScheduleMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if scheduleState.mode == .dates {
                DatePicker(
                    "日程を選択",
                    selection: $scheduleState.selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(MegrumTheme.lavender)
                .onAppear {
                    if let text = scheduleState.onDatePickerAppearText() {
                        localSchedule = text
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .onChange(of: scheduleState.mode) { _, _ in
            localSchedule = scheduleState.localScheduleTextAfterModeChange(currentLocalSchedule: localSchedule)
        }
        .onChange(of: scheduleState.selectedDate) { _, newValue in
            if let text = scheduleState.localScheduleTextAfterDateChange(newValue) {
                localSchedule = text
            }
        }
        .onChange(of: localSchedule) { _, newValue in
            scheduleState.applyExternalLocalSchedule(newValue)
        }
    }
}
