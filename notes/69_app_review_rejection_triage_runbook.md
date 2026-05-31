# 69. App Reviewリジェクト・追加情報要求トリアージRunbook

最終更新: 2026-05-31

ステータス: Draft v0.1（初回提出前・指摘未受領）

## 目的

App Reviewからリジェクト、Metadata Rejected、Unresolved Issues、追加情報要求、TestFlight App Review指摘が来た時に、慌てて不要なコード変更や不正確な返信をしないための初動手順を整理する。

この文書は運用手順であり、コード、App Store Connect設定、公開URL、法務原典docxは変更しない。返信文の部品は `notes/41_app_review_response_templates.md` を使う。

## 1. 公式前提の要点

Apple公式ヘルプ上、App Review又はTestFlight App Reviewで却下された場合、App Store ConnectのApp ReviewセクションでAppleとやり取りし、スクショ等の添付を含めて返信できる。メタデータ起因の却下であれば、問題解消後に同じビルドで再提出できる。

submission内の一部itemが却下された場合は、statusがUnresolved Issuesになり、承認完了にはすべてのitemの承認が必要になる。続行するには却下itemを編集して再提出するか、submissionから削除する。

Waiting for Review、In Review、Pending Developer Release等の状態では、提出をreview/release processから取り下げられる。ただし取り下げるとDeveloper Rejected扱いとなり、再提出時はreview processが最初から始まる。

Apple App Review Guidelinesでは、疑問や追加説明がある場合はApp Store ConnectでApp Reviewチームへ直接連絡でき、結果に同意できない場合はappealできる旨が示されている。

## 2. 使うタイミング

使う:
- App Store Connectで `Rejected` 又は `Metadata Rejected` になった。
- App Reviewセクションにunresolved issueが出た。
- Resolution Center又はApp Review Messageで追加情報を求められた。
- TestFlight App Reviewで外部テスト用buildが却下された。
- submissionを取り下げるか、同じbuildで再提出するか、新buildを作るか迷う。

使わない:
- まだSubmit for Review前の提出準備。提出前は `notes/62_app_review_manual_submission_checklist.md` を使う。
- 承認済みで手動公開待ち。公開前は `notes/51_post_submission_release_day_runbook.md` を使う。
- ユーザー問い合わせへの返信。通常問い合わせは `notes/67_support_inbox_triage_runbook.md` を使う。

## 3. 初動15分

| Step | やること | 証跡 |
|---|---|---|
| RV-001 | App Store Connect statusを記録する | status, 受信日時 |
| RV-002 | Apple本文を全文保存する | `notes/64` の `11_review_response/` |
| RV-003 | Guideline番号、指摘item、指摘画面、添付有無を抽出する | `notes/53` と照合 |
| RV-004 | メタデータ修正、公開URL修正、App Privacy修正、コード修正、新build、appeal候補に仮分類する | 本文要約 |
| RV-005 | App Review返信担当、開発担当、法務/Privacy担当を決める | 担当表 |
| RV-006 | 返信前に、断定できる事実と未確認事項を分ける | 返信下書き |

禁止:
- Apple本文を要約だけで済ませ、原文を保存しない。
- 原因未確認のまま「修正済み」と返信する。
- 実パスワード、secret、個人情報入りスクショを添付する。
- 返信前にApp Store説明文、Privacy、公開URLを場当たり的に書き換える。

## 4. 分類表

