# 33. IAP商品設定ワークシート

> 目的：App Store Connectでアプリ内課金を作成する前に、商品ID、表示名、説明、価格、権限、審査メモを固定する。
> コード変更なし。初回提出で有料機能を出すかどうかの判断材料として使う。

最終更新: 2026-05-31
ステータス: Draft v0.1（オーナー判断・Apple設定前）

---

## 1. 結論

初回App Store提出で最も安全なのは、IAP実装とApp Store Connect設定が完了するまで、Premium、めぐりPlus、ブーストの購入導線をアプリ内で見せないこと。

有料機能を見せる場合は、次をP0として同時に完了する。

| 項目 | 必須条件 |
|---|---|
| App Store Connect | 商品作成、価格、配信国、ローカライズ、審査情報 |
| アプリ | StoreKit購入、購入復元、購入失敗、解約導線説明 |
| サーバー | Apple取引検証、権限付与、返金/取消/期限切れ同期 |
| 法務 | 特商法表記、利用規約、プライバシーポリシー、サポートページ |
| App Privacy | Purchasesを回答対象に含める |
| Review Notes | 有料導線、デモアカウント、テスト手順を明記 |

Appleの審査では、アプリ内で消費・利用するデジタル機能は原則としてIAPで扱う前提に寄せるのが保守的。物理グッズそのものの決済をMegrum内で扱わない限り、交換対象グッズ代金とIAPは分けて整理する。

---

## 2. 初回提出の判断

| 判断 | 推奨 | 理由 |
|---|---|---|
| 初回提出は完全無料で出す | 推奨 | 審査範囲を認証、UGC、安全、プライバシーへ絞れる |
| 有料機能の紹介だけ見せる | 非推奨 | 未購入導線や価格表示があるとIAP未設定と見なされる可能性がある |
| IAPを同時提出する | 条件付き | StoreKit、復元、サーバー検証、特商法、返金説明まで完了している場合のみ |
| Stripe等の外部決済をiOSアプリ内に置く | 非推奨 | デジタル機能の課金はApple審査上のリスクが高い |

初回版で無料にする場合、App Store ConnectのIn-App Purchasesは未作成でもよい。ただし、アプリ内の有料機能ボタン、価格表示、課金画面、購入モーダル、特典説明が表示されないことを実機で確認する。
アプリ本体の配信地域、EU DSA、IAP Availabilityの横断確認は `notes/68_app_store_territory_dsa_iap_availability.md` を使う。

---

## 3. 商品IDルール

App Store ConnectのProduct IDは保存後に編集できず、削除しても同じIDを別商品に再利用できない。作成前にこの表で最終確認する。

| ルール | 方針 |
|---|---|
| Prefix | `jp.megrum.ios.` |
| 形式 | 小文字、ドット、アンダースコア、数字 |
| 変更 | 作成後は変更しない |
| 環境 | 本番AppとSandboxで同じProduct IDを使う |
| 廃止 | 商品を消すより、販売停止にする |

---

## 4. サブスクリプション設計

### 4.1 サブスクリプショングループ

Appleでは、同じサブスクリプショングループ内ではユーザーが同時に1商品だけ購入できる。PremiumとめぐりPlusを同時加入できる設計にするなら、グループを分ける必要がある。

| グループ | 含める商品 | 方針 | 注意 |
|---|---|---|---|
| Megrum Premium | Premium月額、Premium年額 | 同じ権限の期間違い | 月額/年額の切替を同グループで管理 |
| Megrum Meguri Plus | めぐりPlus月額 | Premiumと別権限 | 両方加入できる場合、二重課金になることをUIで説明 |

未決定：PremiumとめぐりPlusを同時加入可能にするか、めぐりPlusをPremium上位プランへ統合するか。現行仕様では `premium` と `meguri_plus` は別権限なので、このワークシートでは別グループを仮置きする。

### 4.2 サブスクリプション商品案

