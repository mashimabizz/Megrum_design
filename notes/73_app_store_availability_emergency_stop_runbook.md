# 73. App Store公開停止・Availability変更Runbook

最終更新: 2026-05-31

ステータス: Draft v0.1（公開後・緊急停止判断）

## 目的

公開後に重大障害、個人情報又はセキュリティ事故疑い、App Privacy不一致、公開URL障害、IAP重大不具合が起きた時、App Store上で地域Availability変更、`Remove App From Sale`、旧version unavailable、新build提出、サポート告知のどれを使うかを迷わず判断する。

この文書は公開停止・Availability変更のRunbookであり、コード、App Store Connect設定、Apple Developer設定、公開URL、証跡ファイル自体は変更しない。

## 1. 公式前提の要点

Apple公式ヘルプ上、App Store ConnectではPricing and AvailabilityからApp Availabilityを管理し、国又は地域ごとに利用可能範囲を変更できる。国又は地域を外すと、その国又は地域のApp StoreからMegrumは削除されるが、既に入手済みのユーザーは更新を受け取れる場合があり、必要な契約が有効な限り購入履歴から再ダウンロードできる場合がある。

全地域から外す場合はPricing and Availabilityの `Remove App From Sale` を使う。反映は24時間以内と案内されている。Availability変更は即時反映されるが、全ユーザーに見えるまで最大24時間かかる場合がある。

旧versionに法的又は利用上の問題がある場合、Appleはapp updateを提出し、前versionの問題をsubmissionで明確に説明することを求めている。updateを提出できない場合はApp Storeからアプリを外す必要がある。

## 2. 使うタイミング

使う:
- 公開後又は公開初日監視中にP0事故疑いがある。
- 他人データ表示、ログイン不能、削除不能、Privacy URL / Support URL障害などが公開継続に影響する。
- IAP購入、復元、価格、Availabilityが重大に壊れている。
- App Privacy又は商品ページと実buildの重大な不一致が公開後に判明した。
- 旧versionを残すと法的又は利用上の問題が続く。

使わない:
- 軽微なUI崩れ、誤字、FAQだけで解消できる問い合わせ。
- 公開停止よりアプリ内feature flagやサーバー側一時停止で十分に拡大防止できる。
- 事実確認がなく、影響範囲も不明なまま感情的に止めたいだけの状態。

## 3. 停止判断の種類

| 判断 | 使う条件 | 注意 |
|---|---|---|
| Monitor only | 影響が軽微で回避可能 | 証跡とサポート返信だけ残す |
| In-app / server stop | 特定機能だけ止めれば拡大防止できる | 開発側の対応が必要。App Store停止ではない |
| Territory deselect | 特定地域だけ法務/運用/サポートリスクが高い | 既存入手ユーザーへの影響が残る場合がある |
| Remove App From Sale | 全地域で公開継続が危険 | 反映に最大24時間。既存入手ユーザーへの対応が別途必要 |
| New build | 修正済みbuildで置き換える | Review Notesで前version問題と修正内容を明確化 |
| Last-compatible version change | 旧versionに法的又は利用上の問題がある | 提出済みversionだけが対象 |

## 4. Emergency snapshot

停止判断前に、次を埋める。

| 項目 | 値 |
|---|---|
| 受付番号 | TODO |
| 発覚日時 | TODO |
| 判断者 | TODO |
| Incident Lead | TODO |
| App Store Connect担当 | TODO |
| Version / Build | TODO |
| App Availability | Japan only / selected / all / unknown |
| 影響地域 | TODO |
| 影響機能 | Auth / Core Flow / Safety / Account / IAP / Privacy / URL / Other |
| 優先度 | P0 / P1 / P2 |
| 一時停止候補 | Monitor / Server stop / Territory deselect / Remove App From Sale / New build |
| 証跡保存先 | TODO |

保存しない:
- 実パスワード
- secret、token、private key
- 影響ユーザーの不要な個人情報
- App Store Connect担当者の個人情報が大きく写った管理画面

## 5. 即時停止候補の判定

| Check | 事象 | 推奨初動 |
|---|---|---|
| STOP-001 | 他人データが見える | P0。事故初動、機能停止、公開停止候補 |
| STOP-002 | ログイン不能又は登録不能が広範囲 | P0。影響範囲確認、公開停止又はnew build候補 |
| STOP-003 | アカウント削除が動かない | P0/P1。代替受付、公開継続可否判断 |
| STOP-004 | Privacy URL又はSupport URLが落ちる | P0。URL復旧、公開停止候補 |
| STOP-005 | App Privacy回答と実buildが重大に違う | P0/P1。App Privacy修正又はnew build候補 |
| STOP-006 | IAP購入、復元、価格表示が壊れる | P0/P1。IAP露出停止、Availability確認、new build候補 |
| STOP-007 | 旧versionに法的又は利用上の問題がある | P0/P1。new build又は旧version unavailable候補 |
| STOP-008 | サポート受信ができない | P1。公開URL/メール復旧、公開継続可否判断 |

