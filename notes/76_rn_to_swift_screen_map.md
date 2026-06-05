# 76. RN → Swift 画面対応メモ

> 目的: `mobile/app/*.tsx` のどの画面を、`ios-native/Sources/MegrumApp/*.swift` のどこへ移行・比較するかを素早く引くための実務メモ。
>
> 使い方:
> - オーナーはまず `RN元` と `Swift先` をこの表から指定する
> - そのうえで「今回合わせたい挙動」を 1〜3 点だけ指示する
> - 見た目の完全一致ではなく、RN の機能と状態遷移を iOS 標準コンポーネントでどう再現するかを確認する

最終更新: 2026-06-01
ステータス: Draft v0.1

---

## 指示テンプレ

```text
RN元:
mobile/app/xxxx.tsx

Swift先:
ios-native/Sources/MegrumApp/YYYY.swift

今回やりたいこと:
- RN版の〇〇の挙動をSwiftへ移したい
- iOS標準コンポーネント優先
- 仕様変更はしない

今回合わせたい点:
- 〇〇
- 〇〇
- 〇〇

今回やらないこと:
- 隣接画面の修正
- データモデル変更
- 文言全面改修

最初にやってほしいこと:
RNとSwiftの差分を3点以内で整理してから、差分1件だけ実装して。
```

---

## 1. 認証・オンボーディング

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/(auth)/_layout.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | 認証フローのリダイレクト制御 |
| `mobile/app/(auth)/welcome.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | ウェルカム / ログイン導線 |
| `mobile/app/(auth)/login.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | メールログイン |
| `mobile/app/(auth)/signup.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | メール登録 |
| `mobile/app/(auth)/verify-email.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | 認証メール待ち |
| `mobile/app/(auth)/password-reset.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | パスワード再設定導線 |
| `mobile/app/password-reset.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | 別導線のパスワード再設定 |
| `mobile/app/auth/email-confirmed.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | 認証完了導線 |
| `mobile/app/auth/password-reset-confirm.tsx` | `ios-native/Sources/MegrumApp/AuthScreen.swift` | リセット完了導線 |
| `mobile/app/onboarding/gender.tsx` | `ios-native/Sources/MegrumApp/AccountSetupScreen.swift` | 初回設定フロー |
| `mobile/app/onboarding/oshi.tsx` | `ios-native/Sources/MegrumApp/OnboardingOshiSelection.swift` | 推し選択の主対応先 |
| `mobile/app/onboarding/members.tsx` | `ios-native/Sources/MegrumApp/OnboardingOshiSelection.swift` | メンバー選択 |
| `mobile/app/onboarding/area.tsx` | `ios-native/Sources/MegrumApp/AccountSetupScreen.swift` | エリア / 住所関連 |
| `mobile/app/onboarding/done.tsx` | `ios-native/Sources/MegrumApp/AccountSetupScreen.swift` | 初回完了導線 |

## 2. ホーム・検索・相手プロフィール

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/_layout.tsx` | `ios-native/Sources/MegrumApp/MegrumApp.swift` | アプリ全体のルート / Provider 構成 |
| `mobile/app/(tabs)/_layout.tsx` | `ios-native/Sources/MegrumApp/MegrumApp.swift` | タブとドロワーの構成 |
| `mobile/app/(tabs)/index.tsx` | `ios-native/Sources/MegrumApp/HomeScreen.swift` | ホーム全体 |
| `mobile/app/search.tsx` | `ios-native/Sources/MegrumApp/SearchScreen.swift` | 検索画面 |
| `mobile/app/match-detail.tsx` | `ios-native/Sources/MegrumApp/MatchRelationScreen.swift` | 関係図 / 候補選択 |
| `mobile/app/user-profile.tsx` | `ios-native/Sources/MegrumApp/PublicUserProfileScreen.swift` | 相手プロフィール |
| `mobile/app/user-evaluations.tsx` | `ios-native/Sources/MegrumApp/PublicUserProfileScreen.swift` | `EvaluationListScreen` を内包 |
| `mobile/app/preview-detail.tsx` | `ios-native/Sources/MegrumApp/PublicUserProfileScreen.swift` | 相手詳細まわりの派生導線として扱う |

## 3. 在庫・ウィッシュ・個別募集

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/(tabs)/inventory.tsx` | `ios-native/Sources/MegrumApp/CollectionScreens.swift` | `GoodsCollectionScreen` が主対応先 |
| `mobile/app/goods-editor.tsx` | `ios-native/Sources/MegrumApp/GoodsEditorScreen.swift` | 在庫追加 / 編集 |
| `mobile/app/(tabs)/wishes.tsx` | `ios-native/Sources/MegrumApp/CollectionScreens.swift` | `WishCollectionScreen` が主対応先 |
| `mobile/app/listing-editor.tsx` | `ios-native/Sources/MegrumApp/IndividualListingsScreen.swift` | 個別募集作成 / 編集 |
| `mobile/app/me.tsx` | `ios-native/Sources/MegrumApp/CollectionScreens.swift` | 自分在庫 / コレクション文脈で参照するケースあり |

## 4. 打診作成

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/proposal-select.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` | STEP1 候補選択 |
| `mobile/app/proposal-confirm.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` | STEP2 確認 / 送信 |
| `mobile/app/schedule-editor.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` | 待ち合わせ候補編集の近縁 |
| `mobile/app/schedules.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` | スケジュール候補比較で参照 |