| 商品 | Product ID案 | 種別 | 表示名案 | 説明案 | 価格 | 権限 |
|---|---|---|---|---|---|---|
| Premium月額 | `jp.megrum.ios.premium.monthly` | Auto-renewable subscription | Premium 月額 | 広告非表示などの便利機能を1か月利用 | 500円/月 | `premium` |
| Premium年額 | `jp.megrum.ios.premium.yearly` | Auto-renewable subscription | Premium 年額 | 広告非表示などの便利機能を1年利用 | 4,800円/年 | `premium` |
| めぐりPlus月額 | `jp.megrum.ios.meguri_plus.monthly` | Auto-renewable subscription | めぐりPlus 月額 | めぐり本文表示と返信を1か月利用 | 1,000円/月 | `meguri_plus` |

表示名は2〜30文字、説明は45文字以内に収める。価格はApp Store Connectの価格表に合わせるため、最終表示金額はApple側設定を優先する。

### 4.3 サブスクリプション審査メモ案

```
PremiumはMegrum内の広告非表示等の追加機能を提供します。
めぐりPlusは、めぐりメッセージの本文表示、返信、新規送信上限拡張を提供します。
いずれも物理商品の購入や交換成立を保証するものではありません。
テストアカウントでログイン後、設定画面または該当機能の案内から購入画面を確認できます。
購入復元は設定画面から実行できます。
```

---

## 5. ブースト設計

ブーストは使うと残数が減る機能なので、IAP種別はConsumableを仮置きする。購入後にサーバーで検証し、`boosts` 残数を冪等に付与する。

| 商品 | Product ID案 | 種別 | 表示名案 | 説明案 | 価格 | 付与 |
|---|---|---|---|---|---|---|
| ブースト1個 | `jp.megrum.ios.boost.1` | Consumable | ブースト1個 | 表示優先に使えるブースト1個 | 150円 | 1 |
| ブースト5個 | `jp.megrum.ios.boost.5` | Consumable | ブースト5個 | 表示優先に使えるブースト5個 | 600円 | 5 |
| ブースト10個 | `jp.megrum.ios.boost.10` | Consumable | ブースト10個 | 表示優先に使えるブースト10個 | 1,000円 | 10 |

### 5.1 ブーストの表示ルール

| 項目 | 方針 |
|---|---|
| 結果保証 | 取引成立、返信、閲覧増、評価向上を保証しない |
| 効果時間 | 発動から24時間 |
| 対象 | `proposal` / `match_view` / `chat` はPhase βで再確認 |
| 発動上限 | 1日2個の上限は未実装なら初回IAP導入時に隠す |
| 返金 | App Storeの返金処理とサーバー残数調整を同期する |

### 5.2 ブースト審査メモ案

```
ブーストはMegrum内で表示優先などに使う消耗型アイテムです。
購入後、サーバー検証後にブースト残数へ反映されます。
ブーストは取引成立、返信、閲覧増、評価その他の結果を保証しません。
```

---

## 6. 権限とDB対応

| App Store商品 | `subscriptions.plan_type` | `user_entitlements.feature_key` | `transactions.kind` | 備考 |
|---|---|---|---|---|
| Premium月額 | `premium_monthly` | `premium` | `subscription_initial` / `subscription_renewal` | 月額 |
| Premium年額 | `premium_yearly` | `premium` | `subscription_initial` / `subscription_renewal` | 年額 |
| めぐりPlus月額 | `meguri_plus_monthly` | `meguri_plus` | `subscription_initial` / `subscription_renewal` | Premiumとは別権限 |
| ブースト1個 | なし | なし | `boost_pack` | `boosts` 1件付与 |
| ブースト5個 | なし | なし | `boost_pack` | `boosts` 5件付与 |
| ブースト10個 | なし | なし | `boost_pack` | `boosts` 10件付与 |

