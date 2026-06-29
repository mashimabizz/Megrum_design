# 54. 提出前セキュリティ監査チェックリスト

最終更新: 2026-06-29

ステータス: Draft v1.0（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / 運営通知・通知本文統制 / ローカルenv・Vercel env・Supabase secrets・server-only key境界 / デバッグログ・Edge Functionエラー・公開証跡secret混入防止 / カスタムURL scheme・認証リダイレクト・ディープリンク / Storage公開範囲・署名URL・Edge Function外部送信の現行読み取りを反映・コード変更なし・提出前監査用）

## 目的

App Store初回提出前に、MegrumのDB、Storage、Edge Function、秘密鍵、通知、公開URL、管理者権限まわりを横断して確認するための監査チェックリスト。

この文書は確認台帳であり、コード、DB、Supabase設定、Apple Developer設定、App Store Connect設定は変更しない。
担当者、権限、secret管理場所の棚卸しは `notes/61_release_access_owner_registry.md` を使う。

## 1. 公式ドキュメントからの前提

| 領域 | 確認前提 |
|---|---|
| Supabase RLS | `public` schema等、APIから到達し得るテーブルはRLSを有効にし、ロールごとに必要な権限だけを与える |
| Supabase Storage | アップロード、閲覧、更新、削除は `storage.objects` のRLS policyで制御する |
| Supabase secrets | Edge Function内のsecret keyやservice role keyはRLSを迂回するため、ブラウザ/アプリ/公開リポジトリに出さない |
| Edge Function認証 | ユーザー呼び出し、service-to-service、公開Webhookで認証方式を分け、公開Functionは別の署名/secret検証を持つ |
| APNs | provider server側でAPNs credentialとdevice tokenを扱う。通知payloadに不要な個人情報を入れない |

## 2. 現行リポジトリから読めた事実

2026-05-31時点の静的読み取り。実環境の設定値、Dashboard設定、デプロイ済み状態は未確認。

