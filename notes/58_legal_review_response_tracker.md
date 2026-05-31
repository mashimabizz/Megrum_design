# 58. 法務レビュー回答反映台帳

最終更新: 2026-05-31

ステータス: Draft v0.1（弁護士回答待ち）

## 目的

弁護士レビュー後の回答、修正指示、未決論点を、利用規約、プライバシーポリシー、特商法、公開サポート、App Store提出文面へ漏れなく反映するための台帳。

この文書は反映管理表であり、コード、公開URL、App Store Connect設定、法務原典docxは変更しない。

## 1. 使い方

1. 弁護士へ `notes/29_legal_review_brief.md` の内容を送る。
2. 回答を受け取ったら、本台帳の「レビュー回答一覧」に1件ずつ転記する。
3. 影響文書を特定し、反映担当と期限を決める。
4. 反映後、対象文書、差分、公開URL、App Store Connect入力欄を確認する。
5. 未反映又は判断保留がある場合、Go / No-Go判定ではConditional Go以上にしない。

公開URLへ流し込む前の最終化手順は `notes/66_legal_review_publication_runbook.md` を使う。

## 2. 受領時に保存するもの

| 項目 | 保存方針 |
|---|---|
| 弁護士回答メール | 原文をオーナー管理の安全な場所に保存 |
| 添付ファイル | ファイル名、受領日時、版数を記録 |
| 口頭回答 | 日時、参加者、要点、次アクションをメモ化 |
| 修正済み文面 | 対象文書と差分を記録 |
| 未決論点 | 次回確認事項として残す |

秘密情報、個人情報、弁護士とのやり取りの全文は、公開リポジトリに貼らない。必要な判断要点だけを本台帳へ要約する。

## 3. レビュー回答一覧

| ID | 受領日 | 論点 | 弁護士回答要約 | 影響文書 | 判断 | ステータス | 担当 | 証跡 |
|---|---|---|---|---|---|---|---|---|
| LR-001 | TODO | 現地交換の安全/免責 | TODO | Terms, Support, FAQ, App Review Notes | TODO | 未反映 | TODO | TODO |
| LR-002 | TODO | 位置情報/服装写真の保存期間 | TODO | Privacy, Data Retention, App Privacy | TODO | 未反映 | TODO | TODO |
| LR-003 | TODO | 未成年利用/保護者同意 | TODO | Terms, Safety, FAQ, Age Rating | TODO | 未反映 | TODO | TODO |
| LR-004 | TODO | AI機能/外部AI送信/学習利用 | TODO | Terms, Privacy, AI page, App Privacy | TODO | 未反映 | TODO | TODO |
| LR-005 | TODO | UGC/通報/ブロック/モデレーション | TODO | Terms, Trust & Safety, Support, Guideline | TODO | 未反映 | TODO | TODO |
| LR-006 | TODO | 有料機能/IAP/返金/解約 | TODO | Terms, Commerce, IAP, Copy Sheet | TODO | 未反映 | TODO | TODO |
| LR-007 | TODO | 特商法の代表者情報非公表 | TODO | Commerce, Support Templates, Owner Ops | TODO | 未反映 | TODO | TODO |
| LR-008 | TODO | アカウント削除/保存期間 | TODO | Privacy, Account Deletion, Retention | TODO | 未反映 | TODO | TODO |
| LR-009 | TODO | 外国事業者/委託/第三者提供 | TODO | Privacy, Vendor Register, App Privacy | TODO | 未反映 | TODO | TODO |
| LR-010 | TODO | 古物営業法/チケット/権利物 | TODO | Terms, FAQ, Safety, Metadata | TODO | 未反映 | TODO | TODO |

## 4. 影響文書マップ