Apple由来の取引ID、Original Transaction ID、期限、返金、取消、請求失敗は、クライアント表示とは別にサーバーで保持する。アプリ側の有料判定は `subscriptions` の生状態ではなく、最終権限である `user_entitlements` を参照する。

---

## 7. StoreKit実装前チェック

| チェック | 必須 |
|---|---|
| 商品一覧をApp Store Connectから取得できる | はい |
| 購入成功時にApple取引を検証する | はい |
| サーバー側で同じ取引を二重付与しない | はい |
| サブスクリプション更新、期限切れ、返金、請求失敗を同期する | はい |
| 購入復元ボタンを設定画面へ置く | はい |
| 解約はApp Storeのサブスクリプション管理で行うと説明する | はい |
| TestFlight/Sandboxで購入、復元、期限切れ、返金相当を確認する | はい |
| App PrivacyでPurchasesを回答する | はい |

---

## 8. App Store Connect入力欄

### 8.1 共通

| 欄 | 入力方針 |
|---|---|
| Reference Name | 内部用。`Megrum Premium Monthly JP` など |
| Product ID | §4、§5の候補から最終決定 |
| Display Name | 日本語を主。English (U.S.)追加時は英語名も作る |
| Description | 45文字以内。結果保証表現を入れない |
| Price | 日本円の候補価格に近いApple価格を選ぶ |
| Availability | 初回は日本のみ推奨。多国展開時に拡張 |
| Review Screenshot | 実機またはSimulatorの購入画面を添付 |
| Review Notes | §4.3、§5.2を商品ごとに調整 |

### 8.2 商品別の未決定欄

| 商品 | 未決定 |
|---|---|
| Premium月額 | 実際に提供するPremium特典の最小範囲 |
| Premium年額 | 年額割引率と年額返金説明 |
| めぐりPlus月額 | Premiumと同時加入可能か |
| ブースト各種 | 発動対象、1日上限、返金時の残数調整 |

---

## 9. 特商法・サポート表示との突合

| 表示先 | 必ず一致させる項目 |
|---|---|
| アプリ内購入画面 | 商品名、価格、期間、解約、復元 |
| App Store Connect | 商品名、説明、価格、配信国 |
| 特商法表記 | 価格、支払方法、提供時期、解約、返金 |
| 利用規約 | 有料機能、返金、解約、結果非保証 |
| サポートページ | 解約、返金、購入復元、問い合わせ先 |
| App Review Notes | テスト方法、購入導線、復元導線 |

代表者名、住所、電話番号は、規約原典方針どおり「請求があれば遅滞なく開示」とする。ただし、App Store審査で問い合わせ先を確認される可能性があるため、`support@megrum.jp` とサポートURLは必ず有効化する。

---

## 10. Go / No-Go

| 条件 | 判定 |
|---|---|
| StoreKit購入と復元が未実装 | No-Go。有料UIを隠す |
| App Store Connect商品が未承認 | No-Go。有料UIを隠す |
| サーバー検証が未実装 | No-Go。有料UIを隠す |
| 特商法・サポート文面が未公開 | No-Go。有料UIを隠す |
| App PrivacyにPurchases未回答 | No-Go。有料UIを隠す |
| TestFlightで購入、復元、解約説明を確認済み | Go候補 |

---

## 11. 参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple In-App Purchase: https://developer.apple.com/in-app-purchase/
- Apple In-App Purchase information: https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-information/
- Apple Auto-renewable subscription information: https://developer.apple.com/help/app-store-connect/reference/auto-renewable-subscription-information/
- Apple IAP pricing and availability: https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-and-subscriptions-pricing-and-availability/
- App Store配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`
- Megrum マネタイズ戦略: `notes/16_monetization.md`
- Megrum データモデル: `notes/05_data_model.md`
- Megrum API仕様: `notes/13_api_spec.md`
- Megrum 法務整合: `notes/17_legal_alignment.md`
