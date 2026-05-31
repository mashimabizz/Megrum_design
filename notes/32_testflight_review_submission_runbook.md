# 32. TestFlight / App Review 提出ランブック

最終更新: 2026-05-31

ステータス: Draft（完成ビルド後に使う手順）

## 目的

完成ビルドができた後、TestFlight配布、内部確認、App Store審査提出までを迷わず進めるための手順書。

この文書は運用手順であり、コード、ビルド設定、App Store Connect設定は変更しない。

## 1. 前提

- 初回リリースの勝ち条件は、App Store審査への初回提出完了。
- コード修正、ビルド作成、署名、アップロードは別セッションの開発作業。
- このランブックでは、完成ビルドがApp Store Connectにアップロードされた後の確認と提出準備を扱う。
- Apple公式情報では、ビルドはXcode、Swift Playground、altool、Transporter等でアップロードでき、App Store Connect側の処理完了後に選択できる。

## 2. 役割

| 役割 | 担当 |
|---|---|
| オーナー | App Store Connect入力、最終判断、審査提出 |
| 開発セッション | ビルド作成、署名、アップロード、P0修正 |
| Codex準備セッション | 文書、メタデータ、チェックリスト、審査対応整理 |
| テスター | TestFlightで実機確認 |
| 法務 | 規約、プライバシー、特商法、AI/UGC/現地交換レビュー |

## 3. ビルド受領時チェック

ビルドがアップロードされたら確認する。

| 項目 | 確認内容 |
|---|---|
| App | Megrumの正しいApp Recordか |
| Bundle ID | 提出対象のBundle IDか |
| Version | App Store ConnectのVersionと一致するか |
| Build Number | 前回より大きいか |
| Processing | App Store Connectで処理完了しているか |
| Internal Only | Internal Only buildではないか。App Store提出するなら注意 |
| Warnings | Privacy、Missing compliance、Icon、Export等の警告がないか |
| TestFlight | 内部グループへ追加できるか |

## 4. TestFlight内部配布

Apple公式上、内部テスターはApp Store Connectユーザーで最大100人、内部テスターはビルドを90日間テストできる。

初回提出前は、まず内部テスターでP0確認を行う。

手順:
1. App Store ConnectでMegrumを開く。
2. TestFlightタブを開く。
3. Internal Testingのグループを確認又は作成する。
4. 対象ビルドをグループへ追加する。
5. What to Testを入力する。
6. オーナー端末と最低1名の別端末でインストールする。
7. 下記スモークテストを行う。

### What to Test 下書き

```
Megrum release candidate.

Please test:
- Sign up / sign in / sign out
- Inventory registration and editing
- Wish registration and editing
- Proposal creation and receiving
- Negotiation and agreement
- Trade chat and completion
- Report / block / support links
- Account deletion entry point

Known focus:
- Confirm that no unfinished 3D, unfinished external AI, or incomplete paid feature appears in this build unless explicitly enabled for review.
- Confirm Terms, Privacy Policy, and Support links open correctly.
```

## 5. 内部スモークテスト

最低2アカウントで確認する。

| ID | 領域 | 手順 | 合格条件 | 対応トラッカー |
|---|---|---|---|---|
| SM-001 | Auth | 新規登録、メール確認、ログイン、ログアウト | 登録から復帰まで通る | RL-001, RL-002 |
| SM-002 | Inventory | 在庫追加、編集、削除 | 一覧と詳細に反映 | RL-003, RL-004 |
| SM-003 | Wish | wish追加、編集、削除 | マッチ条件に反映 | RL-005 |
| SM-004 | Listing | 個別条件作成、編集、削除 | 保存内容が崩れない | RL-006 |
| SM-005 | Matching | ホームを開く | 空白/クラッシュなし | RL-007 |
| SM-006 | Proposal | 相手プロフィールから打診 | 自分/相手の在庫取り違えなし | RL-008, RL-009 |
| SM-007 | Negotiation | 受信、拒否、承諾、反対提案、合意 | 状態遷移が通る | RL-010, RL-011 |
| SM-008 | Trade | 取引チャット、証跡、承認、評価 | 完了まで通る | RL-012 |
| SM-009 | Legal | 規約、プライバシー、問い合わせ | リンク切れなし | RL-013 |
| SM-010 | Scope | 現地交換スコープ、住所登録系導線なし | 初回提出の機能範囲と一致 | RL-019〜021 |
| SM-011 | Safety | 通報、ブロック | 入口と送信/反映を確認 | RL-030 |
| SM-012 | Account | アカウント削除入口 | アプリ内で開始できる | RL-031 |
| SM-013 | Privacy | App Privacy対象データ | 実装と回答が矛盾しない | RL-029 |
| SM-014 | Scope | 未完成機能露出 | 3D/外部AI/未完成有料が出ない | RL-017, RL-028 |

