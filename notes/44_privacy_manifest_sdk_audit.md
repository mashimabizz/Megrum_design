# 44. Privacy Manifest / SDK監査台帳

> 目的：提出直前に、最終iOSビルドのPrivacy Manifest、Required Reason API、SDK、通信先を確認するための台帳。
> コード変更なし。実ビルド確認時に結果を埋める。
> 外部サービス/委託先の横断整理は `notes/48_external_service_vendor_register.md` を使う。
> RLS、Storage、secret、APNs、管理者権限の提出前監査は `notes/54_prelaunch_security_audit_checklist.md` を使う。

最終更新: 2026-06-29
ステータス: Draft v0.13（StoreKit・IAP販売可否・復元失敗 / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search / 顔特徴量RLS・学習データ既定true / 郵送交換 / 会員間支払い情報経路を反映、実ビルド未監査）

---

## 1. 現時点の静的確認

2026-06-29時点で読めたSwift Native側の状態。

| 対象 | 現状 |
|---|---|
| `ios-native/App/PrivacyInfo.xcprivacy` | `NSPrivacyTracking=false`、UserDefaults `CA92.1` |
| `ios-native/App/Info.plist` | カメラ、位置情報、`ITSAppUsesNonExemptEncryption=false`、AdMob app id / ad unit id build setting、SKAdNetworkItems |
| `ios-native/Package.swift` | `GoogleMobileAds` Swift Package依存あり |
| `ios-native/MegrumNative.xcodeproj` | `GoogleMobileAds` product linkあり |
| `ios-native/Config/MegrumNative.xcconfig` | 2026-07-03時点のチェックイン既定は `MEGRUM_ADS_ENABLED=NO`、AdMob app id/unit id/test unit id空、`MEGRUM_ADMOB_TEST_ADS_ENABLED=NO`、`MEGRUM_PLUS_IAP_ENABLED=NO`。Debug targetにはtest ads overrideが残るが、広告OFFのため既定ではSDK起動条件を満たさない |
| 広告同意/Tracking | `NSPrivacyTracking=false`、`NSUserTrackingUsageDescription`なし。ATT要求、UMP同意管理、非パーソナライズ広告指定、Publisher First-Party ID制御、mediation制御は現行検索で未確認 |
| Supabase設定 | Info.plist / 環境からURLとキーを読む |
| 生年月日 / 年齢 | 初回設定で生年月日入力が必須。年齢を算出して保存・表示する経路あり。公的年齢確認、身分証確認、保護者同意確認は未確認 |
| 公開プロフィール / 性別 / 活動エリア | 性別、活動エリア、年齢、評価、完了取引数、支払い方法要約等が公開プロフィール、ホーム候補、交換条件等で表示され得る。本人確認、法的性別確認、安全確認、支払能力確認ではない |
| 評価 / 通報 / ブロック / モデレーション | `user_evaluations`、`reports`、`goods_reports`、`groom_reports`、`meguri_board_reports`、`disputes`、`groom_user_blocks` の保存/表示制御経路あり。評価コメント、通報補足、異議申し立て本文、削除申出本文、送信防止措置希望、証跡URL、ブロック関係、status、運営対応情報をApp Privacy回答と照合する |
| APNs | token更新通知とSupabase通知クライアントあり。通知payloadはtitle/body/linkPath/未読バッジを含み得る |
| PhotosUI / Camera | GoodsEditor / Tradesで利用 |
| CoreLocation / MapKit系 | 現地交換、検索、取引チャットの現在地共有で利用 |
| StoreKit | メグルムプラス購入・復元・`currentEntitlements` 読み込み経路あり。ただしチェックイン既定は `MEGRUM_PLUS_IAP_ENABLED=NO` で、購入/復元ボタン表示、商品情報照会、購入、復元actionは停止される。IAPを有効化する場合は、商品情報照会、価格取得、購入ボタン表示、復元ボタン表示、購入開始、承認待ち、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、購入後のtransaction id / Original Transaction ID / 期限同期、Server API検証、Server Notifications同期をApp Privacyと照合 |
| 外部AI API | `suggest-goods-series` Edge Function経由でOpenAI Responses APIへ最大3件の画像又は画像URL、グループ名、メンバー名、グッズ種別、既存候補を送り、`web_search` を必須実行する経路あり。導線が見える場合、送信前説明とApp Privacy回答が必要 |
| 顔候補付け | Apple Visionによる顔矩形検出、`member_face_profiles` / `face_uploaded_images` / `detected_faces` / `face_match_candidates` / `face_match_corrections` の保存境界あり。Face ID / 生体認証APIではない。`member_face_profiles` はembedding/source image URLをauthenticated readする設計、補正履歴の学習データ追加フラグは既定trueの経路あり |
| 郵便番号検索 | `PostalCodeAddressClient` からZipCloudへ郵便番号を送信する経路あり |
| 支払い設定 | `user_payment_settings` へ銀行口座情報を保存し、金額指定取引の合意後に支払い情報スナップショットを当事者へ表示する経路あり |

