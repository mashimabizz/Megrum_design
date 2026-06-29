# 33. IAP商品設定ワークシート

> 目的：App Store Connectでアプリ内課金を作成する前に、商品ID、表示名、説明、価格、権限、審査メモを固定する。
> コード変更なし。初回提出で有料機能を出すかどうかの判断材料として使う。

最終更新: 2026-06-29
ステータス: Draft v0.6（StoreKit・IAP販売可否・復元失敗 / 手動有料権限・権限上書き / 有料権限・ブースト非決済手段 / 現行メグルムプラスStoreKit経路・価格固定文言・サーバー検証未完了リスクを反映、Apple設定前）

---

## 1. 結論

現行Swift Nativeコードでは、メグルムプラスのStoreKit購入・復元経路と、商品ID候補 `megrum.plus.monthly` が存在する。購入ボタンはStoreKitの商品価格を読み込む一方、画面フッターには「月額500円」の固定文言もある。購入成功後もサーバー同期が失敗した場合は「購入は確認できました。サーバー同期は次回起動時に再確認してください。」と表示されるため、購入完了、権限反映、復元成功、販売継続を一体の保証として扱わない。初回App Store提出で最も安全なのは、App Store Connect商品、価格、審査情報、復元、サーバー同期、サーバー検証、返金/取消/期限切れ同期、特商法、App Privacyがそろうまで、メグルムプラスとブーストの購入導線をアプリ内で見せないこと。

設定画面内の特定商取引法に基づく表記は、現行コード上、正式な法的本文ではない旨の要約表示である。購入ボタン、復元ボタン、価格、特典説明又はサブスクリプション状態を見せる場合は、ログイン不要の公開特商法ページ、利用規約、プライバシーポリシー、FAQ、Review Notes、App Privacy、App Store Connect商品を同時に揃える。

有料機能を見せる場合は、次をP0として同時に完了する。

| 項目 | 必須条件 |
|---|---|
| App Store Connect | 商品作成、価格、配信国、ローカライズ、審査情報 |
| アプリ | StoreKit購入、購入復元、購入失敗、承認待ち、キャンセル、サーバー同期失敗、解約導線説明 |
| サーバー | Apple取引検証、権限付与、返金/取消/期限切れ/請求失敗/猶予期間同期 |
| 法務 | 特商法表記、利用規約、プライバシーポリシー、サポートページ |
| App Privacy | Purchasesを回答対象に含め、商品情報照会、価格取得、購入開始、未完了、キャンセル、復元失敗、サーバー同期失敗の記録をPrivacyと一致させる |
| Review Notes | 有料導線、デモアカウント、テスト手順を明記 |

Appleの審査では、アプリ内で消費・利用するデジタル機能は原則としてIAPで扱う前提に寄せるのが保守的。物理グッズそのものの決済をMegrum内で扱わない限り、交換対象グッズ代金とメグルムプラス/ブーストのIAPは分けて整理する。

---

## 2. 初回提出の判断

| 判断 | 推奨 | 理由 |
|---|---|---|
| 初回提出は完全無料で出す | 推奨 | 審査範囲を認証、UGC、安全、プライバシーへ絞れる |
| 有料機能の紹介だけ見せる | 非推奨 | 未購入導線や価格表示があるとIAP未設定と見なされる可能性がある |
| IAPを同時提出する | 条件付き | StoreKit、復元、サーバー検証、特商法、返金説明まで完了している場合のみ |
| Stripe等の外部決済をiOSアプリ内に置く | 非推奨 | デジタル機能の課金はApple審査上のリスクが高い |

初回版で無料にする場合、App Store ConnectのIn-App Purchasesは未作成でもよい。ただし、アプリ内のメグルムプラスボタン、復元ボタン、価格表示、課金画面、購入モーダル、特典説明、特定商取引法表示入口から有料条件に到達できないことを実機で確認する。現行コードに購入経路があるため、「実装していない」ではなく「表示・到達不可にしている」ことを確認する。
アプリ本体の配信地域、EU DSA、IAP Availabilityの横断確認は `notes/68_app_store_territory_dsa_iap_availability.md` を使う。

