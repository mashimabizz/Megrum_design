import MegrumDesign
import SwiftUI

#if DEBUG
struct MeguriHomeHeader: View {
    var body: some View {
        ZStack {
            Text("めぐり")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
    }
}
#endif