No-Go:
- P0事故疑いがあるのに受付番号、証跡、Incident Leadを作らない。
- 停止後に既存入手ユーザーへ何が残るか確認しない。
- App Store Connect操作だけで事故が解消したと扱う。

## 6. Territory availability変更手順

特定地域だけ外す場合の読み合わせ。

1. App Store Connect担当がAppsでMegrumを開く。
2. Pricing and Availabilityを開く。
3. App AvailabilityでManageを開く。
4. Availabilityの国又は地域一覧を確認する。
5. 変更する国又は地域、変更理由、影響、サポート方針を読み合わせる。
6. 対象の国又は地域をdeselectする。
7. Next、Confirmへ進む。
8. 変更時刻、対象地域、反映見込み、証跡を `notes/64` のmanifestへ記録する。

確認:
- 変更は最大24時間かかる場合がある。
- 既に入手済みのユーザーには影響が残る場合がある。
- サポート窓口、Privacy請求、削除請求の受付は継続する。

## 7. `Remove App From Sale` 手順

全地域で公開継続が危険な場合の読み合わせ。

1. Incident Lead、App Store Connect担当、オーナーが停止理由を確認する。
2. `notes/49` の事故初動、`notes/67` のサポート受信、`notes/72` の公開後停止判断と照合する。
3. App Store ConnectでApps > Megrum > Pricing and Availabilityを開く。
4. ページ下部の `Remove App From Sale` を選ぶ。
5. 確認ダイアログを読み、対象アプリがMegrumであることを再確認する。
6. RemoveをConfirmする。
7. 実施者、時刻、直後status、App Store直リンク確認、サポート告知要否を記録する。

注意:
- 反映は24時間以内と見込む。
- 既存入手ユーザーの利用、更新、再ダウンロード可能性を別途判断する。
- 公開停止後も、削除請求、個人情報請求、問い合わせ、事故対応は継続する。

## 8. 旧version unavailable / new build判断

旧versionに法的又は利用上の問題がある場合は、Apple公式前提に沿ってnew build提出を第一候補にする。

| 判断 | 使う条件 | 記録 |
|---|---|---|
| New build | 修正コード又は設定変更が必要 | 修正内容、Version/Build、Review Notes |
| Metadata / App Privacy修正 | buildは正しいが公開情報が違う | App Store Connect修正欄、反映証跡 |
| Last-compatible version change | 旧versionを残すと問題が続く | 対象version、外す理由、復帰条件 |
| Remove App From Sale | update提出まで公開継続が危険 | 停止理由、復帰条件、サポート告知 |

Review Notesに書くこと:
- 前versionで何が問題だったか。
- 新buildで何を直したか。
- 審査員が確認できる経路。
- ユーザー向けサポート又は公開URLの更新有無。

## 9. サポート・公開文面

停止又はAvailability変更時は、サポート側の一次返信を先に用意する。

| 対象 | 更新候補 |
|---|---|
| Support URL | 障害又は一時停止中の問い合わせ先 |
| FAQ | 一時停止理由、再開見込み、削除請求/個人情報請求 |
| Privacy Policy | データ取扱いが変わる場合だけ |
| Terms | 利用条件が変わる場合だけ |
| App Store Review Notes | new build提出時の修正説明 |

書かない:
- 影響範囲が未確定なのに「影響はありません」と断定する。
- 個別ユーザーの情報。
- secret、内部ID、管理画面情報。
- 法務確認前の補償、返金、責任範囲の断定。

## 10. 復帰判定

復帰前に、次を確認する。

| Check | 確認 | 結果 |
|---|---|---|
| RESUME-001 | 原因と影響範囲を記録した | TODO |
| RESUME-002 | 修正又は拡大防止策が完了した | TODO |
| RESUME-003 | Privacy / Support / Terms / FAQが必要に応じて更新済み | TODO |
| RESUME-004 | App Privacy回答が実buildと一致している | TODO |
| RESUME-005 | P0スモークテスト又は該当機能テストがPass | TODO |
| RESUME-006 | サポート返信テンプレートが準備済み | TODO |
| RESUME-007 | new build又はAvailability復帰操作の証跡保存先がある | TODO |

No-Go:
- 原因が不明のまま復帰する。
- 事故疑いの本人通知/PPC報告判断が未了。
- URL、サポート、削除請求、個人情報請求の受付が止まったまま復帰する。

## 11. 関連文書

- App Store承認後・手動公開制御: `notes/72_app_store_approval_release_control_runbook.md`
- App Store提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- 個人情報・セキュリティ事故初動: `notes/49_privacy_security_incident_response_runbook.md`
- サポート受信トリアージ: `notes/67_support_inbox_triage_runbook.md`
- 配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`
- App Reviewリジェクト/追加情報要求: `notes/69_app_review_rejection_triage_runbook.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- ドメイン・メール・公開URL運用: `notes/47_domain_email_publication_runbook.md`

## 12. 公式参照

- Apple Manage availability for your app on the App Store: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/
- Apple Make a version unavailable for download: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/make-a-version-unavailable-for-download/
