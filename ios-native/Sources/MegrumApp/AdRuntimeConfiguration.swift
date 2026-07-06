import Foundation

struct AdRuntimeConfiguration: Equatable, Sendable {
    static let googleDemoBannerUnitID = "ca-app-pub-3940256099942544/2435281174"
    static let googleDemoNativeUnitID = "ca-app-pub-3940256099942544/3986624511"
    static let previewViewerIDsEnvironmentKey = "MEGRUM_AD_PREVIEW_VIEWER_IDS"

    var isEnabled: Bool
    var showsPlaceholders: Bool
    var provider: AdProvider
    var appID: String?
    var usesGoogleTestAdUnits: Bool
    var testBannerUnitID: String?
    var testNativeUnitID: String?
    var unitIDs: [AdPlacement: String]
    var previewViewerIDs: Set<UUID>

    init(
        isEnabled: Bool = false,
        showsPlaceholders: Bool = false,
        provider: AdProvider = .admob,
        appID: String? = nil,
        usesGoogleTestAdUnits: Bool = false,
        testBannerUnitID: String? = nil,
        testNativeUnitID: String? = nil,
        unitIDs: [AdPlacement: String] = [:],
        previewViewerIDs: Set<UUID> = []
    ) {
        self.isEnabled = isEnabled
        self.showsPlaceholders = showsPlaceholders
        self.provider = provider
        self.appID = Self.cleaned(appID)
        self.usesGoogleTestAdUnits = usesGoogleTestAdUnits
        self.testBannerUnitID = Self.cleaned(testBannerUnitID)
        self.testNativeUnitID = Self.cleaned(testNativeUnitID)
        self.unitIDs = unitIDs.compactMapValues(Self.cleaned)
        self.previewViewerIDs = previewViewerIDs
    }

    static let disabled = AdRuntimeConfiguration()

    func unitID(for placement: AdPlacement) -> String? {
        guard let configuredUnitID = unitIDs[placement] else {
            return nil
        }
        if usesGoogleTestAdUnits, placement.format == .banner {
            return testBannerUnitID ?? Self.googleDemoBannerUnitID
        }
        if usesGoogleTestAdUnits, placement.format == .native {
            return testNativeUnitID ?? Self.googleDemoNativeUnitID
        }
        return configuredUnitID
    }

    func isPreviewViewer(_ viewerID: UUID?) -> Bool {
        guard let viewerID else {
            return false
        }
        return previewViewerIDs.contains(viewerID)
    }

    func previewUnitID(for placement: AdPlacement) -> String? {
        if let configuredUnitID = unitID(for: placement) {
            return configuredUnitID
        }
        guard usesGoogleTestAdUnits else {
            return nil
        }
        switch placement.format {
        case .banner:
            return testBannerUnitID ?? Self.googleDemoBannerUnitID
        case .native:
            return testNativeUnitID ?? Self.googleDemoNativeUnitID
        case .interstitial:
            return nil
        }
    }

    var shouldStartAdMobSDK: Bool {
        isEnabled && !showsPlaceholders && provider == .admob && appID != nil
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
                ?? infoDictionary?["GADApplicationIdentifier"] as? String
        )
        let usesGoogleTestAdUnits = bool(
            environment["MEGRUM_ADMOB_TEST_ADS_ENABLED"]
                ?? infoDictionary?["MegrumAdMobTestAdsEnabled"] as? String
        )
        let testBannerUnitID = cleaned(
            environment["MEGRUM_ADMOB_TEST_BANNER_UNIT_ID"]
                ?? infoDictionary?["MegrumAdMobTestBannerUnitID"] as? String
        )
        let testNativeUnitID = cleaned(
            environment["MEGRUM_ADMOB_TEST_NATIVE_UNIT_ID"]
                ?? infoDictionary?["MegrumAdMobTestNativeUnitID"] as? String
        )
        let previewViewerIDs = uuidSet(
            environment[Self.previewViewerIDsEnvironmentKey]
                ?? infoDictionary?["MegrumAdPreviewViewerIDs"] as? String
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
            usesGoogleTestAdUnits: usesGoogleTestAdUnits,
            testBannerUnitID: testBannerUnitID,
            testNativeUnitID: testNativeUnitID,
            unitIDs: unitIDs,
            previewViewerIDs: previewViewerIDs
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
        case .searchResultsNative:
            "MEGRUM_ADMOB_SEARCH_NATIVE_UNIT_ID"
        case .publicProfileFooterBanner:
            "MEGRUM_ADMOB_PROFILE_BANNER_UNIT_ID"
        case .tradesListTopBanner:
            "MEGRUM_ADMOB_TRADES_BANNER_UNIT_ID"
        case .boardRoomHeaderBanner:
            "MEGRUM_ADMOB_BOARD_ROOM_BANNER_UNIT_ID"
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

    private static func uuidSet(_ value: String?) -> Set<UUID> {
        guard let cleaned = cleaned(value) else {
            return []
        }
        let separators = CharacterSet(charactersIn: ",; \n\t")
        return Set(cleaned.components(separatedBy: separators).compactMap(UUID.init(uuidString:)))
    }
}

public enum MegrumMobileAdsBootstrap {
    public static var shouldStartSDK: Bool {
        AdRuntimeConfiguration.current().shouldStartAdMobSDK
    }
}
