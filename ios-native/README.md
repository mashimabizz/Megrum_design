# Megrum Native iOS

This directory is the Swift-first migration workspace for Megrum.

The existing Expo / React Native app under `mobile/` remains the rollback source until the Swift app reaches feature parity. New user-facing iOS implementation should move into this workspace unless the task explicitly says to patch the legacy app.

## Current Contents

- `Package.swift` defines the first native Swift package.
- `MegrumNative.xcodeproj` contains the first buildable iOS app host for the Swift version.
- `App/MegrumNativeApp.swift` is the app entry point and mounts `MegrumRootView`.
- `App/MegrumNative.entitlements` declares the native Push Notifications entitlement for APNs registration and the Sign in with Apple capability.
- `Sources/MegrumCore` contains portable domain models that mirror the current Supabase-backed product concepts.
- `Sources/MegrumData` contains the first Supabase/PostgREST configuration and request layer.
- `Sources/MegrumDesign` contains native SwiftUI design primitives, starting with a Liquid Glass-style search button.
- `Sources/MegrumApp` contains the SwiftUI app shell and first native screens for Home, Search, Inventory, Wish, Trades, and Meguri.
- `Sources/MegrumApp/MegrumAppState.swift` contains the first app state and repository boundary for Supabase integration.
- `Sources/MegrumApp/MegrumAuthState.swift` and `AuthScreen.swift` contain the first native auth state, Supabase auth repository bridge, and SwiftUI login/signup screen.
- `Sources/MegrumApp/AccountSetupScreen.swift` contains the first native account setup screen for users whose `account_status` still requires onboarding.
- `Sources/MegrumApp/SettingsScreen.swift` contains the first native settings list and address settings form.
- `Sources/MegrumApp/MegrumLocationState.swift` contains the CoreLocation boundary used by native location-aware Meguri surfaces.
- `Sources/MegrumData/SupabaseAuthClient.swift` contains the first Supabase Auth request layer for email/password login, signup, native Apple ID token login, and logout.
- `Sources/MegrumData/SupabaseAuthRedirect.swift` contains redirect URL parsing for Supabase email/OAuth callbacks.
- `Sources/MegrumData/SupabaseAccountClient.swift` contains the account bootstrap request layer that ensures a Megrum `public.users` profile after signup.
- `Sources/MegrumData/SupabaseOshiClient.swift` contains the first request layer for reading `groups_master` and `characters_master` into native oshi selection flows.
- `Sources/MegrumData/SupabaseGoodsInventoryClient.swift` contains the request layer for reading `goods_types_master`, creating `goods_inventory` rows for Inventory/Wish, searching tradeable goods, and archiving or deleting owned goods rows.
- `Sources/MegrumData/SupabaseGoodsReportClient.swift` contains the request layer for filing item-level reports into `goods_reports`.
- `Sources/MegrumData/SupabaseListingClient.swift` contains the request layer for reading and creating individual listings through `listings` and `listing_wish_options`.
- `Sources/MegrumData/SupabaseProposalClient.swift` contains the request layer for loading and creating `proposals`.
- `Sources/MegrumData/SupabaseDisputeClient.swift` contains the request layer for filing trade disputes into `disputes`.
- `Sources/MegrumData/SupabaseMessageClient.swift` contains the request layer for loading and sending trade chat `messages`.
- `Sources/MegrumData/SupabaseMeguriMessageClient.swift` contains the request layer for loading and sending `meguri_messages`.
- `Sources/MegrumData/SupabaseGroomClient.swift` contains the RPC request layer for `list_groom_feed_nearby`, Storage upload/signing, native groom post creation, groom views, groom reactions, and groom replies.
- `Sources/MegrumData/SupabaseBoardClient.swift` contains the request layer for board thread lists, board thread creation, board replies, and reply submission.
- `Sources/MegrumData/SupabaseMailingAddressClient.swift` contains the request layer for reading and upserting `user_mailing_addresses`.
- `Sources/MegrumData/PostalCodeAddressClient.swift` contains the zipcloud postal code lookup boundary for address autofill.
- `Sources/MegrumData/SupabaseBlockClient.swift` contains the request layer for listing and deleting `groom_user_blocks`.
- `Sources/MegrumData/SupabaseNotificationClient.swift` contains the request layer for loading and marking `notifications` read, plus the mobile push notification setting.
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

