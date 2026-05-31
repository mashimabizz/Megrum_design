# 66. 法務レビュー後公開文面最終化Runbook

最終更新: 2026-05-31

ステータス: Draft v0.1（弁護士回答受領後に使用）

## 目的

弁護士レビュー回答を受け取った後、利用規約、プライバシーポリシー、特商法表示、公開サポート、FAQ、App Store説明文、Review Notes、App Privacy回答へ反映漏れが起きないように、最終化手順を整理する。

この文書は公開文面の反映手順であり、コード、公開URL、App Store Connect設定、法務原典docx、実アカウント情報は変更しない。

## 1. 使うタイミング

使うタイミング:
- 弁護士から、規約、Privacy、特商法、サポート文面、AI、UGC、IAP、削除、現地交換安全に関する回答を受け取った。
- 回答要点を `notes/58_legal_review_response_tracker.md` へ記録する準備ができている。
- App Store提出前に、公開URLへ流し込む最終文面を確定したい。

使わないタイミング:
- 弁護士回答の原文を安全な場所に保存していない。
- 回答の要点、判断、反映先が未整理。
- 初回提出で出す/隠す機能が未確定。
- 開発側Release CandidateのVersion、Build、commit SHAが不明。

## 2. 反映の原則

- 弁護士回答の全文は公開リポジトリに貼らない。要点、判断、反映先、未決論点だけを記録する。
- 法務原典docxは保管し、公開前ドラフトは現行仕様と初回提出スコープに合わせて更新する。
- 回答を1か所だけに反映して終わりにしない。Terms、Privacy、Support、FAQ、App Store文面、Review Notes、App Privacyの横断確認を行う。
- 初回で隠す機能は、公開ページとApp Store文面でも利用可能な機能として断定しない。
- 特商法の代表者情報非公表、価格、返金、解約、個人情報請求、外部AI、UGCの扱いは、弁護士回答とApp Store提出文面を必ず照合する。
- 実パスワード、secret、実ユーザー情報、実代表者情報、個人住所、個人電話番号はこのRunbookに書かない。

## 3. 反映フロー

| Step | 作業 | 完了条件 | 参照 |
|---|---|---|---|
| LR-PUB-001 | 弁護士回答を安全な場所に保存 | 原文保存先と受領日時だけを記録 | `notes/58` |
| LR-PUB-002 | 回答要点を台帳へ転記 | LR-ID、論点、要約、影響文書、判断が埋まる | `notes/58` |
| LR-PUB-003 | 初回提出への影響を分類 | Must before submit / Can defer / Not applicable | 本文書 |
| LR-PUB-004 | 公開文面を更新 | Terms、Privacy、Support、FAQ、Commerce候補が更新済み | `notes/legal`, `notes/25`, `notes/55` |
| LR-PUB-005 | App Store文面を更新 | Description、Review Notes、質問票、App Privacyが一致 | `notes/40`, `notes/46`, `notes/43` |
| LR-PUB-006 | アプリ内コピー影響を整理 | 実装側へ渡す文言変更があるか分類 | `notes/56`, `notes/65` |
| LR-PUB-007 | レダクションQA | secret、実データ、未確定機能、未確定価格がない | `notes/63` |
| LR-PUB-008 | URL公開前QA | ログイン不要、HTTPS、200応答、最終更新日 | `notes/37` |
| LR-PUB-009 | Go / No-Goへ反映 | G5、G6、G7、G8、G9、G13、G14が更新済み | `notes/50` |
| LR-PUB-010 | 証跡を保存 | manifestへ反映日、commit、対象URLを記録 | `notes/64` |

## 4. 論点別反映マップ

| 論点 | 反映先 | App Store影響 | No-Go |
|---|---|---|---|
| 現地交換安全/免責 | Terms, Support, FAQ, Review Notes | Safety説明、サポート導線 | 事故時の責任分界や緊急時案内がない |
| 位置情報/服装写真 | Privacy, Data Retention, App Privacy, Review Notes | Location / Photos / user content回答 | 保存期間や共有範囲が矛盾 |
| 未成年利用 | Terms, FAQ, Age Rating, Safety | Age Rating、Review Notes | 保護者同意や安全注意が未整理 |
| UGC/通報/ブロック | Terms, Trust & Safety, Support, FAQ | Guideline 1.2説明 | UGCが見えるのに通報/ブロックが説明不能 |
| アカウント削除 | Terms, Privacy, Support, FAQ | Guideline 5.1.1(v)説明 | アカウント作成があるのに削除導線が説明不能 |
| AI/外部AI | Terms, Privacy, AI page, App Privacy, Review Notes | 送信情報、同意、Privacy回答 | 外部AIが見えるのに説明/同意/回答なし |
| 有料機能/IAP | Terms, Commerce, IAP, FAQ, Metadata | IAP同時提出、価格、解約 | 有料導線が見えるのにIAP/特商法が未整備 |
| 代表者情報非公表 | Commerce, Support templates, Owner Ops | 有料機能を出す場合の公開表示 | 請求時の開示フローがない |
| 個人情報請求 | Privacy, Support, Data Retention | Privacy URL、Support URL | 窓口、本人確認、対応範囲が不明 |
| 外部サービス/委託 | Privacy, Vendor Register, App Privacy | SDK/外部送信回答 | 外部サービス台帳とPrivacyが不一致 |
| 禁止物/権利侵害 | Terms, FAQ, Safety, Metadata | IP/Content Rights説明 | 公式提供や権利侵害を誘発する表現 |

