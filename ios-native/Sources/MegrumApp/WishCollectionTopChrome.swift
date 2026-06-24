import MegrumDesign
import SwiftUI

struct WishCollectionTopChrome: View {
    var title: String
    var accessory: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            accessory
                .padding(.top, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
                .padding(.bottom, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