| 領域 | 読み取り結果 | 監査ポイント |
|---|---|---|
| Supabase migrations | 多数の `enable row level security` と `create policy` がある | 未保護テーブル、広すぎる `using (true)`、権限ロールを提出前に確認 |
| Storage | `goods-photos`, `chat-photos`, `avatars`, `groom-posts`, `meguri-message-media`, `meguri-board-media` 等のbucket/policyがある | public bucketとprivate bucketの意図、署名URL、削除policyを確認 |
| APNs Edge Function | `send-apns-notification` が `SUPABASE_SERVICE_ROLE_KEY`, APNs秘密鍵、dispatch secret等を使う | secret登録、認証header、ログ、環境切替を確認 |
| Web server | `SUPABASE_SECRET_KEY` をserver側で使う箇所がある | server-onlyであること、クライアントbundleや公開ログへ出ないことを確認 |
| Web管理画面 | `admin_roles`、`admin_audit_logs`、ユーザー一覧、通報/異議申し立て、推し追加リクエスト、有料権限、サブスクリプション、運営通知をservice role経由で扱う。有料権限は `entitlements.manage` 権限で `plan_overrides` と `user_entitlements.source='manual_override'` を作成し、理由、期限、変更前後、作成者を監査ログ化する。運営通知は `notifications.send` 権限で、全有効ユーザー又は指定ユーザーへ `admin_announcement` を作成し、title/body/link_pathを通知行及び直近通知表示に残す | 管理者MFA、最小権限、owner冗長性、監査ログ、IP/User-Agent保存、secretのserver-only、有料権限の対象ユーザー確認、理由、期限、変更前後、手動上書きの非保証説明、運営通知の送信理由、対象件数、本文プレビュー、全体送信確認、退会後保持を確認 |
| Swift Native | Supabase URL/key、Storage URL、APNs device token、Apple/Google認証、位置情報、カメラ/写真を扱う | publishable keyのみ、Privacy/App Privacyと一致することを確認。位置情報は現在地共有、待ち合わせ候補、現地交換モード、グルーム/掲示板の作成座標、閲覧者座標、1km/3km距離判定まで棚卸しする |
| Swift Native / 会員間支払い | `user_payment_settings` に支払い方法、銀行名、支店名、口座種別、口座番号、口座名義、任意メモを保存し、金額指定取引の合意時に `proposals.sender_payment_settings` / `receiver_payment_settings` へスナップショット化して当事者へ表示する経路がある | RLS、proposal参加者限定表示、管理者最小権限、ログ/通知/サポート証跡への口座情報・送金リンク・送金用QR・外部サービスID混入防止、設定変更/削除後も成立後スナップショットが残る説明を確認 |
| Swift Native / Auth Links | `CFBundleURLSchemes=$(MEGRUM_URL_SCHEME)`、`MegrumAuthEmailRedirectURL`、`MegrumAuthOAuthAuthorizeURL`、`ASWebAuthenticationSession`、`onOpenURL`、認証callback parserが存在 | callback token、redirect allowlist、URL scheme、外部ブラウザ/メールアプリ、deep linkのログ/共有リスクを確認 |
| Swift Native / DEBUG logs | `MegrumAppLogger.general` と `NativePush` loggerがあり、DEBUG時に `privacy: .public` でerror descriptionを出す箇所がある | error objectにtoken、署名URL、画像URL、個人情報が混ざらないか、公開証跡へ貼らない運用を確認 |
| Edge Function / error detail | `suggest-goods-series` と `send-apns-notification` は外部API又はSupabase応答本文を含むエラーdetailを返す経路がある | response textにユーザー入力、画像URL、通知本文、secretが混ざらないか、Function logs/レスポンス/証跡の最小化を確認 |
| Local / deploy env | `.env.local`、`.vercel/.env.production.local`、`web/.env.local` 等のローカル/デプロイ用envファイルが存在し得る。`web/.env.local.example` はplaceholderのみ | 実値を開示せず、キー名、保管場所、権限、ローテーション要否だけを証跡化する。実値入りenvファイルをPR、チャット、App Review証跡、公開ページへ入れない |
| Seed / admin scripts | `scripts/seed_michilion_receive_selection_live_data.py` と `scripts/seed_mutual_match_live_data.py` は `web/.env.local` から `SUPABASE_SECRET_KEY` を読み、service role相当で実DBを操作し得る | 本番/共有環境での実行権限、出力、summary、事故時ロールバック、secret実値のログ混入を確認 |
| Swift Native / checked-in config | `ios-native/Config/MegrumNative.xcconfig` にはAdMob app id、test ad unit id、一部production ad unit idが入る。これはsecretではないが広告SDK設定として公開・審査・App Privacy対象 | AdMob app id/unit idをprivate key扱いしない一方、test ads除去、広告開示、ATT/Google公式開示、広告通報導線と合わせて確認 |
| 外部サービス | Supabase、Apple、Google、地図、IAP、Stripe候補、外部AI候補がある | 初回提出で見えるサービスだけを公開文面とApp Privacyへ反映 |
| 事故対応 | `notes/49` に初動ランブックがある | 担当者、連絡先、証跡保存先は未確定 |

## 3. 監査Gate

