import MegrumDesign
import SwiftUI

enum AuthLegalLinkDestination {
    static let terms = URL(string: "https://megrum.jp/terms")!
    static let privacy = URL(string: "https://megrum.jp/privacy")!
}

struct AuthLegalConsentNotice: View {
    var fontSize: CGFloat = 13

    var body: some View {
        VStack(spacing: 6) {
            Text("登録すると")
                .foregroundStyle(MegrumTheme.muted)
            HStack(spacing: 0) {
                Link("利用規約", destination: AuthLegalLinkDestination.terms)
                Text("・")
                    .foregroundStyle(MegrumTheme.muted)
                Link("プライバシーポリシー", destination: AuthLegalLinkDestination.privacy)
            }
            .fontWeight(.black)
            .tint(MegrumTheme.lavender)
            Text("に同意したことになります")
                .foregroundStyle(MegrumTheme.muted)
        }
        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}
