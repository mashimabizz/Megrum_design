# 31. App Store Connect 入力ワークシート

最終更新: 2026-05-31

ステータス: Draft（提出画面へ入力する前の作業表）

## 目的

App Store Connectの各入力欄へ何を入れるか、制限、下書き、未確定事項を1枚にまとめる。

この文書はメタデータ準備用であり、コード、ビルド設定、公開ページは変更しない。

提出直前にコピーする最終文面は `notes/40_app_store_connect_copy_paste_sheet.md` を使う。
日本語/English (U.S.)/Review Notesの整合確認は `notes/60_app_store_localization_metadata_qa.md` を使う。

## 1. 先に決めること

| 項目 | 推奨 / 候補 | 未確定理由 |
|---|---|---|
| 初回提出の主言語 | 日本語 | 主ターゲットが日本国内の推し活ユーザー |
| 追加ローカライズ | English (U.S.) は後回しでも可 | 初回提出速度を優先 |
| Primary Category | Lifestyle 又は Social Networking | `Info.plist` はSocial Networking。App Store上の見え方で最終判断 |
| Secondary Category | Social Networking 又は Lifestyle | Primaryと逆にする案 |
| Made for Kids | No | UGC、取引チャット、位置情報があるため |
| 外部AI | 初回は出さない又はオンデバイス限定推奨 | 外部AI送信は説明/同意/Privacy回答が重くなる |
| 有料機能 | IAPが固まるまで隠す選択もあり | 出すならIAP、特商法、スクショ、審査メモがP0 |
| 現地外の交換手段 | 初回は隠す | 現地交換に集中するため |
| 配信地域 / EU DSA | 初回はJapanのみ候補。EU配信はDSA trader情報確認後 | `notes/68_app_store_territory_dsa_iap_availability.md` で判断 |

## 2. App Information

| 欄 | 制限 / 注意 | 下書き | 状態 |
|---|---|---|---|
| Name | 2〜30文字 | Megrum | 候補確定 |
| Subtitle | 30文字以内 | 推し活グッズを安心交換 | 候補 |
| Primary Language | App Store表示の基準言語 | Japanese | 候補 |
| Bundle ID | ビルドと一致必須 | 完成ビルドで確認 | 未確定 |
| SKU | App Store Connect内部管理用 | `megrum-ios-2026` など | 未確定 |
| Primary Category | Xcodeカテゴリとの整合確認 | Lifestyle / Social Networking | 未確定 |
| Secondary Category | 任意 | Social Networking / Lifestyle | 未確定 |
| Privacy Policy URL | iOS/macOSで必須 | `https://megrum.jp/legal/privacy` | 要公開 |
| Content Rights | 第三者コンテンツ/UGCの権利整理 | 要判断 | 未確定 |
| Age Rating | 質問票回答が必須 | UGC / Messagingあり前提 | 未確定 |
| License Agreement | Apple標準EULA又は独自 | Apple標準EULA + 利用規約URL案 | 要確認 |

## 3. Version Information

| 欄 | 制限 / 注意 | 下書き | 状態 |
|---|---|---|---|
| Screenshots | 1〜10枚、`.jpeg` / `.jpg` / `.png` | `notes/28` の8枚構成 | 完成ビルド待ち |
| App Preview | 任意、各ローカライズ/デバイスサイズ最大3本 | 初回はなし推奨 | 候補 |
| Promotional Text | 170文字以内 | イベント現地でのグッズ交換を、在庫・Wish・打診・取引チャットでスムーズに管理できます。 | 候補 |
| Description | 4000文字以内、HTML不可 | 下記 | 候補 |
| Keywords | 100 bytes以内、アプリ名/会社名重複・他社名不可 | `推し活,グッズ交換,KPOP,アニメ,トレカ,交換,イベント,コレクション,Wish` | 要byte確認 |
| Support URL | ユーザー向けサポートサイト | `https://megrum.jp/support` | 要公開 |
| Marketing URL | 任意 | `https://megrum.jp` | 要公開 |
| Copyright | 例: `Copyright (c) 2026 ...` | `Copyright (c) 2026 Megrum. All rights reserved.` | 候補 |
| Version | ビルドのMarketing Versionと一致 | 完成ビルドで確認 | 未確定 |
| Build | App Store Connectへ処理済みのビルド | 完成ビルドで選択 | 未確定 |