| Gate | 項目 | 完了条件 | 証跡 | No-Go |
|---|---|---|---|---|
| SEC-001 | RLS有効化 | API到達テーブルにRLSがあり、認証不要/認証済み/管理者の意図が説明できる | SQL一覧、Dashboardスクショ、policyレビュー記録 | user_idや取引情報を持つtableがRLSなし |
| SEC-002 | RLS policyの範囲 | `using (true)` の公開範囲がマスター/公開プロフィール等に限定されている | 広いpolicyの棚卸し | 個人情報、取引、通知、通報、削除対象で広いselectがある |
| SEC-003 | Storage bucket公開範囲 | public/privateの意図が各bucketで説明できる | bucket設定、policy一覧 | 取引チャット、証跡、通報画像が公開bucket又は広すぎるselect。又はprivate bucketでもauthenticated全体selectや長期signed URLを説明できない |
| SEC-004 | Storage所有者制御 | upload/update/deleteが本人又は参加者に制限されている | `storage.objects` policy確認 | 他人の画像を上書き/削除/一覧できる |
| SEC-005 | 署名URL | private mediaは用途に合う有効期限で生成し、不要な永続公開URLを使わない | 実装箇所、実機通信確認 | private mediaをpublic URLで返している。又は1年等の長期signed URLを使う理由、再共有リスク、削除時無効化を説明できない |
| SEC-006 | service role / secret key | secret keyはserver/Edge Function/Dashboard/安全なローカルenvに限定され、公開コード・client bundle・提出証跡にはキー名だけを残す | envキー名一覧、bundle確認、ログ確認、権限者/保管場所の確認。`.env.local`等の実値は保存しない | iOS app、web client、公開ページ、スクショ、README、App Review証跡、チャットにsecret実値がある |
| SEC-007 | Edge Function認証 | APNs dispatch Functionはservice role又はdispatch secretで保護されている | Function設定、README、呼び出し元SQL/cron確認 | 認証なしで任意通知を送れる |
| SEC-008 | APNs credential | Team ID、Key ID、private key、Bundle ID、production/development環境が一致する | Apple Developer、Supabase secrets、送信テスト | production buildでdevelopment credential、又はprivate key漏えい |
| SEC-009 | 通知payload | 通知本文に不要な個人情報、正確な場所、内部IDを含めない。運営通知の全体送信では送信理由、対象件数、本文プレビュー、二重確認、監査ログを確認する | payloadサンプル、実機通知スクショ、管理画面送信前確認、監査ログ | ロック画面に機微な取引内容や内部IDが出る。又は運営通知の全体送信で宛先、理由、本文、リンク先、対象件数を確認できない |
| SEC-010 | Auth/OAuth | Apple/Google redirect URL、削除時連携解除、secret管理が確認済み | Auth設定、削除テスト記録 | Sign in with Appleの削除連携が未説明、OAuth secret漏えい |
| SEC-010.5 | Auth callback / URL scheme | `MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Supabase Redirect URLs、Google OAuth redirect、Web中継Route、Info.plist、Review Notesが一致し、callback tokenをログ/証跡/スクショへ出さない | xcconfig、Info.plist、Supabase Auth設定、Google Cloud設定、Web route確認、実OAuth/メールcallbackテスト | 認証callbackのaccess token/refresh tokenを外部に露出する。redirect allowlistが古い/広すぎる/本番scheme不一致。custom URL schemeを安全保証として説明している |
| SEC-010.6 | Keychain session / refresh token | AuthSessionのKeychain保存、`kSecAttrAccessible`方針、ThisDeviceOnly要否、refresh token更新、logout時clear、他端末session失効、端末紛失時案内が説明できる | `AuthSessionStore.swift`、実機logout、再起動復元、Keychain accessibility確認、ログ/証跡確認 | access token/refresh tokenをログ、スクショ、サポート証跡へ出す。Keychain accessibility/backups/復元/他端末session未確認のまま完全削除を保証する |
| SEC-011 | 公開URL/サポート | Legal/Support URLがHTTPSで公開され、秘密情報が混入していない | `notes/37` 証跡 | URLが404、又は公開ページに内部ID/secret/debug情報がある |
| SEC-012 | 管理者権限 | admin role、permissions、MFA、owner冗長性、audit log、運用者アクセスが最小限である | admin一覧、audit log確認、`web/src/lib/admin/permissions.ts`、管理画面スクショ | 一般ユーザーがadmin対象の情報を読める。又はservice role経由の閲覧/更新にMFA、最小権限、操作理由、監査ログがない |
| SEC-013 | 外部サービス | 初回提出で見える外部サービスが `notes/48` とApp Privacyに反映されている | 台帳、App Privacy回答 | 外部AI、決済、地図APIが見えるのに未記載 |
| SEC-014 | ログ/証跡 | サーバーログ、Functionログ、Swift DEBUG OSLog、外部APIエラーdetail、管理者監査JSON、サポート証跡にsecretや実在ユーザー情報を残さない | ログサンプル確認、`privacy: .public` 箇所棚卸し、Edge Function error response確認、管理画面監査ログ表示確認 | token、private key、実パスワード、認証code、signed URL、画像URL、通知本文、通報本文、削除請求本文を不用意に保存又は公開証跡へ貼る |
| SEC-015 | データ削除 | アカウント削除時にDB/Storage/通知token/外部サービスの扱いを説明できる | `notes/45`, `notes/52` | 削除請求後も不要なdevice tokenや画像が残る |
| SEC-016 | Incident readiness | 漏えい疑い時の担当、受付番号、証跡保存、本人通知/PPC報告判断が準備済み | `notes/49` | 事故疑いがあるのに提出判断を進める |
| SEC-017 | Member payment data | 支払い設定と成立後支払い情報スナップショットが本人又は取引当事者に限定され、管理者閲覧は最小権限・理由・監査ログ付きで、通知/ログ/証跡/サポート返信へ不要に出ない | `user_payment_settings` RLS、proposal snapshot参照範囲、管理画面権限、ログサンプル、Supportテンプレ | 銀行口座、口座名義、送金リンク、送金用QR、外部サービスIDが当事者以外へ見える。Megrumが口座名義、本人性、支払能力、残高、外部ID、送金リンク、QRを確認済みのように扱う |
| SEC-018 | Location data and proximity scope | 現在地共有、待ち合わせ候補、現地交換モード、グルーム/掲示板の作成座標、閲覧者座標、距離判定、公開範囲が、RLS、RPC、ログ、通知、サポート証跡、App Privacy、Privacy、FAQと一致し、必要最小限の表示/保持になっている | `messages` RLS、`user_local_mode_settings` RLS、`activity_windows`、`groom_posts.origin_lat/lng`、`meguri_board_threads.origin_lat/lng`、RPC範囲、ログサンプル、Review Notes | 精密座標、作成位置、閲覧者位置、半径、距離、公開範囲が不要な相手、公開ログ、通知本文、管理者以外のサポート証跡に出る。1km/3kmを匿名化、安全確認、本人確認又は推測防止として扱う |

## 4. Supabase RLS監査

### 4.1 机上確認

| 確認 | 方法 | 判定 |
|---|---|---|
| API到達table一覧 | Supabase Dashboard又はSQLで `public` schemaのtableを一覧化 | TODO |
| RLSなしtable | `relrowsecurity=false` のtableを抽出 | TODO |
| 広いselect policy | `using (true)` や匿名read policyを棚卸し | TODO |
| owner/participant制御 | user_id、owner_user_id、proposal参加者、trade参加者で絞れているか確認 | TODO |
| 通報/通知/削除対象 | reports、notifications、devices、deletion-related dataが本人/管理者限定か確認 | TODO |

### 4.2 管理者画面 / service role監査

2026-06-29のコード読み取りで、Web管理画面は次を扱うことを確認した。提出前に実環境と完成ビルド運用で再確認する。

| 確認 | 読み取り結果 | 判定 |
|---|---|---|
| 管理者ロール | `owner`, `support`, `trust_safety`, `billing`, `viewer`。`owner` 又は `*` は全権限 | TODO |
| 権限 | `users.read`, `users.update_status`, `roles.read`, `roles.manage`, `reports.read`, `reports.moderate`, `oshi_requests.*`, `notifications.send`, `billing.read`, `entitlements.manage`, `audit.read` 等 | TODO |
| MFA | `requires_mfa` がtrueならJWT claim `aal` が `aal2` でなければ管理画面を404扱い | TODO |
| service role | 管理者権限確認、ユーザー検索、通報、課金、権限、通知、監査ログはサーバー側service role client経由 | TODO |
| 監査ログ | `actor_user_id`, `action`, `target_type`, `target_id`, `reason`, `before_state`, `after_state`, `metadata`, `request_ip`, `user_agent` を保存 | TODO |
| ユーザー管理 | メール、ハンドル、表示名、活動エリア、アカウント状態、有料権限を表示し、状態変更を監査ログ化 | TODO |
| 通報/異議 | `reports`, `goods_reports`, `groom_reports`, `meguri_board_reports`, `disputes` を横断表示し、status、operator_comment、outcomeを更新可能 | TODO |
| 運営通知 | 全有効ユーザー又は指定ユーザーへ `admin_announcement` を作成。title/body/link_pathは通知行及び直近通知表示に残り、reasonとaudience/recipient_count/title/link_pathは監査ログへ残る。bodyを監査metadataへ入れる経路は未確認 | TODO |
| 有料権限 | `user_entitlements`, `plan_overrides`, `subscriptions` を表示し、手動上書きでは対象ユーザー、feature key、active/inactive、期限、理由、変更前後、作成者、override idを監査ログ化 | TODO |
| 権限管理 | 最後のownerを無効化/降格できないガードあり | TODO |

No-Go:
- `SUPABASE_SECRET_KEY` 又はservice role keyがクライアントbundle、公開ページ、ログ、スクショ、証跡へ出る。
- `.env.local`、`.vercel/.env.production.local`、`web/.env.local`、Supabase Dashboard secrets、Vercel env、Apple private key、Stripe webhook secret等の実値を、確認証跡、PR、Issue、チャット、公開ページ、App Review添付、サポート返信へ貼る。
- `supabase secrets list`、Vercel env一覧、Apple Developer Key画面、Stripe webhook設定、Google OAuth client secret画面を、実値又はsecretの一部が見える状態で保存する。
- access token、refresh token、password reset token、認証code、Keychain保存session JSON、OAuth secret、SMTP passwordがログ、スクショ、公開証跡、問い合わせテンプレート又はPRに出る。
- `privacy: .public` のOSLog、Function `messageOf(error)`、外部API `response.text()`、管理者監査JSON、App Review証跡、サポート返信に、token、secret、signed URL、画像URL、通知本文、通報/削除申出本文又は実ユーザー情報が混入する。
- Keychain sessionの `kSecAttrAccessible` 方針、ThisDeviceOnly要否、端末バックアップ/復元/紛失時の案内、他端末session失効、logout時clearを説明できないのに、ログアウト又は退会で全session/tokenの即時完全削除を保証している。
- 管理者MFAが無効なまま、ユーザー、通報、課金、権限、監査ログを閲覧又は更新できる。
- `audit.read` 権限が広すぎ、監査ログのbefore/after stateやIP/User-Agentを不要な担当者が読める。
- 有料権限の手動付与又は停止に、対象ユーザー確認、理由、期限、変更前後の状態、監査ログ、権限者確認がない。
- 手動有料権限上書きを、購入完了、返金完了、補償、無償提供継続又はApp Store決済取消として案内している。
- 運営通知の全体送信に二重確認、理由、対象件数、本文プレビュー、監査ログ、送信対象の確認がない。
- 運営通知の本文又はリンク先に、正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報又は異議申し立て詳細本文、secret、内部ID、相手会員の不要な個人情報を含める。
- 通知本文、運営通知、Function logs、Swift DEBUG OSLog、管理者監査JSON、App Review証跡、公開レビュー返信又はサポート返信に、銀行口座番号、口座名義、送金リンク、送金用QR、外部サービスID、相手方の支払い情報スナップショットを不要に含める。
- 通知本文、運営通知、Function logs、Swift DEBUG OSLog、管理者監査JSON、App Review証跡、公開レビュー返信又はサポート返信に、精密座標、作成位置、閲覧者位置、活動ウィンドウ中心座標、宿泊先、座席番号、未成年者の居場所を不要に含める。
- 現地交換モード、グルーム、掲示板、待ち合わせ候補のRLS/RPC/Storage/ログ確認なしに、近距離公開を匿名、安全確認済み、本人確認済み、所在確認済み又は推測防止済みとして公開説明する。
- 通報者情報、削除申出本文、会員間支払い情報、成立後支払い情報スナップショット、郵送先情報、監査ログをサポート外の担当者が見られる。

### 4.3 SQL確認案

実DBに対して実行する場合は、readonlyで結果だけ保存する。

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by tablename;
```

