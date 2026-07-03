import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(iOS) && canImport(GoogleMobileAds)
@preconcurrency import GoogleMobileAds

struct AdMobNativeCardView: UIViewRepresentable {
    var unitID: String
    var presentation: AdNativePresentation
    @Binding var loadState: AdMobNativeLoadState

    func makeUIView(context: Context) -> MegrumNativeAdUIKitView {
        let adView = MegrumNativeAdUIKitView(presentation: presentation)
        context.coordinator.adView = adView
        context.coordinator.load(unitID: unitID)
        return adView
    }

    func updateUIView(_ uiView: MegrumNativeAdUIKitView, context: Context) {
        context.coordinator.adView = uiView
        uiView.nativeAd?.rootViewController = Self.rootViewController
        if context.coordinator.unitID != unitID {
            loadState = .loading
            uiView.reset()
            context.coordinator.load(unitID: unitID)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadState: $loadState)
    }

    private static var rootViewController: UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            if let rootViewController = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController {
                return rootViewController
            }
        }
        return nil
    }

    final class Coordinator: NSObject, NativeAdLoaderDelegate {
        @Binding private var loadState: AdMobNativeLoadState
        weak var adView: MegrumNativeAdUIKitView?
        var adLoader: AdLoader?
        var unitID: String?

        init(loadState: Binding<AdMobNativeLoadState>) {
            _loadState = loadState
        }

        func load(unitID: String) {
            self.unitID = unitID
            let options = NativeAdViewAdOptions()
            options.preferredAdChoicesPosition = .topRightCorner
            let loader = AdLoader(
                adUnitID: unitID,
                rootViewController: AdMobNativeCardView.rootViewController,
                adTypes: [.native],
                options: [options]
            )
            loader.delegate = self
            adLoader = loader
            loader.load(Request())
        }

        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            nativeAd.rootViewController = AdMobNativeCardView.rootViewController
            adView?.configure(with: nativeAd)
            loadState = .loaded
        }

        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            adView?.reset()
            loadState = .failed
        }
    }
}

