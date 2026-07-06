# 40. App Store Connect転記用シート

> 目的：App Store Connectへ入力する文面を、提出直前にコピーしやすい形へ集約する。
> コード変更なし。実ビルドの機能範囲に合わせて、不要な段落を削ってから入力する。
> 日本語/English (U.S.)/Review Notesの整合確認は `notes/60_app_store_localization_metadata_qa.md` を使う。
> App Store Connectへ入力した後の実値との照合は `notes/71_app_store_connect_final_input_reconciliation.md` を使う。

最終更新: 2026-06-29
ステータス: Draft v1.2（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 古物営業・チケット不正転売 / 精密位置・MapKit・CoreLocation・逆ジオコーディング / EU DSA・配信地域 / 公式非提携・権利物 / AdMob実設定・ATT・テスト広告No-Go / 公開プロフィール・性別・活動エリア / 未成年・生年月日・年齢表示 / 評価・通報・ブロック・モデレーション / 顔候補付け / Apple標準EULA / 広告通報を反映・転記前）

---

## 1. 転記前の前提

このシートのデフォルトは、初回提出の安全寄せ。

| 項目 | デフォルト |
|---|---|
| 有料機能 | 非表示 |
| 外部AI | 非表示 |
| 未完成3D | 非表示 |
| UGC | 出す場合は通報/ブロック/問い合わせ導線とモデレーション説明あり。画面内通報ボタンがない対象はsupport@フォールバックを説明。評価コメント、虚偽通報、緊急時外部連絡も説明 |
| 生年月日/年齢表示 | 出す場合は自己申告年齢として説明し、Age Assuranceなしと整合 |
| 公開プロフィール | 性別、活動エリア、年齢、評価、支払い方法要約は自己入力又は利用状況ベースの参考情報として説明 |
| 会員間支払い | 出す場合はPayment Info、成立後支払い情報スナップショット、外部決済サービス非関与、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認ではない説明を揃える |
| 広告 | 出す場合は不適切/年齢不相応広告の通報導線、App Privacy、ATT/Tracking、test ads除去、Google公式データ開示を確認 |
| 配信地域 / DSA | 初回はJapanのみ候補。EU又はAll Countries or Regionsを選ぶ場合はtrader statusと商品ページ表示連絡先をオーナー確認済みにする |
| 現地外の交換手段 | 初回は非表示 |
| 実在IP | スクショ、初期データ、説明文には原則使わない。必要な表示がある場合も、公式/公認/提携/代理/権利者承認済みサービスではない説明を揃える |
| License Agreement | 初回はApple標準EULAを推奨。独自EULAは弁護士レビューとApple Minimum Terms照合後 |

提出前に、完成ビルドで見えている機能だけを説明する。見えていない機能はApp Store説明文、スクショ、Review Notesから削る。

---

## 2. App Information

| 欄 | 入力値 |
|---|---|
| Name | `Megrum` |
| Subtitle | `推し活グッズを安心交換` |
| Primary Language | `Japanese` |
| SKU | `megrum-ios-2026` |
| Primary Category | `Lifestyle` 候補 |
| Secondary Category | `Social Networking` 候補 |
| Privacy Policy URL | `https://megrum.jp/legal/privacy` |
| Support URL | `https://megrum.jp/support` |
| Marketing URL | `https://megrum.jp` |
| Copyright | `Copyright (c) 2026 Megrum. All rights reserved.` |

カテゴリの最終判断:
- 交換管理・推し活ユーティリティ寄りに見せるなら `Lifestyle`。
- グルーム/掲示板/ユーザー交流が主に見えるなら `Social Networking`。

---

## 3. Promotional Text

### 初回提出

```
イベント現地でのグッズ交換を、在庫・Wish・打診・取引チャットでスムーズに管理できます。
```

---

## 4. Description

### 4.1 グルーム・掲示板を出す場合

```
Megrumは、K-POP、アニメ、イベントグッズなどの推し活グッズを交換したい人のためのアプリです。
手元にあるグッズと探しているグッズを登録し、条件が合う相手へ打診できます。合意までの調整、取引チャット、証跡確認、評価までをひとつの流れで管理できます。

主な機能:
・在庫とWishの登録
・条件に合う相手の確認
・打診、反対提案、合意
・取引チャット
・現地交換の待ち合わせ補助
・めぐり、グルーム、スポット掲示板

Megrumは、ユーザー同士の交換を補助するサービスです。売買マーケット、古物商、買取、販売代理、オークション、チケット譲渡、決済代行、資金移動、収納代行又はエスクローサービスではありません。金銭売買、チケット転売、盗品又は権利侵害品の取引、法令又は利用規約に反する利用は禁止しています。
```

