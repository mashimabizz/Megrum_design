# 54. 提出前セキュリティ監査チェックリスト

最終更新: 2026-05-31

ステータス: Draft v0.1（コード変更なし・提出前監査用）

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
| Swift Native | Supabase URL/key、Storage URL、APNs device token、Apple/Google認証、位置情報、カメラ/写真を扱う | publishable keyのみ、Privacy/App Privacyと一致することを確認 |
| 外部サービス | Supabase、Apple、Google、地図、IAP、Stripe候補、外部AI候補がある | 初回提出で見えるサービスだけを公開文面とApp Privacyへ反映 |
| 事故対応 | `notes/49` に初動ランブックがある | 担当者、連絡先、証跡保存先は未確定 |

## 3. 監査Gate

| Gate | 項目 | 完了条件 | 証跡 | No-Go |
|---|---|---|---|---|
| SEC-001 | RLS有効化 | API到達テーブルにRLSがあり、認証不要/認証済み/管理者の意図が説明できる | SQL一覧、Dashboardスクショ、policyレビュー記録 | user_idや取引情報を持つtableがRLSなし |
| SEC-002 | RLS policyの範囲 | `using (true)` の公開範囲がマスター/公開プロフィール等に限定されている | 広いpolicyの棚卸し | 個人情報、取引、通知、通報、削除対象で広いselectがある |
| SEC-003 | Storage bucket公開範囲 | public/privateの意図が各bucketで説明できる | bucket設定、policy一覧 | 取引チャット、証跡、通報画像が公開bucket又は広すぎるselect |
| SEC-004 | Storage所有者制御 | upload/update/deleteが本人又は参加者に制限されている | `storage.objects` policy確認 | 他人の画像を上書き/削除/一覧できる |
| SEC-005 | 署名URL | private mediaは短い有効期限で生成し、不要な永続公開URLを使わない | 実装箇所、実機通信確認 | private mediaをpublic URLで返している |
| SEC-006 | service role / secret key | secret keyはserver/Edge Function/Dashboardのsecretに限定されている | env一覧、bundle確認、ログ確認 | iOS app、web client、公開ページ、スクショ、READMEにsecret実値がある |
| SEC-007 | Edge Function認証 | APNs dispatch Functionはservice role又はdispatch secretで保護されている | Function設定、README、呼び出し元SQL/cron確認 | 認証なしで任意通知を送れる |
| SEC-008 | APNs credential | Team ID、Key ID、private key、Bundle ID、production/development環境が一致する | Apple Developer、Supabase secrets、送信テスト | production buildでdevelopment credential、又はprivate key漏えい |
| SEC-009 | 通知payload | 通知本文に不要な個人情報、正確な場所、内部IDを含めない | payloadサンプル、実機通知スクショ | ロック画面に機微な取引内容や内部IDが出る |
| SEC-010 | Auth/OAuth | Apple/Google redirect URL、削除時連携解除、secret管理が確認済み | Auth設定、削除テスト記録 | Sign in with Appleの削除連携が未説明、OAuth secret漏えい |
| SEC-011 | 公開URL/サポート | Legal/Support URLがHTTPSで公開され、秘密情報が混入していない | `notes/37` 証跡 | URLが404、又は公開ページに内部ID/secret/debug情報がある |
| SEC-012 | 管理者権限 | admin role、audit log、運用者アクセスが最小限である | admin一覧、audit log確認 | 一般ユーザーがadmin対象の情報を読める |
| SEC-013 | 外部サービス | 初回提出で見える外部サービスが `notes/48` とApp Privacyに反映されている | 台帳、App Privacy回答 | 外部AI、決済、地図APIが見えるのに未記載 |
| SEC-014 | ログ/証跡 | サーバーログ、Functionログ、サポート証跡にsecretや実在ユーザー情報を残さない | ログサンプル確認 | token、private key、実パスワード、削除請求本文を不用意に保存 |
| SEC-015 | データ削除 | アカウント削除時にDB/Storage/通知token/外部サービスの扱いを説明できる | `notes/45`, `notes/52` | 削除請求後も不要なdevice tokenや画像が残る |
| SEC-016 | Incident readiness | 漏えい疑い時の担当、受付番号、証跡保存、本人通知/PPC報告判断が準備済み | `notes/49` | 事故疑いがあるのに提出判断を進める |

## 4. Supabase RLS監査

### 4.1 机上確認

