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
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }
            Spacer()
            if showsRequestButton {
                requestButton
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 48, height: 48)
                    .background(.black.opacity(0.04), in: Circle())
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
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .background(MegrumTheme.lavender.opacity(0.11), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