## 4. 日本語メタデータ候補

### Promotional Text

```
イベント現地でのグッズ交換を、在庫・Wish・打診・取引チャットでスムーズに管理できます。
```

### Description

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

### Keywords

```
推し活,グッズ交換,KPOP,アニメ,トレカ,交換,イベント,コレクション,Wish
```

注意:
- `Megrum` はアプリ名なのでkeywordsへ入れない。
- 他社アプリ名、実在企業名、実在アーティスト名、作品名は入れない。
- 100 bytes制限なので、提出前にApp Store Connect上で最終確認する。

## 5. English (U.S.) 追加時の候補

初回は日本語のみでもよい。English (U.S.) を追加する場合のたたき台。

### Name

Megrum

### Subtitle

Trade fan goods safely

### Promotional Text

Organize fan goods, wishlists, proposals, and trade chats for smoother in-person exchanges.

### Description

```
Megrum is an app for fans who want to exchange K-pop, anime, event, and collectible goods.
Register items you have and items you want, send proposals to people with matching conditions, and manage the flow from negotiation to trade chat, proof, and ratings.

Main features:
- Register items you can trade
- Manage your wishlist
- Find potential trade matches
- Send and receive proposals
- Negotiate and agree on trade conditions
- Use trade chat for the final exchange
- Support for in-person exchanges
- Community features such as Groom and spot boards

Megrum helps users coordinate user-to-user exchanges. Sales, ticket resale, stolen goods, counterfeit items, rights-infringing items, and uses that violate laws or the Terms of Service are prohibited.
```

### Keywords

```
fan goods,trade,kpop,anime,photocard,collectibles,event,wishlist
```

## 6. App Review Information

| 欄 | 下書き |
|---|---|
| Contact First Name | TODO |
| Contact Last Name | TODO |
| Phone Number | TODO |
| Email | `support@megrum.jp` 又は審査用個人連絡先 |
| Sign-in required | Yes |
| Demo account email | TODO |
| Demo account password | TODO |
| Notes | 下記 |

デモアカウントと審査用データの具体案は `notes/35_demo_account_review_data_plan.md` を使う。実パスワードはこのリポジトリへ書かない。

### Review Notes

```
Megrum is a goods exchange app for fan communities. Users can register items they have, items they want, send proposals, negotiate exchange details, and complete transactions through an in-app trade chat.

The app does not sell physical goods directly. It provides matching and communication tools for user-to-user exchanges. Paid features, if enabled in this build, are limited to app functionality such as premium features or boosts and use Apple's in-app purchase where required.

User-generated content areas include profiles, item images, trade chat, Groom posts, and the spot board. The app provides reporting/blocking flows and operational moderation for inappropriate content or users.

If AI-assisted item registration is available in this build, it is used to help extract item information from user-provided images/text. External AI processing, if enabled, is disclosed to the user before transmission.

Demo account:
Email: [TODO]
Password: [TODO]

Suggested review path:
1. Sign in with the demo account.
2. Open inventory and Wish.
3. Create or inspect a proposal.
4. Open trade chat.
5. Open Settings > Terms / Privacy / Contact.
6. Open Settings > Account deletion.
```

提出前に削る/直す:
- 未完成機能を説明しない。
- AIを出さないならAI段落を削る。
- 有料機能を出さないならPaid features段落を削る。
- 住所登録系の未完成導線が残る場合は、説明文・スクショ・App Privacyと一致するまで提出しない。

## 7. Age Rating 回答メモ

