#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/ios-native/Sources/MegrumApp"

echo "# iOS Navigation Surface Inventory"
echo
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Source: \`ios-native/Sources/MegrumApp\`"
echo
echo "This is an extraction aid for updating \`notes/81_ios_screen_transition_map_for_legal_review.md\`."
echo "Review the Swift source before treating any entry as a confirmed user-facing route."
echo

echo "## Screen, Route, Destination, and Step Types"
echo
rg -n \
  "^(public )?struct .*Screen: View|^struct .*Sheet: View|^struct .*Composer.*: View|^enum .*Route|^enum .*Destination|^enum .*Step|^enum MegrumTab|^enum AuthFlowRoute|^enum SettingsEssentialRoute|^enum NotificationRouteIntent" \
  "$APP_DIR" || true
echo

echo "## SwiftUI Presentation Surfaces"
echo
rg -n \
  "NavigationStack|NavigationLink|navigationDestination|TabView|\\.sheet\\(|fullScreenCover|MegrumSlide|groomViewerImmersiveOverlay|confirmationDialog|alert\\(" \
  "$APP_DIR" || true
echo

echo "## Known Root Files To Review Manually"
echo
cat <<'LIST'
- ios-native/Sources/MegrumApp/MegrumRootView.swift
- ios-native/Sources/MegrumApp/MegrumRootAuthenticatedContent.swift
- ios-native/Sources/MegrumApp/MegrumRootRouting.swift
- ios-native/Sources/MegrumApp/MegrumAuthenticatedTabsView.swift
- ios-native/Sources/MegrumApp/MegrumAuthenticatedTabContentView.swift
- ios-native/Sources/MegrumApp/NotificationRouteIntent.swift
- ios-native/Sources/MegrumApp/SettingsScreen.swift
- ios-native/Sources/MegrumApp/HomeScreen.swift
- ios-native/Sources/MegrumApp/GoodsCollectionScreenBody.swift
- ios-native/Sources/MegrumApp/WishCollectionScreen.swift
- ios-native/Sources/MegrumApp/TradesScreen.swift
- ios-native/Sources/MegrumApp/MeguriScreen.swift
LIST