---

## 2. Privacy Manifest確認

| 項目 | 現状 | 最終確認 |
|---|---|---|
| `NSPrivacyTracking` | false | TODO |
| Tracking Domains | 未記載 | AdMob/Google関連ドメインがTracking Domainに該当しないかTODO |
| Collected Data Types | 未記載 | TODO |
| Required Reason API: UserDefaults | `CA92.1` | TODO |
| Required Reason API: File Timestamp | 未記載 | TODO |
| Required Reason API: Disk Space | 未記載 | TODO |
| Required Reason API: System Boot Time | 未記載 | TODO |
| 追加SDKのPrivacy Manifest | Google Mobile Ads SDKあり。SDK同梱manifest、Privacy Report、Google公式開示を確認 | TODO |

判断メモ:
- アプリ本体のApp Privacy回答はApp Store Connect側で行う。
- Privacy ManifestはRequired Reason APIやSDK由来の宣言不足がないかを確認する。
- Google Mobile Ads SDKはアプリのPrivacy Report/App Privacy回答へ影響する。広告を無効化して提出する場合でも、SDK初期化と広告リクエストが発生しないことを確認する。現行チェックイン設定はSDK起動条件を満たし得るため、広告を有効化する場合はGoogle公式データ開示、ATT/Tracking回答、SDK同梱Privacy Manifest、SKAdNetworkItems、テスト広告除去、不適切又は年齢に合わない広告の通報導線と広告通報時の取得情報もApp Privacyと照合する。
- Apple Vision / Core ML境界はRequired Reason APIの対象ではないが、顔特徴量又は画像特徴量の収集・保存・照合が到達可能な場合、App Privacy回答ではSensitive Info / biometric data相当を確認する。`member_face_profiles` のembedding/source image URLの読み取り範囲と、補正履歴の学習データ追加可否が送信前説明・同意・削除導線と一致しない場合はNo-Go。
- Crash、Analytics、追加AI SDK、広告メディエーションSDKが入った場合は再監査する。

---

## 3. SDK/Framework監査

| 領域 | 確認対象 | 現状 | App Privacy影響 | 最終確認 |
|---|---|---|---|---|
| Auth / DB | Supabase REST | あり | Contact Info, Identifiers, User Content | TODO |
| Birthdate / Age / Gender | Supabase REST / users profile | 生年月日、算出年齢又は年代、性別表示あり | Other Data Types候補, Product Personalization, Safety | TODO |
| Public profile / Activity area | Supabase REST / public profile / home summaries | 表示名、ユーザーID、活動エリア、評価、完了取引数、支払い方法要約等 | User Content, Coarse Location, Other Data Types | TODO |
| Moderation / Reports / Blocks / Evaluations | Supabase REST / moderation tables / support tools | 評価、ユーザー/グッズ/めぐり/掲示板通報、異議申し立て、削除申出、送信防止措置希望、ブロック関係、status、運営対応情報 | Customer Support, Other User Content, Other Data Types, Product Interaction | TODO |
| Storage | Supabase Storage相当 | 画像保存あり得る | Photos or Videos | TODO |
| Push | APNs token、通知タイトル/本文、通知リンク先、未読バッジ | あり | Device ID, User Content, Usage Data | TODO |
| Camera | AVFoundation / UIKit camera | あり | Photos or Videos | TODO |
| Photo Picker | PhotosUI | あり | Photos or Videos | TODO |
| Location | CoreLocation | あり | Precise / Coarse Location | TODO |
| Maps | MapKit又は地図表示 | あり得る | Location | TODO |
| Postal lookup | ZipCloud API | あり | Physical Address / Contact Info | TODO |
| Payment settings | Supabase REST / `user_payment_settings` | あり | Financial Info / Payment Info | TODO |
| IAP | StoreKit | メグルムプラス経路あり。チェックイン既定は `MEGRUM_PLUS_IAP_ENABLED=NO` で購入/復元/商品照会を停止。導線を有効化する場合は、商品情報照会、価格取得、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、返金/取消/期限切れ/請求失敗/猶予期間、復元、サーバー同期状態も確認 | Purchases, 必要に応じてIdentifiers / Other Data | TODO |
| Analytics | Analytics SDK | 未確認 | Usage Data | TODO |
| Crash | Crash SDK | 未確認 | Diagnostics | TODO |
| Face / Member suggestion | Apple Vision / 将来Core ML / Supabase face tables | 顔矩形検出、候補付け保存境界あり。`member_face_profiles` embedding/source image URLのauthenticated readと補正履歴/学習データ追加可否を確認 | Sensitive Info / Biometric Data, User Content | TODO |
| External AI | OpenAI Responses API via Supabase Edge Function | グッズシリーズ候補経路あり。最大3画像又は画像URL、推し文脈、既存候補、web search利用、保持/学習利用説明を確認 | User Content / Photos or Videos / Other Data | TODO |
| External image URLs | URLSession / AsyncImage / 外部画像ホスト/CDN | 外部画像URL又はAI/検索候補画像の表示経路あり。導線露出次第 | User Content / Other Data / Device Infoの可能性 | TODO |
| Advertising | Google Mobile Ads SDK / AdMob / SKAdNetwork | SDK/Info.plist構成あり。広告有効化次第。広告通報導線も要確認 | Device ID, Advertising Data, Product Interaction, Diagnostics, Tracking該当性 | TODO |