| 分類 | 典型例 | 最初に見る文書 | 初動 |
|---|---|---|---|
| Metadata Rejected | 説明文、スクショ、URL、Review Notesの不備 | `notes/40`, `notes/60`, `notes/63` | 同じbuildで直せるか判断 |
| 2.1 App Completeness | ログイン不可、placeholder、クラッシュ、URL不通 | `notes/35`, `notes/42`, `notes/37` | 再現し、new build要否を判断 |
| 1.2 UGC | 通報、ブロック、連絡先、モデレーション不明 | `notes/26`, `notes/53`, `notes/41` | 実画面証跡と運用説明を揃える |
| 5.1 Privacy | App Privacy、Privacy Policy、削除、権限説明の不一致 | `notes/27`, `notes/43`, `notes/45`, `notes/48` | 実ビルド/公開文面/回答を再照合 |
| 3.1.1 IAP | 有料導線、復元、商品設定、価格説明 | `notes/33`, `notes/68`, `notes/41` | 隠すかIAPを完成させるか決める |
| Age / Content Rights / Export | 質問票、権利物、暗号化回答 | `notes/46`, `notes/28`, `notes/31` | 回答とスクショ/SDKを照合 |
| AI | 外部AI送信、説明、Privacy不一致 | `notes/legal`, `notes/27`, `notes/48` | 隠すか説明/同意/回答を揃える |
| Unresolved Issues | submission内itemの一部却下 | `notes/33`, `notes/62`, 本文 | itemを編集/削除して再提出 |
| Invalid Binary | binary要件、署名、entitlement、privacy manifest | 開発セッション, `notes/75`, `notes/44` | 開発側へ切り出し、新build前提 |
| 追加情報要求 | Guideline違反ではなく説明不足 | `notes/41`, `notes/53` | 事実と確認経路を短く返信 |
| Appeal候補 | Appleの事実認定と実装事実が明確に違う | `notes/36`, `notes/53`, 法務判断 | 先に通常返信で説明し、必要時のみappeal |

## 5. 判断ツリー

1. Apple本文は「質問」か「修正要求」か「却下itemの処理要求」かを分ける。
2. 修正要求なら、同じbuildで直せるものか判断する。
3. 同じbuildで直せるものは、メタデータ、公開URL、App Privacy、Review Notes、添付資料を修正する。
4. 実装、権限、SDK、クラッシュ、ログイン、削除入口、通報入口が原因なら、開発セッションへ新build依頼として切り出す。
5. submission内itemの一部却下なら、itemを編集して再提出するか、初回提出から削除するか決める。
6. 取り下げが必要な場合だけ、影響を記録したうえでRemove submissionを検討する。
7. Appleの事実認定とMegrum側の証跡が明確に食い違う場合のみ、appealを検討する。

## 6. 同じbuildで直せる可能性が高いもの

| 項目 | 例 | 必要証跡 |
|---|---|---|
| Description / Subtitle / Keywords | 未完成機能や実在IP表現を削る | 修正前後の文面 |
| Screenshots | 未完成機能、実データ、debug表示を差し替える | 新スクショ |
| Review Notes | 審査経路、デモアカウント、通報/削除導線を追記 | 最終本文 |
| Public URL | 404、ログイン必須、古い文面を直す | 200応答、画面控え |
| App Privacy | 実ビルドと回答が一致しない | 回答控え、`notes/27` 差分 |
| IAP item | 初回で出さないitemを削除又は非表示にする | item status、画面証跡 |

## 7. 新buildが必要になりやすいもの

| 項目 | 例 | 開発側へ渡す情報 |
|---|---|---|
| Crash / Freeze | Appleが再現したクラッシュ、空画面 | 端末、OS、手順、ログ、画面 |
| Login failure | デモアカウントで入れない | アカウント状態、認証方式、時刻 |
| Missing feature | 通報、ブロック、削除、復元が実装されていない | Guideline、期待導線、該当画面 |
| Privacy Manifest / SDK | manifest不足、SDKのRequired Reason API | Apple本文、build番号、SDK一覧 |
| IAP runtime | 購入、復元、権限付与が動かない | 商品ID、Sandbox手順、期待結果 |
| External AI | 隠すはずのAI導線が見える | 画面、文面、送信有無 |

新buildが必要な場合は、元ツリーの開発セッションへ切り出し、修正後に `notes/65_release_candidate_handoff.md` で新しいVersion/Build/commit SHAを受け取る。

## 8. 返信前チェック

