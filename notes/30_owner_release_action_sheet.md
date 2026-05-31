# 30. オーナー向けリリース準備アクションシート

最終更新: 2026-05-31

ステータス: Draft（コード変更なしで今すぐ進めること）

## 目的

開発セッションを止めずに、オーナー側で今すぐ準備できるものを一覧化する。

この文書は作業メモであり、コード、DB、ビルド設定は変更しない。

## 1. 今日できること

| 優先 | 作業 | 完了条件 | 関連メモ |
|---|---|---|---|
| P0 | `support@megrum.jp` の受信確認 | 実際にメールを送って受信できる | App StoreサポートURL、法務窓口、`notes/34` |
| P0 | `megrum.jp` の公開URL枠を決める | `/support` `/legal/terms` `/legal/privacy` `/legal/commerce` をどこで公開するか決定 | `notes/25`, `notes/37` |
| P0 | 弁護士レビューに回すか決める | 回す場合、`notes/29` の短文を使って依頼 | `notes/29_legal_review_brief.md` |
| P0 | 弁護士回答の反映台帳を使う | 回答後、要点と反映先を `notes/58` に記録する | `notes/58_legal_review_response_tracker.md` |
| P0 | App Store Connect のデモアカウント方針を決める | メール/パスワード、テストデータ、削除可否を決める | `notes/35_demo_account_review_data_plan.md` |
| P0 | 外部AIを初回提出に含めるか決める | 含める/含めないを決定 | 含めない方が審査・法務は軽い |
| P0 | 有料機能を初回提出に含めるか決める | Premium/めぐりPlus/ブーストの露出有無を決定 | 含めるなら `notes/33` のIAP表と特商法がP0 |
| P0 | 初回提出を現地交換スコープに固定する | App Store文面、規約、App Privacy、テスト台本から住所登録系の説明を外す | `notes/29` の重点論点 |
| P1 | 個人情報・セキュリティ事故時の初動担当を決める | Incident Lead、記録担当、サポート一次返信担当を決める | `notes/49` |
| P1 | App Store説明文を確認 | 違和感がある文言を修正指示できる | `notes/24` |
| P1 | スクショ用デモデータを決める | 架空グループ/グッズ/ユーザー名を採用 | `notes/28` |

## 2. オーナー判断が必要なP0

### 2.1 初回提出スコープ

次を「出す / 隠す / 後回し」で決める。

| 機能 | 推奨 |
|---|---|
| コア交換 | 出す |
| 現地外の交換手段 | 初回は隠す |
| グルーム | 出すなら通報/ブロック確認をP0 |
| スポット掲示板 | 未完成なら隠す |
| 外部AI | 初回は隠す又はオンデバイス限定推奨 |
| Premium / めぐりPlus / ブースト | `notes/33` のIAP設定が固まるまで隠す選択もあり |
| 3Dめぐり演出 | 未完成なら隠す |

### 2.2 代表者情報の扱い

現方針は「非公表、請求があれば遅滞なく開示」。

ただし、特商法上の最終可否は `notes/29_legal_review_brief.md` の質問として弁護士確認対象にする。

### 2.3 App Storeカテゴリ

現在の候補:

- ライフスタイル
- ソーシャルネットワーキング

Swift Nativeの `Info.plist` では `public.app-category.social-networking` が読める。App Store Connect側も合わせるか、ライフスタイルへ寄せるかを提出前に決める。

## 3. Apple提出前に入力するもの