---

## 4. 通信先監査

提出前に、実機又はビルド設定から確認する。

| 通信先 | 用途 | App Privacy影響 | 確認 |
|---|---|---|---|
| Supabase Project URL | Auth / DB / Storage | 多数 | TODO |
| Supabase moderation tables / support records | 評価、通報、異議申し立て、削除申出、送信防止措置、ブロック、モデレーション状態 | Customer Support, Other User Content, Other Data Types, Product Interaction | TODO |
| Supabase `user_payment_settings` / proposals snapshots | 支払い設定、合意後支払い情報表示 | Payment Info | TODO |
| Supabase face recognition tables | 顔候補付け、候補・補正履歴保存 | Sensitive Info / User Content | TODO |
| Apple APNs | 通知 | Device ID, User Content, Usage Data | TODO |
| Apple App Store / StoreKit | IAP、商品情報照会、価格取得、購入開始、承認待ち、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止 | Purchases, 必要に応じてIdentifiers / Other Data | 有料機能を出す場合。既定OFF提出でも購入/復元/商品照会なしを実ビルド確認 |
| MapKit / Apple Location関連 | 地図/場所 | Location | TODO |
| ZipCloud | 郵便番号検索/住所補完 | Physical Address / Contact Info | TODO |
| Google Mobile Ads / AdMob | 広告表示、広告測定、広告通報対応 | Device ID, Advertising Data, Product Interaction, Diagnostics, Tracking該当性 | TODO |
| 外部AI API / OpenAI Responses API | AI機能 | User Content / Photos or Videos / Other Data | グッズシリーズ候補を出す場合。web search、画像URL、濫用監視ログ、削除可否も確認 |
| 外部画像ホスト / CDN | 外部画像URL表示、AI/検索候補画像表示 | User Content / Other Data / Device Infoの可能性 | 外部画像URLを出す場合 |
| Analytics / Crash endpoint | 分析/診断 | Usage Data / Diagnostics | 導入時 |
| 広告メディエーションSDK endpoint | 広告 | Tracking / Advertising Data可能性 | 導入時 |

---

## 5. 確認コマンド案

ローカルで静的確認する場合:

```bash
plutil -p ios-native/App/PrivacyInfo.xcprivacy
plutil -p ios-native/App/Info.plist
sed -n '1,160p' ios-native/Package.swift
rg -n "Firebase|Analytics|Crash|StoreKit|Supabase|URLSession|AsyncImage|PhotosUI|CoreLocation|MapKit|APNs|PrivacyInfo|NSPrivacy|GoogleMobileAds|AdMob|GAD|SKAdNetwork|OpenAI|suggest-goods-series|image_url|imageURL|photoURLs|ZipCloud|zipcloud|PostalCode|user_mailing_addresses|mailing_address|user_payment_settings|payment_settings|bank_account|PaymentInfo|Vision|VNDetectFace|FaceEmbedding|member_face_profiles|detected_faces|face_match|user_evaluations|reports|goods_reports|groom_reports|meguri_board_reports|disputes|groom_user_blocks|blockUser|reportUser|reportGoods|fileTradeDispute|submitTradeEvaluation" ios-native supabase
```

実機で確認する場合:
- iOSのApp Privacy Reportをオンにして通信先を確認する。
- TestFlightビルドで権限ダイアログ、位置情報、写真、カメラ、通知を確認する。
- 送信/保存されるデータが `notes/43` の回答と一致するか確認する。

---

## 6. 監査結果記録欄