```sql
select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname in ('public', 'storage')
order by schemaname, tablename, policyname;
```

## 5. Storage監査

| bucket | 初回提出の想定 | 確認 |
|---|---|---|
| `goods-photos` | 在庫写真。migration上public bucketで、`GoodsPhotoURLResolver` が公開URLを生成 | 公開カード/検索/プロフィール等で見える前提の画像だけ入ること。第三者の顔、住所、チケット、QR、EXIF等の注意文と削除時のStorage cleanupを確認 |
| `avatars` | プロフィール画像。migration上public bucketで、`SupabaseProfilePhotoStorage` が公開URLを生成 | 公開プロフィールに使う画像だけ入ること。削除/更新時の古いobject残存、外部共有、キャッシュを確認 |
| `chat-photos` | 取引チャット/服装写真/証跡。private bucket、proposal参加者限定policy | 現行コードではsigned URLが365日。URL再共有、削除時無効化、証跡保持、相手保存をPrivacy/FAQと合わせて確認 |
| `meguri-message-media` | めぐりメッセージ画像。private bucket、送受信者限定policy | block/削除/退会時の表示、signed URL期限、通報時保持を確認 |
| `meguri-board-media` | スポット掲示板画像。private bucketだがStorage policyはauthenticated user全体select | アプリ側は表示可能thread/replyのpathだけsigned URL化する設計。path推測、一覧、RLS/policy、公開範囲、削除、通報時保持を提出前No-Goで確認 |
| `groom-posts` | グルーム画像。後続migrationでprivate化し、`can_view_groom_object()` 経由の閲覧制御 | 投稿期限切れ、非表示、block、通報、signed URLキャッシュ、削除時のobject残存を確認 |

