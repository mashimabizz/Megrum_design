import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceStatusRow: View {
    var canSave: Bool
    var message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: canSave ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(canSave ? MegrumTheme.ok : MegrumTheme.pink)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}
