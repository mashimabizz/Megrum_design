# 76. Zenn Webサービス公開前チェックリスト対応

最終更新: 2026-07-03
ステータス: Active checklist
参照元: https://zenn.dev/catnose99/articles/547cbf57e5ad28

## 目的

Zenn「Webサービス公開前のチェックリスト」をMegrum向けに読み替え、公開Web、Swift Native iOS、Supabase、App Store提出、法務・運用の公開前確認を1枚で追跡する。

判定:
- `[OK]`: 現在のコード又は公開URLで確認済み。
- `[PARTIAL]`: 実装はあるが、網羅確認又は外部設定確認が残る。
- `[NO-GO]`: 公開・提出前に対策が必要。
- `[N/A]`: 初回リリース範囲では該当しない。

## 今回実施した対策

- `web/next.config.ts` に公開Web全体のセキュリティヘッダーを追加した。
  - `Strict-Transport-Security`
  - `Content-Security-Policy: frame-ancestors 'none'` など
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy`
  - `Permissions-Policy`
- `web/src/app/legal/privacy/page.tsx` と `web/src/app/legal/terms/page.tsx` を追加し、App Store入力候補だった `/legal/*` URLでも既存の公開法務本文へ到達できるようにした。
- `web/next.config.ts` で `/admin`、`/auth`、`/login`、パスワード再設定系に `Cache-Control: private, no-store` を追加した。
- `web/src/app/not-found.tsx` を追加し、404ページを `noindex` かつ公式ページ導線付きにした。
- `web/src/app/auth/callback/route.ts` でWeb認証後の `next` を同一originのpathだけに正規化し、外部URLやscheme付き文字列を `/admin` にfallbackするようにした。
- `web/src/app/auth/actions.ts` で未知のSupabase認証エラーをそのまま画面へ返さず、固定の利用者向け文言へ丸めるようにした。
- `supabase/functions/suggest-goods-series/index.ts` と `supabase/functions/send-apns-notification/index.ts` で、外部API/Supabase/APNsのレスポンス本文や設定エラー詳細をHTTPレスポンスへ返さず、固定の公開エラーコードへ丸めるようにした。
- `ios-native/Sources/MegrumApp/GoodsGoogleLensPickerSheet.swift` で、Google Lensへ画像又は画像URLを送る前に、送信先と扱いを確認するNative alertを表示するようにした。
- `supabase/migrations/20260703120000_harden_meguri_board_media_storage_policy.sql` を追加し、`meguri-board-media` のStorage selectを認証済み全体から、表示可能な掲示板thread/replyに紐づくobjectへ絞った。
- `supabase/migrations/20260703123000_revoke_notification_devices_on_account_deletion.sql` を追加し、退会申請RPCの成功時にそのユーザーの未失効通知deviceをまとめて `revoked_at` にするようにした。
- `ios-native/Sources/MegrumApp/MegrumAuthStateSupport.swift` で、Native認証の未知Supabaseエラーや登録済みメールエラーをそのまま表示せず、文脈別の固定文言へ丸めるようにした。
- `ios-native/Config/MegrumNative.xcconfig` のチェックイン既定を広告OFF、AdMob app id/unit id/test unit id空、test ads OFFに変更し、提出ビルドで意図せずAdMob SDK初期化や広告リクエストが発生しない設定へ寄せた。
- `ios-native/Config/MegrumNative.local.xcconfig.example` に、広告検証時だけlocal configへ明示的に入れるAdMob設定欄を追加した。
- `ios-native/Config/MegrumNative.xcconfig` に `MEGRUM_PLUS_IAP_ENABLED=NO` を追加し、チェックイン既定ではメグルムプラスの購入/復元/StoreKit商品情報照会が動かない設定へ寄せた。
- `ios-native/Sources/MegrumApp/MegrumPlusRuntimeConfiguration.swift` を追加し、`MEGRUM_PLUS_IAP_ENABLED` 又はInfo.plistの `MegrumPlusIAPEnabled` が明示的にtrue系値の場合だけIAP購入導線を有効化するようにした。
- `ios-native/Sources/MegrumApp/SubscriptionSettingsScreen.swift` と `SubscriptionSettingsContent.swift` で、IAP無効時は購入/復元ボタンを表示せず、StoreKit商品取得と購入/復元actionを早期停止するようにした。

## セキュリティ

| ID | 項目 | 判定 | 現在の証拠 | 残対応 |
|---|---|---:|---|---|
| SEC-01 | 認証Cookieに `HttpOnly` / `SameSite` / `Secure` / 適切なDomainがある | `[PARTIAL]` | Webは `@supabase/ssr` のcookie連携を使用 | 実ログイン時の `Set-Cookie` を本番URLで取得し、属性を記録する |
| SEC-02 | GETで更新処理を行わない | `[PARTIAL]` | 管理系はserver actions中心 | Route Handlerとserver actionの操作系を再スキャンする |
| SEC-03 | ユーザー入力はサーバー側でも検証する | `[PARTIAL]` | Supabase RLS、Swift側validation、Edge Functionの入力上限あり | 管理画面action、Edge Function、RPC単位でvalidation表を作る |
| SEC-04 | ユーザー入力URLのprotocolを制限する | `[PARTIAL]` | OAuth authorize routeはscheme/host/pathをallowlist | `linkPath`、外部リンク、プロフィール入力を追加確認する |
| SEC-05 | HTMLをそのまま出力しない | `[PARTIAL]` | 現行Webで危険なHTML直出しは未確認 | `dangerouslySetInnerHTML` / markdown render / URL自動リンクを継続スキャンする |
| SEC-06 | SQL injectionを避ける | `[PARTIAL]` | PostgREST/RPC/RLS中心 | Supabase function内の動的SQLとRPCを重点確認する |
| SEC-07 | HSTSを返す | `[OK]` | live headerで確認済み、今回 `next.config.ts` にも追加 | deploy後に再確認する |
| SEC-08 | クリックジャッキング対策を行う | `[OK]` | 今回 `CSP frame-ancestors 'none'` と `X-Frame-Options: DENY` を追加 | deploy後に再確認する |
| SEC-09 | `X-Content-Type-Options: nosniff` を返す | `[OK]` | 今回 `next.config.ts` に追加 | deploy後に再確認する |
| SEC-10 | ユーザー別レスポンスをCDN等にキャッシュしない | `[PARTIAL]` | 今回admin/auth/login系に `no-store` を追加 | Supabase SSR cookie利用ページの本番headerを確認する |
| SEC-11 | オブジェクトストレージ一覧・推測アクセスを防ぐ | `[PARTIAL]` | `meguri-board-media` のauthenticated-wide readは今回migrationで表示可能thread/reply紐づきへ縮小 | 本番適用後のpolicy確認、public bucket運用、signed URL期間、削除時のobject cleanupを確認する |
| SEC-12 | オープンリダイレクト対策を行う | `[OK]` | mobile redirectはscheme/host/path allowlist、Web callbackの `next` は同一origin pathへ正規化 | 新しいredirect導線を追加するたびに同じ規則へ寄せる |
| SEC-13 | 更新・削除は権限のあるユーザーだけ可能 | `[PARTIAL]` | RLSとRPCで所有者/参加者確認が多数あり | 主要RPCの権限表を `notes/54` に同期する |
| SEC-14 | サーバー内部エラーをそのまま表示しない | `[PARTIAL]` | OpenAI/APNs Edge FunctionとWeb auth actionの未知エラー表示は今回解消 | Web管理画面のserver component/actionで管理者向けに出すDBエラー文の扱いを別途整理する |
| SEC-15 | ファイル形式・サイズ・ファイル名を検証する | `[PARTIAL]` | iOS側に画像サイズ上限とcontent type正規化あり | EXIF/GPS metadata残存とStorage object pathの設計確認 |
| SEC-16 | DB/Storage backup、cloud 2FAが有効 | `[NO-GO]` | コードからは確認不可 | Supabase/Vercel/Apple/Google/AdMob/メール/DNSのowner確認証跡が必要 |

## ログイン・メール

| ID | 項目 | 判定 | 現在の証拠 | 残対応 |
|---|---|---:|---|---|
| AUTH-01 | メール本人確認が有効 | `[OK]` | Supabase configで email confirmations 有効 | hosted Supabase設定で再確認する |
| AUTH-02 | メールアドレス列挙ができない | `[PARTIAL]` | Web auth actionとNative auth stateの未知エラー/登録済みメール表示は固定文言へ丸めた | 本番Supabaseのlogin/reset/sign-up実応答とメール送信挙動を確認する |
| AUTH-03 | 複数ログイン方法の同一メール仕様が決まっている | `[PARTIAL]` | Apple/Google/メール導線あり | 同一メールのリンク/衝突仕様をQAケース化する |
| MAIL-01 | SPF/DKIM/DMARCが設定済み | `[NO-GO]` | `notes/47` でTODO | DNS実測とZoho管理画面の証跡を残す |
| MAIL-02 | 大量送信・重複送信・購読解除に対応 | `[PARTIAL]` | 現状は認証/通知中心 | 販促メールや全体告知を出す前に同意・停止・重複防止を実装する |

## SEO / OGP / 公開URL

| ID | 項目 | 判定 | 現在の証拠 | 残対応 |
|---|---|---:|---|---|
| SEO-01 | title / description / canonical がある | `[OK]` | `layout.tsx` と各公開page metadata | ページ別OGPも必要なら拡張する |
| SEO-02 | 40x/50xが適切なstatus又はnoindex | `[OK]` | 今回 `not-found.tsx` を追加 | deploy後に404 statusとHTMLを確認する |
| SEO-03 | サイト全体にnoindexがない | `[OK]` | `layout.tsx` robotsはindex/follow | deploy後にHTMLを再確認する |
| SEO-04 | robots/sitemapがある | `[OK]` | `robots.ts` / `sitemap.ts` | Search Console登録はowner作業 |
| OGP-01 | og:title/description/url/image、twitter card | `[PARTIAL]` | root metadataは設定済み | `/terms` `/privacy` `/support` のページ別OGPを必要に応じて追加する |
| URL-01 | App Store / アプリ内リンクの法務URLが到達する | `[PARTIAL]` | 今回 `/legal/privacy` `/legal/terms` に同一本文のaliasページを追加 | 本文が正式原稿と同期するまでNo-Goを維持する |
| URL-02 | `html lang="ja"` がある | `[OK]` | `layout.tsx` | なし |
| URL-03 | favicon / apple-touch-icon がある | `[OK]` | `favicon.ico` / `apple-icon.png` | deploy後に再確認する |

## 決済・広告・外部AI

| ID | 項目 | 判定 | 現在の証拠 | 残対応 |
|---|---|---:|---|---|
| PAY-01 | IAP商品、価格、解約、返金、復元失敗、同期失敗の扱いが整う | `[PARTIAL]` | チェックイン既定は `MEGRUM_PLUS_IAP_ENABLED=NO`。IAP無効時は購入/復元ボタンを表示せず、StoreKit商品情報照会、購入、復元actionを早期停止する。Releaseの `MEGRUM_PLUS_IAP_ENABLED=NO` を確認 | 有料導線を出す場合はlocal/CIで明示的に有効化し、App Store Connect商品、価格、特商法、FAQ、Review Notes、Server API/Notifications、返金/取消/期限切れ同期、Purchases回答をそろえる |
| PAY-02 | 退会時の有料権限/購読状態が不整合を起こさない | `[NO-GO]` | 新規購入導線は既定停止にしたが、既存権限、手動上書き、将来IAP有効化時の削除申請と購読同期の完了保証は未確認 | 退会保留、購読案内、権限停止、返金/取消/期限切れ/請求失敗同期、削除完了時の権限扱いのQAを作る |
| ADS-01 | AdMob、ATT、UMP、App Privacy、テスト広告が整合 | `[PARTIAL]` | チェックイン既定は広告OFF、AdMob app id/unit id/test unit id空、Releaseの `MEGRUM_ADMOB_TEST_ADS_ENABLED=NO` を確認。`GoogleMobileAds` 依存とSKAdNetworkItemsは残る | 初回提出で広告を出す場合はlocal/CIで明示的に有効化し、ATT/UMP/App Privacy/Google公式開示/広告通報/test ads除去をそろえる。広告を出さない提出でも、実機でSDK初期化/広告リクエストなしを確認する |
| AI-01 | 外部画像検索・AI画像送信の説明・同意・保持・学習利用が明示される | `[PARTIAL]` | Google Lensの可視導線は今回送信前alertを追加。OpenAI Responses API + web searchのFunctionは存在 | OpenAI系をUI露出する場合は、送信前説明、任意性、送信先、保持/削除、学習利用の説明を同等に実装する |

## アクセシビリティ・性能・互換性

| ID | 項目 | 判定 | 現在の証拠 | 残対応 |
|---|---|---:|---|---|
| A11Y-01 | 画像に代替テキストがある | `[PARTIAL]` | 公開Web主要画像にはaltあり | SwiftUI画像、投稿画像、装飾画像の読み上げ方を画面別に確認する |
| A11Y-02 | icon-only button/linkにaccessibility labelがある | `[PARTIAL]` | Swift側にlabel多数 | 全主要フローのAccessibility Inspector又はUI testを追加する |
| PERF-01 | bundle analyzer / 静的asset cache / 画像サイズを確認 | `[PARTIAL]` | Webは静的画像中心 | `next build`結果、画像サイズ、Lighthouse相当を記録する |
| PERF-02 | SQL indexが足りている | `[PARTIAL]` | migrationに多数indexあり | 本番相当データで主要RPC/検索のEXPLAINを取る |
| COMPAT-01 | Safari/Firefox/mobile/tablet/長文入力で崩れない | `[PARTIAL]` | 今回はコード確認のみ | iPhone実機、iPad幅、Safari/Firefoxの公開Web確認を追加する |

## その他運用・法務

| ID | 項目 | 判定 | 現在の証拠 | 残対応 |
|---|---|---:|---|---|
| OPS-01 | server error monitoringがある | `[NO-GO]` | Sentry/Datadog等は未確認 | Crash/Edge Function/Web error monitoringを選定する |
| OPS-02 | 退会、個人情報請求、削除、保持例外が実装と一致 | `[NO-GO]` | 退会申請時の通知device失効は今回migrationで追加。`notes/45` で他の未完了項目あり | Auth削除、Apple/Google連携解除、削除完了ジョブ、完了通知、保持例外証跡をそろえる |
| OPS-03 | 通信の秘密・閉じた会話機能の届出要否を確認 | `[NO-GO]` | 取引チャットとめぐりメッセージあり | 専門家確認又は届出要否メモを `notes/17` / release runbookへ残す |
| OPS-04 | 公開法務文面、App Privacy、Review Notes、FAQが一致 | `[NO-GO]` | `notes/17` / `notes/37` で同期No-Go | 公開Web本文を正式原稿へ同期し、App Store入力値と照合する |

## 次に着手する順序

1. 公開Web deploy後にheaderと `/legal/*` redirect、404をlive確認する。
2. 正式な利用規約・プライバシーポリシー本文を公開Webへ同期し、アプリ内同意リンクとApp Store入力値を1本化する。
3. 広告を初回提出に含めるかを決める。現チェックイン既定は広告OFFなので、出す場合だけATT/App Privacy/UMP/テスト広告/広告通報をそろえてlocal/CI設定で明示的に有効化する。
4. 有料機能を初回提出に含めるかを決める。現チェックイン既定はIAP購入OFFなので、出す場合だけApp Store Connect商品、価格、公開特商法、Review Notes、Purchases回答、Server API/Notificationsをそろえてlocal/CI設定で明示的に有効化する。
5. OpenAI系の画像/検索Functionをユーザー向けUIに出すかを決め、露出する場合は送信前説明と任意性を追加する。
6. Supabase Storageの本番policy、signed URL期間、削除時cleanup、backup、cloud 2FA、DNS email認証をowner確認付きで埋める。
