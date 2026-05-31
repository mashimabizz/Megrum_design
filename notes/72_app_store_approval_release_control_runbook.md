# 72. App Store承認後・手動公開制御Runbook

最終更新: 2026-05-31

ステータス: Draft v0.1（承認後・公開前）

## 目的

App Review承認後に、`Pending Developer Release`、Release option、`Release This Version`、公開地域、公開URL、サポート受信、事故疑い、公開初日監視を読み合わせ、意図しない自動公開や公開タイミングの取り違えを防ぐ。

この文書は公開制御Runbookであり、コード、App Store Connect設定、Apple Developer設定、公開URL、証跡ファイル自体は変更しない。

## 1. 公式前提の要点

Apple公式ヘルプ上、手動公開を選んだversionは、承認後に `Pending Developer Release` となり、App Store Connect上で `Release This Version` を選んで公開する。手動公開後、App Storeに表示されるまで最大24時間かかる場合がある。

Apple公式のApp statusでは、`Pending Developer Release` は承認済みだがApp Store配信のために開発者側の公開操作が必要な状態であり、`Processing for Distribution` は配信準備中で24時間以内に準備される状態と説明されている。

将来のversion updateでは段階的リリースを選べる。段階的リリースは7日間で自動アップデート対象を広げる方式で、一時停止は合計30日まで可能。ただし、段階的リリース中でもApp Storeから手動で入手するユーザーには新versionが提供される点に注意する。

## 2. 使うタイミング

使う:
- App Reviewで初回提出が承認された時。
- App Store Connect上で `Pending Developer Release` を確認した時。
- `Release This Version` を押す直前。
- 公開処理中又は公開初日の監視を始める時。

使わない:
- まだ `Waiting for Review` 又は `In Review` の段階。
- App Store Connect最終入力差分QAが未完了。
- 公開URL、サポート受信、App Privacy、配信地域、DSA、IAP Availabilityが未確認。
- 個人情報又はセキュリティ事故疑いが未処理。

## 3. 承認後スナップショット

`Pending Developer Release` を確認したら、まず次を埋める。

| 項目 | 値 |
|---|---|
| 確認日 | TODO |
| 確認者 | TODO |
| App Store Connect status | Pending Developer Release / Other |
| Version | TODO |
| Build Number | TODO |
| Release option | Manual / Automatic / Date |
| 配信地域 | TODO |
| DSA status | TODO |
| IAP Availability | None / Confirmed / Not exposed |
| 公開URL最終確認 | Pass / Fail |
| support@受信確認 | Pass / Fail |
| 証跡保存先 | TODO |

保存しない:
- Demo account password
- 2FA code
- secret、token、private key
- 実代表者情報、個人住所、個人電話番号
- App Store Connect担当者の個人情報が大きく写った管理画面

## 4. Release option QA

初回公開では、意図しない自動公開を避けるため、手動公開を推奨する。

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| REL-OPT-001 | Release optionがManualである | TODO | TODO |
| REL-OPT-002 | Automatic又はDate releaseを誤って選んでいない | TODO | TODO |
| REL-OPT-003 | `notes/51` の提出後ランブックと整合している | TODO | `notes/51` |
| REL-OPT-004 | Automatic又はDate releaseにする場合、オーナー明示承認がある | TODO | TODO |
| REL-OPT-005 | 初回公開で段階的リリースを使う判断になっていない | TODO | TODO |

No-Go:
- Release optionがManualか確認できない。
- 承認直後に自動公開される設定かもしれない。
- Date releaseの日時、タイムゾーン、配信地域を説明できない。
- 初回公開なのに段階的リリース前提の運用にしている。

## 5. Pending Developer Release gate

`Release This Version` を押す前に、次を読み合わせる。

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| PDR-001 | App statusが `Pending Developer Release` である | TODO | TODO |
| PDR-002 | `notes/50` のG0〜G22がGo又はConditional Go | TODO | `notes/50` |
| PDR-003 | App Store Connect最終入力差分QAがPass | TODO | `notes/71` |
| PDR-004 | 商品ページ素材QAがPass | TODO | `notes/70` |
| PDR-005 | Support、Privacy、Terms、Commerce、FAQがHTTPSで開く | TODO | `notes/37` |
| PDR-006 | `support@megrum.jp` が受信できる | TODO | `notes/47`, `notes/67` |
| PDR-007 | 個人情報又はセキュリティ事故疑いがない | TODO | `notes/49` |
| PDR-008 | 配信地域、DSA、IAP Availabilityが最終判断済み | TODO | `notes/68` |
| PDR-009 | App Privacy回答が完成buildと一致している | TODO | `notes/43`, `notes/71` |
| PDR-010 | 証跡フォルダとmanifestが作成済み | TODO | `notes/64` |

No-Go:
- PDR-001〜PDR-010のどれかがFail。
- Support URL又はPrivacy Policy URLが404、ログイン必須、又は別内容。
- App Store商品ページに未完成機能、古いUI、実データ、権利未確認素材が残る。
- `support@megrum.jp` が受信できない。
- 事故疑いがあるのに初動記録、法務確認、公開可否判断がない。

## 6. `Release This Version` 操作手順

実操作はApp Store Connect上で、提出権限を持つ担当者が実施する。

