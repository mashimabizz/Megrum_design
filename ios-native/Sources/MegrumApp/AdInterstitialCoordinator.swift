import Foundation
import MegrumDesign
import SwiftUI

struct AdInterstitialRequest: Identifiable, Equatable {
    var id = UUID()
    var placement: AdPlacement
    var requestedAt: Date = Date()
}

struct AdInterstitialPresentation: Identifiable, Equatable {
    var id = UUID()
    var placement: AdPlacement
    var unitID: String?
    var requestedAt: Date
}

enum AdInterstitialCoordinator {
    static let minimumInterval: TimeInterval = 180

    static func presentation(
        for request: AdInterstitialRequest,
        context: AdDisplayContext,
        configuration: AdRuntimeConfiguration,
        lastPresentedAt: Date?
    ) -> Result<AdInterstitialPresentation, AdSuppressionReason> {
        guard request.placement.format == .interstitial else {
            return .failure(.forbiddenScreen)
        }
        if let lastPresentedAt,
           request.requestedAt.timeIntervalSince(lastPresentedAt) < minimumInterval {
            return .failure(.frequencyCapped)
        }

        let decision = AdDisplayPolicy.decision(
            for: request.placement,
            context: context,
            configuration: configuration
        )
        guard decision.isAllowed else {
            return .failure(decision.suppressionReason ?? .configurationDisabled)
        }
        return .success(
            AdInterstitialPresentation(
                placement: request.placement,
                unitID: decision.unitID,
                requestedAt: request.requestedAt
            )
        )
    }
}

enum AdInterstitialPlacementResolver {
    static func placement(for tab: MegrumTab) -> AdPlacement? {
        switch tab {
        case .home:
            .homeBrowseInterstitial
        case .wish:
            .wishBrowseInterstitial
        case .meguri:
            .meguriBrowseInterstitial
        case .inventory, .trades:
            nil
        }
    }
}

struct AdInterstitialPresenterModifier: ViewModifier {
    @Binding var request: AdInterstitialRequest?
    var displayContext: AdDisplayContext
    var configuration: AdRuntimeConfiguration
    @State private var placeholderPresentation: AdInterstitialPresentation?
    @State private var lastPresentedAt: Date?

    func body(content: Content) -> some View {
        content
            .onChange(of: request) { _, request in
                handle(request)
            }
            .sheet(item: $placeholderPresentation) { presentation in
                AdInterstitialPlaceholderView(presentation: presentation)
            }
    }

    private func handle(_ request: AdInterstitialRequest?) {
        guard let request else {
            return
        }
        defer {
            self.request = nil
        }

        switch AdInterstitialCoordinator.presentation(
            for: request,
            context: displayContext,
            configuration: configuration,
            lastPresentedAt: lastPresentedAt
        ) {
        case .success(let presentation):
            lastPresentedAt = request.requestedAt
            if configuration.showsPlaceholders {
                placeholderPresentation = presentation
            }
        case .failure:
            break
        }
    }
}

extension View {
    func adInterstitialPresenter(
        request: Binding<AdInterstitialRequest?>,
        displayContext: AdDisplayContext,
        configuration: AdRuntimeConfiguration
    ) -> some View {
        modifier(
            AdInterstitialPresenterModifier(
                request: request,
                displayContext: displayContext,
                configuration: configuration
            )
        )
    }
}

private struct AdInterstitialPlaceholderView: View {
    var presentation: AdInterstitialPresentation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "megaphone.fill")
                .font(.system(size: 46, weight: .heavy))
                .foregroundStyle(MegrumTheme.lavender)

            Text("インターステイシャル広告枠")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("\(presentation.placement.screenID) に将来の全画面広告SDKを接続します。")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()

            Button("閉じる", action: dismiss.callAsFunction)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(MegrumTheme.lavender, in: Capsule())
                .padding(.horizontal, 24)
                .padding(.bottom, 26)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }
}
