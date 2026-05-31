# 46. App Store質問票回答シート

最終更新: 2026-05-31

ステータス: Draft v0.1（App Store Connect入力前）

## 目的

App Store Connectで入力するAge Rating、Content Rights、Export Compliance、Kidsカテゴリ、License Agreement周辺の回答候補を、初回提出スコープに合わせて整理する。

この文書は提出前の回答シートであり、コード、Info.plist、App Store Connect設定は変更しない。実回答は、完成ビルドの機能、SDK、公開地域、法務レビュー結果と照合してから行う。

## 1. 現時点の読み取り事実

| 項目 | 現状 |
|---|---|
| `LSApplicationCategoryType` | `public.app-category.social-networking` |
| `ITSAppUsesNonExemptEncryption` | `false` |
| 初回提出スコープ | 現地交換MVP |
| UGC | プロフィール、画像、取引チャット、グルーム/掲示板を出す場合あり |
| チャット | 取引チャット、めぐりメッセージを出す場合あり |
| IAP | 初回で隠すならNo、出すならYes |
| 外部AI | 初回で隠す又はオンデバイス限定推奨 |
| Kidsカテゴリ | No |

## 2. Age Rating回答候補

AppleのAge Ratingは、App Store Connectの質問票への回答で算出される。UGCとユーザー間メッセージがあるため、Kidsカテゴリにはしない。

| 質問カテゴリ | 回答候補 | 理由 |
|---|---|---|
| Made for Kids | No | UGC、ユーザー間メッセージ、位置情報、取引調整がある |
| User-Generated Content | Yes | プロフィール、画像、投稿、取引チャット等 |
| Messaging and Chat | Yes | 取引チャット、めぐりメッセージ等 |
| Unrestricted Web Access | No | 任意ブラウザ機能を提供しない前提 |
| Advertising | 初回広告なしならNo | 広告SDKや広告表示を出す場合はYes |
| In-App Purchases | 有料機能を隠すならNo、出すならYes | Premium、めぐりPlus、ブーストの露出次第 |
| Gambling | No | 賭博機能なし |
| Loot Boxes | No | ランダム課金や景品抽選として提供しない |
| Contests | No | コンテスト機能なし |
| Simulated Gambling | No | 該当なし |
| Mature or Suggestive Themes | None又はInfrequent | UGC上の発生可能性は通報/モデレーションで対応 |
| Sexual Content / Nudity | None又はInfrequent | UGC上の発生可能性は通報/モデレーションで対応 |
| Violence / Horror / Weapons | None又はInfrequent | グッズ画像やUGC次第。初期データでは使わない |
| Alcohol / Tobacco / Drug References | None | 初期データでは使わない |
| Medical / Treatment Information | No | 医療アプリではない |
| Age Assurance | No候補 | 初回で年齢確認機構なし |
| Parental Controls | No候補 | 保護者管理機能なし |

推奨:
- 算出結果が低く出すぎる場合、UGC/チャット/現地交換の実態に合わせてOverride to Higher Age Ratingを検討する。
- 利用規約で最低年齢を設定する場合は、Appleの説明どおり、その要件に合わせて上位年齢へOverrideが必要になる可能性がある。
- スクショとデモデータは、年齢制限を上げる原因になり得る文言や画像を使わない。

## 3. Content Rights回答候補

AppleのApp Informationでは、第三者コンテンツを含む、表示する、又はアクセスするアプリは、各国/地域の法律上必要な権利又は許諾を持つ必要がある。

Megrumの整理:

| 項目 | 方針 |
|---|---|
| ユーザー投稿画像 | UGCとして扱い、利用規約で権利侵害を禁止 |
| グッズ写真 | ユーザーが権限を持つ写真のみ登録する前提 |
| 公式画像 | 運営提供素材としては初回で使わない |
| 実在アーティスト/作品名 | App Storeメタデータ、スクショ、初期データでは使わない |
| スクショ | 架空グループ、架空グッズ、権利クリア素材のみ |
| 通報 | 権利侵害やなりすましを通報できる |