1. AppsでMegrumを開く。
2. 対象versionを開く。
3. Version、Build Number、status、Release optionを声に出して読み合わせる。
4. `notes/50` の最終判定と `notes/72` のPDR gateがGo又はConditional Goであることを確認する。
5. `Release This Version` を選ぶ。
6. 確認ダイアログの内容を読み、対象versionが正しいことを再確認する。
7. Confirmする。
8. 実施時刻、実施者、直後のApp Store Connect statusを `notes/36` と証跡manifestへ記録する。

操作中に迷った場合:
- ダイアログを閉じる。
- スクショ又はメモを保存する。
- `notes/61` の権限担当、`notes/50` の最終判定者、オーナーへ確認してから再開する。

## 7. Processing / Available監視

公開操作後は、App Store表示まで最大24時間を見込んで監視する。

| 時点 | 確認 | 証跡 |
|---|---|---|
| T+0 | App Store Connect status、公開操作時刻、配信地域を記録 | `notes/64` REL-002 |
| T+1h | App Store直リンク、検索、Privacy URL、Support URLを確認 | `notes/64` REL-003 |
| T+3h | 実端末でApp Storeから入手できるか確認 | `notes/64` REL-003 |
| T+6h | 新規登録、ログイン、在庫、wish、打診、取引チャットを軽く確認 | `notes/42`, `notes/64` REL-004 |
| T+12h | `support@megrum.jp`、App Store Connect messages、TestFlight feedbackを確認 | `notes/67` |
| T+24h | 初日まとめ、問い合わせ、障害、次build候補を記録 | `notes/51`, `notes/64` |

監視中の優先順位:
1. ログイン不能、アカウント作成不能、公開URL不通。
2. 他人データ表示、位置情報又は取引チャットの共有範囲異常。
3. アカウント削除、通報、ブロック、問い合わせ導線の不具合。
4. App Privacy、商品ページ、実buildの重大な矛盾。

## 8. 段階的リリース / 将来アップデート

初回公開では手動公開を基本にし、段階的リリースは初回公開後のversion updateで検討する。

段階的リリースを使う場合:
- 対象は自動アップデートであり、App Storeから手動で入手するユーザーには新versionが提供される前提で監視する。
- 一時停止は合計30日までの制限がある。
- 一時停止しても、既に入手済みのユーザーからの問い合わせ、事故疑い、サポート対応は止まらない。
- pause / resume / release to all users の判断者と証跡保存先を事前に決める。

Pause候補:
- ログイン不能、クラッシュ、他人データ表示などのP0障害。
- Privacy URL又はSupport URLの障害。
- App Privacy又は商品ページの重大な不一致。
- IAP権限、復元、価格表示の重大な不一致。

## 9. 公開後に止める判断

公開後に次が起きたら、`notes/73_app_store_availability_emergency_stop_runbook.md` と合わせて、配信停止、地域availability変更、段階的リリースpause、新build、サポート告知、事故初動の要否を判断する。

| 事象 | 初動 | 参照 |
|---|---|---|
| 他人データが見える | 直ちに証跡を隔離し、事故初動へ | `notes/49` |
| ログイン不能が複数発生 | 影響範囲と再現条件を記録 | `notes/51`, `notes/67` |
| Privacy URL又はSupport URLが落ちる | URL復旧、証跡保存、公開継続可否判断 | `notes/37`, `notes/47` |
| アカウント削除が動かない | 削除請求の代替受付を用意 | `notes/45`, `notes/67` |
| IAP購入又は復元が壊れる | IAP露出停止又はnew build判断 | `notes/33`, `notes/68` |
| App Review又は公開メタデータの問題 | 指摘本文保存、返信案、同じbuild可否を判断 | `notes/69`, `notes/41` |
| 公開継続が危険 | Territory deselect、Remove App From Sale、new buildを判断 | `notes/73` |

## 10. 最終サインオフ

| 項目 | 判定 | 証跡 | 署名/日付 |
|---|---|---|---|
| Release option確認 | Go / Conditional / No-Go | TODO | TODO |
| Pending Developer Release gate | Go / Conditional / No-Go | TODO | TODO |
| 公開URL/サポート受信 | Go / Conditional / No-Go | TODO | TODO |
| App Privacy/商品ページ/配信地域 | Go / Conditional / No-Go | TODO | TODO |
| 事故疑いなし | Go / Conditional / No-Go | TODO | TODO |
| Release This Version実施 | Done / Not done | TODO | TODO |
| T+24h監視完了 | Done / Not done | TODO | TODO |

最終記録:

```text
Decision: Release / Hold / Stop distribution / New build
Version:
Build:
Released by:
Released at:
App Store available at:
Evidence folder:
Known issues:
Next action:
```

## 11. 関連文書

- App Store提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- App Store商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- 配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`
- サポート受信トリアージ: `notes/67_support_inbox_triage_runbook.md`
- 個人情報・セキュリティ事故初動: `notes/49_privacy_security_incident_response_runbook.md`
- ドメイン・メール・公開URL運用: `notes/47_domain_email_publication_runbook.md`
- App Reviewリジェクト/追加情報要求: `notes/69_app_review_rejection_triage_runbook.md`
- App Review指摘対応テンプレート: `notes/41_app_review_response_templates.md`
- App Store公開停止・Availability変更: `notes/73_app_store_availability_emergency_stop_runbook.md`

## 12. 公式参照

- Apple Select an App Store version release option: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/
- Apple App and submission statuses: https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses
- Apple Release a version update in phases: https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases
