import MegrumDesign
import SwiftUI

enum AdNativePresentation: Equatable {
    case standard
    case searchResultsGrid

    var cardHeight: CGFloat {
        switch self {
        case .standard:
            250
        case .searchResultsGrid:
            SearchResultGridMetrics.nativeAdCardHeight
        }
    }

    var mediaHeight: CGFloat {
        switch self {
        case .standard:
            128
        case .searchResultsGrid:
            SearchResultGridMetrics.nativeAdMediaHeight
        }
    }

    var isCompactSearchGrid: Bool {
        self == .searchResultsGrid
    }
}

enum AdMobNativeLoadState: Equatable {
    case loading
    case loaded
    case failed
}

struct AdNativePlaceholder: View {
    var placement: AdPlacement
    var presentation: AdNativePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("広告")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(MegrumTheme.lavender, in: Capsule())

                Text("Sponsored")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Text("\(placement.screenID) / \(placement.format.rawValue)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: presentation.cardHeight, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("広告枠")
    }
}