App Store Connectの年齢制限指定は質問票で決まる。MegrumはKidsカテゴリにしない前提。
詳細な質問票回答、Content Rights、Export Compliance、EULAの照合は `notes/46_app_store_questionnaire_answer_sheet.md` を使う。

| 質問カテゴリ | 回答候補 | 理由 |
|---|---|---|
| User-Generated Content | Yes | グルーム、掲示板、プロフィール、画像、投稿がある |
| Messaging and Chat | Yes | 取引チャット、めぐりメッセージ等がある |
| Unrestricted Web Access | No候補 | 任意Webブラウザを提供しない前提 |
| Advertising | 初回広告なしならNo | 広告導入時はYes |
| In-App Purchases | 有料機能を出すならYes | Premium、めぐりPlus、ブースト |
| Gambling / Loot Boxes | No | 交換/ブーストはギャンブルではない整理 |
| Mature/Sexual/Violence/Drug content | No又はInfrequent | UGC上は投稿可能性があるためモデレーション前提で回答 |
| Age Assurance | No候補 | 初回リリースで年齢確認機構なし |
| Parental Controls | No候補 | 初回リリースで保護者管理機能なし |

注意:
- UGCとチャットがあるため、低年齢向けアプリとして扱わない。
- 利用規約で未成年は保護者同意前提。
- 算出結果が低すぎる/説明と合わない場合は、AppleのOverride to Higher Age Ratingを検討する。

## 8. Content Rights 回答メモ

Megrumはユーザーがグッズ写真や投稿をアップロードするため、第三者の著作権、商標権、肖像権が関わる可能性がある。

運営が公式画像や第三者IPをアプリ内素材として提供する場合は、権利許諾が必要。

初回提出の推奨:
- スクショは架空データのみ。
- アプリ内初期データも架空データのみ。
- 利用規約で権利侵害品、無許諾画像、チケット等を禁止。
- Content Rights欄は、実際のApp Store Connect質問文に合わせて、UGCと運営提供コンテンツを分けて判断する。

## 9. Export Compliance / Encryption

`ios-native/App/Info.plist` では `ITSAppUsesNonExemptEncryption=false` が読める。

ただし、提出時は完成ビルドが使う暗号化、HTTPS、認証、外部SDK、配布地域に応じて、App Store Connectの輸出コンプライアンス質問へ回答する。

提出前に確認:
- [ ] 独自暗号化を実装していない
- [ ] 標準HTTPS/TLS等の範囲か
- [ ] Appleの質問に合わせて回答できる
- [ ] 変更があればInfo.plistとApp Store Connect回答が一致している

## 10. 文字数/byte確認メモ

提出前に確認する制限:

| 項目 | 制限 |
|---|---|
| App Name | 2〜30文字 |
| Subtitle | 30文字以内 |
| Promotional Text | 170文字以内 |
| Description | 4000文字以内 |
| Keywords | 100 bytes以内 |
| IAP Display Name | 2〜30文字 |

## 11. 完成ビルド後の最終チェック

- [ ] メタデータに出した機能が実ビルドで使える
- [ ] スクショに未完成機能が写っていない
- [ ] App Privacyが実通信・SDKと一致している
- [ ] Age Rating質問票が実機能と一致している
- [ ] Review Notesのレビュー経路が実際に辿れる
- [ ] デモアカウントでログインできる
- [ ] アカウント削除、通報、ブロック、問い合わせが説明どおり
- [ ] URLが404ではない

## 12. 公式参照

- Apple App Information: https://developer.apple.com/help/app-store-connect/reference/app-information
- Apple Platform Version Information: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- Apple Required / Localizable / Editable Properties: https://developer.apple.com/help/app-store-connect/reference/required-localizable-and-editable-properties/
- Apple App Store Localizations: https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/
- Apple Age Rating: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- Apple Age Rating Values: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/
- Apple In-App Purchase Information: https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-information
