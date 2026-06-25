import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceActionButton: View {
    var title: String
    var systemImage: String
    var isEnabled: Bool
    var showsProgress = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Label {
                Text(title)
            } icon: {
                if showsProgress {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: systemImage)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .proposalPlaceSheetActionStyle(isEnabled: isEnabled)
        .disabled(!isEnabled)
    }
}