## 5. 取引・ネゴ・完了

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/(tabs)/transactions.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | やりとり一覧 |
| `mobile/app/transaction-detail.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | `TradeDetailScreen` を内包 |
| `mobile/app/transaction-schedule.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | 取引日程シート |
| `mobile/app/transaction-capture.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | 証跡撮影導線 |
| `mobile/app/transaction-approve.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | 承認フロー |
| `mobile/app/transaction-rate.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | 評価フロー |
| `mobile/app/transaction-cancel-or-late.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` | キャンセル / 遅刻 |
| `mobile/app/dispute-new.tsx` | `ios-native/Sources/MegrumApp/DisputeDetailScreen.swift` | 異議申し立て起票の近縁 |
| `mobile/app/dispute-detail.tsx` | `ios-native/Sources/MegrumApp/DisputeDetailScreen.swift` | 異議申し立て詳細 |

## 6. めぐり・掲示板・グルーム

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/(tabs)/encounters.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | めぐりの入口 |
| `mobile/app/meguri-map.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | `MeguriMapScreen` を内包 |
| `mobile/app/groom-map.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | グルーム / 地図近縁 |
| `mobile/app/meguri-board.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | 掲示板一覧 |
| `mobile/app/meguri-board-thread.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | `BoardThreadDetailScreen` を内包 |
| `mobile/app/meguri-board-map.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | 掲示板マップ |
| `mobile/app/meguri-profile.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | めぐりプロフィール近縁 |
| `mobile/app/meguri-profile-edit.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | 明確な独立Swift画面は未分離、要確認 |
| `mobile/app/meguri-avatar-edit.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | 明確な独立Swift画面は未分離、要確認 |
| `mobile/app/meguri-share.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | めぐり共有 |
| `mobile/app/meguri-letters.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `MeguriMessagesScreen` を内包 |
| `mobile/app/meguri-plaza.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | めぐり広場近縁 |
| `mobile/app/meguri-intro.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | 導入画面近縁 |
| `mobile/app/meguri-achievements.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | 実装状況は要確認 |
| `mobile/app/meguri-plus.tsx` | `ios-native/Sources/MegrumApp/MeguriScreen.swift` | 有料導線、Swiftでは独立画面未分離の可能性 |

## 7. プロフィール・設定・法務

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/(tabs)/profile.tsx` | `ios-native/Sources/MegrumApp/OwnProfileScreen.swift` | 自分プロフィールの主対応先 |
| `mobile/app/profile-edit.tsx` | `ios-native/Sources/MegrumApp/AccountSetupScreen.swift` | 編集モードあり |
| `mobile/app/oshi-settings.tsx` | `ios-native/Sources/MegrumApp/OshiSettingsScreen.swift` | 推し設定 |
| `mobile/app/address-settings.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `AddressSettingsScreen` を内包 |
| `mobile/app/blocked-users.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `BlockedUsersScreen` を内包 |
| `mobile/app/notification-settings.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | 通知設定近縁 |
| `mobile/app/settings-privacy.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `PrivacySettingsScreen` を内包 |
| `mobile/app/help.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `SettingsHelpScreen` を内包 |
| `mobile/app/legal/terms.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `LegalDocumentScreen(kind: .terms)` |
| `mobile/app/legal/privacy.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `LegalDocumentScreen(kind: .privacy)` |
| `mobile/app/legal/notice.tsx` | `ios-native/Sources/MegrumApp/SettingsScreen.swift` | `LegalDocumentScreen(kind: .commerce)` |

## 8. 通知

| RN元 | Swift先 | 補足 |
|---|---|---|
| `mobile/app/(tabs)/notifications.tsx` | `ios-native/Sources/MegrumApp/NotificationsScreen.swift` | 通知タブ |
| `mobile/app/notifications.tsx` | `ios-native/Sources/MegrumApp/NotificationsScreen.swift` | 通知一覧の派生導線 |

## 9. 移行メモ

- `CollectionScreens.swift` は RN の `inventory.tsx` と `wishes.tsx` の両方をまとめて持っている。
- `TradesScreen.swift` は RN では別ファイルだった取引詳細、日程、証跡、承認、評価、異議申し立て導線をかなり内包している。
- `MeguriScreen.swift` も RN の `meguri-*` 系を複数まとめて持っている。
- `SettingsScreen.swift` は設定配下の子画面を内包しているため、RN の 1 画面 = Swift の 1 ファイルではないケースが多い。
- Swift 側で独立ファイルがまだない画面は、「未移行」ではなく「内包実装」か「未分離」のどちらかとして読む。

## 10. まず優先して対応を固定しやすいペア

この 8 本は、RN → Swift の比較元と対応先が比較的はっきりしていて、実装指示がしやすい。

| 優先 | RN元 | Swift先 |
|---|---|---|
| 高 | `mobile/app/search.tsx` | `ios-native/Sources/MegrumApp/SearchScreen.swift` |
| 高 | `mobile/app/match-detail.tsx` | `ios-native/Sources/MegrumApp/MatchRelationScreen.swift` |
| 高 | `mobile/app/proposal-select.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` |
| 高 | `mobile/app/proposal-confirm.tsx` | `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift` |
| 高 | `mobile/app/(tabs)/transactions.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` |
| 高 | `mobile/app/transaction-detail.tsx` | `ios-native/Sources/MegrumApp/TradesScreen.swift` |
| 高 | `mobile/app/(tabs)/inventory.tsx` | `ios-native/Sources/MegrumApp/CollectionScreens.swift` |
| 高 | `mobile/app/(tabs)/profile.tsx` | `ios-native/Sources/MegrumApp/OwnProfileScreen.swift` |
