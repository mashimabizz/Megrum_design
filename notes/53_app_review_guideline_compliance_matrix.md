# 53. App Review Guideline 適合マトリクス

最終更新: 2026-05-31

ステータス: Draft v0.1（提出前・実機確認前）

## 目的

Megrumの初回App Store提出前に、Apple App Review Guidelinesの主要論点を、Megrumの機能、証跡、No-Go、Review Notes説明へ紐づける。

この文書は審査適合チェック表であり、コード、DB、App Store Connect設定、公開ページは変更しない。

## 1. 使い方

1. 完成候補ビルドで `notes/42` のP0スモークテストを実施する。
2. App Privacy、公開URL、IAP、AI、削除、UGCの証跡を `notes/36` に残す。
3. この文書の各Guideline行について、Pass / Conditional Go / No-Goを記録する。
4. No-Goが残る場合は提出しない。
5. Conditional Goの場合は、該当機能を完全に隠し、App Store説明文、スクショ、Review Notesからも外す。

## 2. 最重要Guideline対応表

| Guideline | Apple側の主な観点 | Megrumで見るもの | 必要証跡 | No-Go |
|---|---|---|---|---|
| Before You Submit | クラッシュ、正確なメタデータ、連絡先、デモアカウント、backend稼働、Review Notes | P0スモークテスト、デモアカウント、公開URL、Review Notes | `notes/35`, `notes/36`, `notes/40`, `notes/42` | デモログイン不可、backend停止、説明不足 |
| 1.2 User-Generated Content | 不適切投稿のフィルタ、通報、対応、ブロック、公開連絡先 | プロフィール、グッズ画像、グルーム、掲示板、取引チャット、証跡、評価 | 通報入口、ブロック入口、問い合わせURL、運用SOP | UGCが見えるのに通報/ブロック/連絡先がない |
| 1.4 Physical Harm | 身体的危険を招く機能や誘導を避ける | 現地交換、待ち合わせ、現在地共有、服装写真、危険誘導対応 | 安全注意、通報、取引チャット内対応、Review Notes | 危険な合流を助長し、止める導線がない |
| 1.5 Developer Information | アプリとSupport URLに連絡手段がある | `support@megrum.jp`, `/support`, アプリ内問い合わせ | URL 200応答、メール送受信、サポートテンプレ | Support URL不通、連絡先不明 |
| 1.6 Data Security | ユーザー情報の適切な保護、無断利用/開示/第三者アクセス防止 | Supabase、Storage、RLS、APNs token、外部サービス、事故対応 | `notes/48`, `notes/49`, `notes/52`, `notes/54` | 他人データ表示、公開bucket、secret露出疑い |
| 2.1 App Completeness | 最終版、URL完全稼働、placeholderなし、実機安定、デモアカウント | P0全機能、URL、スクショ、IAP可視性、未完成機能非露出 | `notes/36`, `notes/42`, `notes/50` | クラッシュ、空画面、仮文言、未完成3D露出 |
| 2.3 Accurate Metadata | 説明、スクショ、Privacy情報が実体験を正確に反映 | App Store説明文、スクショ、Keywords、Review Notes、App Privacy | `notes/31`, `notes/40`, `notes/43` | 出ない機能を宣伝、出る機能を説明しない |
| 2.3.2 IAP Metadata | IAPがある場合、説明・スクショ・Previewで追加購入が分かる | Premium、めぐりPlus、ブースト | `notes/33`, `notes/40` | 有料機能が見えるのに価格/商品/復元が不明 |
| 2.3.6 Age Rating | 年齢質問票を正直に回答 | UGC、チャット、位置情報、AI、IAP、権利物 | `notes/46` | UGC/チャットを過小回答 |
| 3.1.1 In-App Purchase | アプリ内機能解放はIAP、復元、消耗/非消耗の扱い | Premium、めぐりPlus、ブースト、Stripe露出有無 | IAP商品、Sandbox購入、復元、特商法 | 外部決済でアプリ内機能解放、IAP未設定 |
| 3.1.2 Subscriptions | 継続価値、期間、価格、解約、復元、重複防止 | サブスクを出す場合のPremium/めぐりPlus | `notes/33`, `notes/45` | 解約案内なし、価格/期間不一致 |
| 4.2 Minimum Functionality | 単なるWebラッパーでなく、十分なアプリ機能がある | Swift Nativeの在庫、wish、打診、取引、通知、地図/カメラ | 実機スクショ、P0テスト | 主要体験が空、Web表示だけ |
| 4.8 Login Services | 第三者ログインを使う場合、同等のプライバシー配慮ログインが必要 | Appleログイン、Googleログイン、メールログイン | 実装有無、Review Notes、削除時連携解除 | GoogleだけでAppleログインなし |
| 5.1.1 Privacy Policy | データ収集、利用、第三者、保持/削除、同意撤回/削除請求を明示 | Privacy URL、アプリ内Privacy導線、保持/削除表 | `notes/legal/02`, `notes/25`, `notes/52` | Privacy URLなし、保持/削除説明なし |
| 5.1.1 Permission | データ収集の同意、目的文字列、同意撤回、不要権限を求めない | カメラ、写真、位置情報、通知、AI、分析 | Info.plist文言、アプリ内説明、App Privacy | 位置情報/通知を必須化して主要機能を塞ぐ |
| 5.1.1 Data Minimization | コア機能に必要なデータだけ取得 | 住所/電話番号なし方針、写真picker、位置共有の任意性 | `notes/27`, `notes/43`, `notes/52` | 初回MVPで不要な住所/電話番号を求める |
| 5.1.1 Account Sign-In | 重要なアカウント機能がないならログインなし利用。作成ありならアプリ内削除 | Megrumは在庫、wish、取引、通報がアカウント依存 | `notes/35`, `notes/45`, Review Notes | 削除入口なし、ログイン必須の理由が説明不能 |
| 5.1.2 Data Use and Sharing | 目的外利用、無断共有、追跡、広告利用を避ける | 外部AI、分析、広告、Map API、サポートツール | `notes/27`, `notes/43`, `notes/48` | App Privacyで未申告の外部送信 |
| 5.2 Intellectual Property | 第三者権利物、商標、公式画像、誤認表示を避ける | スクショ、デモデータ、グッズ画像、Keywords | `notes/28`, `notes/46` | 公式画像や実在IPを権利確認なしに掲載 |
| 5.6 Developer Code of Conduct | Apple・ユーザーへの説明が正確、レビュー返信に個人情報や迷惑表現なし | Resolution Center返信、レビュー返信、サポート返信 | `notes/34`, `notes/41`, `notes/51` | 断定できない事実を断定、個人情報を返信に含める |

