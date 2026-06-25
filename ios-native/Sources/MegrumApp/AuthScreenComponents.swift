import MegrumDesign
import SwiftUI

struct AuthTopBar: View {
    var title: String
    var onBack: () -> Void

    var body: some View {
        ZStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 29, weight: .medium))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .padding(.top, 30)
        .frame(height: 76)
    }
}
