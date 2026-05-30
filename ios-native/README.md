# Megrum Native iOS

This directory is the Swift-first migration workspace for Megrum.

The existing Expo / React Native app under `mobile/` remains the rollback source until the Swift app reaches feature parity. New user-facing iOS implementation should move into this workspace unless the task explicitly says to patch the legacy app.

## Current Contents

- `Package.swift` defines the first native Swift package.
- `MegrumNative.xcodeproj` contains the first buildable iOS app host for the Swift version.
- `App/MegrumNativeApp.swift` is the app entry point and mounts `MegrumRootView`.
- `Sources/MegrumCore` contains portable domain models that mirror the current Supabase-backed product concepts.
- `Sources/MegrumData` contains the first Supabase/PostgREST configuration and request layer.
- `Sources/MegrumDesign` contains native SwiftUI design primitives, starting with a Liquid Glass-style search button.
- `Sources/MegrumApp` contains the SwiftUI app shell and first native screens for Home, Search, Inventory, Wish, Trades, and Meguri.
- `Sources/MegrumApp/MegrumAppState.swift` contains the first app state and repository boundary for Supabase integration.
- `Sources/MegrumApp/MegrumAuthState.swift` and `AuthScreen.swift` contain the first native auth state, Supabase auth repository bridge, and SwiftUI login/signup screen.
- `Sources/MegrumApp/AccountSetupScreen.swift` contains the first native account setup screen for users whose `account_status` still requires onboarding.
- `Sources/MegrumApp/SettingsScreen.swift` contains the first native settings list and address settings form.
- `Sources/MegrumData/SupabaseAuthClient.swift` contains the first Supabase Auth request layer for email/password login, signup, and logout.
- `Sources/MegrumData/SupabaseAuthRedirect.swift` contains redirect URL parsing for Supabase email/OAuth callbacks.
- `Sources/MegrumData/SupabaseAccountClient.swift` contains the account bootstrap request layer that ensures a Megrum `public.users` profile after signup.
- `Sources/MegrumData/SupabaseOshiClient.swift` contains the first request layer for reading `groups_master` and `characters_master` into native oshi selection flows.
- `Sources/MegrumData/SupabaseMailingAddressClient.swift` contains the request layer for reading and upserting `user_mailing_addresses`.
- `Sources/MegrumData/PostalCodeAddressClient.swift` contains the zipcloud postal code lookup boundary for address autofill.
- `Sources/MegrumData/SupabaseBlockClient.swift` contains the request layer for listing and deleting `groom_user_blocks`.
- `Sources/MegrumData/SupabaseNotificationClient.swift` contains the request layer for loading and marking `notifications` read.
- `Sources/MegrumData/AuthSessionStore.swift` contains the session persistence boundary. Live auth uses Keychain; tests and preview mode use an in-memory store.
- `Tests/MegrumCoreTests`, `Tests/MegrumDataTests`, and `Tests/MegrumAppTests` verify state names, display labels, Supabase request construction, and the preview repository load path.

## Build Loop

Use the smallest useful native check first:

```bash
swift build --package-path ios-native
swift test --package-path ios-native --scratch-path /tmp/megrum-ios-native-build --enable-xctest --disable-swift-testing -j 1
```

To run the native app against Supabase from Xcode or CLI, provide only public/client-side configuration:

- `MegrumSupabaseURL` / `MEGRUM_SUPABASE_URL`
- `MegrumSupabasePublishableKey` / `MEGRUM_SUPABASE_PUBLISHABLE_KEY`
- `MegrumSupabaseViewerID` / `MEGRUM_SUPABASE_VIEWER_ID`
- `MegrumAuthEmailRedirectURL` / `MEGRUM_AUTH_EMAIL_REDIRECT_URL`

If these values are absent, the Swift app intentionally falls back to preview data.

Auth currently supports the first native email/password path. If Supabase config is present and no session is available, `MegrumRootView` shows `AuthScreen`; without config, it starts signed into preview mode so the app shell remains immediately inspectable.

Live sessions are encoded as `AuthSession` and persisted through `KeychainAuthSessionStore`. The Swift app can restore a saved session on launch, while still keeping the storage abstraction replaceable in tests.

When an auth session is available, `MegrumAppStateFactory.repository(authSession:)` rebuilds the live Supabase repository with that session's access token and user id. This keeps the app shell preview-friendly while allowing signed-in users to drive authenticated data loading.

After email/password signup returns a session, `SupabaseMegrumAuthRepository` calls `SupabaseAccountClient.ensureUserProfile(...)` so the native app has a matching Megrum profile row before moving into account setup screens.

Supabase redirect URLs are handled by `MegrumRootView.onOpenURL`. `SupabaseAuthRedirectParser` reads query or fragment tokens, then `SupabaseAuthClient` loads `/auth/v1/user` before saving the restored `AuthSession`.

`UserProfile.accountStatus` mirrors `users.account_status`. `registered`, `verified`, and `onboarding` route into `AccountSetupScreen`; `active` routes into the main native tab shell.

`OshiGroup` and `OshiCharacter` mirror `groups_master` and `characters_master`. `SupabaseOshiClient` can load L1 groups and L2 characters for onboarding, inventory/Wish editing, and search filters. Account setup now saves the selected group/member into `user_oshi` before moving the profile to `active`.

`MailingAddress` mirrors `user_mailing_addresses`. `SettingsScreen` is reachable from the home header avatar and lets the user review or save an address through `MegrumAppState` and `SupabaseMailingAddressClient`. Postal code input is normalized to seven digits and can autofill prefecture, city, and town through `PostalCodeAddressClient`.

`BlockedUser` mirrors the viewer's `groom_user_blocks` relationships. `SettingsScreen` exposes a native blocked users list with pull-to-refresh and confirmation before unblock.

`MegrumNotification` mirrors `notifications`. `SettingsScreen` shows an unread badge, and the native notification list can filter unread/trade notices, mark items read, mark all read, and route broad notification targets back to the matching native tab.

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
