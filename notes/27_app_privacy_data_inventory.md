# 27. App Privacy データインベントリ

最終更新: 2026-05-31

ステータス: Draft（提出直前の照合表）

## 目的

App Store Connect の App Privacy、`PrivacyInfo.xcprivacy`、プライバシーポリシー、実アプリの通信・SDK利用を提出直前に突き合わせるための作業表。

この文書は確認用であり、コード、Info.plist、Privacy Manifest は変更しない。

App Store Connectへ転記する回答は `notes/43_app_privacy_connect_answer_sheet.md`、Privacy Manifest/SDKの監査台帳は `notes/44_privacy_manifest_sdk_audit.md` を使う。
外部サービス、委託先、SDK、APIの横断台帳は `notes/48_external_service_vendor_register.md` を使う。
保存期間、削除、匿名化、例外保持の横断整理は `notes/52_data_retention_deletion_matrix.md` を使う。

## 1. 現時点で読めた事実

### Swift Native

- `ios-native/App/PrivacyInfo.xcprivacy`
  - `NSPrivacyTracking=false`
  - Required Reason API: `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1`
- `ios-native/App/Info.plist`
  - `NSCameraUsageDescription` あり
  - `NSLocationWhenInUseUsageDescription` あり
  - `ITSAppUsesNonExemptEncryption=false`
  - `LSApplicationCategoryType=public.app-category.social-networking`
- `ios-native/Package.swift`
  - 現時点のSwift Package定義上は外部Swift Package依存なし

### Legacy Expo / React Native

Swift Native移行前の参照線として、legacy `mobile/` には次が存在する。

- Supabase
- Expo Camera
- Expo Image Picker / Media Library
- Expo Location
- Expo Notifications
- Expo Apple Authentication
- Expo IAP
- React Native Maps
- Three.js
- Expo Updates

初回提出対象がSwift Nativeなら、legacy Expoの依存をそのままApp Privacyへ足すのではなく、最終バイナリに含まれるSDKと通信だけを回答する。

### Web / 運用

- Web側にはSupabase、Stripe webhook、Map系ライブラリが存在する。
- Web管理画面やサポート運用で取得する情報は、プライバシーポリシー上は対象だが、App Store Connect の「アプリが収集するデータ」はiOSアプリ経由の収集実態を中心に回答する。

## 2. App Privacy 回答候補

| App Privacyカテゴリ | Megrumでの例 | 収集 | ユーザーに紐づく | 目的候補 | トラッキング |
|---|---|---|---|---|---|
| Contact Info / Email Address | 登録メール、問い合わせメール | あり | はい | App Functionality, Account Management, Customer Support | いいえ |
| Contact Info / Name | 表示名、問い合わせ時の氏名 | あり | はい | App Functionality, Customer Support | いいえ |
| Contact Info / Physical Address | 住所 | 初回MVPでは収集しない | いいえ | 該当なし | いいえ |
| Contact Info / Phone Number | 電話番号 | 初回MVPでは収集しない | いいえ | 該当なし | いいえ |
| User Content / Photos or Videos | グッズ写真、証跡写真、グルーム写真、プロフィール画像 | あり | はい | App Functionality, Safety, Customer Support | いいえ |
| User Content / Other User Content | 投稿、返信、取引チャット、通報本文、問い合わせ本文 | あり | はい | App Functionality, Safety, Customer Support | いいえ |
| Location / Precise Location | 現在地共有、近くのグルーム/掲示板表示 | あり | はい | App Functionality, Safety | いいえ |
| Location / Coarse Location | 都道府県、スポット、活動エリア | あり | はい | App Functionality, Personalization | いいえ |
| Identifiers / User ID | Supabase user id、プロフィールID | あり | はい | App Functionality, Safety, Analytics | いいえ |
| Identifiers / Device ID | APNs device token等 | 通知を出すならあり | はい | App Functionality | いいえ |
| Purchases | IAP購入状態、サブスクリプション状態 | 有料機能を出すならあり | はい | App Functionality | いいえ |
| Usage Data / Product Interaction | 画面操作、検索、投稿、通知開封 | 分析を出すならあり | 原則はい | Analytics, App Functionality | いいえ |
| Diagnostics / Crash Data | クラッシュ、エラー、パフォーマンス | クラッシュ収集を出すならあり | SDK設定による | App Functionality, Analytics | いいえ |
| Sensitive Info | 要配慮個人情報 | 積極取得なし | 該当時のみ | Safety / Legal | いいえ |
| Other Data | AI入力・出力・ログ | AI機能を出すならあり | 入力内容による | App Functionality, Safety | いいえ |