| 項目 | 下書き所在 | オーナー確認 |
|---|---|---|
| アプリ名 | `notes/24` | MegrumでOKか |
| サブタイトル | `notes/24` | 30文字以内でOKか |
| プロモーションテキスト | `notes/24` | 現地交換スコープと一致しているか |
| 説明文 | `notes/24` | 機能範囲と一致しているか |
| キーワード | `notes/24` | 実在IPに寄りすぎていないか |
| 質問票 | `notes/46` | Age Rating、Content Rights、Export Compliance |
| サポートURL | `notes/25` | 公開先を決める |
| FAQ URL | `notes/55` | Supportトップから辿れるようにする |
| プライバシーポリシーURL | `notes/legal` / `notes/25` | 公開先を決める |
| 審査メモ | `notes/24` | デモアカウントを入れる |
| App Privacy | `notes/27` | 実ビルドと最終照合 |
| 外部サービス | `notes/48` | Supabase、Apple、Google、地図、決済、AI候補 |
| 提出前セキュリティ監査 | `notes/54` | RLS、Storage、secret、APNs、管理者権限のNo-Go確認 |
| 個人情報・セキュリティ事故初動 | `notes/49` | 受付番号、初動担当、本人通知/PPC報告判断 |
| スクショ | `notes/28` | 完成ビルドで撮影 |
| 商品ページ素材QA | `notes/70` | App icon、スクショ、App Preview、poster frame、Product Page Previewを確認 |
| IAP商品 | `notes/33` | 初回提出で有料機能を出す場合だけ |
| サポート返信 | `notes/34` | 通報、削除、購入、AI、特商法請求 |
| 削除/個人情報請求 | `notes/45` | アプリ内削除、保持対象、Sign in with Apple連携 |
| データ保持・削除 | `notes/52` | 保存期間、削除、匿名化、例外保持 |
| デモアカウント | `notes/35` | 実パスワードはリポジトリに書かない |
| 提出証跡 | `notes/36` | Build、URL、App Privacy、スクショ、Notesの控え |
| 公開URL | `notes/37` | ログイン不要、HTTPS、200応答 |
| ドメイン/メール | `notes/47` | DNS、HTTPS、support@受信確認 |
| TestFlight案内 | `notes/38` | 協力者向け注意事項とフォーム項目 |
| 提出司令塔 | `notes/39` | 実行順とP0ブロッカー |
| Go / No-Go判定 | `notes/50` | 提出直前の最終判定 |
| 提出後・公開初日運用 | `notes/51` | 手動公開、公開初日監視、指摘対応 |
| Guideline適合 | `notes/53` | Apple審査Guideline別の証跡確認 |
| アプリ内法務・安全コピー | `notes/56` | 同意、権限説明、安全注意、AI/IAP文言を実装前に確認 |
| 法務branch統合手順 | `notes/57` | 開発branchと混ぜずにPR化/mergeする |
| 法務レビュー回答反映 | `notes/58` | 回答、判断、反映先、未決論点を管理 |
| 初回提出スコープ露出監査 | `notes/59` | 出す/隠す機能が画面・文面・FAQ・App Privacyで一致しているか確認 |
| ローカライズ・メタデータQA | `notes/60` | 日本語、English (U.S.)候補、Review Notes、スクショ説明の整合を確認 |
| リリース権限・運用アカウント | `notes/61` | App Store Connect、DNS、メール、Supabase、法務の担当と権限を棚卸し |
| App Review手動提出チェック | `notes/62` | Add for Review、Draft Submission、Submit for Review直前の画面確認に使う |
| 公開ページレダクションQA | `notes/63` | 公開前に内部情報、secret、未確定機能、未確定価格、実データが混ざっていないか確認する |
| リリース証跡フォルダ索引 | `notes/64` | スクショ、URL控え、Review Notes、App Privacy回答をどこにどう保存するか決める |
| Release Candidateハンドオフ | `notes/65` | 開発セッションからVersion、Build、commit SHA、検証結果、出す/隠す機能を受け取る |
| 法務レビュー後公開文面最終化 | `notes/66` | 弁護士回答をTerms、Privacy、Support、FAQ、App Store文面、App Privacyへ反映する |
| サポート受信トリアージ | `notes/67` | App Review連絡、通報、削除、個人情報請求、事故疑いの分類と担当を決める |
| 配信地域・EU DSA・IAP Availability | `notes/68` | 初回配信地域、EU DSA trader status、IAP提供地域を決める |
| App Review指摘トリアージ | `notes/69` | リジェクト/追加情報要求時の返信、再提出、取り下げ、appeal判断を決める |
| App Store商品ページ素材QA | `notes/70` | App icon、スクショ、App Preview、poster frame、Product Page Previewを提出前に確認する |

## 4. デモアカウント準備

決めるもの:

- メールアドレス
- パスワード
- 表示名
- 登録済み推し
- 在庫データ
- wishデータ
- 打診済みデータ
- 合意済み取引データ
- 通報/ブロック確認用の相手アカウント

