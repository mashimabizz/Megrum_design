# 74. App Store評価・レビュー返信Runbook

最終更新: 2026-05-31

ステータス: Draft v0.1（公開後・レビュー運用前）

## 目的

App Store公開後に、星評価、ユーザーレビュー、レビュー要約、レビュー返信、concern report、overview rating resetを安全に扱い、公開返信で個人情報、未確認事実、補償、相手方処分、内部情報を出さないようにする。

この文書はApp Store上の評価・レビュー運用Runbookであり、コード、App Store Connect設定、公開URL、サポートツール設定、証跡ファイル自体は変更しない。

## 1. 公式前提の要点

Apple公式ヘルプ上、ユーザーはアプリを1〜5 starsで評価でき、iOS、macOS、visionOSでは文章レビューも投稿できる。App Store product pageには国又は地域ごとのoverview rating、個別評価、個別レビューが表示される。

App Store Connectではratings and reviewsを確認でき、国又は地域、app version、rating、編集済み/返信済みなどで絞り込める。レビュー又はレビュー要約に問題がある場合はAppleへconcernを報告できる。

iOS、macOS、watchOS、visionOSではレビューへ公開返信できる。返信はApp Store product page上で公開表示され、返信の表示には最大24時間かかる場合がある。返信は編集又は削除でき、表示される返信は1レビューにつき1つ。

新version公開時にはoverview rating resetを選べるが、リセット後に以前のratingへ戻せず、文章レビューは引き続き表示される。

## 2. 使うタイミング

使う:
- App Store公開後、Ratings and Reviewsを日次確認する時。
- 1〜2 stars又は安全・個人情報・課金・ログイン関連のレビューが入った時。
- 公開返信を出す前。
- レビュー又はレビュー要約が不適切、個人情報を含む、虚偽又は攻撃的に見える時。
- 次versionでoverview rating resetを検討する時。

使わない:
- App Review審査員からの連絡。これは `notes/69` / `notes/41` を使う。
- `support@megrum.jp` に届いた個別問い合わせ。これは `notes/67` / `notes/34` を使う。
- 個人情報又はセキュリティ事故疑い。これは `notes/49` / `notes/73` へ即時エスカレーションする。

## 3. 役割と権限

| 役割 | やること |
|---|---|
| Review Monitor | Ratings and Reviewsを確認し、記録する |
| Response Drafter | 返信案を作る |
| Response Approver | 公開返信前にNG表現と事実確認を見る |
| Support Lead | 個別サポートへ誘導し、受付番号を発行する |
| Incident Lead | P0レビューを事故疑いへ切り替える |

最小運用では兼務してよい。ただし、P0レビューへの返信は、公開前に少なくとも別担当又はオーナーが読み合わせる。

## 4. 日次確認

| Check | 確認 | 頻度 | 証跡 |
|---|---|---|---|
| REVW-001 | 新規レビューとratingを確認 | 公開初週は毎日 | `notes/64` |
| REVW-002 | 1〜2 starsを確認 | 毎日 | `notes/64` |
| REVW-003 | 安全、個人情報、ログイン、IAP、削除、URL不備を含むレビューを抽出 | 毎日 | `notes/67` |
| REVW-004 | 返信が必要なレビューを分類 | 毎日 | 本Runbook |
| REVW-005 | App Store product page上の返信反映を確認 | 返信後24時間以内 | `notes/64` |
| REVW-006 | レビュー要約に問題がないか確認 | 週1回又は公開初週 | 本Runbook |

## 5. レビュー分類

| 分類 | 例 | 優先度 | 初動 |
|---|---|---|---|
| P0 Incident | 他人データ表示、個人情報露出、不正アクセス疑い | P0 | `notes/49` へ。公開返信は事実確認後 |
| P0 Safety | 危険行為、脅迫、個人情報晒し、現地トラブル | P0 | `notes/26` / `notes/67` へ |
| P1 Login | 登録不能、ログイン不能、認証メール不着 | P1 | サポート誘導、既知障害確認 |
| P1 Account | 削除できない、個人情報請求できない | P1 | `notes/45` / `notes/67` へ |
| P1 IAP | 購入、復元、解約、価格表示 | P1 | `notes/33` / `notes/34` へ |
| P1 Bug | クラッシュ、表示崩れ、通知不達、リンク切れ | P1 | version/build/端末を案内 |
| P2 Usability | 使い方が分からない、改善要望 | P2 | FAQ又は今後改善へ |
| P2 Praise | 良い評価、好意的レビュー | P2 | 必要なら短く返信 |
| Concern | 侮辱、個人情報、スパム、レビュー要約の問題 | P0/P1 | Appleへconcern report候補 |

## 6. 返信前チェック

