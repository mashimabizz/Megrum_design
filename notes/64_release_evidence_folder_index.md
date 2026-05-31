# 64. リリース証跡フォルダ索引

最終更新: 2026-05-31

ステータス: Draft v0.1（提出前・証跡保存ルール）

## 目的

App Store初回提出、審査中対応、承認後の手動公開、公開初日の確認で発生するスクリーンショット、App Store Connect入力控え、URL疎通結果、スモークテスト結果、Review Notes、App Privacy回答控えを、あとから追える形で保存する。

この文書は証跡保存の索引案であり、コード、ビルド、App Store Connect設定、公開URL、実証跡ファイルは変更しない。

## 1. 保存先方針

推奨保存先:
- オーナー管理のDrive又は安全な共有フォルダ
- 必要に応じて `notes/release_evidence/` に、秘密情報を含まないテキスト索引だけ置く

リポジトリに置いてよいもの:
- 証跡のファイル名一覧
- いつ、誰が、何を確認したかの要約
- 公開URL、App Version、Build Number、App Store Connect status
- secretや個人情報を含まないスクショ説明

リポジトリに置かないもの:
- デモアカウントの実パスワード
- 認証コード、2FA復旧コード
- API key、secret、private key、token
- App Store Connect、Apple Developer、DNS、Supabase、決済、外部サービスの管理画面に入れる情報
- 実ユーザー、実取引、実問い合わせ、実通報、実事故の個人情報
- 個人住所、個人電話番号、個人メールアドレス
- 公開前の実代表者情報、所在地、電話番号

## 2. フォルダ構成案

```text
release_evidence/
  2026-05-31_appstore_vX.Y_buildN/
    00_manifest.md
    01_build/
    02_testflight_smoke/
    03_public_urls/
    04_app_privacy/
    05_privacy_manifest_sdk/
    06_screenshots/
    07_review_notes_metadata/
    08_safety_account_deletion/
    09_security_audit/
    10_submission/
    11_review_response/
    12_release_day/
```

Drive等へ保存する場合も、同じ番号と名前にすると探しやすい。

## 3. 命名規則

基本形:

```text
YYYY-MM-DD_hhmm_appstore_vX.Y_buildN_area_short-description.ext
```

例:

```text
2026-05-31_1030_appstore_v1.0_build42_build_processing-complete.png
2026-05-31_1045_appstore_v1.0_build42_privacy_policy_200.txt
2026-05-31_1100_appstore_v1.0_build42_review_notes_final.md
2026-05-31_1130_appstore_v1.0_build42_submit_for_review_status.png
```

ルール:
- `vX.Y` と `buildN` は実際の提出候補へ置き換える。
- 画像は必要最小限にする。
- 実メール、実住所、内部ID、debug表示が写った画像は保存前に除外又はマスクする。
- 実パスワードやsecretが写った画像は保存しない。
- ファイル名に個人名、個人メール、実ユーザーIDを入れない。

## 4. `00_manifest.md` テンプレート

```markdown
# Megrum App Store Evidence

## Submission

| Item | Value |
|---|---|
| Evidence folder | 2026-05-31_appstore_vX.Y_buildN |
| App Version | TODO |
| Build Number | TODO |
| Bundle ID | TODO |
| Submitted at | TODO |
| Submitted by | TODO |
| App Store Connect status | TODO |
| Release option | Manual / Automatic / Date |

## Scope

| Item | Value |
|---|---|
| Paid features visible | No / Yes |
| External AI visible | No / Yes |
| Unfinished 3D visible | No / Yes |
| UGC visible | No / Yes |
| Account deletion visible | No / Yes |
| Public URLs verified | No / Yes |

## Evidence Files

| ID | Area | File | Summary | Contains sensitive info |
|---|---|---|---|---|
| EV-001 | Build | TODO | TODO | No |
| EV-002 | TestFlight | TODO | TODO | No |
| EV-003 | URLs | TODO | TODO | No |
| EV-004 | App Privacy | TODO | TODO | No |
| EV-005 | Review Notes | TODO | TODO | No |

## Redaction Check

- [ ] No demo account password
- [ ] No verification code
- [ ] No API key / secret / token
- [ ] No personal address / phone
- [ ] No real user data
- [ ] No internal ID or debug output
- [ ] No unfinished feature in screenshots
```