| 確認 | 方法 | 判定 |
|---|---|---|
| API到達table一覧 | Supabase Dashboard又はSQLで `public` schemaのtableを一覧化 | TODO |
| RLSなしtable | `relrowsecurity=false` のtableを抽出 | TODO |
| 広いselect policy | `using (true)` や匿名read policyを棚卸し | TODO |
| owner/participant制御 | user_id、owner_user_id、proposal参加者、trade参加者で絞れているか確認 | TODO |
| 通報/通知/削除対象 | reports、notifications、devices、deletion-related dataが本人/管理者限定か確認 | TODO |

### 4.2 SQL確認案

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
| `goods-photos` | 在庫写真。公開カードで見える範囲のみpublic可 | TODO |
| `avatars` | プロフィール画像。公開プロフィールに使う範囲のみpublic可 | TODO |
| `chat-photos` | 取引チャット/証跡。参加者限定が原則 | TODO |
| `meguri-message-media` | 初回で見せる場合は参加者限定 | TODO |
| `meguri-board-media` | 初回で見せる場合は認証済み範囲の妥当性確認 | TODO |
| `groom-posts` | 初回で見せる場合はUGC安全確認と合わせる | TODO |

No-Go:
- 参加者限定であるべき画像がpublic bucketにある。
- bucket一覧やpath規則から他人の画像を推測できる。
- 削除済みアカウントの画像が不要に残る。
- signed URLの有効期限が長すぎ、再共有リスクを説明できない。

## 6. Edge Function / APNs監査

| 確認 | 完了条件 | 証跡 |
|---|---|---|
| secrets登録 | `SUPABASE_SERVICE_ROLE_KEY`, `MEGRUM_APNS_TEAM_ID`, `MEGRUM_APNS_KEY_ID`, `MEGRUM_APNS_PRIVATE_KEY`, `MEGRUM_APNS_BUNDLE_ID`, `MEGRUM_APNS_ENVIRONMENT`, `MEGRUM_APNS_DISPATCH_SECRET` が本番Projectに設定済み | Supabase secrets listのキー名だけ |
| dispatch認証 | Function呼び出し元がservice role又はdispatch secretを使う | README、設定、呼び出し元確認 |
| APNs環境 | TestFlight/本番でproduction APNs、Debugでdevelopment APNsを使う | 送信ログ、端末受信 |
| payload | title/bodyに不要な個人情報や内部IDが入らない | payloadサンプル |
| token失効 | APNsエラー時にdevice token無効化/再登録ができる | テスト記録 |
| logs | Function logsにtoken、private key、通知本文の全文が出ない | ログサンプル |

## 7. Secret / Key監査

| 対象 | 置き場所 | 確認 |
|---|---|---|
| Supabase publishable key | iOS/Web clientに露出可。ただしRLS前提 | TODO |
| Supabase secret/service role key | server/Edge Functionだけ | TODO |
| APNs private key | Supabase secret又は安全なsecret managerだけ | TODO |
| OAuth client secret | Supabase Auth/Dashboard secretだけ | TODO |
| Stripe webhook secret | server/secret managerだけ。初回で見せないなら露出なし | TODO |
| Map API key | 公開可能keyでもドメイン制限/用途制限を確認 | TODO |
| External AI API key | server/secret managerだけ。初回で見せないなら未使用確認 | TODO |

ローテーション判断:
- secret実値をリポジトリ、スクショ、チャット、公開URL、サポート返信に出した疑いがある場合は即ローテーション。
- TestFlight外部配布後にsecret漏えい疑いがある場合は、Build差し替えと事故初動を同時に判断する。

## 8. ローカル静的確認コマンド案

コードは変更せず、読み取りだけで実行する。

```bash
rg -n "enable row level security|create policy|using \\(true\\)" supabase/migrations
rg -n "storage\\.buckets|storage\\.objects|bucket_id|publicStorageObjectURL|createSignedURL" supabase ios-native web mobile --glob '!**/node_modules/**' --glob '!web/.next/**'
rg -n "SERVICE_ROLE|SUPABASE_SECRET|PRIVATE_KEY|SECRET|OPENAI|STRIPE|MAPTILER|APNS|DISPATCH_SECRET" supabase web ios-native mobile --glob '!**/node_modules/**' --glob '!web/.next/**'
plutil -p ios-native/App/Info.plist
plutil -p ios-native/App/PrivacyInfo.xcprivacy
```

実値が出る可能性のあるコマンドは、出力を公開証跡に貼らない。証跡には「キー名だけ」「Pass/Fail」「確認日時」を残す。

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