| Check | 確認 | 結果 |
|---|---|---|
| RPLY-001 | 公開返信であることを理解している | TODO |
| RPLY-002 | 個人情報、相手方情報、内部IDを書いていない | TODO |
| RPLY-003 | 未確認の原因、復旧時刻、補償、返金、責任範囲を断定していない | TODO |
| RPLY-004 | 個別対応が必要なら `support@megrum.jp` へ誘導している | TODO |
| RPLY-005 | P0ならIncident Lead又はSupport Leadが確認済み | TODO |
| RPLY-006 | 返信後のApp Store反映確認予定を決めた | TODO |

No-Go:
- レビュー本文に含まれる個人情報を引用する。
- 相手方ユーザーの処分、内部審査、内部ログの内容を書く。
- 「必ず直します」「補償します」「返金します」と断定する。
- 事故疑いを確認前に否定する。
- App Store公開返信だけで個別サポートを完了扱いにする。

## 7. 返信テンプレート

### 7.1 ログイン・登録

```text
ご不便をおかけしています。ログイン状況を確認しますので、アプリのバージョン、端末、表示されたエラーを添えて support@megrum.jp までご連絡ください。パスワードや認証コードは送らないでください。
```

### 7.2 不具合

```text
ご報告ありがとうございます。状況を確認します。発生した画面、操作手順、アプリのバージョン、端末情報を support@megrum.jp へお送りいただけると確認が早くなります。
```

### 7.3 安全・通報

```text
安全に関わるご連絡として確認します。アプリ内の通報、又は support@megrum.jp から詳細をご連絡ください。身の危険がある場合は、会場スタッフや公的機関への相談も優先してください。
```

### 7.4 アカウント削除

```text
アカウント削除はアプリ内の設定画面から開始できます。操作できない場合は、登録メールアドレスから support@megrum.jp へご連絡ください。本人確認のうえ対応します。
```

### 7.5 IAP・購入

```text
購入や復元でご不便をおかけしています。状況確認のため、アプリのバージョン、購入画面、発生日時を support@megrum.jp へご連絡ください。返金手続きが必要な場合はApp Store側の購入履歴からの申請もご確認ください。
```

### 7.6 好意的レビュー

```text
レビューありがとうございます。安心して交換を進められるよう、引き続き改善していきます。
```

### 7.7 個人情報・事故疑い

```text
重要なご連絡として確認します。公開レビューでは詳しい状況を伺えないため、support@megrum.jp へ発生日時、該当画面、アプリのバージョンをお送りください。パスワードや認証コードは送らないでください。
```

## 8. Concern report判断

Appleへconcern reportを検討するもの:
- レビューに個人情報、電話番号、住所、外部連絡先、認証情報が含まれる。
- 脅迫、差別、嫌がらせ、スパム、明らかななりすましが含まれる。
- レビュー要約がMegrumの機能、法務表示、安全対応を重大に誤って要約している。
- 実在IP、他社、個人への権利侵害又は攻撃が含まれる。

concern report前に残す記録:
- Review date
- Country / region
- Rating
- Version
- レビュー要約
- concern理由
- Appleへ送る説明文

## 9. Overview rating reset判断

次version公開時にoverview rating resetを検討する条件:
- 初期version固有の重大不具合が修正済み。
- 低評価の主因が新versionで解消されている。
- サポート返信、FAQ、公開文面も更新済み。
- reset後も文章レビューが残ることを理解している。

No-Go:
- 低評価を隠す目的だけでresetする。
- 原因未解決のままresetする。
- reset後に以前のratingへ戻せないことを理解していない。
- 文章レビューが残ることを見落としている。

## 10. 記録フォーマット

```text
Review ticket:
Checked at:
Reviewer:
Country / region:
Platform:
Version:
Rating:
Review summary:
Category:
Priority:
Response needed: Yes / No
Response draft:
Approved by:
Submitted at:
App Store reflected at:
Support ticket:
Incident ticket:
Concern reported: No / Yes
Evidence folder:
```

公開リポジトリに残す場合は、レビュー本文の全文、ユーザー名、個人情報、認証情報を残さず要約だけにする。

## 11. 関連文書

- サポート受信トリアージ: `notes/67_support_inbox_triage_runbook.md`
- サポート返信テンプレート: `notes/34_support_response_templates.md`
- 個人情報・セキュリティ事故初動: `notes/49_privacy_security_incident_response_runbook.md`
- App Store提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- 公開停止・Availability変更: `notes/73_app_store_availability_emergency_stop_runbook.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`

## 12. 公式参照

- Apple Ratings and reviews overview: https://developer.apple.com/help/app-store-connect/monitor-ratings-and-reviews/ratings-and-reviews-overview/
- Apple View ratings and reviews: https://developer.apple.com/help/app-store-connect/monitor-ratings-and-reviews/view-ratings-and-reviews/
- Apple Respond to reviews: https://developer.apple.com/help/app-store-connect/monitor-ratings-and-reviews/respond-to-reviews/
- Apple Reset an app overview rating: https://developer.apple.com/help/app-store-connect/monitor-ratings-and-reviews/reset-an-app-overview-rating/