合格証跡:
- Build番号
- 端末名
- OSバージョン
- テストアカウント
- 成功/失敗
- スクリーンショット又は短いメモ

デモアカウントと審査用データは `notes/35_demo_account_review_data_plan.md`、P0実機確認の詳細台本は `notes/42_p0_smoke_test_script.md`、提出時に残す証跡は `notes/36_submission_evidence_checklist.md` を使う。TestFlight協力者へ渡す案内は `notes/38_testflight_tester_comms.md` を使う。

## 6. 外部TestFlight判断

Apple公式上、外部テスターは最大10,000人まで招待できるが、外部テストにはベータApp Reviewが必要になる場合がある。

3日で初回審査提出を狙う場合、外部TestFlightは必須ではない。内部確認でP0を潰して、そのままApp Review提出へ進む選択が速い。

外部TestFlightへ進む条件:
- 内部スモークテストが通っている
- 通報/ブロック/削除/法務URLが説明できる
- 外部テスターへ見せてよい完成度
- Beta Reviewに出してもよいメタデータがそろっている

## 7. App Store提出前チェック

| 項目 | 合格条件 | 関連文書 |
|---|---|---|
| App Information | Name、Subtitle、Category、Age Rating、Privacy URLが入力済み | `notes/31` |
| Version Metadata | Description、Keywords、Support URL、Copyright、Screenshotsが入力済み | `notes/31`, `notes/28` |
| App Privacy | 実SDK/通信/ポリシーと一致 | `notes/27` |
| Build | 正しいVersion/Buildを選択 | 本文書 |
| App Review Information | 連絡先、デモアカウント、Notesが入力済み | `notes/31` |
| Legal URLs | terms/privacy/commerce/supportが公開済み | `notes/25`, `notes/37` |
| UGC | 通報、ブロック、連絡先、モデレーション説明あり | `notes/26` |
| Account Deletion | アプリ内削除開始導線あり | `notes/26` |
| IAP | 有料機能が見える場合、IAPと特商法が一致 | `notes/25`, `notes/31` |
| AI | 外部AIが見える場合、説明/同意/Privacy回答あり | `notes/24`, `notes/27` |

## 8. Submit for Review 手順

Apple公式上、アプリバージョンへ必要メタデータを入力し、ビルドを選択してから、Add for Review、Submit for Reviewへ進む。

手順:
1. App Store ConnectでMegrumを開く。
2. 提出するApp Versionを開く。
3. Build欄で正しいビルドが選ばれていることを確認する。
4. メタデータ、スクショ、URL、App Review Information、App Privacyを確認する。
5. Add for Reviewを押す。
6. Draft Submissionを開く。
7. 追加でIAP等を同時提出する場合は同じSubmissionへ含める。
8. Submit for Reviewを押す。
9. ステータスがReady for Review又はIn Reviewへ進んだことを記録する。

記録するもの:
- 提出日時
- Version
- Build Number
- 証跡フォルダ又は証跡メモ
- App Store Connect転記シートの最終版
- リジェクト時は `notes/41_app_review_response_templates.md` の分類結果
- 提出後、承認後、公開初日の運用は `notes/51_post_submission_release_day_runbook.md`
- 提出者
- 同時提出したIAP/イベント等
- App Review Notes本文
- スクショセット
- App Privacy回答のスクショ又は控え

## 9. リジェクト時ランブック

1. Appleの指摘文をそのまま保存する。
2. ガイドライン番号、対象画面、対象ビルドを特定する。
3. 次の3つに分類する。
   - メタデータ修正で対応可能
   - 公開URL/サポート文面の修正で対応可能
   - コード修正が必要
4. メタデータ/文面で対応できる場合、`notes/31` 又は `notes/25` を更新する。
5. コード修正が必要な場合、別セッションへP0タスクとして渡す。
6. 再提出時のReview Notesに、何を変更したかを明記する。

### リジェクト対応テンプレ

```
Guideline:
Apple message:
Affected build:
Likely cause:
Can fix without code:
Required code change:
Files/docs to update:
Response draft:
```

## 10. よくある提出停止ライン

- サポートURL又はプライバシーポリシーURLが404
- アカウント作成できるのにアプリ内削除がない
- UGCがあるのに通報/ブロック/公開連絡先がない
- 外部AIへ個人情報を送るのに説明/同意がない
- App Privacyで未申告のデータ収集がある
- 有料機能が見えるのにIAP未設定
- 住所登録又は住所表示の未完成導線が見える
- デモアカウントで審査員が主要機能を確認できない
- スクショに実在IP、実住所、内部ID、デバッグ表示がある

## 11. 公式参照

- Apple Upload Builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Apple TestFlight Overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Apple Add Internal Testers: https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/
- Apple Invite External Testers: https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers
- Apple Submit an App: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple Overview of Submitting for Review: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/overview-of-submitting-for-review/
- Apple App and submission statuses: https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses
