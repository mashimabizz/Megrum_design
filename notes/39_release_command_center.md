# 39. App Store初回提出コントロールボード

> 目的：App Store初回提出までに見る文書、判断、実行順、残ブロッカーを1枚にまとめる。
> コード変更なし。提出当日の迷子防止用。

最終更新: 2026-05-31
ステータス: Draft v0.1（提出前）

---

## 1. 現在の勝ち条件

今回の勝ち条件は、一般公開完了ではなく、App Store審査への初回提出完了。

法務・リリース準備docsは Draft PR `https://github.com/mashimabizz/Megrum_design/pull/2` で開発branchから分離して管理する。

提出してよい状態:
- 完成候補ビルドがApp Store Connectへアップロード済み。
- デモアカウントで主要機能を確認できる。
- App Store Connectのメタデータ、スクショ、Review Notes、App Privacy、URLが埋まっている。
- 利用規約、プライバシーポリシー、サポートURLが公開済み。
- UGCの通報/ブロック、アカウント削除、問い合わせ導線を説明できる。
- 未完成の有料機能、外部AI、3D機能が露出していない。出す場合は該当チェックを通過している。

---

## 2. 今日できるオーナー判断

| 判断 | 推奨 | 参照 |
|---|---|---|
| 有料機能を初回提出に含めるか | IAP未完なら隠す | `notes/33` |
| 外部AIを初回提出に含めるか | 未完成なら隠す | `notes/legal`, `notes/27` |
| 初回提出を現地交換スコープに固定する | 住所登録系導線が見えないことをP0確認 | `notes/26`, `notes/35` |
| グルーム/掲示板を出すか | 出すなら通報/ブロックをP0確認 | `notes/26` |
| 3Dめぐり演出を出すか | 初回は隠す | `notes/22_release_triage_tracker.csv` |
| App Storeカテゴリ | ライフスタイル又はソーシャルネットワーキング | `notes/31` |
| 弁護士レビューへ回すか | 公開前に回す | `notes/29` |
| 公開URLをどこで出すか | `megrum.jp` 直下で統一 | `notes/37` |

---

## 3. 文書マップ

| 用途 | 見るもの |
|---|---|
| 全体提出素材 | `notes/24_app_store_submission_pack.md` |
| 公開ページ原稿 | `notes/25_public_legal_support_pages.md` |
| 公開FAQ原稿 | `notes/55_public_help_faq_draft.md` |
| アプリ内法務・安全コピー | `notes/56_in_app_legal_safety_copy_deck.md` |
| 法務branch統合手順 | `notes/57_legal_release_branch_integration_plan.md` |
| ドメイン・メール・公開URL運用 | `notes/47_domain_email_publication_runbook.md` |
| Trust & Safety運用 | `notes/26_trust_safety_release_sop.md` |
| App Privacy / Privacy Manifest | `notes/27_app_privacy_data_inventory.md` |
| App Privacy回答 | `notes/43_app_privacy_connect_answer_sheet.md` |
| Privacy Manifest / SDK監査 | `notes/44_privacy_manifest_sdk_audit.md` |
| 提出前セキュリティ監査 | `notes/54_prelaunch_security_audit_checklist.md` |
| アカウント削除・個人情報請求 | `notes/45_account_deletion_privacy_request_runbook.md` |
| データ保持・削除 | `notes/52_data_retention_deletion_matrix.md` |
| App Store質問票 | `notes/46_app_store_questionnaire_answer_sheet.md` |
| 外部サービス/委託先 | `notes/48_external_service_vendor_register.md` |
| 個人情報・セキュリティ事故初動 | `notes/49_privacy_security_incident_response_runbook.md` |
| Go / No-Go判定 | `notes/50_release_go_no_go_decision_matrix.md` |
| 提出後・公開初日運用 | `notes/51_post_submission_release_day_runbook.md` |
| スクショ台本 | `notes/28_app_store_screenshot_storyboard.md` |
| 弁護士レビュー依頼 | `notes/29_legal_review_brief.md` |
| 法務レビュー回答反映 | `notes/58_legal_review_response_tracker.md` |
| 初回提出スコープ露出監査 | `notes/59_initial_release_scope_exposure_audit.md` |
| ローカライズ・メタデータQA | `notes/60_app_store_localization_metadata_qa.md` |
| リリース権限・運用アカウント | `notes/61_release_access_owner_registry.md` |
| App Review手動提出チェック | `notes/62_app_review_manual_submission_checklist.md` |
| 公開ページレダクションQA | `notes/63_public_page_redaction_qa.md` |
| リリース証跡フォルダ索引 | `notes/64_release_evidence_folder_index.md` |
| Release Candidateハンドオフ | `notes/65_release_candidate_handoff.md` |
| 法務レビュー後公開文面最終化 | `notes/66_legal_review_publication_runbook.md` |
| サポート受信トリアージ | `notes/67_support_inbox_triage_runbook.md` |
| 配信地域・EU DSA・IAP Availability | `notes/68_app_store_territory_dsa_iap_availability.md` |
| オーナー作業表 | `notes/30_owner_release_action_sheet.md` |
| App Store Connect入力 | `notes/31_app_store_connect_metadata_worksheet.md` |
| TestFlight / Submit手順 | `notes/32_testflight_review_submission_runbook.md` |
| App Review Guideline適合 | `notes/53_app_review_guideline_compliance_matrix.md` |
| P0スモークテスト台本 | `notes/42_p0_smoke_test_script.md` |
| IAP商品設定 | `notes/33_iap_product_setup_worksheet.md` |
| サポート返信 | `notes/34_support_response_templates.md` |
| デモアカウント | `notes/35_demo_account_review_data_plan.md` |
| 提出証跡 | `notes/36_submission_evidence_checklist.md` |
| 公開URL確認 | `notes/37_public_url_publication_checklist.md` |
| TestFlight協力者案内 | `notes/38_testflight_tester_comms.md` |
| App Store Connect転記 | `notes/40_app_store_connect_copy_paste_sheet.md` |
| App Review指摘対応 | `notes/41_app_review_response_templates.md` |
| P0/P1トラッカー | `notes/22_release_triage_tracker.csv` |

