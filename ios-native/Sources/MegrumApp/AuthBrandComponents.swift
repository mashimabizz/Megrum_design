import MegrumDesign
import SwiftUI

struct AuthBrandLockup: View {
    enum Style {
        case wordmarkOnly
        case iconAboveWordmark
        case compactIconAndWordmark
    }

    var style: Style = .wordmarkOnly
    var wordmarkWidth: CGFloat = 184

    var body: some View {
        Group {
            switch style {
            case .compactIconAndWordmark:
                HStack(spacing: 15) {
                    AuthAppIconMark(size: 38)
                    MegrumWordmark(width: wordmarkWidth)
                }
            case .iconAboveWordmark:
                VStack(spacing: 18) {
                    AuthAppIconMark(size: 72)
                    MegrumWordmark(width: wordmarkWidth)
                }
            case .wordmarkOnly:
                MegrumWordmark(width: wordmarkWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AuthAppIconMark: View {
    var size: CGFloat

    var body: some View {
        Image("MegrumBrandIcon", bundle: .main)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct MegrumWordmark: View {
    var width: CGFloat

    var body: some View {
        Image("MegrumWordmark", bundle: .main)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .accessibilityLabel("Megrum")
    }
}