---

## 3. 商品IDルール

App Store ConnectのProduct IDは保存後に編集できず、削除しても同じIDを別商品に再利用できない。作成前にこの表で最終確認する。

| ルール | 方針 |
|---|---|
| Prefix | 現行コード候補はprefixなしの `megrum.` 系。新規に `jp.megrum.ios.` 系へ変更する場合はコード更新が必要 |
| 形式 | 小文字、ドット、アンダースコア、数字 |
| 変更 | 作成後は変更しない |
| 環境 | 本番AppとSandboxで同じProduct IDを使う |
| 廃止 | 商品を消すより、販売停止にする |

---

## 4. サブスクリプション設計

### 4.1 サブスクリプショングループ

Appleでは、同じサブスクリプショングループ内ではユーザーが同時に1商品だけ購入できる。現行公開導線はメグルムプラスに統一する。旧Premium/旧めぐりPlusは互換・履歴用の権限として扱い、新規商品として出す場合は別途レビューする。

| グループ | 含める商品 | 方針 | 注意 |
|---|---|---|---|
| Megrum Plus | メグルムプラス月額 | 現行公開導線 | 初回は月額のみ。年額や上位プランを追加する場合は同グループで整理 |
| Legacy Premium | Premium月額、Premium年額 | 互換・履歴用 | 新規公開導線では使わない |
| Legacy Meguri Plus | めぐりPlus月額 | 互換・履歴用 | 新規公開導線では使わない |

現行仕様では `megrum_plus` が公開向けの正、`premium` と `meguri_plus` は互換・履歴用。互換権限を保持する場合でも、App Store Connectで新規作成する商品はメグルムプラスから始める。

### 4.2 サブスクリプション商品案

| 商品 | Product ID案 | 種別 | 表示名案 | 説明案 | 価格 | 権限 |
|---|---|---|---|---|---|---|
| メグルムプラス月額 | `megrum.plus.monthly` | Auto-renewable subscription | メグルムプラス | 個別募集やグルーム保存を広げる月額プラン | 500円/月 | `megrum_plus` |

表示名は2〜30文字、説明は45文字以内に収める。価格はApp Store Connectの価格表に合わせるため、最終表示金額はApple側設定を優先する。現行アプリ内固定文言の「月額500円」とApp Store Connectの価格がずれる場合はNo-Go。

旧コード互換候補:

| 商品 | Product ID候補 | 権限 | 公開方針 |
|---|---|---|---|
| Premium月額 | `megrum.premium.monthly` | `premium` | 新規公開導線では使わない |
| Premium年額 | `megrum.premium.yearly` | `premium` | 新規公開導線では使わない |
| めぐりPlus月額 | `megrum.meguri_plus.monthly` | `meguri_plus` | 新規公開導線では使わない |

### 4.3 サブスクリプション審査メモ案