避けるもの:

- 実在メールアドレスの個人利用
- 実住所
- 実在アーティスト/作品の公式画像
- 本番ユーザーの取引履歴
- 未完成機能の露出

## 5. 弁護士へ送る時の添付セット

最小セット:

- `notes/legal/01_terms_of_service_draft.md`
- `notes/legal/02_privacy_policy_draft.md`
- `notes/25_public_legal_support_pages.md`
- `notes/37_public_url_publication_checklist.md`
- `notes/38_testflight_tester_comms.md`
- `notes/39_release_command_center.md`
- `notes/29_legal_review_brief.md`

追加で渡すとよいもの:

- `notes/26_trust_safety_release_sop.md`
- `notes/27_app_privacy_data_inventory.md`
- `notes/17_legal_alignment.md`

依頼文は `notes/29_legal_review_brief.md` の「弁護士へ渡す短文」を使う。

## 6. 提出直前の判断ライン

提出してよい:

- 登録、ログイン、在庫、wish、打診、合意、取引完了が実機で通る
- 規約、プライバシー、問い合わせURLが公開済み
- App Privacyと実装が矛盾しない
- 通報/ブロック/削除が説明できる
- 未完成の外部AI、有料機能、3Dが露出していない

提出を止める:

- アカウント作成できるのにアプリ内削除がない
- UGCがあるのに通報/ブロック/連絡先が説明できない
- 外部AIへ個人情報を送るのに説明/同意がない
- 住所登録又は住所表示の未完成導線が見えている
- 有料機能が見えているのにIAP/特商法/価格が未確定、又は `notes/33` のNo-Goに該当する
- サポートURL又はプライバシーポリシーURLが404

## 7. Codexへ投げると速い依頼文

### App Store入力前

```
notes/24, 25, 27, 28を見て、App Store Connectに入力する最終文面を1枚にまとめて。
コードは触らないで。
```

### 弁護士レビュー後

```
弁護士回答を反映して、notes/legal と notes/25 の公開文面だけ修正して。
コードは触らないで。
```

### 完成ビルド後

```
完成ビルドの機能範囲に合わせて、App Privacy回答とスクショ台本を最終化して。
コードは触らないで。
```

### リジェクト後

```
Appleのリジェクト文を貼るので、ガイドライン番号ごとに対応方針を分解して。
まず文書/メタデータで直せるか、コード修正が必要かを分けて。
```

## 8. 関連ドキュメント

- `notes/24_app_store_submission_pack.md`
- `notes/25_public_legal_support_pages.md`
- `notes/26_trust_safety_release_sop.md`
- `notes/27_app_privacy_data_inventory.md`
- `notes/28_app_store_screenshot_storyboard.md`
- `notes/29_legal_review_brief.md`
- `notes/22_release_triage_tracker.csv`
- `notes/49_privacy_security_incident_response_runbook.md`
- `notes/50_release_go_no_go_decision_matrix.md`
- `notes/51_post_submission_release_day_runbook.md`
- `notes/52_data_retention_deletion_matrix.md`
- `notes/53_app_review_guideline_compliance_matrix.md`
- `notes/54_prelaunch_security_audit_checklist.md`
- `notes/55_public_help_faq_draft.md`
- `notes/56_in_app_legal_safety_copy_deck.md`
- `notes/57_legal_release_branch_integration_plan.md`
- `notes/58_legal_review_response_tracker.md`
- `notes/59_initial_release_scope_exposure_audit.md`
- `notes/60_app_store_localization_metadata_qa.md`
- `notes/61_release_access_owner_registry.md`
- `notes/62_app_review_manual_submission_checklist.md`
- `notes/63_public_page_redaction_qa.md`
- `notes/64_release_evidence_folder_index.md`
- `notes/65_release_candidate_handoff.md`
- `notes/66_legal_review_publication_runbook.md`
- `notes/67_support_inbox_triage_runbook.md`
- `notes/68_app_store_territory_dsa_iap_availability.md`
- `notes/69_app_review_rejection_triage_runbook.md`
- `notes/70_app_store_product_page_asset_qa.md`
