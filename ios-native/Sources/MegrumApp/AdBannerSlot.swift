import MegrumDesign
import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(iOS) && canImport(GoogleMobileAds)
@preconcurrency import GoogleMobileAds
#endif

struct AdBannerSlot: View {
    var placement: AdPlacement
    var displayContext: AdDisplayContext
    var configuration: AdRuntimeConfiguration = .current()
    var bottomSpacing: CGFloat = 0
    @State private var adMobLoadState: AdMobBannerLoadState = .loading

    private var decision: AdDisplayDecision {
        AdDisplayPolicy.decision(
            for: placement,
            context: displayContext,
            configuration: configuration
        )
    }

    var body: some View {
        Group {
            if decision.isAllowed {
                if decision.usesPlaceholder {
                    AdBannerPlaceholder(placement: placement)
                        .padding(.bottom, bottomSpacing)
                } else {
                    adMobBanner
                }
            }
        }
        .onChange(of: decision.unitID) { _, _ in
            adMobLoadState = .loading
        }
    }

    @ViewBuilder
    private var adMobBanner: some View {
        #if os(iOS) && canImport(GoogleMobileAds)
        if let unitID = decision.unitID, adMobLoadState != .failed {
            AdMobBannerView(unitID: unitID, loadState: $adMobLoadState)
                .frame(maxWidth: .infinity)
                .frame(height: adMobBannerHeight)
                .padding(.bottom, adMobBannerHeight > 0 ? bottomSpacing : 0)
                .clipped()
                .accessibilityLabel("広告")
        }
        #endif
    }

    private var adMobBannerHeight: CGFloat {
        guard case let .loaded(height) = adMobLoadState else {
            return 0
        }
        return height
    }
}

private enum AdMobBannerLoadState: Equatable {
    case loading
    case loaded(height: CGFloat)
    case failed
}

private struct AdBannerPlaceholder: View {
    var placement: AdPlacement

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("広告枠", systemImage: "megaphone")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.72))

            Text("\(placement.screenID) / \(placement.format.rawValue)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("広告枠")
        .accessibilityHint("広告SDK導入後にバナー広告を表示する場所です")
    }
}

#if os(iOS) && canImport(GoogleMobileAds)
private struct AdMobBannerView: UIViewRepresentable {
    var unitID: String
    @Binding var loadState: AdMobBannerLoadState

    func makeUIView(context: Context) -> BannerView {
        let adSize = largeAnchoredAdaptiveBanner(width: 320)
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = unitID
        banner.rootViewController = UIApplication.shared.megrumAdRootViewController
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.rootViewController = UIApplication.shared.megrumAdRootViewController
        if uiView.adUnitID != unitID {
            loadState = .loading
            uiView.adUnitID = unitID
            uiView.load(Request())
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadState: $loadState)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        @Binding private var loadState: AdMobBannerLoadState

        init(loadState: Binding<AdMobBannerLoadState>) {
            _loadState = loadState
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            loadState = .loaded(height: ceil(bannerView.adSize.size.height))
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            loadState = .failed
        }
    }
}

private extension UIApplication {
    var megrumAdRootViewController: UIViewController? {
        for scene in connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            if let rootViewController = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController {
                return rootViewController
            }
        }
        return nil
    }
}
#endif
