import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeSummarySheetSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

struct TradeMeetupCandidateSummaryRow: View {
    var index: Int
    var meetup: ProposalMeetupInput

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(MegrumTheme.lavender, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(meetup.placeName)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(timeText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    private var timeText: String {
        "\(meetup.startAt.formatted(.dateTime.month().day().hour().minute())) - \(meetup.endAt.formatted(.dateTime.hour().minute()))"
    }
}

extension ExchangeMethod {
    var supportsHand: Bool {
        self == .hand || self == .both
    }

    var supportsMail: Bool {
        self == .mail || self == .both
    }
}