## 3. 目的別の回答方針

| 目的 | 回答方針 |
|---|---|
| App Functionality | 認証、プロフィール、在庫、wish、打診、取引、通知、めぐりに必要なデータ |
| Analytics | 実際に分析SDK又は自社ログで行動分析をする場合だけ選択 |
| Product Personalization | マッチング、表示順、近くの投稿、推し/地域ベースの表示に使う場合だけ選択 |
| Developer's Advertising or Marketing | 広告配信やキャンペーンに使う場合だけ選択 |
| Third-Party Advertising | 初回リリースでは原則選択しない方針。広告SDKが入る場合は再確認 |
| Other Purposes | 法令対応、Trust & Safety、AI安全確認など、通常カテゴリに入らない場合に検討 |

## 4. トラッキング回答

初回提出の推奨方針:

- `Tracking`: No
- `NSPrivacyTracking`: false
- IDFA利用: なし
- マッチングデータ、取引履歴、位置情報を広告会社へ販売しない
- 他社アプリ/サイトのデータと結合した追跡をしない

次のどれかを入れる場合は、App PrivacyとATTの再確認が必要。

- IDFA
- 外部広告ネットワーク
- リターゲティング
- 他社データと結合した広告効果測定
- 広告SDKによるトラッキング

## 5. Privacy Manifest 照合

### 現在のSwift Native

| 項目 | 現状 | 提出前確認 |
|---|---|---|
| `NSPrivacyTracking` | `false` | 最終SDK構成でもfalseでよいか |
| Collected Data Types | Swift Native manifestには未記載 | App Store Connect回答で足りるか、manifestに宣言が必要なSDKがないか |
| Required Reason API / UserDefaults | `CA92.1` | 利用目的と一致しているか |
| Required Reason API / File Timestamp | Swift Native manifestには未記載 | 追加SDKが使う場合は要確認 |
| Required Reason API / Disk Space | Swift Native manifestには未記載 | 追加SDKが使う場合は要確認 |
| Required Reason API / System Boot Time | Swift Native manifestには未記載 | 追加SDKが使う場合は要確認 |

### Legacy Expoとの差分

legacy `mobile/ios/MegrumPreview/PrivacyInfo.xcprivacy` には File Timestamp、UserDefaults、Disk Space、System Boot Time がある。Swift Native初回提出でExpoを含めない場合、この内容をそのまま移す必要はない。Expo版で提出する場合は、legacy manifestとApp Privacyを再照合する。

## 6. 外部サービス別チェック