final class MegrumNativeAdUIKitView: NativeAdView {
    private let presentation: AdNativePresentation
    private let cardView = UIView()
    private let mediaAssetView = MediaView()
    private let adChoicesContainerView = UIView()
    private let adChoicesAssetView = AdChoicesView()
    private let iconImageView = UIImageView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let attributionLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)

    init(presentation: AdNativePresentation) {
        self.presentation = presentation
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        self.presentation = .standard
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with nativeAd: NativeAd) {
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = presentation.isCompactSearchGrid || nativeAd.body == nil
        advertiserLabel.text = nativeAd.advertiser
        advertiserLabel.isHidden = nativeAd.advertiser == nil
        callToActionButton.setTitle(nativeAd.callToAction ?? "詳しく見る", for: .normal)
        callToActionButton.isHidden = nativeAd.callToAction == nil
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon?.image == nil
        mediaAssetView.mediaContent = nativeAd.mediaContent

        headlineView = headlineLabel
        bodyView = bodyLabel
        advertiserView = advertiserLabel
        callToActionView = callToActionButton
        iconView = iconImageView
        mediaView = mediaAssetView
        adChoicesView = adChoicesAssetView
        self.nativeAd = nativeAd
    }

    func reset() {
        nativeAd = nil
        headlineLabel.text = nil
        bodyLabel.text = nil
        advertiserLabel.text = nil
        callToActionButton.setTitle(nil, for: .normal)
        iconImageView.image = nil
        mediaAssetView.mediaContent = nil
    }

    private func setup() {
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = "広告"

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor(white: 1, alpha: 0.92)
        cardView.layer.cornerRadius = 18
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor(red: 0.65, green: 0.58, blue: 0.85, alpha: 0.26).cgColor
        addSubview(cardView)

        mediaAssetView.translatesAutoresizingMaskIntoConstraints = false
        mediaAssetView.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.99, alpha: 1)
        mediaAssetView.layer.cornerRadius = 14
        mediaAssetView.layer.cornerCurve = .continuous
        mediaAssetView.clipsToBounds = true

        adChoicesContainerView.translatesAutoresizingMaskIntoConstraints = false
        adChoicesContainerView.backgroundColor = UIColor(white: 1, alpha: 0.96)
        adChoicesContainerView.layer.cornerRadius = 10
        adChoicesContainerView.layer.cornerCurve = .continuous
        adChoicesContainerView.layer.borderWidth = 1
        adChoicesContainerView.layer.borderColor = UIColor(red: 0.65, green: 0.58, blue: 0.85, alpha: 0.22).cgColor
        adChoicesContainerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        adChoicesContainerView.layer.shadowOpacity = 1
        adChoicesContainerView.layer.shadowRadius = 2
        adChoicesContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)

        adChoicesAssetView.translatesAutoresizingMaskIntoConstraints = false
        adChoicesAssetView.backgroundColor = .clear

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 10
        iconImageView.layer.cornerCurve = .continuous
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFill

        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .systemFont(ofSize: 15, weight: .heavy)
        headlineLabel.textColor = UIColor(red: 0.19, green: 0.17, blue: 0.27, alpha: 1)
        headlineLabel.numberOfLines = 2

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        bodyLabel.textColor = UIColor(red: 0.50, green: 0.47, blue: 0.60, alpha: 1)
        bodyLabel.numberOfLines = 2

        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        advertiserLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        advertiserLabel.textColor = UIColor(red: 0.50, green: 0.47, blue: 0.60, alpha: 1)
        advertiserLabel.numberOfLines = 1

        attributionLabel.translatesAutoresizingMaskIntoConstraints = false
        attributionLabel.text = "Ad"
        attributionLabel.font = .systemFont(ofSize: 10, weight: .black)
        attributionLabel.textColor = .white
        attributionLabel.textAlignment = .center
        attributionLabel.backgroundColor = UIColor(red: 0.65, green: 0.58, blue: 0.85, alpha: 1)
        attributionLabel.layer.cornerRadius = 11
        attributionLabel.layer.cornerCurve = .continuous
        attributionLabel.clipsToBounds = true
        attributionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        callToActionButton.tintColor = .white
        callToActionButton.backgroundColor = UIColor(red: 0.65, green: 0.58, blue: 0.85, alpha: 1)
        callToActionButton.layer.cornerRadius = 14
        callToActionButton.layer.cornerCurve = .continuous
        callToActionButton.isUserInteractionEnabled = false

        let titleStack = UIStackView(arrangedSubviews: [headlineLabel, advertiserLabel, bodyLabel])
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.axis = .vertical
        titleStack.spacing = 3

        let headerStack = UIStackView(arrangedSubviews: [iconImageView, titleStack])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 10

        [mediaAssetView, adChoicesContainerView, headerStack, attributionLabel, callToActionButton].forEach {
            cardView.addSubview($0)
        }
        adChoicesContainerView.addSubview(adChoicesAssetView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            mediaAssetView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            mediaAssetView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            mediaAssetView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            mediaAssetView.heightAnchor.constraint(equalToConstant: presentation.mediaHeight),

            adChoicesContainerView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            adChoicesContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            adChoicesContainerView.widthAnchor.constraint(equalToConstant: 28),
            adChoicesContainerView.heightAnchor.constraint(equalToConstant: 28),

            adChoicesAssetView.centerXAnchor.constraint(equalTo: adChoicesContainerView.centerXAnchor),
            adChoicesAssetView.centerYAnchor.constraint(equalTo: adChoicesContainerView.centerYAnchor),
            adChoicesAssetView.widthAnchor.constraint(equalToConstant: 18),
            adChoicesAssetView.heightAnchor.constraint(equalToConstant: 18),

            headerStack.topAnchor.constraint(equalTo: mediaAssetView.bottomAnchor, constant: presentation.isCompactSearchGrid ? 8 : 12),
            headerStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            headerStack.trailingAnchor.constraint(lessThanOrEqualTo: callToActionButton.leadingAnchor, constant: -8),

            iconImageView.widthAnchor.constraint(equalToConstant: presentation.isCompactSearchGrid ? 30 : 42),
            iconImageView.heightAnchor.constraint(equalToConstant: presentation.isCompactSearchGrid ? 30 : 42),

            attributionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            attributionLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            attributionLabel.widthAnchor.constraint(equalToConstant: 28),
            attributionLabel.heightAnchor.constraint(equalToConstant: 22),

            callToActionButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            callToActionButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: presentation.isCompactSearchGrid ? 64 : 108),
            callToActionButton.heightAnchor.constraint(equalToConstant: presentation.isCompactSearchGrid ? 30 : 34)
        ])
    }
}
#endif
