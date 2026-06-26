# Megrum

K-POP / アニメ等の推し活グッズを現地で交換するモバイルアプリ Megrum の実装リポジトリ。

現在の主線は Swift Native iOS です。旧 React Native / Expo 版、旧 JSX mockup、画面案素材は 2026-06-26 時点で削除済みです。

## このリポジトリで扱うもの

- `ios-native/`: Swift 6 + SwiftUI / UIKit / Apple framework のユーザー向けiOSアプリ
- `web/`: Next.js の管理者・運用・サポート確認用Web
- `supabase/`: DB schema、RLS、Edge Functions、ローカルSupabase設定
- `notes/`: 要件、状態遷移、用語、法務整合、設計判断の履歴
- `MegrumIcon.icon/`: Xcode target が参照する App Icon source

## クイックスタート

Swift Native iOS:

```bash
swift build --package-path ios-native
swift test --package-path ios-native --scratch-path /tmp/megrum-ios-native-build --enable-xctest --disable-swift-testing -j 1
xcodebuild -project ios-native/MegrumNative.xcodeproj -scheme MegrumNative -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/megrum-native-xcodebuild CODE_SIGNING_ALLOWED=NO build
```

Web 管理画面:

```bash
npm run web:dev
npm run web:build
```

## 開発ルール

作業前に `AGENTS.md` を読み、iOS作業では `notes/22_swift_native_migration.md` も確認します。

設計・実装変更をした場合は、最小限で意味のある検証を実行し、`notes/08_design_iterations.md` に iteration として記録します。状態名、用語、DB schema に影響する変更は、それぞれ `notes/09_state_machines.md`、`notes/10_glossary.md`、`notes/05_data_model.md` も更新します。

## 本番系の見方

- iOS本番候補: `ios-native/`
- Web公開/管理系: `web/`
- Backend: Supabase cloud + `supabase/`
- App Store / TestFlight の状態は Apple 側の管理画面にあります

旧RN/ExpoのOTA、EAS、JSX mockup、GitHub Pages mockup preview は現在の運用対象外です。
