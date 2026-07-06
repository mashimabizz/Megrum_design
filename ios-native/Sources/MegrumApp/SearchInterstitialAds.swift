import Foundation
import SwiftUI
#if os(iOS)
@preconcurrency import GoogleMobileAds
import UIKit
#endif

/// 検索インターステイシャルの頻度ルール：
/// 1日の検索2回目に1回挟み、以降は2回ごと（2・4・6…回目）に挟む。
enum SearchInterstitialFrequencyPolicy {
    static func shouldShowInterstitial(searchCountToday: Int) -> Bool {
        searchCountToday >= 2 && searchCountToday.isMultiple(of: 2)
    }
}

/// 「今日何回検索したか」の永続カウンタ。日付が変わったら1から数え直す。
enum SearchDailyCountStore {
    static let dayKey = "megrum.search.interstitial.day"
    static let countKey = "megrum.search.interstitial.count"

    static func incrementedCount(
        now: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) -> Int {
        let day = dayIdentifier(for: now, calendar: calendar)
        let count = defaults.string(forKey: dayKey) == day
            ? defaults.integer(forKey: countKey) + 1
            : 1
        defaults.set(day, forKey: dayKey)
        defaults.set(count, forKey: countKey)
        return count
    }

    static func dayIdentifier(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}

#if os(iOS)
/// 検索画面用のインターステイシャル広告コントローラ。
/// 事前ロードしておき、頻度ルールに合致した検索の直後に全画面表示する。
@MainActor
final class SearchInterstitialAdController: NSObject, ObservableObject {
    private var loadedAd: InterstitialAd?
    private var isLoading = false
    private var presentsWhenLoaded = false
    private var currentUnitID: String?

    /// ユーザーが検索を1回実行した時に呼ぶ。カウントを進め、
    /// 2回目・以降2回ごとにインターステイシャルを表示する。
    func registerSearch(
        displayContext: AdDisplayContext,
        configuration: AdRuntimeConfiguration
    ) {
        guard let unitID = allowedUnitID(displayContext: displayContext, configuration: configuration) else {
            return
        }
        let count = SearchDailyCountStore.incrementedCount()
        guard SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: count) else {
            preload(unitID: unitID)
            return
        }
        if loadedAd != nil {
            presentLoadedAd()
        } else {
            // まだロード中なら、ロード完了と同時に表示する。
            presentsWhenLoaded = true
            preload(unitID: unitID)
        }
    }

    /// 検索画面表示時に呼んで事前ロードしておく。
    func preloadIfNeeded(
        displayContext: AdDisplayContext,
        configuration: AdRuntimeConfiguration
    ) {
        guard let unitID = allowedUnitID(displayContext: displayContext, configuration: configuration) else {
            return
        }
        preload(unitID: unitID)
    }

    private func allowedUnitID(
        displayContext: AdDisplayContext,
        configuration: AdRuntimeConfiguration
    ) -> String? {
        // VisualQA の自動検索ではカウント・表示しない
        guard !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) else {
            return nil
        }
        let decision = AdDisplayPolicy.decision(
            for: .searchBrowseInterstitial,
            context: displayContext,
            configuration: configuration
        )
        guard decision.isAllowed, let unitID = decision.unitID else {
            return nil
        }
        return unitID
    }

    private func preload(unitID: String) {
        guard loadedAd == nil, !isLoading else {
            return
        }
        isLoading = true
        currentUnitID = unitID
        Task { @MainActor [weak self] in
            do {
                let ad = try await InterstitialAd.load(with: unitID, request: Request())
                guard let self else {
                    return
                }
                self.isLoading = false
                self.loadedAd = ad
                self.loadedAd?.fullScreenContentDelegate = self
                if self.presentsWhenLoaded {
                    self.presentsWhenLoaded = false
                    self.presentLoadedAd()
                }
            } catch {
                #if DEBUG
                print("[Ads] search interstitial load failed: \(error.localizedDescription)")
                #endif
                guard let self else {
                    return
                }
                self.isLoading = false
                self.presentsWhenLoaded = false
            }
        }
    }

    private func presentLoadedAd() {
        guard let ad = loadedAd, let presenter = Self.topViewController() else {
            return
        }
        loadedAd = nil
        ad.present(from: presenter)
    }

    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension SearchInterstitialAdController: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            // 閉じたら次回分を事前ロードしておく。
            if let unitID = currentUnitID {
                preload(unitID: unitID)
            }
        }
    }
}
#else
@MainActor
final class SearchInterstitialAdController: NSObject, ObservableObject {
    func registerSearch(displayContext: AdDisplayContext, configuration: AdRuntimeConfiguration) {}
    func preloadIfNeeded(displayContext: AdDisplayContext, configuration: AdRuntimeConfiguration) {}
}
#endif
