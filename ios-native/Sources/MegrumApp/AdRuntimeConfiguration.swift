import Foundation

struct AdRuntimeConfiguration: Equatable, Sendable {
    var isEnabled: Bool
    var showsPlaceholders: Bool
    var provider: AdProvider
    var appID: String?
    var unitIDs: [AdPlacement: String]

    init(
        isEnabled: Bool = false,
        showsPlaceholders: Bool = false,
        provider: AdProvider = .admob,
        appID: String? = nil,
        unitIDs: [AdPlacement: String] = [:]
    ) {
        self.isEnabled = isEnabled
        self.showsPlaceholders = showsPlaceholders
        self.provider = provider
        self.appID = Self.cleaned(appID)
        self.unitIDs = unitIDs.compactMapValues(Self.cleaned)
    }

    static let disabled = AdRuntimeConfiguration()

    func unitID(for placement: AdPlacement) -> String? {
        unitIDs[placement]
    }

    static func current(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary
    ) -> AdRuntimeConfiguration {
        let isEnabled = bool(
            environment["MEGRUM_ADS_ENABLED"]
                ?? infoDictionary?["MegrumAdsEnabled"] as? String
        )
        let showsPlaceholders = bool(
            environment["MEGRUM_AD_PLACEHOLDERS_ENABLED"]
                ?? infoDictionary?["MegrumAdPlaceholdersEnabled"] as? String
        )
        let provider = AdProvider(
            rawValue: cleaned(
                environment["MEGRUM_AD_PROVIDER"]
                    ?? infoDictionary?["MegrumAdProvider"] as? String
            ) ?? ""
        ) ?? .admob
        let appID = cleaned(
            environment["MEGRUM_ADMOB_APP_ID"]
                ?? infoDictionary?["MegrumAdMobAppID"] as? String
        )
        let unitIDs = Dictionary(uniqueKeysWithValues: AdPlacement.allCases.compactMap { placement in
            let environmentKey = environmentKey(for: placement)
            let value = cleaned(
                environment[environmentKey]
                    ?? infoDictionary?[placement.unitIDInfoKey] as? String
            )
            return value.map { (placement, $0) }
        })
        return AdRuntimeConfiguration(
            isEnabled: isEnabled,
            showsPlaceholders: showsPlaceholders,
            provider: provider,
            appID: appID,
            unitIDs: unitIDs
        )
    }

    static func environmentKey(for placement: AdPlacement) -> String {
        switch placement {
        case .homeFeedBanner:
            "MEGRUM_ADMOB_HOME_BANNER_UNIT_ID"
        case .wishListBanner:
            "MEGRUM_ADMOB_WISH_BANNER_UNIT_ID"
        case .searchResultsBanner:
            "MEGRUM_ADMOB_SEARCH_BANNER_UNIT_ID"
        case .publicProfileFooterBanner:
            "MEGRUM_ADMOB_PROFILE_BANNER_UNIT_ID"
        case .pastTradesFooterBanner:
            "MEGRUM_ADMOB_TRADES_BANNER_UNIT_ID"
        case .homeBrowseInterstitial:
            "MEGRUM_ADMOB_HOME_INTERSTITIAL_UNIT_ID"
        case .wishBrowseInterstitial:
            "MEGRUM_ADMOB_WISH_INTERSTITIAL_UNIT_ID"
        case .searchBrowseInterstitial:
            "MEGRUM_ADMOB_SEARCH_INTERSTITIAL_UNIT_ID"
        case .meguriBrowseInterstitial:
            "MEGRUM_ADMOB_MEGURI_INTERSTITIAL_UNIT_ID"
        }
    }

    private static func bool(_ value: String?) -> Bool {
        switch cleaned(value)?.lowercased() {
        case "1", "true", "yes", "on":
            true
        default:
            false
        }
    }

    private static func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty, !trimmed.contains("$(") else {
            return nil
        }
        return trimmed
    }
}