---

## 4. 実行順

### Phase A: ビルド前に今できる

1. 初回提出スコープを決める。
2. 弁護士レビューへ出す文面を確定する。
3. 公開URLの置き場を決める。
4. `support@megrum.jp` の受信を確認する。
5. デモアカウントのメール候補を確定する。
6. IAPを出すか隠すか決める。
7. 外部AIを出すか隠すか決める。
8. TestFlight協力者へ渡す案内を用意する。

### Phase B: 完成ビルドが来たら

1. TestFlight内部配布を行う。
2. デモアカウントでログインする。
3. `notes/42` に沿って2アカウントでAuth、在庫、wish、打診、ネゴ、取引チャットを確認する。
4. 通報、ブロック、アカウント削除入口を確認する。
5. 公開URLがアプリ内リンクから開くことを確認する。
6. App PrivacyとPrivacy Manifestを実ビルドで照合する。
7. スクショを撮影する。
8. App Store Connectへメタデータを入力する。
9. Review Notesへデモアカウントとレビュー経路を入れる。
10. `notes/40` の転記内容とApp Store Connect入力値を一致させる。
11. `notes/36` の証跡を埋める。
12. Add for Review、Submit for Reviewへ進む。

### Phase C: リジェクト時

1. Resolution Center本文を保存する。
2. 指摘Guidelineを分類する。
3. メタデータ修正で済むか、コード修正が必要か分ける。
4. `notes/41` で返信案を作る。
5. 修正後の証跡を追加する。
6. Review Notesへ変更点を書いて再提出する。

---

## 5. P0ブロッカー分類

### 5.1 実機確認が必要なP0

| 領域 | トラッカー |
|---|---|
| Auth | RL-001, RL-002 |
| 在庫 | RL-003, RL-004 |
| wish | RL-005, RL-022 |
| 個別条件 | RL-006 |
| ホーム/マッチ | RL-007 |
| 打診 | RL-008, RL-009, RL-010 |
| ネゴ/合意 | RL-011 |
| 取引チャット/証跡/評価 | RL-012 |
| 現地交換スコープ | RL-019, RL-020, RL-021 |
| UGC安全 | RL-030 |
| アカウント削除 | RL-031 |

### 5.2 運用・提出準備のP0

