# 61. リリース権限・運用アカウント台帳

最終更新: 2026-05-31

ステータス: Draft v0.1（実値未記入・公開不可情報なし）

## 目的

App Store初回提出、TestFlight配布、公開URL運用、サポート対応、Supabase運用、事故初動に必要なアカウント、権限、担当者、連絡先、保管場所を整理する。

この文書は権限台帳の雛形であり、コード、App Store Connect設定、Apple Developer設定、DNS、メール、Supabase設定は変更しない。パスワード、secret、private key、復旧コード、実電話番号は書かない。

## 1. 記録してよいもの / 書かないもの

| 種別 | 書いてよい | 書かない |
|---|---|---|
| 担当者 | 役割名、担当者名又は管理者名 | 個人電話番号、私用メール、本人確認書類 |
| アカウント | サービス名、権限、保管場所の名前 | パスワード、2FAコード、復旧コード |
| Secret | secret名、管理場所、ローテーション担当 | secret実値、private key、service role key |
| 連絡先 | `support@megrum.jp` 等の公開連絡先 | 審査用個人連絡先の詳細 |
| 証跡 | 確認日時、Pass/Fail、スクショ保存場所 | 個人情報や秘密情報が写ったスクショ |

## 2. Apple Developer / App Store Connect

| 項目 | 必要な権限 | 担当 | 保管/確認場所 | 提出前確認 |
|---|---|---|---|---|
| Account Holder | 契約、税務、銀行、全体管理 | TODO | Apple Developer | TODO |
| Admin | ユーザー/権限、App管理 | TODO | App Store Connect Users and Access | TODO |
| App Manager | App情報、TestFlight、提出作業 | TODO | App Store Connect | TODO |
| Developer | 証明書、Identifiers、ビルド補助 | TODO | Apple Developer | TODO |
| Customer Support | ユーザー返信、レビュー返信候補 | TODO | App Store Connect | TODO |
| Finance / Sales | IAP売上、支払い、契約確認 | TODO | App Store Connect | 有料機能を出す場合 |
| Access to Certificates/Profiles | 証明書、Profiles、Identifiers | TODO | Apple Developer | TODO |
| Signing / Capabilities確認 | Bundle ID、App ID、Capabilities、profile/certificate照合 | TODO | `notes/75` | Archive/upload前 |
| App Review contact | 審査連絡先 | TODO | App Store Connect Review Information | TODO |

提出前No-Go:
- App Store Connectへログインできる担当が1人しかいない。
- Account Holderしか契約/税務/銀行を確認できず、当日連絡不能。
- App Manager権限がなく、ビルド選択、TestFlight、Submit for Reviewができない。
- 審査連絡先のメール/電話が古い。
- 実パスワードや2FA復旧コードがリポジトリに書かれている。

## 3. App Store提出作業の権限チェック

| 作業 | 必要な人/権限 | 事前確認 |
|---|---|---|
| App Information入力 | App Manager以上 | TODO |
| Privacy Policy URL入力 | App Manager以上 | TODO |
| App Privacy回答 | App Manager以上 | TODO |
| Age Rating / Content Rights / Export Compliance回答 | App Manager以上 | TODO |
| Bundle ID / Capabilities / 署名確認 | Developer + App Manager | `notes/75` |
| TestFlight内部配布 | App Manager / Admin / Account Holder等 | TODO |
| IAP商品作成 | Account Holder / Admin / App Manager等、契約状況も確認 | 有料機能を出す場合 |
| Add for Review / Submit for Review | App Manager以上 | TODO |
| Resolution Center返信 | App Manager / Admin等 | TODO |
| 手動公開 | App Manager以上 | TODO |

## 4. ドメイン / DNS / 公開URL

| 項目 | 担当 | 管理場所 | 提出前確認 |
|---|---|---|---|
| `megrum.jp` レジストラ | TODO | TODO | 更新期限、ログイン可否 |
| DNS管理 | TODO | TODO | A/AAAA/CNAME/CAA確認 |
| 公開ホスティング | TODO | TODO | deploy権限、rollback手順 |
| HTTPS証明書 | TODO | ホスト又はDNS管理 | 証明書エラーなし |
| `www` の扱い | TODO | DNS/hosting | redirect又は200方針 |
| 公開URL証跡 | TODO | `notes/36` 又はDrive | curl/スクショ保存 |

No-Go:
- ドメイン更新期限が近いのに更新担当が不明。
- Privacy Policy URL又はSupport URLを直せる人が提出日にいない。
- 公開ページのrollback手順がない。

## 5. メール / サポート

| 項目 | 担当 | 管理場所 | 提出前確認 |
|---|---|---|---|
| `support@megrum.jp` 受信 | TODO | TODO | 受信テストPass |
| `support@megrum.jp` 送信 | TODO | TODO | 返信テストPass |
| SPF/DKIM/DMARC | TODO | DNS/メール管理 | TODO |
| サポート一次返信 | TODO | `notes/34` | TODO |
| 通報/安全対応 | TODO | `notes/26` | TODO |
| 個人情報請求 | TODO | `notes/45` | TODO |
| 事故初動連絡 | TODO | `notes/49` | TODO |

No-Go:
- supportメールが受信できない。
- 返信が迷惑メール扱いになる。
- 個人情報/安全問い合わせの担当が不明。