### 4.2 初回最小スコープの場合

グルーム、掲示板を隠すならこちらを使う。

```
Megrumは、K-POP、アニメ、イベントグッズなどの推し活グッズを交換したい人のためのアプリです。
手元にあるグッズと探しているグッズを登録し、条件が合う相手へ打診できます。合意までの調整、取引チャット、証跡確認、評価までをひとつの流れで管理できます。

主な機能:
・在庫とWishの登録
・条件に合う相手の確認
・打診、反対提案、合意
・取引チャット
・現地交換の待ち合わせ補助
・通報、ブロック、問い合わせ

Megrumは、ユーザー同士の交換を補助するサービスです。売買マーケット、古物商、買取、販売代理、オークション、チケット譲渡、決済代行、資金移動、収納代行又はエスクローサービスではありません。金銭売買、チケット転売、盗品又は権利侵害品の取引、法令又は利用規約に反する利用は禁止しています。
```

---

## 5. Keywords

```
推し活,グッズ交換,KPOP,アニメ,トレカ,交換,イベント,コレクション,Wish
```

注意:
- App Store Connect上で100 bytes制限に収まるか最終確認する。
- 実在アーティスト名、作品名、他社アプリ名、商標に寄る語は入れない。

---

## 6. App Review Information

| 欄 | 入力値 |
|---|---|
| Sign-in required | `Yes` |
| Contact First Name | TODO |
| Contact Last Name | TODO |
| Phone Number | TODO |
| Email | `support@megrum.jp` 又は審査用個人連絡先 |
| Demo account email | App Store Connectにのみ入力 |
| Demo account password | App Store Connectにのみ入力 |

実パスワードはこのリポジトリへ書かない。

---

## 7. Review Notes

### 7.1 初回安全寄せ

有料機能、外部AI、未完成3Dを出さない場合はこちら。

```
Megrum is a goods exchange app for fan communities. Users can register items they have, items they want, send proposals, negotiate exchange details, and complete transactions through an in-app trade chat.

The app does not sell physical goods directly. It provides matching and communication tools for user-to-user exchanges.

Paid features are not enabled in this build.
External AI processing is not enabled in this build.
Unfinished 3D features are not enabled in this build.

User-generated content areas may include profiles, item images, trade chat, Groom posts, and the spot board depending on the enabled build scope. The app provides reporting/blocking flows and operational moderation for inappropriate content or users.

Users may submit ratings and optional comments after completed trades. Ratings and comments are user-generated reference information and are not identity verification, safety verification, credit checks, payment capacity verification, item authenticity verification, or an endorsement by the developer.

Reporting, blocking, and moderation features are provided for in-app safety operations. They are not emergency services, law enforcement, legal advice, or a guarantee that the reported content will be removed or that a dispute will be resolved in a particular way.

The app may ask users to enter their birthdate during profile setup and may show derived age or age-range information in profile/discovery surfaces. This is self-reported information and is not official identity verification, age assurance, parental consent verification, or ID document verification.

Profile and discovery surfaces may show self-reported or usage-derived profile information such as gender, activity area, derived age, ratings, completed trade counts, and payment method summaries. These displays are not legal gender verification, identity verification, safety verification, payment capacity verification, or an endorsement by the developer.

If user-to-user payment details are enabled in this build, the app may show payment method summaries before agreement and agreement-time payment information snapshots, such as bank transfer details, only to the trade parties after agreement. The app does not receive, hold, transfer, collect, refund, charge back, escrow, verify account ownership, verify identity, verify payment capacity, or validate external payment IDs, transfer links, or QR codes.

If ads are enabled in this build, users can report inappropriate or age-inappropriate ads from the in-app reporting/support flow.

Demo account:
Email: [enter in App Store Connect only]
Password: [enter in App Store Connect only]

Suggested review path:
1. Sign in with the demo account.
2. Open inventory and Wish.
3. Create or inspect a proposal.
4. Open trade chat.
5. Open Settings > Terms / Privacy / Contact.
6. Open Settings > Account deletion. The flow marks the account as deletion requested after final confirmation; do not submit the deletion request on the demo account unless requested by App Review.
7. Open report/block entry points where available.
```

### 7.2 有料機能を出す場合の差し替え段落

```
Paid features, if enabled in this build, are limited to app functionality such as Megrum Plus or boosts and use Apple's in-app purchase where required.
In-App Purchase products are configured in App Store Connect and can be reviewed from the paid feature entry points in the app. Subscription purchase, restore, expiration, cancellation, and refund handling should be verified before enabling these entry points in a submitted build.
Administrative entitlement adjustments, if used for support or testing, are internal corrective actions and are not a substitute for App Store purchase, refund, or subscription cancellation flows.
```