| 領域 | トラッカー | 主文書 |
|---|---|---|
| 法務/問い合わせ | RL-013 | `notes/legal`, `notes/25`, `notes/34` |
| App Storeメタデータ | RL-014 | `notes/24`, `notes/31` |
| TestFlight内部配布 | RL-015 | `notes/32` |
| 3D非露出 | RL-017 | `notes/22_release_triage_tracker.csv` |
| 初回提出定義 | RL-027 | `notes/32`, `notes/39` |
| AI開示 | RL-028 | `notes/legal`, `notes/27` |
| App Privacy照合 | RL-029 | `notes/27` |
| 外部サービス/委託先 | RL-046 | `notes/48` |
| アカウント削除/個人情報請求 | RL-031, RL-043 | `notes/45` |
| データ保持・削除 | RL-050 | `notes/52` |
| IAP判断 | RL-032 | `notes/33` |
| App Store質問票 | RL-044 | `notes/46` |
| デモアカウント | RL-034 | `notes/35` |
| 公開URL/メール | RL-036, RL-045 | `notes/37`, `notes/47` |
| 個人情報・セキュリティ事故初動 | RL-047 | `notes/49` |
| Go / No-Go判定 | RL-048 | `notes/50` |
| 提出後・公開初日運用 | RL-049 | `notes/51` |
| App Review Guideline適合 | RL-051 | `notes/53` |
| 提出前セキュリティ監査 | RL-052 | `notes/54` |
| 公開ヘルプFAQ | RL-053 | `notes/55` |
| アプリ内法務・安全コピー | RL-054 | `notes/56` |
| 法務branch統合手順 | RL-055 | `notes/57` |
| 法務レビュー回答反映 | RL-056 | `notes/58` |
| 初回提出スコープ露出監査 | RL-057 | `notes/59` |
| ローカライズ・メタデータQA | RL-058 | `notes/60` |
| リリース権限・運用アカウント | RL-059 | `notes/61` |
| App Review手動提出チェック | RL-060 | `notes/62` |
| 公開ページレダクションQA | RL-061 | `notes/63` |
| リリース証跡フォルダ索引 | RL-062 | `notes/64` |
| Release Candidateハンドオフ | RL-063 | `notes/65` |
| 法務レビュー後公開文面最終化 | RL-064 | `notes/66` |
| サポート受信トリアージ | RL-065 | `notes/67` |
| 配信地域・EU DSA・IAP Availability | RL-066 | `notes/68` |

---

## 6. 提出直前No-Go

提出を止める条件:
- デモアカウントでログインできない。
- Support URL又はPrivacy Policy URLが404。
- App Privacyと実装が矛盾している。
- RLS、Storage公開範囲、secret、APNs通知の監査でNo-Goが残っている。
- アカウント削除入口がない。
- UGCがあるのに通報/ブロック/問い合わせ導線がない。
- 有料機能が見えているのにIAPが未設定。
- 外部AIが見えているのに説明/同意/Privacy回答がない。
- 個人情報・セキュリティ事故疑いがあるのに初動記録と法務確認がない。
- 住所登録又は住所表示の未完成導線が見える。
- 未完成3Dが見える。
- スクショに実住所、実在IP、内部ID、デバッグ表示がある。

---

## 7. コード非変更で完了済みの準備