| 影響領域 | 反映先 |
|---|---|
| 利用規約 | `notes/legal/01_terms_of_service_draft.md` |
| プライバシーポリシー | `notes/legal/02_privacy_policy_draft.md` |
| 特商法 | `notes/25_public_legal_support_pages.md`, `notes/33_iap_product_setup_worksheet.md` |
| 公開サポート | `notes/25_public_legal_support_pages.md`, `notes/55_public_help_faq_draft.md` |
| アプリ内コピー | `notes/56_in_app_legal_safety_copy_deck.md` |
| App Store説明/Review Notes | `notes/24_app_store_submission_pack.md`, `notes/31_app_store_connect_metadata_worksheet.md`, `notes/40_app_store_connect_copy_paste_sheet.md` |
| App Privacy | `notes/27_app_privacy_data_inventory.md`, `notes/43_app_privacy_connect_answer_sheet.md` |
| Privacy Manifest/SDK | `notes/44_privacy_manifest_sdk_audit.md` |
| 外部サービス/委託先 | `notes/48_external_service_vendor_register.md` |
| データ保持/削除 | `notes/45_account_deletion_privacy_request_runbook.md`, `notes/52_data_retention_deletion_matrix.md` |
| Trust & Safety | `notes/26_trust_safety_release_sop.md`, `notes/34_support_response_templates.md` |
| Go / No-Go | `notes/50_release_go_no_go_decision_matrix.md` |

## 5. 反映ステータス定義

| ステータス | 意味 |
|---|---|
| 未反映 | 回答を受け取ったが文書に反映していない |
| 反映中 | 反映先文書を更新中 |
| 要再確認 | 弁護士又はオーナー判断が不足 |
| 反映済み | 対象文書へ反映し、関連文書との矛盾チェック済み |
| 不採用 | 理由を記録した上で反映しない |
| 後続対応 | 初回提出後又は機能公開時に対応 |

## 6. 反映時チェック

| チェック | 内容 |
|---|---|
| 用語 | 廃止用語を使っていない |
| 初回スコープ | 初回で見えない機能を断定していない |
| App Privacy | 収集データ、利用目的、第三者/委託が回答と一致 |
| 公開URL | サポート、Terms、Privacy、Commerce、FAQと矛盾しない |
| App Store文面 | 説明文、スクショ、Review Notes、質問票と一致 |
| 実装 | Swift Native実ビルドで見える画面と一致 |
| 証跡 | 受領日、要約、反映先、差分確認を残した |

## 7. No-Go

次の状態では、法務レビュー完了として扱わない。

- 弁護士回答の要点が台帳に残っていない。
- 回答を受け取ったが、Terms / Privacy / Support / App Store文面のどこへ反映するか決まっていない。
- 有料機能、外部AI、位置情報、UGC、アカウント削除、外国事業者のいずれかで、回答と公開文面が矛盾している。
- 代表者情報、特商法、保存期間、削除対象について、公開前判断が未確定。
- 公開ページ、App Privacy、Review Notesのどれかに古い前提が残っている。

## 8. 弁護士回答を反映した後の確認コマンド案

```bash
rg -n "TODO|要確認|未反映|●●|TBD" notes/legal notes/25_public_legal_support_pages.md notes/29_legal_review_brief.md notes/58_legal_review_response_tracker.md
```

```bash
rg -n "<旧用語・旧主体表現チェックの正規表現>" notes/legal notes/24_app_store_submission_pack.md notes/25_public_legal_support_pages.md notes/55_public_help_faq_draft.md notes/56_in_app_legal_safety_copy_deck.md
```

```bash
git diff --check -- notes
```

## 9. 関連文書

- 法務レビュー依頼メモ: `notes/29_legal_review_brief.md`
- 法務レビュー後公開文面最終化Runbook: `notes/66_legal_review_publication_runbook.md`
- 法的文書整合性管理: `notes/17_legal_alignment.md`
- 利用規約ドラフト: `notes/legal/01_terms_of_service_draft.md`
- プライバシーポリシードラフト: `notes/legal/02_privacy_policy_draft.md`
- 公開法務・サポートページ: `notes/25_public_legal_support_pages.md`
- App Store提出パック: `notes/24_app_store_submission_pack.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