No-Go:
- 参加者限定であるべき画像がpublic bucketにある。
- bucket一覧やpath規則から他人の画像を推測できる。
- 削除済みアカウントの画像が不要に残る。
- signed URLの有効期限が長すぎ、再共有リスクを説明できない。
- `meguri-board-media` のauthenticated selectが、掲示板の閲覧範囲、block、非表示、削除、通報対応と矛盾する。
- 公開画像bucketに、住所、顔、チケット、注文履歴、バーコード、QR、EXIF/GPS等を含む画像が入り得るのに、アプリ内注意、Privacy、FAQ、削除手順がない。

## 6. Edge Function / APNs監査

| 確認 | 完了条件 | 証跡 |
|---|---|---|
| secrets登録 | `SUPABASE_SERVICE_ROLE_KEY`, `MEGRUM_APNS_TEAM_ID`, `MEGRUM_APNS_KEY_ID`, `MEGRUM_APNS_PRIVATE_KEY`, `MEGRUM_APNS_BUNDLE_ID`, `MEGRUM_APNS_ENVIRONMENT`, `MEGRUM_APNS_DISPATCH_SECRET` が本番Projectに設定済み | Supabase secrets listのキー名だけ |
| dispatch認証 | Function呼び出し元がservice role又はdispatch secretを使う | README、設定、呼び出し元確認 |
| APNs環境 | TestFlight/本番でproduction APNs、Debugでdevelopment APNsを使う | 送信ログ、端末受信 |
| payload | title/bodyに不要な個人情報や内部IDが入らない。運営通知では全体送信前に宛先区分、対象件数、本文、リンク先、送信理由を確認する | payloadサンプル、管理画面確認記録 |
| token失効 | APNsエラー時にdevice token無効化/再登録ができる。ログアウト時のclient-side revoke、退会申請/削除完了時の全端末token無効化との関係を説明できる | テスト記録、コード確認 |
| logs | Function logsにtoken、private key、通知本文の全文が出ない | ログサンプル |

