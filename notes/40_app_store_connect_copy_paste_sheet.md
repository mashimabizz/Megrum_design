# 40. App Store Connect転記用シート

> 目的：App Store Connectへ入力する文面を、提出直前にコピーしやすい形へ集約する。
> コード変更なし。実ビルドの機能範囲に合わせて、不要な段落を削ってから入力する。

最終更新: 2026-05-31
ステータス: Draft v0.1（転記前）

---

## 1. 転記前の前提

このシートのデフォルトは、初回提出の安全寄せ。

| 項目 | デフォルト |
|---|---|
| 有料機能 | 非表示 |
| 外部AI | 非表示 |
| 未完成3D | 非表示 |
| UGC | 出す場合は通報/ブロック/問い合わせ導線あり |
| 現地外の交換手段 | 初回は非表示 |
| 実在IP | スクショ、初期データ、説明文に使わない |

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

Megrumは、ユーザー同士の交換を補助するサービスです。金銭売買、チケット転売、盗品又は権利侵害品の取引、法令又は利用規約に反する利用は禁止しています。
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

Megrumは、ユーザー同士の交換を補助するサービスです。金銭売買、チケット転売、盗品又は権利侵害品の取引、法令又は利用規約に反する利用は禁止しています。
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

Demo account:
Email: [enter in App Store Connect only]
Password: [enter in App Store Connect only]

Suggested review path:
1. Sign in with the demo account.
2. Open inventory and Wish.
3. Create or inspect a proposal.
4. Open trade chat.
5. Open Settings > Terms / Privacy / Contact.
6. Open Settings > Account deletion.
7. Open report/block entry points where available.
```

### 7.2 有料機能を出す場合の差し替え段落

```
Paid features, if enabled in this build, are limited to app functionality such as premium features or boosts and use Apple's in-app purchase where required.
In-App Purchase products are configured in App Store Connect and can be reviewed from the paid feature entry points in the app.
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
| Age Assurance | No候補 |
| Parental Controls | No候補 |

最終的にはApp Store Connectの質問票に従う。UGCとチャットがあるため、Kidsカテゴリにはしない。詳細回答は `notes/46_app_store_questionnaire_answer_sheet.md` を正とする。

---

## 9. Content Rights回答メモ

初回提出の回答方針:
- スクショと初期データは架空データのみ。
- 運営が公式画像、実在アーティスト画像、実在作品画像を提供しない。
- ユーザー投稿については利用規約で権利侵害を禁止し、通報に対応する。

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
- Location
- Identifiers
- Purchases
- Usage Data
- Diagnostics

Trackingは、広告識別子や他社データと結合した追跡をしない限りNo方針。

---

## 12. 提出前削除リスト

次に該当する場合、説明文・スクショ・Review Notesから削る。

| 条件 | 削るもの |
|---|---|
| 住所登録系の導線を隠す | 住所確認、address exchange |
| グルーム/掲示板を隠す | グルーム、スポット掲示板、Groom posts、spot board |
| 有料機能を隠す | Premium、めぐりPlus、ブースト、IAP商品説明 |
| 外部AIを隠す | 外部AI、AI-assisted、External AI processing |
| 3Dを隠す | 3D、アバター、未完成演出 |

---

## 13. 参照

- App Store Connect入力表: `notes/31_app_store_connect_metadata_worksheet.md`
- 提出パック: `notes/24_app_store_submission_pack.md`
- デモアカウント計画: `notes/35_demo_account_review_data_plan.md`
- 公開URLチェック: `notes/37_public_url_publication_checklist.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- App Store質問票回答シート: `notes/46_app_store_questionnaire_answer_sheet.md`
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
