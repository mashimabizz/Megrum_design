import MegrumDesign
import SwiftUI

struct WishCollectionTopChrome: View {
    var title: String
    var accessory: AnyView
    @Binding var columns: Int
    var showsColumnToggle: Bool
    var hidesTitle = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !hidesTitle {
                HStack(alignment: .top, spacing: 16) {
                    Text(title)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Spacer()

                    if showsColumnToggle {
                        ColumnToggleButton(columns: $columns)
                            .padding(.top, 3)
                    }
                }
                .transition(MegrumTopChromeCollapseAnimation.titleTransition)
            }

            accessory
                .padding(.top, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
                .padding(.bottom, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