## 5. エリア別に保存する証跡

### 5.1 `01_build/`

| ID | 証跡 | 形式 |
|---|---|---|
| BLD-001 | App Store ConnectでBuild Processing完了 | png又はmd |
| BLD-002 | Version / Build Number / Bundle ID | md |
| BLD-003 | Compliance警告と回答結果 | md又はpng |
| BLD-004 | 開発セッションからの提出候補共有メモ | md |

### 5.2 `02_testflight_smoke/`

| ID | 証跡 | 形式 |
|---|---|---|
| SMK-001 | `notes/42` のP0スモークテスト結果 | md |
| SMK-002 | Auth、在庫、wish、打診、取引チャット確認 | md又は必要最小限のpng |
| SMK-003 | 通報、ブロック、アカウント削除入口 | png又はmd |
| SMK-004 | 未完成機能が見えていない確認 | md |

注意:
- 実ユーザーの画面は使わない。
- デモアカウントの実パスワードは書かない。

### 5.3 `03_public_urls/`

| ID | 証跡 | 形式 |
|---|---|---|
| URL-001 | Support URL 200応答 | txt又はmd |
| URL-002 | Privacy Policy URL 200応答 | txt又はmd |
| URL-003 | Terms URL 200応答 | txt又はmd |
| URL-004 | Account deletion / privacy request / report / FAQの公開確認 | txt又はmd |
| URL-005 | `notes/63` の公開ページレダクションQA結果 | md |

### 5.4 `04_app_privacy/`

| ID | 証跡 | 形式 |
|---|---|---|
| APV-001 | App Store Connect App Privacy回答控え | md又はpng |
| APV-002 | `notes/43` の最終回答との照合結果 | md |
| APV-003 | Privacy Policy URLと回答の一致確認 | md |
| APV-004 | 外部サービス台帳との照合 | md |

注意:
- App Store Connect画面に管理者個人情報が写る場合は、保存前に除外又はマスクする。

### 5.5 `05_privacy_manifest_sdk/`

| ID | 証跡 | 形式 |
|---|---|---|
| SDK-001 | PrivacyInfo.xcprivacy確認 | md |
| SDK-002 | Required Reason API確認 | md |
| SDK-003 | SDK一覧と外部サービス台帳の照合 | md |
| SDK-004 | Tracking有無の確認 | md |

### 5.6 `06_screenshots/`

| ID | 証跡 | 形式 |
|---|---|---|
| SCR-001 | App Store提出スクショ一式 | png |
| SCR-002 | スクショ台本との対応表 | md |
| SCR-003 | 実住所、実在IP、内部ID、debug表示なし確認 | md |
| SCR-004 | App icon、App Preview、poster frame、Product Page PreviewのQA結果 | md |
| SCR-005 | 初回で隠す機能が写っていない確認 | md |

### 5.7 `07_review_notes_metadata/`

| ID | 証跡 | 形式 |
|---|---|---|
| MET-001 | App Store Connect入力最終文面 | md |
| MET-002 | Review Notes最終版 | md |
| MET-003 | Keywords、Subtitle、Descriptionの文字数/byte確認 | md |
| MET-004 | English (U.S.)を入れる場合の日英整合QA | md |
| MET-005 | 商品ページ素材QAとメタデータ整合の確認 | md |
| MET-006 | App Store Connect実入力値と提出docs/buildの最終差分QA | md |

### 5.8 `08_safety_account_deletion/`

| ID | 証跡 | 形式 |
|---|---|---|
| SAF-001 | 通報入口 | png又はmd |
| SAF-002 | ブロック入口 | png又はmd |
| SAF-003 | アカウント削除入口 | png又はmd |
| SAF-004 | サポート/Privacy請求導線 | png又はmd |

### 5.9 `09_security_audit/`