## 3. Megrum固有の審査説明メモ

### 3.1 ログイン必須の説明

Megrumは、在庫、wish、打診、取引チャット、通報、ブロック、評価、アカウント削除がユーザーIDに強く紐づくため、主要機能はアカウントベースである。

Review Notesでは次を説明する。
- 審査用デモアカウントを提供する。
- アカウントは、ユーザー間の取引安全、通報、ブロック、削除請求、取引履歴確認に必要。
- アカウント削除はアプリ内設定から開始できる。

### 3.2 UGCの説明

Review Notesでは次を短く説明する。
- UGC領域はプロフィール、グッズ画像、グルーム、掲示板、取引チャット、証跡、評価。
- 不適切コンテンツは通報できる。
- 迷惑ユーザーはブロックできる。
- `support@megrum.jp` と `/support` で連絡できる。
- 運営側で通報確認と非表示/制限対応を行う。

### 3.3 現地交換の安全説明

Review Notesでは次を必要に応じて説明する。
- Megrumはユーザー同士の現地交換を補助する。
- 現在地共有と服装写真は任意。
- 危険・個人情報露出・規約違反は通報できる。
- 運営者は取引当事者ではないが、安全対応と規約違反対応を行う。

### 3.4 有料機能の説明

初回で有料機能を隠す場合:
- App Store説明文、スクショ、Review Notesから有料機能の訴求を削る。
- IAP商品を同時提出しない。
- 画面にPremium/ブースト導線が出ない証跡を残す。

