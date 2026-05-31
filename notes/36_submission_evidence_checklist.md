# 36. App Store提出証跡チェックリスト

> 目的：TestFlight内部確認からApp Review提出までに、あとで見返せる証跡を揃える。
> コード変更なし。提出当日に「確認したはず」を減らすための記録台帳。

最終更新: 2026-05-31
ステータス: Draft v0.1（提出前）

---

## 1. 証跡保管方針

| 項目 | 方針 |
|---|---|
| 保存先 | `notes/release_evidence/` 又はオーナー管理のDrive |
| 実パスワード | 証跡に含めない |
| 個人情報 | 実在ユーザーの情報を含めない |
| スクショ | 必要箇所だけ。住所、メール、内部IDは隠す |
| 命名 | `YYYY-MM-DD_appstore_vX.Y_buildN_項目` |

この文書はチェックリストであり、証跡ファイル自体はまだ作成しない。
証跡フォルダの構成、命名、manifest、保存してよい情報/保存しない情報は `notes/64_release_evidence_folder_index.md` を使う。

---

## 2. 提出メタ情報

| 項目 | 値 |
|---|---|
| 提出日 | TODO |
| App Version | TODO |
| Build Number | TODO |
| Bundle ID | TODO |
| Xcode / Transporter / EASなどのアップロード方法 | TODO |
| App Store Connect提出者 | TODO |
| 初回提出の範囲 | TODO |

---

## 3. 必須証跡

| ID | 領域 | 証跡 | 関連 |
|---|---|---|---|
| EV-001 | Build | App Store Connectで提出ビルドがProcessing完了 | `notes/32` |
| EV-002 | Auth | デモアカウントでログインできる | `notes/35` |
| EV-003 | Legal URL | Terms、Privacy、Support、Commerceが開く | `notes/25` |
| EV-004 | App Privacy | App Store Connect回答の控え | `notes/27` |
| EV-005 | Privacy Manifest | 実ビルドのPrivacyInfo.xcprivacy確認 | `notes/27` |
| EV-006 | Account Deletion | アプリ内削除入口が見える | `notes/26` |
| EV-007 | UGC Safety | 通報、ブロック入口が見える | `notes/26` |
| EV-008 | Core Flow | 在庫、wish、打診、取引チャットが通る | `notes/32` |
| EV-009 | Screenshot | App Store用スクショ一式 | `notes/28` |
| EV-010 | Review Notes | App Review Notes最終本文 | `notes/31` |
| EV-011 | Copy Sheet | App Store Connectへ入力した最終文面 | `notes/40` |
| EV-012 | Security Audit | RLS、Storage、secret、APNs、公開URL、管理者権限の監査結果 | `notes/54` |

---

## 4. 条件付き証跡

| ID | 条件 | 証跡 | 関連 |
|---|---|---|---|
| EV-101 | 有料機能を出す | IAP商品、価格、購入復元、Sandbox購入 | `notes/33` |
| EV-102 | 外部AIを出す | 送信前説明、同意、送信情報、AI結果修正 | `notes/legal`, `notes/27` |
| EV-103 | 現地交換スコープ | 住所登録系導線が見えない、削除/問い合わせ導線がある | `notes/26`, `notes/35` |
| EV-104 | グルーム/掲示板を出す | 通報、ブロック、モデレーション確認 | `notes/26` |
| EV-105 | Push通知を出す | 通知許可文言、APNsトークン、通知受信 | `notes/27` |
| EV-106 | 個人情報・セキュリティ事故疑いがある | 受付番号、初動記録、法務確認、本人通知/PPC報告判断 | `notes/49` |

---

## 5. 内部スモークテスト記録フォーマット

| 項目 | 値 |
|---|---|
| 実施日時 | TODO |
| 実施者 | TODO |
| 端末 | TODO |
| iOS | TODO |
| App Version / Build | TODO |
| アカウント1 | TODO |
| アカウント2 | TODO |
| 結果 | Pass / Fail |
| 未確認 | TODO |