```
メグルムプラスは、個別募集の作成数上限拡張、ホーム/検索でのグッズ優先表示、グルームアーカイブ保存枠の拡張を提供します。
物理商品の購入、交換成立、返信、表示回数、取引結果を保証するものではありません。
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
| 法務境界 | ブーストはMegrum内の表示補助特典であり、現金、ポイント、前払式支払手段、資金移動、預り金、決済手段、譲渡可能資産として説明しない |

未使用残数がある場合でも、利用規約、App Store規約、返金、取消、期限切れ、規約違反、アカウント制限、機能終了、仕様変更又は運営上必要な場合に、失効、消費、停止、取消、調整又は削除され得る前提で設計する。画面上も、換金、譲渡、売買、アカウント間移転、外部サービスへの持ち出し、取引成立保証、閲覧数保証、返信保証のように見せない。

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
| メグルムプラス月額 | `megrum_plus_monthly` | `megrum_plus` | `subscription_initial` / `subscription_renewal` | 現行公開導線 |
| Premium月額 | `premium_monthly` | `premium` | `subscription_initial` / `subscription_renewal` | 互換・履歴 |
| Premium年額 | `premium_yearly` | `premium` | `subscription_initial` / `subscription_renewal` | 互換・履歴 |
| めぐりPlus月額 | `meguri_plus_monthly` | `meguri_plus` | `subscription_initial` / `subscription_renewal` | 互換・履歴 |
| ブースト1個 | なし | なし | `boost_pack` | `boosts` 1件付与 |
| ブースト5個 | なし | なし | `boost_pack` | `boosts` 5件付与 |
| ブースト10個 | なし | なし | `boost_pack` | `boosts` 10件付与 |

Apple由来の取引ID、Original Transaction ID、期限、返金、取消、請求失敗、猶予期間は、クライアント表示とは別にサーバーで保持する。アプリ側の有料判定は `subscriptions` の生状態ではなく、最終権限である `user_entitlements` を参照する。購入直後にサーバー同期が失敗した場合のローカル有効表示は、永続的な権限付与の証拠として扱わない。

管理画面の有料権限手動上書きは、`plan_overrides` と `user_entitlements.source = 'manual_override'` を使う運用上の暫定・補正手段として扱う。サポート対応、返金/取消/チャージバック、同期不具合、キャンペーン、トライアル、障害対応、規約違反、セキュリティ対応、検証又は公開前テスト等で権限を付与又は停止する場合でも、購入完了、返金保証、無償提供の継続又はApp Store決済の取消を意味しない。対象ユーザー、feature key、active/inactive、期限、理由、変更前後の状態、作成者、監査ログを確認し、理由なしの恒久付与を避ける。

---

## 7. StoreKit実装前チェック

| チェック | 必須 |
|---|---|
| 商品一覧をApp Store Connectから取得できる | はい |
| 購入成功時にApple取引を検証する | はい。現行RPCコメント上、App Store Server APIによるサーバー検証は本番前追加 |
| サーバー側で同じ取引を二重付与しない | はい |
| サブスクリプション更新、期限切れ、返金、取消、請求失敗、猶予期間を同期する | はい |
| 購入復元ボタンを設定画面へ置く | はい |
| 解約はApp Storeのサブスクリプション管理で行うと説明する | はい |
| TestFlight/Sandboxで購入、復元、期限切れ、返金相当を確認する | はい |
| App PrivacyでPurchasesを回答する | はい |
| 手動有料権限上書きに理由、監査ログ、期限、対象ユーザー確認がある | はい |
| 手動上書きを購入証明、返金保証、無償提供保証として扱わない説明がある | はい |

---

## 8. App Store Connect入力欄

### 8.1 共通

| 欄 | 入力方針 |
|---|---|
| Reference Name | 内部用。例: `Megrum Plus Monthly JP` |
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
| メグルムプラス月額 | Product IDを `megrum.plus.monthly` で確定するか、prefix付きへ変更するか |
| メグルムプラス月額 | 無料ユーザー上限、優先表示の範囲、グルーム保存枠の実装と文面一致 |
| メグルムプラス月額 | App Store Connect価格と、購入画面、フッター固定文言、特商法、FAQ、Review Notesの価格一致 |
| メグルムプラス月額 | App Store Server API又はServer Notificationsで、更新、返金、取消、期限切れ、請求失敗、猶予期間を同期する方法 |
| Legacy Premium / Legacy Meguri Plus | 新規公開導線に出さないことの確認 |
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
| 返金/取消/期限切れ/請求失敗/猶予期間の同期が未確認 | No-Go。有料UIを隠す |
| アプリ内価格固定文言とApp Store Connect価格が一致しない | No-Go。有料UIを隠す |
| 特商法・サポート文面が未公開 | No-Go。有料UIを隠す |
| App PrivacyにPurchases未回答 | No-Go。有料UIを隠す |
| 手動有料権限上書きに理由、監査ログ、期限又は対象ユーザー確認がない | No-Go。有料UI又は管理運用を止める |
| 手動上書きを購入完了、返金確定、無償提供継続の根拠として案内している | No-Go。規約、FAQ、サポート文面を修正する |
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