## 6. Supabase / Backend / Storage

| 項目 | 担当 | 管理場所 | 提出前確認 |
|---|---|---|---|
| Supabase Owner/Admin | TODO | Supabase Dashboard | TODO |
| Production project | TODO | Supabase Dashboard | project idを証跡に記録 |
| Database access | TODO | Supabase Dashboard | RLS監査 |
| Storage buckets | TODO | Supabase Dashboard | public/private/policy監査 |
| Edge Functions | TODO | Supabase Dashboard/CLI | APNs Function確認 |
| Secrets | TODO | Supabase secrets | secret名だけ確認 |
| Backups | TODO | Supabase plan/settings | 復旧方針確認 |
| Logs | TODO | Supabase logs | 個人情報/secretを出さない |

No-Go:
- service role keyを持つ人/管理場所が不明。
- APNs秘密鍵やdispatch secretの管理場所が不明。
- productionとdevelopmentのSupabase projectが区別できない。

## 7. Apple Sign in / Google OAuth / APNs

| 項目 | 担当 | 管理場所 | 提出前確認 |
|---|---|---|---|
| Sign in with Apple | TODO | Apple Developer / Supabase Auth | Bundle ID / Services ID確認 |
| Google OAuth | TODO | Google Cloud Console / Supabase Auth | redirect URL確認 |
| APNs Key | TODO | Apple Developer / Supabase secrets | key id / team id / bundle id確認 |
| APNs environment | TODO | Supabase secrets | production/development確認 |
| Token revocation | TODO | `notes/45` | 削除時方針確認 |

No-Go:
- APNs production buildでdevelopment credentialを使う。
- OAuth redirect URLが古い。
- Sign in with Apple削除連携の方針が説明できない。

署名、Capabilities、provisioning profile、certificate、Bundle ID照合の詳細は `notes/75_apple_developer_signing_capabilities_preflight.md` を使う。

## 8. IAP / 課金

有料機能を初回で隠す場合も、誰がIAPを作成できるかだけ確認する。

| 項目 | 担当 | 管理場所 | 提出前確認 |
|---|---|---|---|
| Paid Apps契約 | TODO | App Store Connect Agreements | 有料機能を出す場合 |
| 税務/銀行 | TODO | App Store Connect | 有料機能を出す場合 |
| IAP商品作成 | TODO | App Store Connect | 有料機能を出す場合 |
| Sandbox tester | TODO | App Store Connect | 有料機能を出す場合 |
| 返金案内 | TODO | `notes/34` | TODO |

No-Go:
- 有料導線が見えるのに、IAP商品作成/契約確認できる担当がいない。
- App Store価格と公開ページ/FAQの価格が一致しない。

## 9. 法務 / Privacy / 外部サービス

| 項目 | 担当 | 管理場所 | 提出前確認 |
|---|---|---|---|
| 弁護士連絡先 | TODO | オーナー管理 | 回答保存場所 |
| 規約原典docx | TODO | `利用規約など/` | 最新版確認 |
| 法務レビュー回答 | TODO | `notes/58` | 未反映なし |
| 外部サービス契約/DPA | TODO | 各サービス | `notes/48` と照合 |
| 個人情報請求対応 | TODO | `notes/45` | 担当/本人確認方針 |
| 事故初動 | TODO | `notes/49` | Incident Lead確定 |

No-Go:
- 弁護士回答を受けたが反映台帳に残していない。
- Privacy PolicyとApp Privacy回答が外部サービス台帳と矛盾している。

## 10. アクセス棚卸しフォーマット

提出前に1回、公開後に1回、次を埋める。

| 項目 | 値 |
|---|---|
| 棚卸し日 | TODO |
| 実施者 | TODO |
| App Store Connect提出者 | TODO |
| Apple Account Holder連絡可否 | TODO |
| Domain/DNS担当 | TODO |
| Support担当 | TODO |
| Supabase担当 | TODO |
| Incident Lead | TODO |
| 2FA/復旧手段の安全な保管 | Pass / Conditional / Fail |
| secret実値がリポジトリにない | Pass / Conditional / Fail |
| No-Go残件 | TODO |

## 11. 関連文書

- TestFlight / App Review提出ランブック: `notes/32_testflight_review_submission_runbook.md`
- Apple Developer署名・Capabilities事前確認: `notes/75_apple_developer_signing_capabilities_preflight.md`
- ドメイン・メール・公開URL運用: `notes/47_domain_email_publication_runbook.md`
- 提出前セキュリティ監査: `notes/54_prelaunch_security_audit_checklist.md`
- 個人情報・セキュリティ事故初動: `notes/49_privacy_security_incident_response_runbook.md`
- IAP商品設定: `notes/33_iap_product_setup_worksheet.md`
- 法務レビュー回答反映: `notes/58_legal_review_response_tracker.md`

## 12. 公式参照

- Apple App Store Connect role permissions: https://developer.apple.com/help/app-store-connect/reference/role-permissions/
- Apple Add and edit users: https://developer.apple.com/help/app-store-connect/manage-your-team/add-and-edit-users/
- Apple Overview of app transfer: https://developer.apple.com/help/app-store-connect/transfer-an-app/overview-of-app-transfer/