### 7.3 外部AIを出す場合の差し替え段落

```
If AI-assisted item registration is available in this build, it is used to help extract item information from user-provided images/text.
External AI processing, if enabled, is disclosed to the user before transmission, including the information sent and the purpose of processing.
```

---

## 8. Age Rating回答メモ

| 質問カテゴリ | 回答候補 |
|---|---|
| User-Generated Content | Yes |
| Messaging and Chat | Yes |
| Unrestricted Web Access | No |
| Advertising | 初回広告なしならNo |
| In-App Purchases | 有料機能を出すならYes、隠すならNo |
| Gambling / Loot Boxes | No |
| Mature/Sexual/Violence/Drug content | No又はInfrequent |
| Age Assurance | No候補。生年月日/年齢は自己申告で、公的年齢確認又は身分証確認ではない |
| Parental Controls | No候補 |

最終的にはApp Store Connectの質問票に従う。UGCとチャットがあるため、Kidsカテゴリにはしない。生年月日又は年齢表示が見える場合でも、年齢確認済み、本人確認済み、保護者同意確認済みと説明しない。詳細回答は `notes/46_app_store_questionnaire_answer_sheet.md` を正とする。

---

## 9. Content Rights回答メモ

初回提出の回答方針:
- スクショと初期データは架空データのみ。
- 運営が公式画像、実在アーティスト画像、実在作品画像を提供しない。
- ユーザー投稿については利用規約で権利侵害を禁止し、通報に対応する。
- 外部画像URL又はAI/検索候補画像を表示する場合、公式素材又は権利確認済み素材として誤認させない。外部ホストへの通信、第三者ポリシー、権利確認責任をFAQ/Privacy/Review Notesと照合する。
- 実在のアーティスト名、グループ名、メンバー名、作品名、キャラクター名、商品名、商標等を検索、分類、識別又は説明の参考として表示する場合でも、公式、公認、提携、代理、権利者承認、権利許諾、真贋確認又は取引可能性を意味しない説明をFAQ/Review Notes/メタデータと一致させる。

App Store Connectの実際の質問文に合わせて、運営提供コンテンツとユーザー投稿を分けて判断する。

---

## 10. Export Compliance回答メモ

提出前の確認:
- 独自暗号化を実装していない。
- HTTPS、認証、Apple標準又は一般的な通信暗号化の利用に留まる。
- `ios-native/App/Info.plist` の `ITSAppUsesNonExemptEncryption` と実ビルドが一致している。

実際の回答は、完成ビルドのSDK、通信、配布地域、Appleの質問票に合わせる。

---

## 11. App Privacy転記前メモ

詳細は `notes/27_app_privacy_data_inventory.md` と `notes/43_app_privacy_connect_answer_sheet.md` を正とする。提出直前に、実ビルドで使っているSDKと通信を見て最終回答する。

初回で特に確認するカテゴリ:
- Contact Info
- User Content
- Sensitive Info
- Other Data Types（生年月日、算出年齢又は年代、性別、ブロック関係、通報/モデレーション状態の回答候補）
- Location（近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示が出る場合はPrecise Location候補）
- Identifiers
- Purchases
- Usage Data
- Diagnostics

Trackingは、広告識別子や他社データと結合した追跡をしない限りNo方針。ただし、現行AdMob構成では `NSPrivacyTracking=false`、`NSUserTrackingUsageDescription` なし、test ads有効のため、IDFA、Apple定義のTracking、Publisher First-Party ID、パーソナライズ広告、メディエーション又は同意管理が必要な広告設定を出す場合はNo方針のままにしない。

Push通知を出す場合は、APNs/Expo tokenだけでなく、通知タイトル/本文、リンク先、未読バッジ、通知開封、ロック画面表示がIdentifiers / User Content / Usage Dataに影響しないか確認する。

生年月日又は年齢表示を出す場合は、Other Data Types又はAppleの最新UIで最も近いカテゴリとして開示し、Age RatingのAge Assurance/Parental Controls回答と矛盾しないようにする。

近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示を出す場合は、Swift Nativeが精密な緯度経度、精度、時刻、場所名、検索/地図関連情報、半径、距離、公開範囲を扱い得る前提で、App PrivacyのPrecise Location、MapKit/CoreLocation/CLGeocoder等の外部処理、サーバー送信/保存、保持/削除例外、地図/距離/場所名の非保証、1km/3kmが匿名化又は安全保証ではない説明をPrivacy/FAQ/Review Notesと照合する。内部で精密座標を使う実装なのに、Coarse Locationのみ、又は位置情報なしとして転記しない。