| 項目 | 結果 | 証跡 |
|---|---|---|
| PrivacyInfo.xcprivacy確認 | 未 |  |
| Info.plist権限文言確認 | 未 |  |
| 外部SDK有無確認 | 未 |  |
| 通信先確認 | 未 |  |
| App Privacy回答との一致 | 未 |  |
| Tracking Noの根拠確認 | 未 |  |
| IAP有無確認 | 未 | `MEGRUM_PLUS_IAP_ENABLED`、購入ボタン、復元ボタン、商品情報照会、価格取得、購入開始、承認待ち、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、Server API/Notifications |
| AdMob / 広告SDK有無確認 | 未 |  |
| 広告通報導線 / 取得情報確認 | 未 |  |
| 外部AI有無確認 | 未 | OpenAI、web_search、画像又は画像URL送信、保持/学習利用、第三者/未成年/権利未処理画像禁止 |
| 顔候補付け / Sensitive Info有無確認 | 未 | `member_face_profiles` embedding/source image URL、補正履歴、`shouldAddTrainingData`、削除/利用停止 |
| 郵送先住所 / ZipCloud有無確認 | 未 |  |
| 支払い設定 / 口座情報 / Payment Info有無確認 | 未 |  |
| 生年月日 / 年齢表示 / Other Data Types候補確認 | 未 |  |
| 評価 / 通報 / 削除申出 / ブロック / モデレーション取得情報確認 | 未 |  |

---

## 7. No-Go

次に該当する場合は提出しない。

- `NSPrivacyTracking=false` なのにAdMob/広告SDKのIDFA、パーソナライズ広告、Publisher First-Party ID、メディエーション、横断追跡該当性を確認していない。
- `NSUserTrackingUsageDescription` なし又はATT要求未実装のまま、IDFA又はApple定義のTrackingに該当する広告設定を有効にしている。
- 広告を有効化したビルドで、`MEGRUM_ADMOB_TEST_ADS_ENABLED=YES`、Googleデモunit id又は審査用でないtest ads設定のまま一般公開しようとしている。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、不適切又は年齢に合わない広告の通報導線、通報時の取得情報、サポート説明、Google公式データ開示、ATT/Tracking回答、test ads除去、同意管理要否を確認していない。
- Required Reason APIの利用があるのにPrivacy Manifestに理由がない。
- 外部SDKのPrivacy Manifestが不足している。
- App Privacy回答にないデータが実ビルドで送信/保存されている。
- 生年月日又は年齢表示があるのに、Other Data Types候補、Age Assuranceなし、FAQ/Review Notesの自己申告年齢説明と照合していない。
- 性別、活動エリア、評価、支払い方法要約があるのに、Other Data Types / Coarse Location / User Content候補、非保証説明、FAQ/Review Notesとの整合を確認していない。
- 評価コメント、通報補足、異議申し立て本文、削除申出本文、送信防止措置希望、ブロック関係、モデレーションstatusがあるのに、Customer Support / Other User Content / Other Data Types / Product Interaction候補を確認していない。
- 通報/ブロック/モデレーションを緊急通報、本人確認、安全確認、信用保証、法的判断の代替として説明している。
- Privacy PolicyとApp Privacy回答が矛盾している。
- 外部AI、IAP、AdMobのSDK/APIが入っているのに、対応文書と回答が未更新。外部AIではOpenAI、web_search、画像又は画像URL、濫用監視ログ、保持、削除可否、学習利用を確認する。IAPでは商品情報照会、価格取得、購入開始、承認待ち、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、価格表示、Server API検証、Server Notifications、返金/取消/期限切れ同期も確認する。
- 有料機能、購入ボタン、復元ボタン、価格又は権限状態が見えるのに、Purchases回答、公開特商法、IAP Availability、価格/販売地域/販売停止、サーバー同期失敗時のローカル表示とサーバー最終権限の差分を実ビルド監査していない。
- 顔検出、顔特徴量、画像特徴量、メンバー候補付け又は補正履歴保存が見えているのに、Sensitive Info / biometric data候補、Face IDではない説明、削除/同意/外部送信有無、`member_face_profiles` 読み取り範囲、学習データ追加可否が未確認。
- 郵送先住所、電話番号、郵便番号検索又は合意後住所表示があるのに、App Privacyとプライバシーポリシーが未更新。
- 支払い設定、銀行振込、口座番号入力、金額指定又は合意後支払い情報表示があるのに、Payment Infoとプライバシーポリシーが未更新。

---

## 8. 参照

- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- App Privacyインベントリ: `notes/27_app_privacy_data_inventory.md`
- 提出前セキュリティ監査: `notes/54_prelaunch_security_audit_checklist.md`
- Apple Developer署名・Capabilities事前確認: `notes/75_apple_developer_signing_capabilities_preflight.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- Apple Privacy Manifest Files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Apple Adding a Privacy Manifest: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