| 完了した準備 | 文書 |
|---|---|
| 利用規約ドラフト | `notes/legal/01_terms_of_service_draft.md` |
| プライバシーポリシードラフト | `notes/legal/02_privacy_policy_draft.md` |
| 公開ヘルプFAQ下書き | `notes/55_public_help_faq_draft.md` |
| アプリ内法務・安全コピー集 | `notes/56_in_app_legal_safety_copy_deck.md` |
| 法務branch統合手順 | `notes/57_legal_release_branch_integration_plan.md` |
| 法務レビュー依頼メモ | `notes/29_legal_review_brief.md` |
| 法務レビュー回答反映台帳 | `notes/58_legal_review_response_tracker.md` |
| 初回提出スコープ露出監査表 | `notes/59_initial_release_scope_exposure_audit.md` |
| App Storeローカライズ・メタデータQA | `notes/60_app_store_localization_metadata_qa.md` |
| リリース権限・運用アカウント台帳 | `notes/61_release_access_owner_registry.md` |
| App Review手動提出チェックリスト | `notes/62_app_review_manual_submission_checklist.md` |
| 公開ページレダクションQA | `notes/63_public_page_redaction_qa.md` |
| リリース証跡フォルダ索引 | `notes/64_release_evidence_folder_index.md` |
| Release Candidateハンドオフチェックリスト | `notes/65_release_candidate_handoff.md` |
| 法務レビュー後公開文面最終化Runbook | `notes/66_legal_review_publication_runbook.md` |
| サポート受信トリアージRunbook | `notes/67_support_inbox_triage_runbook.md` |
| App Store配信地域・EU DSA・IAP Availability | `notes/68_app_store_territory_dsa_iap_availability.md` |
| App Store提出素材 | `notes/24_app_store_submission_pack.md` |
| App Store Connect入力表 | `notes/31_app_store_connect_metadata_worksheet.md` |
| TestFlight / Submit手順 | `notes/32_testflight_review_submission_runbook.md` |
| IAP商品表 | `notes/33_iap_product_setup_worksheet.md` |
| サポート返信テンプレート | `notes/34_support_response_templates.md` |
| デモアカウント計画 | `notes/35_demo_account_review_data_plan.md` |
| 提出証跡チェックリスト | `notes/36_submission_evidence_checklist.md` |
| 公開URLチェックリスト | `notes/37_public_url_publication_checklist.md` |
| TestFlight協力者案内 | `notes/38_testflight_tester_comms.md` |
| App Store Connect転記用シート | `notes/40_app_store_connect_copy_paste_sheet.md` |
| App Review指摘対応テンプレート | `notes/41_app_review_response_templates.md` |
| P0スモークテスト台本 | `notes/42_p0_smoke_test_script.md` |
| App Review Guideline適合マトリクス | `notes/53_app_review_guideline_compliance_matrix.md` |
| 提出前セキュリティ監査チェックリスト | `notes/54_prelaunch_security_audit_checklist.md` |
| App Privacy回答シート | `notes/43_app_privacy_connect_answer_sheet.md` |
| Privacy Manifest/SDK監査台帳 | `notes/44_privacy_manifest_sdk_audit.md` |
| アカウント削除・個人情報請求ランブック | `notes/45_account_deletion_privacy_request_runbook.md` |
| データ保持・削除マトリクス | `notes/52_data_retention_deletion_matrix.md` |
| App Store質問票回答シート | `notes/46_app_store_questionnaire_answer_sheet.md` |
| ドメイン・メール・公開URL運用ランブック | `notes/47_domain_email_publication_runbook.md` |
| 外部サービス・委託先データ台帳 | `notes/48_external_service_vendor_register.md` |
| 個人情報・セキュリティ事故初動ランブック | `notes/49_privacy_security_incident_response_runbook.md` |
| App Store初回提出 Go / No-Go 判定表 | `notes/50_release_go_no_go_decision_matrix.md` |
| App Store提出後・公開初日ランブック | `notes/51_post_submission_release_day_runbook.md` |

---

## 8. まだ実作業が必要

| 作業 | 実行タイミング |
|---|---|
| 弁護士レビュー依頼 | 公開前 |
| `support@megrum.jp` 受信確認 | 公開前 |
| 法務/サポートURL公開 | 提出前 |
| デモアカウント作成 | 完成ビルド前後 |
| 完成ビルドアップロード | 実装セッション完了後 |
| TestFlight内部配布 | Build Processing後 |
| 2アカウントスモークテスト | TestFlight配布後。`notes/42` を使う |
| App Privacy最終回答 | 実ビルド確認後 |
| スクショ撮影 | 完成ビルドで |
| Submit for Review | 全P0確認後 |
| App Review指摘対応 | 指摘受領後 |
| 承認後の手動公開・公開初日監視 | 承認後 |

---

## 9. 最短ルート

最短で初回提出へ進めるなら:
1. 初回は有料機能、外部AI、未完成3Dを隠す。
2. 住所登録系の未完成導線が見えていないか必ず確認する。
3. 公開URLとサポートメールを先に通す。
4. デモアカウントを作り、主要データを入れる。
5. 完成ビルドでP0だけ実機確認する。
6. スクショ、App Privacy、Review Notesを実ビルドに合わせて最終化する。
7. `notes/40` からApp Store Connectへ転記する。
8. `notes/50` でGo / No-Goを判定する。
9. 証跡を残して提出する。
10. 承認後は `notes/51` に沿って手動公開と公開初日監視を行う。