評価、通報、異議申し立て、ブロック、モデレーションを出す場合は、Customer Support、Other User Content、Other Data Types、Product Interactionのどこで回答するか確認する。評価コメントや通報補足を単なる内部ログとして過少申告しない。

広告を出す場合は、App Privacyで広告SDK/広告識別子/使用状況データ/トラッキング有無を実装と照合し、Google公式データ開示、Privacy Manifest、ATT/Tracking回答、SKAdNetworkItems、test ads除去、同意管理要否、Review Notes又はサポートページでの不適切又は年齢に合わない広告の通報導線を説明する。

実在のアーティスト、グループ、メンバー、作品、キャラクター、商品名、商標等が実ビルド、FAQ、メタデータ又はReview Notesに出る場合は、Megrumが当該権利者、所属事務所、興行主、販売者又は公式ファンクラブの公式、公認、提携又は代理サービスではないこと、名称は検索、分類、識別又は説明の参考であり、承認、権利許諾、真贋確認又は取引可能性を意味しないことを説明する。

初回App AvailabilityはJapanのみ候補とする。EU又はAll Countries or Regionsを選ぶ場合は、EU DSA trader status、App Store商品ページに表示されるProvider/Seller/contact情報、代表者情報非公表方針との差分、英語/現地語サポート可否、IAP Availabilityとの整合を `notes/68` で確認してから転記する。DSA用の住所、電話番号、本人確認情報などの実値はこのシートへ書かない。

---

## 12. License Agreement

初回提出の推奨:
- App Store ConnectではApple標準EULAを使う。
- Megrumの利用規約URLはアプリ内と公開Webに掲載し、サービス利用条件として参照させる。
- 独自EULAを登録する場合は、Apple Minimum Terms、弁護士レビュー、代表者/事業者情報の公開方針、利用規約URL、App Store Connect入力値を照合してから行う。

No-Go:
- 独自EULAを入れるのに、Appleの最低条項、第三者受益者、保守/サポート、製品請求、知的財産、法令遵守、連絡先表示の確認がない。
- 実在IP、商標、公式名称、AI/検索候補、外部画像URLが見えるのに、公式/公認/提携/代理ではない説明、権利確認責任、真贋非保証、取引可否非保証をReview Notes、FAQ、Content Rights回答で揃えていない。
- 初回Japan-only方針なのに、All Countries or Regions、EU 27 territories、又はIAP Availabilityの広域販売を選び、DSA trader statusと商品ページ表示連絡先を確認していない。
- 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示が見えるのに、Precise Location、MapKit/CoreLocation/CLGeocoder、サーバー送信/保存、保持/削除例外、地図/距離/場所名の非保証、1km/3km非保証をPrivacy/FAQ/Review Notes/App Privacyで揃えていない。

---

## 13. 提出前削除リスト

次に該当する場合、説明文・スクショ・Review Notesから削る。

| 条件 | 削るもの |
|---|---|
| 住所登録系の導線を隠す | 住所確認、address exchange |
| グルーム/掲示板を隠す | グルーム、スポット掲示板、Groom posts、spot board |
| 有料機能を隠す | メグルムプラス、ブースト、IAP商品説明 |
| 外部AIを隠す | 外部AI、AI-assisted、External AI processing |
| 外部画像URLを隠す | external image、image URL、CDN、third-party image host |
| 顔候補付けを隠す | Face candidate suggestion、face detection、biometric data、member suggestion from faces |
| 生年月日/年齢表示を隠す | birthdate、age、age range、age assurance、parental consent verification |
| 評価/通報/ブロックを隠す | rating comments、reports、blocking、moderation、emergency reporting |
| 広告を隠す | Advertising、AdMob、sponsored、広告通報説明 |
| 3Dを隠す | 3D、アバター、未完成演出 |

---

## 14. 参照

- App Store Connect入力表: `notes/31_app_store_connect_metadata_worksheet.md`
- App Storeローカライズ・メタデータQA: `notes/60_app_store_localization_metadata_qa.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- 提出パック: `notes/24_app_store_submission_pack.md`
- デモアカウント計画: `notes/35_demo_account_review_data_plan.md`
- 公開URLチェック: `notes/37_public_url_publication_checklist.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- App Store質問票回答シート: `notes/46_app_store_questionnaire_answer_sheet.md`
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Apple Minimum Terms for Developer's EULA: https://www.apple.com/legal/internet-services/itunes/dev/minterms/