出す場合:
- IAP商品、価格、復元、権限付与、特商法、App Privacyを揃える。
- Review Notesに購入経路とSandbox確認方法を書く。

### 3.5 AI機能の説明

初回で外部AIを隠す場合:
- 外部AI送信ボタン、説明、スクショ、Review Notesから該当機能を外す。

出す場合:
- 送信情報、送信先、利用目的、保存期間、学習利用有無、ユーザー確認責任を明示する。
- AI出力をユーザーが確認・修正できる証跡を残す。
- App Privacyとプライバシーポリシーに反映する。

## 4. Guideline別提出前チェック

| ID | Guideline | 判定 | 証跡 | 担当 |
|---|---|---|---|---|
| AG-001 | Before You Submit | TODO | TODO | TODO |
| AG-002 | 1.2 UGC | TODO | TODO | TODO |
| AG-003 | 1.5 Developer Information | TODO | TODO | TODO |
| AG-004 | 1.6 Data Security | TODO | TODO | TODO |
| AG-005 | 2.1 App Completeness | TODO | TODO | TODO |
| AG-006 | 2.3 Metadata | TODO | TODO | TODO |
| AG-007 | 2.3.6 Age Rating | TODO | TODO | TODO |
| AG-008 | 3.1.1 IAP | TODO | TODO | TODO |
| AG-009 | 4.2 Minimum Functionality | TODO | TODO | TODO |
| AG-010 | 4.8 Login Services | TODO | TODO | TODO |
| AG-011 | 5.1.1 Privacy Policy | TODO | TODO | TODO |
| AG-012 | 5.1.1 Permission | TODO | TODO | TODO |
| AG-013 | 5.1.1 Account Sign-In / Deletion | TODO | TODO | TODO |
| AG-014 | 5.1.2 Data Use and Sharing | TODO | TODO | TODO |
| AG-015 | 5.2 Intellectual Property | TODO | TODO | TODO |
| AG-016 | 5.6 Conduct / Review Responses | TODO | TODO | TODO |

## 5. No-Go

- Appleの主要Guidelineに対して証跡がなく、Review Notesで説明もできない。
- UGCが見えるのに、通報、ブロック、公開連絡先がない。
- アカウント作成があるのにアプリ内削除入口がない。
- 有料機能が見えるのにIAP、価格、復元、特商法、App Privacyが揃っていない。
- 外部AIが見えるのに説明、同意、Privacy回答がない。
- App Store説明文、スクショ、Review Notesに実ビルドと違う機能がある。
- Privacy URL、Support URL、問い合わせ先が不通。
- 実在IP、公式画像、実住所、内部ID、デバッグ表示をスクショに含める。

## 6. 関連文書

- App Store提出パック: `notes/24_app_store_submission_pack.md`
- Trust & Safety SOP: `notes/26_trust_safety_release_sop.md`
- App Privacyデータインベントリ: `notes/27_app_privacy_data_inventory.md`
- スクショ台本: `notes/28_app_store_screenshot_storyboard.md`
- App Store Connect入力表: `notes/31_app_store_connect_metadata_worksheet.md`
- IAP商品設定: `notes/33_iap_product_setup_worksheet.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- App Review指摘対応テンプレート: `notes/41_app_review_response_templates.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- 提出前セキュリティ監査チェックリスト: `notes/54_prelaunch_security_audit_checklist.md`
- アカウント削除・個人情報請求: `notes/45_account_deletion_privacy_request_runbook.md`
- App Store質問票回答シート: `notes/46_app_store_questionnaire_answer_sheet.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- 提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`

## 7. 公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
