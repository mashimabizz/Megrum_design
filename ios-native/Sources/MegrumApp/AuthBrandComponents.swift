import MegrumDesign
import SwiftUI

struct AuthBrandLockup: View {
    var compact = false
    var showIconTile = false

    var body: some View {
        Group {
            if compact {
                HStack(spacing: 15) {
                    AuthAppIconMark(size: 38)
                    MegrumWordmark(width: 124)
                }
            } else if showIconTile {
                VStack(spacing: 18) {
                    AuthAppIconMark(size: 72)
                    MegrumWordmark(width: 184)
                }
            } else {
                MegrumWordmark(width: 184)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            if !compact && !showIconTile {
                AuthAppIconMark(size: 74)
                    .offset(y: -70)
            }
        }
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