| サービス / SDK | 使う情報 | App Privacy影響 | 提出前状態 |
|---|---|---|---|
| Supabase Auth | メール、ユーザーID、認証情報 | Contact Info, Identifiers | 要最終確認 |
| Supabase Database | プロフィール、在庫、wish、打診、取引、投稿 | User Content, Identifiers, Usage Data | 要最終確認 |
| Supabase Storage | 画像、証跡、プロフィール画像 | User Content | 要最終確認 |
| Supabase Edge Function / APNs | 通知内容、APNs token | Identifiers, User Contentの一部 | 要最終確認 |
| Apple Sign in | Apple user id、メール | Contact Info, Identifiers | 実装有無確認 |
| Google Sign in | Google user id、メール | Contact Info, Identifiers | 初回Swiftに出すか確認 |
| App Store IAP / StoreKit | 購入状態、サブスク状態 | Purchases | 有料機能露出有無確認 |
| Stripe | Web又は外部決済 | Purchases, Contact Info | iOSアプリ内課金との棲み分け確認 |
| MapKit / CoreLocation | 位置情報 | Precise / Coarse Location | 実装・権限文言確認 |
| Camera / Photos | 写真、画像メタデータ | User Content | 権限文言確認 |
| Analytics / Crash | 操作ログ、クラッシュ | Usage Data, Diagnostics | 導入有無確認 |
| External AI | 画像、本文、取引情報等 | Other Data / User Content | 初回提出では無理に出さない推奨 |

## 7. 送信/保存される可能性が高いデータ

| データ | 保存先候補 | 公開範囲 | 保持/削除の注意 |
|---|---|---|---|
| メールアドレス | Supabase Auth | 非公開 | アカウント管理、問い合わせ |
| プロフィール | Supabase DB | 公開範囲に応じて表示 | 削除申請時に削除/非表示 |
| 在庫 / wish | Supabase DB / Storage | 他会員に表示 | 取引・通報時は一部保存可能 |
| 取引チャット | Supabase DB | 当事者、運営確認 | 紛争対応のため保存可能 |
| 証跡写真 | Supabase Storage | 当事者、運営確認 | 取引終了後の保存期間確認 |
| 現在地 | Supabase DB又は端末内 | 任意共有時の相手 | 取引終了後30日目安 |
| グルーム / 掲示板 | Supabase DB / Storage | 公開範囲に応じて表示 | 通報時は保存可能 |
| 通報 / 異議 | Supabase DB | 運営確認 | 安全・監査目的で保存 |
| APNs token | Supabase DB | 非公開 | 失効時に無効化 |
| IAP状態 | App Store / DB | 非公開 | 会計・権限管理 |
| AIログ | 未確定 | 非公開 | 外部AIなら同意/説明必須 |

## 8. 提出前オープン質問

- [ ] 初回提出バイナリはSwift Nativeのみか、legacy Expo要素を含むか
- [ ] Apple Sign in / Google Sign in を初回提出で出すか
- [ ] 有料機能、IAP、Stripe関連導線を初回提出で出すか
- [ ] Analytics / Crash SDK を入れるか
- [ ] 外部AIサービスへ画像・本文を送る機能を初回提出で出すか
- [ ] 初回MVPで住所又は電話番号を扱う機能が残っていないか
- [ ] PhotosPicker利用時に写真ライブラリ権限文言が必要な実装か
- [ ] 位置情報を正確な現在地として送信するか、スポット/都道府県に丸めるか
- [ ] App Privacyの`Analytics`目的を選ぶほどの行動分析をしているか
- [ ] App Store ConnectのカテゴリをInfo.plistのSocial Networkingに合わせるか、ライフスタイルへ変更するか

## 9. 提出前の推奨回答メモ

- 初回提出では、トラッキングなし、広告ターゲティングなし、外部AIなし又はオンデバイス限定が最も説明しやすい。
- 初回MVPでは住所と電話番号を収集しない前提で、Physical Address / Phone Numberは選択しない。
- 現在地共有と近くの投稿表示を出す場合、Locationは「任意利用」「App Functionality」「Linked to user」「Not tracking」で回答する。
- 取引チャット、投稿、画像、通報はUser Contentとして広めに回答する。
- APNs tokenやユーザーIDはIdentifiersとして回答する。
- IAPを出す場合、Purchasesを回答する。

## 10. 公式参照

- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple Privacy Manifest: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- 個人情報保護委員会 通則ガイドライン: https://www.ppc.go.jp/personalinfo/legal/guidelines_tsusoku/