| ID | 証跡 | 形式 |
|---|---|---|
| SEC-001 | RLS確認結果 | md |
| SEC-002 | Storage公開範囲確認 | md |
| SEC-003 | secret露出確認 | md |
| SEC-004 | APNs/通知送信権限確認 | md |
| SEC-005 | リリース権限台帳のP0確認 | md |

secret実値や管理画面の認証情報は保存しない。

### 5.10 `10_submission/`

| ID | 証跡 | 形式 |
|---|---|---|
| SUB-001 | Add for Review実施 | png又はmd |
| SUB-002 | Draft Submission確認 | png又はmd |
| SUB-003 | Submit for Review実施 | png又はmd |
| SUB-004 | Submission status | png又はmd |
| SUB-005 | 提出日時、提出者、Version/Build | md |
| SUB-006 | App Store Connect最終入力差分QA結果 | md |
| SUB-007 | Release option控え | md又はpng |

### 5.11 `11_review_response/`

| ID | 証跡 | 形式 |
|---|---|---|
| REV-001 | Resolution Center本文 | md |
| REV-002 | Guideline分類 | md |
| REV-003 | Appleへの返信下書き | md |
| REV-004 | 送信後の返信控え | md |
| REV-005 | 再提出時の変更点 | md |
| REV-006 | 同じbuild/new build/却下item削除/appeal判断 | md |

### 5.12 `12_release_day/`

| ID | 証跡 | 形式 |
|---|---|---|
| REL-001 | Pending Developer Release確認 | png又はmd |
| REL-002 | Release This Version実施 | png又はmd |
| REL-003 | App Store公開確認 | png又はmd |
| REL-004 | T+1h/T+3h/T+6h/T+12h/T+24h監視結果 | md |
| REL-005 | 初日問い合わせ/重大通報/障害の有無 | md |
| REL-006 | `notes/72` のPDR gateと公開直前読み合わせ | md |
| REL-007 | Release This Version実施者、時刻、直後status | md又はpng |

## 6. 証跡の扱いで迷う時

| 状況 | 判断 |
|---|---|
| secretやパスワードが写っている | 保存しない |
| 個人情報が写っている | 保存しない。必要ならマスク版だけ |
| デモアカウントのメールが写っている | 審査用の公開可否を確認。迷う場合はマスク |
| App Store Connectの管理者個人名が写っている | 原則マスク |
| 実ユーザーのデータが写っている | 保存しない |
| Review Notesに実パスワードが入っている | リポジトリには残さず、App Store Connectと安全な保管場所だけ |
| URL疎通結果に内部IPや認証情報が出た | 保存しない。公開URLだけ再取得 |

## 7. 提出直前チェック

- [ ] `00_manifest.md` を作成した
- [ ] Build、TestFlight、URL、App Privacy、Review Notesの最低証跡がある
- [ ] デモアカウントの実パスワードを保存していない
- [ ] secret、API key、tokenを保存していない
- [ ] 実ユーザー又は実取引の個人情報を保存していない
- [ ] スクショに内部ID、debug表示、未完成機能がない
- [ ] `notes/36_submission_evidence_checklist.md` のEV-001〜EV-013と対応している
- [ ] `notes/62_app_review_manual_submission_checklist.md` の提出直前チェックと対応している
- [ ] `notes/72_app_store_approval_release_control_runbook.md` のPDR gateと公開初日監視に対応している

## 8. 関連文書

- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- App Review手動提出チェック: `notes/62_app_review_manual_submission_checklist.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- 承認後・手動公開制御Runbook: `notes/72_app_store_approval_release_control_runbook.md`
- 公開ページレダクションQA: `notes/63_public_page_redaction_qa.md`
- TestFlight / App Review提出ランブック: `notes/32_testflight_review_submission_runbook.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- App Store提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- App Reviewリジェクト/追加情報要求Runbook: `notes/69_app_review_rejection_triage_runbook.md`
- 提出前セキュリティ監査: `notes/54_prelaunch_security_audit_checklist.md`
- リリース権限・運用アカウント: `notes/61_release_access_owner_registry.md`
