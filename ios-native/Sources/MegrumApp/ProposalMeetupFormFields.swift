import MegrumDesign
import SwiftUI

struct ProposalMeetupDateRangeFields: View {
    @Binding var startAt: Date
    @Binding var endAt: Date

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("開始日時", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                .proposalFlowMeetupRow()
            Divider()
            DatePicker("終了日時", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                .proposalFlowMeetupRow()
        }
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundStyle(MegrumTheme.ink)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ProposalMeetupPlaceSuggestionChips: View {
    var suggestions: [String]
    var onSelect: (String) -> Void

    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("予定から場所を反映")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                MegrumHaptics.performSelectionChanged {
                                    onSelect(suggestion)
                                }
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundStyle(MegrumTheme.ink)
                                    .padding(.horizontal, 11)
                                    .frame(height: 34)
                                    .background(.white.opacity(0.72), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct ProposalMeetupLocationStatusMessage: View {
    var isRequestingLocation: Bool
    var message: String

    var body: some View {
        HStack(spacing: 8) {
            if isRequestingLocation {
                ProgressView()
                    .controlSize(.small)
            }
            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
