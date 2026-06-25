import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalScheduleBackgroundSection: View {
    var context: ProposalScheduleContext
    var selectedStartAt: Date
    @State private var mode: ProposalScheduleCalendarMode = .fiveDays

    private let calendar = Calendar.current

    var body: some View {
        ProposalCardSection(title: "スケジュール背景") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("表示", selection: $mode) {
                    ForEach(ProposalScheduleCalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ProposalScheduleLegend()

                if context.schedules.isEmpty {
                    ContentUnavailableView(
                        "予定なし",
                        systemImage: "calendar",
                        description: Text("読み込める予定はありません。")
                    )
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                } else {
                    if !context.selectedOverlaps.isEmpty {
                        ProposalSelectedScheduleOverlapBanner(context: context)
                    }

                    switch mode {
                    case .fiveDays:
                        VStack(spacing: 8) {
                            ForEach(context.visibleDays(anchorDate: selectedStartAt, mode: .fiveDays, calendar: calendar), id: \.self) { day in
                                ProposalScheduleDayStrip(
                                    day: day,
                                    schedules: context.schedules(on: day, calendar: calendar),
                                    context: context
                                )
                            }
                        }
                    case .month:
                        ProposalScheduleMonthGrid(context: context, anchorDate: selectedStartAt)
                    }
                }
            }
        }
    }
}
