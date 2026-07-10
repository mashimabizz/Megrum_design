import MegrumDesign
import SwiftUI

struct OshiMasterSelectHeader: View {
    var showsRequestButton = true
    var onRequest: () -> Void
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("推しを追加")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }
            Spacer()
            if showsRequestButton {
                requestButton
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 40, height: 40)
                    .background(MegrumTheme.ink.opacity(0.045), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 10)
    }

    private var requestButton: some View {
        Button(action: onRequest) {
                Text("追加リクエスト")
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