The Xcode host reads checked-in defaults from `Config/MegrumNative.xcconfig`. For a local live-data build, create an ignored local config:

```bash
cp ios-native/Config/MegrumNative.local.xcconfig.example ios-native/Config/MegrumNative.local.xcconfig
```

Then fill `MEGRUM_SUPABASE_URL`, `MEGRUM_SUPABASE_PUBLISHABLE_KEY`, and `MEGRUM_SUPABASE_VIEWER_ID` in the local file. The local config is ignored by git. You can also override these values from the CLI with `xcodebuild ... MEGRUM_SUPABASE_URL='https://...' MEGRUM_SUPABASE_PUBLISHABLE_KEY='...' MEGRUM_SUPABASE_VIEWER_ID='...'`.

If these values are absent, the Swift app intentionally falls back to preview data.

Auth currently supports the native email/password path and Sign in with Apple. If Supabase config is present and no session is available, `MegrumRootView` shows `AuthScreen`; without config, it starts signed into preview mode so the app shell remains immediately inspectable.

Live sessions are encoded as `AuthSession` and persisted through `KeychainAuthSessionStore`. The Swift app can restore a saved session on launch, while still keeping the storage abstraction replaceable in tests.

When an auth session is available, `MegrumAppStateFactory.repository(authSession:)` rebuilds the live Supabase repository with that session's access token and user id. This keeps the app shell preview-friendly while allowing signed-in users to drive authenticated data loading.

After email/password signup returns a session, `SupabaseMegrumAuthRepository` calls `SupabaseAccountClient.ensureUserProfile(...)` so the native app has a matching Megrum profile row before moving into account setup screens.

Sign in with Apple uses SwiftUI's native `SignInWithAppleButton`. The app sends Apple's identity token and the raw nonce to Supabase Auth via `/auth/v1/token?grant_type=id_token`, then persists the returned session through the same Keychain-backed session store.

Supabase redirect URLs are handled by `MegrumRootView.onOpenURL`. `SupabaseAuthRedirectParser` reads query or fragment tokens, then `SupabaseAuthClient` loads `/auth/v1/user` before saving the restored `AuthSession`.

`UserProfile.accountStatus` mirrors `users.account_status`. `registered`, `verified`, and `onboarding` route into `AccountSetupScreen`; `active` routes into the main native tab shell.

`OshiGroup` and `OshiCharacter` mirror `groups_master` and `characters_master`. `SupabaseOshiClient` can load L1 groups and L2 characters for onboarding, inventory/Wish editing, and search filters. Account setup now saves the selected group/member into `user_oshi` before moving the profile to `active`.

`MailingAddress` mirrors `user_mailing_addresses`. `SettingsScreen` is reachable from the home header avatar and lets the user review or save an address through `MegrumAppState` and `SupabaseMailingAddressClient`. Postal code input is normalized to seven digits and can autofill prefecture, city, and town through `PostalCodeAddressClient`.

`BlockedUser` mirrors the viewer's `groom_user_blocks` relationships. `SettingsScreen` exposes a native blocked users list with pull-to-refresh and confirmation before unblock.

`MegrumNotification` mirrors `notifications`. `SettingsScreen` shows an unread badge, and the native notification list can filter unread/trade notices, mark items read, mark all read, and route broad notification targets back to the matching native tab. The settings list also reads and writes `user_notification_settings.push_enabled` through a native iOS Toggle, so users can turn off device notifications while keeping the in-app notification list available. Native APNs device tokens can now be normalized and upserted into `notification_devices` with `push_provider='apns'`, and the registered native token is revoked on logout. The existing Expo Push path remains available for the legacy app.

The Xcode app host requests iOS notification authorization for configured signed-in sessions, registers with APNs, and forwards the native device token into `MegrumAppState.registerNativePushDeviceToken(...)`.

Remote notification taps read `linkPath` / `notificationId` from the payload, reuse the same tab routing rules as the in-app notification list, and can mark the matching notification read after loading the notification center.

`supabase/functions/send-apns-notification` is the trusted server-side APNs dispatch entry point. It accepts a `notification_id`, reads the matching `notifications` row and active APNs devices, signs an APNs provider token with Edge Function secrets, and revokes invalid devices when APNs reports them as unusable. The database trigger calls it only when the target project has `app.settings.apns_dispatch_url` and `app.settings.apns_dispatch_secret` configured.