### 6.1 Edge Function / 外部AI監査

| 確認 | 完了条件 | 証跡 |
|---|---|---|
| `suggest-goods-series` 認証 | Bearer tokenをSupabase Authへ照会し、認証済みユーザーだけOpenAIへ送信 | Functionコード、呼び出し実機確認 |
| OpenAI送信情報 | 最大3件の画像データ又は画像URL、グループ名、メンバー名、グッズ種別、既存候補だけに絞る | payloadサンプル。ただし画像実物やsecretは証跡に貼らない |
| web search利用 | `web_search` 必須の仕様をPrivacy、App Privacy、Review Notes、アプリ内説明と一致させる | Privacy/FAQ/Review Notes |
| 学習利用/保持 | OpenAI APIのデータ保持、学習利用、削除可否、DPA/契約条件を確認 | 公式docs又は契約管理メモ |
| consent/notice | 外部AIへ画像を送る前の説明、同意又は任意性を確認 | 実機スクショ |
| logs | Function logsに画像base64、画像URL、OpenAI API key、ユーザーの秘密情報が出ない | Supabase logsのキー名/Pass-Failのみ |

No-Go:
- 外部AIへ画像又は画像URLを送る導線が見えるのに、送信先、送信情報、web search利用、学習利用、保持、削除可否、任意性が説明されていない。
- base64画像、OpenAI API key、service role key、ユーザー画像URL、解析結果全文がログや公開証跡に残る。
- 顔写真や第三者の権利物を外部AIへ送れるのに、第三者画像禁止、権利確認責任、Sensitive Info回答が未整理。