## 5. 公開文面更新チェック

| 文書 | 更新観点 | 結果 |
|---|---|---|
| `notes/legal/01_terms_of_service_draft.md` | 免責、禁止事項、UGC、AI、IAP、削除、安全 | TODO |
| `notes/legal/02_privacy_policy_draft.md` | 取得情報、利用目的、外部サービス、AI、保持/削除、請求窓口 | TODO |
| `notes/25_public_legal_support_pages.md` | Support、削除、通報、AI、特商法候補 | TODO |
| `notes/55_public_help_faq_draft.md` | 初回で出す機能だけ説明。隠す機能は削る | TODO |
| `notes/56_in_app_legal_safety_copy_deck.md` | 実装へ渡す同意/安全/権限文言 | TODO |
| `notes/40_app_store_connect_copy_paste_sheet.md` | App Store説明、Review Notes、Known exclusions | TODO |
| `notes/43_app_privacy_connect_answer_sheet.md` | App Privacy回答 | TODO |
| `notes/46_app_store_questionnaire_answer_sheet.md` | Age Rating、Content Rights、Export Compliance | TODO |

No-Go:
- 弁護士回答で修正が必要になった文言が、App Store説明又はReview Notesに古いまま残っている。
- Privacyで説明した取得情報とApp Privacy回答が一致しない。
- 特商法表示の価格、解約、返金、提供時期がIAP設定と一致しない。

## 6. 公開URL反映前の最終確認

公開URLへ流し込む直前に確認する。

| Check | 確認 | 結果 |
|---|---|---|
| PUB-001 | `notes/58` のMust before submitが全て反映済み | TODO |
| PUB-002 | 未反映又は要再確認の論点が初回提出に影響しない | TODO |
| PUB-003 | 初回で隠す有料機能、外部AI、未完成3D、住所/電話番号入力を断定説明していない | TODO |
| PUB-004 | 代表者情報非公表の請求対応フローがある | TODO |
| PUB-005 | 特商法表示を公開する場合、価格とApp Store設定が一致 | TODO |
| PUB-006 | Privacy Policy URLの内容がApp Privacy回答と一致 | TODO |
| PUB-007 | Support URLから削除、通報、Privacy請求へ辿れる | TODO |
| PUB-008 | 公開ページレダクションQAがPass | TODO |
| PUB-009 | App Store Connectへ転記する文面が最終版 | TODO |
| PUB-010 | 証跡保存先とmanifestが決まっている | TODO |

## 7. 反映後の確認コマンド

```bash
rg -n "TODO|TBD|未反映|要再確認|●●|予定価格" notes/legal notes/25_public_legal_support_pages.md notes/55_public_help_faq_draft.md notes/40_app_store_connect_copy_paste_sheet.md notes/43_app_privacy_connect_answer_sheet.md
```

```bash
rg -n "password|passwd|secret|token|private key|api[_-]?key|SUPABASE|service_role|anon key|debug|stack trace|localhost|127\\.0\\.0\\.1" notes/legal notes/25_public_legal_support_pages.md notes/55_public_help_faq_draft.md
```

```bash
git diff --check -- notes
```

注意:
- Draft段階のTODOは管理上残せるが、公開HTML、App Store Connect転記文、Review Notes最終版には残さない。
- 実パスワード、secret、実ユーザー情報、実代表者情報を検索で見つけた場合は、公開作業を止める。

## 8. 反映完了記録テンプレート

```text
Legal review publication finalization

Review response received:
Owner:
Source saved at:
Tracker IDs:
Must before submit resolved:
Deferred items:

Updated docs:
- Terms:
- Privacy:
- Support:
- FAQ:
- Commerce:
- App Store copy:
- App Privacy:

Public URL status:
- Support:
- Privacy:
- Terms:
- Commerce:
- Account deletion:
- Report:
- FAQ:

No-Go remaining:
Evidence folder:
Decision: Ready for publication / Conditional / Stop
```

## 9. 公的・公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- 消費者庁 特定商取引法ガイド 通信販売広告: https://www.no-trouble.caa.go.jp/what/mailorder/advertising.html
- 消費者庁 特定商取引法ガイド 通信販売広告Q&A: https://www.no-trouble.caa.go.jp/qa/advertising.html
- 個人情報保護委員会 法令・ガイドライン等: https://www.ppc.go.jp/personalinfo/legal/
- 個人情報保護委員会 ガイドラインQ&A: https://www.ppc.go.jp/personalinfo/faq/APPI_QA/

## 10. 関連文書

- 法務レビュー依頼メモ: `notes/29_legal_review_brief.md`
- 法務レビュー回答反映台帳: `notes/58_legal_review_response_tracker.md`
- 法的文書整合性管理: `notes/17_legal_alignment.md`
- 公開法務・サポートページ: `notes/25_public_legal_support_pages.md`
- 公開ヘルプFAQ: `notes/55_public_help_faq_draft.md`
- 公開ページレダクションQA: `notes/63_public_page_redaction_qa.md`
- 公開URL公開チェックリスト: `notes/37_public_url_publication_checklist.md`
- App Store Connect転記: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Privacy回答: `notes/43_app_privacy_connect_answer_sheet.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
