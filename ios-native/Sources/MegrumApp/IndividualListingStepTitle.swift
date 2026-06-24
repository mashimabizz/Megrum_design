import MegrumDesign
import SwiftUI

struct IndividualListingStepTitle: View {
    var step: IndividualListingEditorStep

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(step.title)
                .font(.system(size: step == .exchange ? 27 : 29, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