## 7. Secret / Key監査

| 対象 | 置き場所 | 確認 |
|---|---|---|
| Supabase publishable key | iOS/Web clientに露出可。ただしRLS前提 | TODO |
| Supabase secret/service role key | server/Edge Function/安全なローカルenvだけ。`web/.env.local.example` はplaceholderのみ | client bundle、公開ページ、App Review証跡、ログ、README実値に出ていない。確認証跡はキー名だけ |
| APNs private key | Supabase secret又は安全なsecret managerだけ | TODO |
| OAuth client secret | Supabase Auth/Dashboard secretだけ | TODO |
| Stripe webhook secret | server/secret managerだけ。初回で見せないなら露出なし | TODO |
| Map API key | 公開可能keyでもドメイン制限/用途制限を確認 | TODO |
| External AI API key | Edge Function secretだけ。初回で見せないなら未使用確認 | `OPENAI_API_KEY` がiOS/Web client bundle、公開ページ、ログ、README実値に出ていない |
| Vercel / deploy env | Vercel Project env又は安全なsecret managerだけ | `.vercel/.env.production.local` 等を証跡化しない。キー名、環境、最終確認日時だけを残す |
| Apple / signing secrets | Key IDやTeam IDは必要最小限、private keyやcertificate private keyは非公開 | `.p8`, `.p12`, private key, recovery codeをリポジトリ/Drive証跡に置かない |
| AdMob app id / ad unit id | secretではないが広告SDK設定・審査対象 | test ads除去、production unit id、App Privacy、ATT、Google公式開示、広告通報導線と照合 |