| Check | 確認 | 結果 |
|---|---|---|
| ARV-001 | Apple本文の全文を保存した | TODO |
| ARV-002 | Guideline番号と指摘itemを特定した | TODO |
| ARV-003 | 実ビルドで再現又は非再現を確認した | TODO |
| ARV-004 | 同じbuildで直す / new build / item削除 / appealの判断を記録した | TODO |
| ARV-005 | 返信文に未確認の断定がない | TODO |
| ARV-006 | 添付スクショにsecret、個人情報、実ユーザーデータがない | TODO |
| ARV-007 | 公開URL、App Privacy、Review Notesを変えた場合、`notes/36` に控えを残した | TODO |
| ARV-008 | コード修正が必要な場合、開発側へ別タスク化した | TODO |

## 9. 返信テンプレートの使い分け

| 状況 | 使うテンプレート |
|---|---|
| 追加説明だけで足りる | `notes/41` の共通返信フォーマット |
| App Completeness | `notes/41` §3 |
| UGC安全 | `notes/41` §4 |
| Privacy / 削除 | `notes/41` §5 |
| IAP | `notes/41` §6 |
| Physical goods / digital goods整理 | `notes/41` §7 |
| Metadata / Screenshots | `notes/41` §8 |
| AI | `notes/41` §9 |
| Public URLs | `notes/41` §10 |

返信の基本形:

```text
Thank you for reviewing Megrum.

We reviewed the issue and made the following changes:
- ...

How to verify:
1. ...
2. ...
3. ...

Additional notes:
- ...
```

## 10. Appeal判断

Appeal候補:
- Appleが見つけられなかっただけで、該当導線が完成build内にあり、証跡とレビュー手順で説明できる。
- Appleの指摘が、提出buildではなく古いbuild又は別itemに基づいている可能性が高い。
- Guideline解釈について、法務/運用上の根拠を添えて説明できる。

Appealにしない:
- 実際にクラッシュする。
- デモアカウントで入れない。
- App Privacy又は公開URLに不一致がある。
- UGC安全、削除、IAP、AIの導線が未実装。
- 返信で説明すれば足りる軽微な追加情報要求。

Appealする場合も、Apple本文、Megrum側証跡、実機手順、関連Guideline、法務判断を分けて記録する。

## 11. 記録テンプレート

```markdown
## App Review対応記録

受付日時:
App Store Connect status:
Version / Build:
Apple本文保存先:
Guideline:
分類:
指摘item:
該当画面:

判断:
- 同じbuildで直す:
- new buildが必要:
- item削除:
- appeal候補:

対応:
- メタデータ:
- 公開URL:
- App Privacy:
- Review Notes:
- コード:

返信本文:

添付:

Resubmit / Reply / Remove / Appeal:
実施者:
実施日時:
次回確認:
```

## 12. No-Go

- Apple本文を全文保存していない。
- 指摘Guidelineを分類していない。
- new buildが必要な問題を、Review Notesだけで済ませようとしている。
- 実装されていない通報、削除、IAP、AI説明を「あります」と返信する。
- 個人情報、secret、実パスワード入りの証跡を添付する。
- 複数itemのUnresolved Issuesで、却下itemを処理せずResubmitしようとする。
- 取り下げの影響を理解せずRemove submissionする。
- 事実確認前にappealする。

## 13. 関連文書

- App Review指摘対応テンプレート: `notes/41_app_review_response_templates.md`
- 提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- App Review Guideline適合: `notes/53_app_review_guideline_compliance_matrix.md`
- App Review手動提出チェック: `notes/62_app_review_manual_submission_checklist.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Release Candidateハンドオフ: `notes/65_release_candidate_handoff.md`
- サポート受信トリアージ: `notes/67_support_inbox_triage_runbook.md`
- App Store配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`

## 14. 公式参照

- Apple Reply to App Review messages: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/reply-to-app-review-messages/
- Apple Manage a submission with unresolved issues: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/manage-a-submission-with-unresolved-issues
- Apple Remove a submission from review: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/remove-a-submission-from-review/
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