回答メモ:
- 運営が第三者IP素材を提供しない。
- ユーザーが投稿するUGCについては、規約と通報/削除運用で対応する。
- 初回提出では、権利許諾が必要な画像、楽曲、映像、ブランドロゴ、公式キャラクター画像をスクショや初期データに入れない。

No-Go:
- 実在IPの画像や名称をスクショに入れる。
- 運営提供の素材として公式画像を入れる。
- UGCがあるのに権利侵害通報の説明がない。

## 4. Export Compliance回答候補

現時点のSwift Native `Info.plist` では `ITSAppUsesNonExemptEncryption=false`。

Apple公式ヘルプの整理では、Apple OS内の暗号化に限定される場合、App Store Connectで追加書類は不要とされている。一方、独自暗号、非標準暗号、Apple OS外の標準暗号ライブラリ、特定地域配布に関わる場合は再確認が必要。

| 質問 | 回答候補 | 確認 |
|---|---|---|
| Encryption used? | HTTPS、認証、Apple標準機能の範囲ならApple OS内暗号化の利用として整理 | 完成ビルドのSDK確認 |
| Non-exempt encryption? | No候補 | `ITSAppUsesNonExemptEncryption=false` と一致 |
| Proprietary or non-standard cryptography? | No | 独自暗号を入れない |
| Documentation required? | No候補 | Apple OS内暗号化に限定される場合 |
| France-specific declaration | 不要候補 | 独自/外部暗号を入れない前提 |

提出前確認:
- Supabase、Sign in with Apple、Google Sign-In、IAP、AI SDK、Analytics/Crash SDKが独自暗号や追加書類を必要としないか確認する。
- `Info.plist` の `ITSAppUsesNonExemptEncryption=false` と実ビルドの実態が一致しているか確認する。
- 独自暗号、VPN、セキュアストレージ専用機能、暗号化メッセージング機能として訴求しない。

## 5. License Agreement / EULA

候補:
- 初回提出ではApple標準EULAを使い、利用規約URLをアプリ内とWebに掲載する。
- 独自EULAをApp Store Connectに登録する場合は、`notes/legal/01_terms_of_service_draft.md` と弁護士レビュー結果を反映してから行う。

No-Go:
- 利用規約URLが未公開。
- アプリ内の利用規約とWeb公開文面がズレている。
- App Store Connectで独自EULAを入れるのに、規約ドラフトが弁護士レビュー前。

## 6. 韓国GRAC / 地域別注意

初回方針:
- ゲーム、ギャンブル、コンテスト、ルートボックスを提供しない。
- Primary CategoryはLifestyle又はSocial Networking候補で、Gamesにはしない。
- 韓国向けに追加のRating Classification Numberが必要になる特徴がないか、App Store Connectの実質問に沿って確認する。

## 7. 転記前チェックリスト

| 項目 | 状態 |
|---|---|
| 完成ビルドでUGC/チャット/掲示板の露出を確認 | 未 |
| 有料機能が見えるか確認 | 未 |
| 外部AIが見えるか確認 | 未 |
| 広告が見えるか確認 | 未 |
| スクショに実在IP/権利物がない | 未 |
| App Store説明文に実在IP/権利物がない | 未 |
| `ITSAppUsesNonExemptEncryption=false` とSDK構成が一致 | 未 |
| Kidsカテゴリを選ばない | 未 |
| Override to Higher Age Ratingの要否を判断 | 未 |
| App Store Connect入力値を `notes/36` に証跡保存 | 未 |

## 8. No-Go

- Kidsカテゴリを選ぶ。
- UGC/チャットが見えるのに、Age Ratingで該当機能を回答していない。
- 有料機能が見えるのに、Age Rating / IAP / Review Notesで整合していない。
- 外部AIが見えるのに、App Privacyや説明文と整合していない。
- 実在IP画像、公式画像、権利未確認素材をスクショに入れている。
- `ITSAppUsesNonExemptEncryption=false` なのに、独自暗号又は追加書類が必要なSDKが入っている。

## 9. 公式参照

- Apple Set an app age rating: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- Apple App Information reference: https://developer.apple.com/help/app-store-connect/reference/app-information
- Apple Overview of export compliance: https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- Apple Export compliance documentation for encryption: https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/