結果メモ:

```
SM-001 Auth:
SM-002 Inventory:
SM-003 Wish:
SM-004 Listing:
SM-005 Matching:
SM-006 Proposal:
SM-007 Negotiation:
SM-008 Trade:
SM-009 Legal:
SM-010 Scope:
SM-011 Safety:
SM-012 Account:
SM-013 Privacy:
SM-014 Scope:
```

---

## 6. App Review提出記録フォーマット

```
Submitted at:
Submitted by:
Version:
Build:
Submission status:
Included IAP:
Review Notes final:
Known exclusions:
  - Paid features:
  - External AI:
  - Non-local exchange flows:
  - Groom / board:
Evidence folder:
```

---

## 7. リジェクト時に残す証跡

| 項目 | 記録 |
|---|---|
| Resolution Centerの本文 | 全文を保存 |
| 指摘されたGuideline | 番号と本文要約 |
| 該当画面 | スクショ又は画面名 |
| Appleへの返信 | 送信前の下書きと送信後の本文 |
| 修正内容 | コード変更、文言変更、メタデータ変更を分ける |
| 対応判断 | 同じbuildで直す/new build/却下item削除/appeal候補を分ける |
| 再提出日時 | App Store Connectの状態と一緒に保存 |

---

## 8. 提出直前No-Go

次のどれかが未確認なら、提出を止める。

最終判定は `notes/50_release_go_no_go_decision_matrix.md` で行う。

- デモアカウントでログインできない。
- 利用規約、プライバシーポリシー、サポートURLが404。
- App Privacyと実ビルドのSDK/通信が矛盾している。
- RLS、Storage公開範囲、secret、APNs通知の監査でNo-Goが残っている。
- アカウント作成があるのにアプリ内削除入口がない。
- UGCがあるのに通報/ブロック/問い合わせ導線が説明できない。
- 有料機能が見えるのにIAP商品と価格が一致していない。
- 外部AIが見えるのに送信前説明とPrivacy回答がない。
- 住所登録又は住所表示の未完成導線が見える。
- スクショに実在IP、実住所、内部ID、デバッグ表示がある。

---

## 9. 関連文書

- リリーストリアージ: `notes/22_release_triage_tracker.csv`
- App Store提出パック: `notes/24_app_store_submission_pack.md`
- Trust & Safety SOP: `notes/26_trust_safety_release_sop.md`
- App Privacy照合: `notes/27_app_privacy_data_inventory.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- 提出前セキュリティ監査チェックリスト: `notes/54_prelaunch_security_audit_checklist.md`
- アカウント削除・個人情報請求ランブック: `notes/45_account_deletion_privacy_request_runbook.md`
- App Store質問票回答シート: `notes/46_app_store_questionnaire_answer_sheet.md`
- ドメイン・メール・公開URL運用ランブック: `notes/47_domain_email_publication_runbook.md`
- 外部サービス・委託先データ台帳: `notes/48_external_service_vendor_register.md`
- 個人情報・セキュリティ事故初動ランブック: `notes/49_privacy_security_incident_response_runbook.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- 提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- 公開URLチェックリスト: `notes/37_public_url_publication_checklist.md`
- TestFlight協力者向け案内: `notes/38_testflight_tester_comms.md`
- スクリーンショット台本: `notes/28_app_store_screenshot_storyboard.md`
- App Review Guideline適合マトリクス: `notes/53_app_review_guideline_compliance_matrix.md`
- App Store Connect入力表: `notes/31_app_store_connect_metadata_worksheet.md`
- TestFlight/App Review提出ランブック: `notes/32_testflight_review_submission_runbook.md`
- デモアカウント計画: `notes/35_demo_account_review_data_plan.md`
- 提出コントロールボード: `notes/39_release_command_center.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Review指摘対応テンプレート: `notes/41_app_review_response_templates.md`
- App Reviewリジェクト/追加情報要求Runbook: `notes/69_app_review_rejection_triage_runbook.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