The Xcode target uses `App/MegrumNative.entitlements` for Push Notifications and Sign in with Apple. Debug builds set `APS_ENVIRONMENT=development`; Release builds set `APS_ENVIRONMENT=production` so TestFlight/App Store distribution can use the production APNs environment with the matching Apple provisioning profile.

`GoodsGrid` is shared by Home, Search, Inventory, and Wish surfaces. It now opens a native detail sheet on tap and uses SwiftUI's native context menu for long-press actions, keeping the action surface close to iOS Home Screen quick actions while preserving standard accessibility behavior. Search reads tradeable goods through `MegrumAppState`, groups results into match buckets, and exposes group/goods type filter chips from the same master data as Inventory and Wish. From a search result, the exchange-list action can open a native proposal creation sheet that selects one of the viewer's inventory items, chooses an exchange method and condition tags, then creates a `proposals` row through `SupabaseProposalClient`. Inventory and Wish collection screens also expose a native 3/4/5-column toggle, group/goods type filter chips, and a left-side add button. The add button opens a native sheet that loads groups and goods types, then creates a `goods_inventory` row through `MegrumAppState`. Wish now has a native segmented switch for "Wish" and "個別募集"; the latter reads `listings` with their `listing_wish_options`, shows compact native cards, and creates a new individual listing from the viewer's inventory and wishes through `SupabaseListingClient`. On the viewer's own Inventory/Wish tiles, the long-press menu can archive the row with `status='archived'` or delete the owned row after a native confirmation dialog. On another user's goods tile, the long-press report action opens a native report sheet and files a `goods_reports` row through `SupabaseGoodsReportClient`.

When a grid tile belongs to another user, the primary tap opens a native public profile sheet. `SupabaseUserProfileClient` loads the profile summary through `get_public_user_profile_for_viewer` and the rating list through `list_user_evaluations_for_profile`, so the app keeps direct `user_evaluations` RLS narrow while still showing profile-safe rating data.

`TradesScreen` splits proposals into "打診中" and "進行中" with a floating native segmented control above the tab bar. Horizontal swipes switch the stage, and tapping a trade card opens a native detail sheet. The detail sheet now loads trade chat messages through `MegrumAppState`, shows native text/photo message bubbles, can open shared photos full-screen, and can send text messages through `SupabaseMessageClient`. For agreed trades, the native detail sheet can capture an evidence photo with the iOS camera or choose one through PhotosPicker, upload it to `chat-photos`, mirror it to `proposal_evidence_photos` and `proposals.evidence_photo_url`, open the evidence photo full-screen, approve evidence from each side, complete the proposal when both sides approve, and submit a `user_evaluations` rating. The detail sheet also exposes a native report sheet that files the existing `disputes` record and leaves a system message in the trade chat.

`MeguriScreen` is wired to `MegrumAppState` and can refresh native groom and board lists. Live data loads through the existing location-scoped Supabase RPCs; preview data remains available without Supabase configuration. The groom rail can launch the iOS camera for a new groom or use PhotosPicker as a library fallback, then uploads the image to `groom-posts`, creates a `groom_posts` row, and refreshes the feed through the same state boundary. The full-screen groom viewer registers `groom_views` as posts are opened, can toggle `groom_reactions` likes with an optimistic native state update, and can send a text reply into `groom_replies` while creating the matching `groom_reply` notification. The native data boundary can also load `meguri_messages` through `list_meguri_messages_for_viewer`, send text messages into `meguri_messages`, and mark received peer messages read when a conversation opens. Notification links for groom replies and meguri messages now push into a native peer message screen with chat bubbles and a text composer. The board section can switch between 3km nearby threads and a selected prefecture; the selected prefecture defaults to the viewer profile value and is persisted with `AppStorage` after the user changes it. Tapping a board thread opens a native thread detail sheet with reply bubbles and a reply input backed by the board reply RPC boundary. The floating "スレッドを立てる" button opens a native composer sheet and creates `meguri_board_threads` through the PostgREST insert boundary. Tapping a groom opens a native full-screen viewer that shows only a spinner while the image is loading. The groom and board section headers can also open native MapKit screens with pins and radius overlays. When location permission is available, the native map and feed refresh center on the viewer's current coordinate through `MegrumLocationState`.

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
