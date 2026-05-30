# Megrum Native iOS

This directory is the Swift-first migration workspace for Megrum.

The existing Expo / React Native app under `mobile/` remains the rollback source until the Swift app reaches feature parity. New user-facing iOS implementation should move into this workspace unless the task explicitly says to patch the legacy app.

## Current Contents

- `Package.swift` defines the first native Swift package.
- `MegrumNative.xcodeproj` contains the first buildable iOS app host for the Swift version.
- `App/MegrumNativeApp.swift` is the app entry point and mounts `MegrumRootView`.
- `Sources/MegrumCore` contains portable domain models that mirror the current Supabase-backed product concepts.
- `Sources/MegrumDesign` contains native SwiftUI design primitives, starting with a Liquid Glass-style search button.
- `Sources/MegrumApp` contains the SwiftUI app shell and first native screens for Home, Search, Inventory, Wish, Trades, and Meguri.
- `Sources/MegrumApp/MegrumAppState.swift` contains the first app state and repository boundary for later Supabase integration.
- `Tests/MegrumCoreTests` and `Tests/MegrumAppTests` verify state names, display labels, and the preview repository load path.

## Build Loop

Use the smallest useful native check first:

```bash
swift build --package-path ios-native
swift test --package-path ios-native --scratch-path /tmp/megrum-ios-native-build --enable-xctest --disable-swift-testing -j 1
```

For the Xcode app host, use CLI-first verification:

```bash
xcodebuild -list -project ios-native/MegrumNative.xcodeproj
xcodebuild -project ios-native/MegrumNative.xcodeproj -scheme MegrumNative -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/megrum-native-xcodebuild CODE_SIGNING_ALLOWED=NO build
```

## Migration Rule

Do not delete or rewrite `mobile/` until the native app has:

1. Auth and onboarding parity.
2. Home, search, inventory, Wish, proposal, trade chat, groom, board, notifications, settings parity.
3. TestFlight validation on the native preview bundle.
4. A documented rollback path.