ローテーション判断:
- secret実値をリポジトリ、スクショ、チャット、公開URL、サポート返信に出した疑いがある場合は即ローテーション。
- TestFlight外部配布後にsecret漏えい疑いがある場合は、Build差し替えと事故初動を同時に判断する。

## 8. ローカル静的確認コマンド案

コードは変更せず、読み取りだけで実行する。

```bash
rg -n "enable row level security|create policy|using \\(true\\)" supabase/migrations
rg -n "storage\\.buckets|storage\\.objects|bucket_id|publicStorageObjectURL|createSignedURL" supabase ios-native web mobile --glob '!**/node_modules/**' --glob '!web/.next/**'
rg -n "SERVICE_ROLE|SUPABASE_SECRET|PRIVATE_KEY|SECRET|OPENAI|STRIPE|MAPTILER|APNS|DISPATCH_SECRET" supabase web ios-native mobile --glob '!**/node_modules/**' --glob '!web/.next/**' --glob '!.env*' --glob '!web/.env.local' --glob '!.vercel/**'
plutil -p ios-native/App/Info.plist
plutil -p ios-native/App/PrivacyInfo.xcprivacy
```

実値が出る可能性のあるコマンドは、出力を公開証跡に貼らない。証跡には「キー名だけ」「Pass/Fail」「確認日時」「誰がどの管理画面で確認したか」を残す。
`.env.local`、`.vercel/.env.production.local`、`web/.env.local`、`supabase secrets list --show-values` 相当の出力、Apple/Stripe/Google等のsecret表示画面は保存しない。

## 9. 提出直前の証跡フォーマット

| 項目 | 値 |
|---|---|
| 監査日時 | TODO |
| 監査者 | TODO |
| 対象Supabase Project | TODO |
| 対象App Version / Build | TODO |
| 対象Git commit | TODO |
| RLS結果 | Pass / Conditional / Fail |
| Storage結果 | Pass / Conditional / Fail |
| Secret結果 | Pass / Conditional / Fail |
| APNs結果 | Pass / Conditional / Fail |
| Auth/OAuth結果 | Pass / Conditional / Fail |
| 公開URL結果 | Pass / Conditional / Fail |
| 未確認 | TODO |
| Go / No-Go反映 | TODO |

## 10. App Review / Privacyとの接続

| 接続先 | 反映内容 |
|---|---|
| `notes/27_app_privacy_data_inventory.md` | 実際に保存/送信するデータ種別 |
| `notes/43_app_privacy_connect_answer_sheet.md` | App Privacy回答の最終照合 |
| `notes/44_privacy_manifest_sdk_audit.md` | SDK、権限、通信先、Privacy Manifest確認 |
| `notes/45_account_deletion_privacy_request_runbook.md` | 削除時のDB/Storage/token/外部サービス処理 |
| `notes/48_external_service_vendor_register.md` | 外部サービス、委託先、API key、DPA確認 |
| `notes/49_privacy_security_incident_response_runbook.md` | 漏えい疑い時の初動判断 |
| `notes/50_release_go_no_go_decision_matrix.md` | セキュリティGateの最終判定 |
| `notes/53_app_review_guideline_compliance_matrix.md` | Guideline 1.6 Data Security、5.1 Privacyの証跡 |
| `notes/61_release_access_owner_registry.md` | 担当者、権限、secret管理場所の棚卸し |
| `notes/75_apple_developer_signing_capabilities_preflight.md` | Bundle ID、Capabilities、APNs、Sign in with Apple、署名の照合 |

## 11. 参照

- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Storage Access Control: https://supabase.com/docs/guides/storage/security/access-control
- Supabase Edge Function Environment Variables: https://supabase.com/docs/guides/functions/secrets
- Supabase Securing Edge Functions: https://supabase.com/docs/guides/functions/auth
- Apple Setting up a remote notification server: https://developer.apple.com/documentation/usernotifications/setting-up-a-remote-notification-server
- Apple Establishing a token-based connection to APNs: https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns
