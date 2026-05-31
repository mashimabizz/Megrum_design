# 67. サポート受信トリアージRunbook

最終更新: 2026-05-31

ステータス: Draft v0.1（運用前・受信箱設計）

## 目的

`support@megrum.jp` に届く問い合わせ、App Review連絡、通報、安全相談、アカウント削除、個人情報請求、購入相談、事故疑いを、初回提出前後に迷わず分類し、適切な返信、記録、エスカレーションへつなげる。

この文書はサポート受信運用の手順であり、コード、メール設定、サポートツール設定、公開URL、DB、App Store Connect設定は変更しない。

## 1. 使うタイミング

使うタイミング:
- `support@megrum.jp` の受信確認ができた。
- App Store ConnectのSupport URLへ公開サポートページを入れる。
- TestFlight、App Review、公開初日に問い合わせを受ける可能性がある。
- 少人数運用で、問い合わせ分類と担当分けを先に決めたい。

使わないタイミング:
- サポートメールが未開通。
- 公開URLが未決。
- 個人情報や安全相談を受けた時の担当が未決。
- 問い合わせ内容を安全に保管する場所が未決。

## 2. 公式前提の要点

AppleのApp Review Guidelinesでは、Support URLを含むメタデータやURLが機能していること、アプリがアカウント作成を提供する場合はアプリ内でアカウント削除を開始できることが重要になる。

個人情報保護委員会の案内では、個人の権利利益を害するおそれがある一定の漏えい等について、報告や本人通知が必要になる場合がある。

そのため、Megrumのサポート受信箱では、通常問い合わせと、削除、個人情報請求、事故疑い、審査連絡を同じ温度で扱わず、最初の分類で優先度を分ける。

## 3. 受信箱の基本ルール

| 項目 | 方針 |
|---|---|
| 受信窓口 | `support@megrum.jp` |
| 通常返信 | 原則2営業日以内 |
| App Review連絡 | 当日中に確認 |
| 安全・危険・個人情報事故疑い | P0として即時確認 |
| アカウント削除 | アプリ内削除を案内し、例外時は本人確認へ |
| 個人情報請求 | 受付番号を発行し、本人確認へ |
| 記録 | 受付番号、分類、担当、日時、対応状況を残す |
| 保存禁止 | パスワード、認証コード、secret、不要な本人確認書類 |

少人数運用では、1人が複数役割を兼ねてよい。ただしP0は「受付担当」と「判断担当」を分けて記録する。

## 4. 初回トリアージ分類

| 分類 | 例 | 優先度 | 初動 | 参照 |
|---|---|---|---|---|
| App Review | Apple審査員からの問い合わせ、デモアカウント不備、URL不備 | P0 | 即確認、証跡保存、必要ならReview Notes更新 | `notes/41`, `notes/62` |
| 安全・危険 | 脅迫、つきまとい、危険な合流誘導、個人情報晒し | P0 | 通報受付、危険時案内、必要に応じて一時制限 | `notes/26`, `notes/34` |
| 個人情報・セキュリティ事故疑い | 他人データ表示、誤送信、RLS/Storage/secret疑い | P0 | `INC-YYYYMMDD-0001` を発行しIncidentへ | `notes/49` |
| アカウント削除 | 削除できない、削除申請、削除完了確認 | P0/P1 | アプリ内削除案内、例外時は本人確認 | `notes/45` |
| 個人情報請求 | 開示、訂正、利用停止、消去、第三者提供記録 | P0/P1 | 受付番号、本人確認、対象情報特定 | `notes/45`, `notes/52` |
| 購入・IAP | 解約、返金、復元、二重課金 | P1 | App Store購入管理を案内、実装状態を確認 | `notes/33`, `notes/34` |
| ログイン/登録 | メール確認、Apple/Googleログイン、復帰不能 | P1 | 本人確認に不要な情報を避けて案内 | `notes/34` |
| 取引相談 | 打診、合意、取引チャット、証跡、評価 | P1 | 画面と受付番号を確認、相手情報は開示しない | `notes/34`, `notes/42` |
| 不具合 | クラッシュ、表示崩れ、通知不達、リンク切れ | P1/P2 | Version、Build、端末、手順を確認 | `notes/42`, `notes/64` |
| 要望/一般質問 | 使い方、改善要望、FAQで解決可能 | P2 | FAQ誘導、必要なら要望リストへ | `notes/55` |

No-Go:
- App Review連絡を通常問い合わせとして放置する。
- 事故疑いを「不具合」として扱い、受付番号や初動記録を作らない。
- 削除請求や個人情報請求を、本人確認なしに実行する。
- パスワードや認証コードをメールで求める。

## 5. 受付番号ルール

| 種別 | 形式 | 用途 |
|---|---|---|
| 通常問い合わせ | `SUP-YYYYMMDD-0001` | 一般サポート |
| 通報・安全 | `SAFE-YYYYMMDD-0001` | 通報、安全相談、危険行為 |
| アカウント削除 | `DEL-YYYYMMDD-0001` | 削除申請、削除例外 |
| 個人情報請求 | `PRV-YYYYMMDD-0001` | 開示、訂正、利用停止、消去等 |
| 事故疑い | `INC-YYYYMMDD-0001` | 個人情報・セキュリティ事故疑い |
| App Review | `APR-YYYYMMDD-0001` | Apple審査連絡 |
| 購入/IAP | `IAP-YYYYMMDD-0001` | 購入、返金、復元 |

受付番号に個人名、メールアドレス、ユーザーIDを含めない。

## 6. 受信時チェックリスト

| Check | 確認 | 結果 |
|---|---|---|
| IN-001 | 受付番号を付与した | TODO |
| IN-002 | 分類と優先度を決めた | TODO |
| IN-003 | 受信日時と受信チャネルを記録した | TODO |
| IN-004 | 送信者にパスワード等を送らない注意を返した | TODO |
| IN-005 | 本人確認が必要か判定した | TODO |
| IN-006 | P0なら担当者へ即時共有した | TODO |
| IN-007 | 関連文書と返信テンプレートを選んだ | TODO |
| IN-008 | 実ユーザー情報やsecretを証跡に残していない | TODO |
| IN-009 | 完了予定又は次回連絡目安を決めた | TODO |

## 7. エスカレーション表

| 条件 | エスカレーション先 | 目安 |
|---|---|---|
| App Review連絡 | App Store Owner / オーナー | 当日中 |
| デモアカウント不備 | App Store Owner + 開発担当 | 当日中 |
| URL 404 / Support URL不備 | 公開URL担当 | 当日中 |
| 通報・危険行為 | Trust & Safety担当 | 24時間以内、危険時は即時 |
| 他人データ表示 | Incident Lead + 開発担当 + 法務確認 | 即時 |
| key / token / secret疑い | Incident Lead + 開発担当 | 即時 |
| アカウント削除できない | Account担当 + 開発担当 | 1営業日以内 |
| 個人情報請求 | Privacy / Legal担当 | 1営業日以内 |
| IAP返金/復元 | Billing担当 | 2営業日以内 |
| 法務判断が必要 | 弁護士確認担当 | 論点に応じて |

少人数運用では兼務してよいが、P0は記録上の担当を必ず置く。

## 8. 初回返信テンプレ選択

| 分類 | 使うテンプレート |
|---|---|
| 通常問い合わせ | `notes/34` §3 |
| ログイン/登録 | `notes/34` §4 |
| アカウント削除 | `notes/34` §5 / `notes/45` |
| 通報 | `notes/34` §6 |
| ブロック相談 | `notes/34` §7 |
| 取引相談 | `notes/34` §8 |
| 個人情報誤公開 | `notes/34` §9 / `notes/49` |
| 個人情報請求 | `notes/45` §6.3 |
| 事故疑い | `notes/49` §8 |
| App Review指摘 | `notes/41` |

返信で言わないこと:
- 相手方ユーザーの処分内容。
- 内部判定、内部スコア、AI判定の詳細。
- 「漏えいはありません」など、確認前の断定。
- Megrumがユーザー間交換を保証するような表現。
- パスワード、認証コード、secretの送付依頼。

## 9. 記録フォーマット

```text
Ticket:
Received at:
Channel:
Sender:
Category:
Priority:
Owner:
Related user/account:
Related trade/proposal/content:
Summary:
Requested action:
Sensitive data included: No / Yes
Immediate risk: No / Yes
Template used:
Escalated to:
Next response due:
Status: Open / Waiting / Escalated / Closed
Evidence folder:
```

注意:
- `Sender` には公開リポジトリで使う場合、メールアドレス実値を書かない。
- `Related user/account` は内部運用台帳だけに記録し、公開docsには要約のみ残す。
- `Sensitive data included: Yes` の場合、保存先と閲覧者を制限する。

## 10. P0専用初動

P0に該当したら、通常返信より先に次を行う。

| Step | 作業 | 完了条件 |
|---|---|---|
| P0-001 | 受付番号を発行 | `SAFE` 又は `INC` が付く |
| P0-002 | 事実と未確認を分ける | 推測で断定しない |
| P0-003 | 証跡を安全な場所へ保存 | secretや実パスワードを保存しない |
| P0-004 | 担当へ即時共有 | Incident Lead / Trust & Safety / 開発担当 |
| P0-005 | 拡大防止が必要か判定 | 一時非表示、制限、key更新等 |
| P0-006 | 本人通知/PPC報告要否を法務確認へ | `notes/49` へ接続 |
| P0-007 | App Store提出/公開を止めるか判断 | `notes/50` へ反映 |

## 11. 日次確認

審査中又は公開初日は、最低限次を見る。

| 項目 | 頻度 | No-Go |
|---|---|---|
| `support@megrum.jp` 未返信P0 | 1日2回以上 | P0未返信 |
| App Review / Apple連絡 | 1日2回以上 | 審査連絡の見落とし |
| アカウント削除 | 1日1回以上 | 削除できない問い合わせ放置 |
| 個人情報請求 | 1日1回以上 | 受付番号なし |
| 通報・安全 | 1日1回以上 | 危険相談放置 |
| 公開URL不備 | 1日1回以上 | Support/Privacy URL不通 |
| 事故疑い | 随時 | Incident未起票 |

## 12. App Store提出前チェック

| Check | 確認 | 結果 |
|---|---|---|
| SUP-001 | `support@megrum.jp` の受信と返信ができる | TODO |
| SUP-002 | App Review連絡の確認担当が決まっている | TODO |
| SUP-003 | P0分類と受付番号ルールが決まっている | TODO |
| SUP-004 | 通報、安全、事故疑いのエスカレーション先が決まっている | TODO |
| SUP-005 | アカウント削除、個人情報請求の本人確認手順が決まっている | TODO |
| SUP-006 | `notes/34` のテンプレートを使える | TODO |
| SUP-007 | `notes/49` のIncident初動へ接続できる | TODO |
| SUP-008 | パスワード、認証コード、secretを受け取らない案内がある | TODO |
| SUP-009 | 証跡保存先と閲覧制限が決まっている | TODO |
| SUP-010 | 公開Support URLから問い合わせ先、削除、通報、Privacy請求へ辿れる | TODO |

No-Go:
- サポートメールが受信できない。
- App Review連絡を確認する担当がいない。
- P0を通常問い合わせと同じ返信期限で扱う。
- 個人情報請求や事故疑いの保存先が未決。

## 13. 関連文書

- サポート返信テンプレート: `notes/34_support_response_templates.md`
- 公開法務・サポートページ: `notes/25_public_legal_support_pages.md`
- 公開ヘルプFAQ: `notes/55_public_help_faq_draft.md`
- アカウント削除・個人情報請求: `notes/45_account_deletion_privacy_request_runbook.md`
- 個人情報・セキュリティ事故初動: `notes/49_privacy_security_incident_response_runbook.md`
- Trust & Safety SOP: `notes/26_trust_safety_release_sop.md`
- ドメイン・メール・公開URL運用: `notes/47_domain_email_publication_runbook.md`
- App Review指摘対応: `notes/41_app_review_response_templates.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`

## 14. 公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Offering account deletion in your app: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- 個人情報保護委員会 漏えい等の対応とお役立ち資料: https://www.ppc.go.jp/personalinfo/legal/leakAction/
- 個人情報保護委員会 漏えい等報告・本人への通知の義務化: https://www.ppc.go.jp/news/kaiseihou_feature/roueitouhoukoku_gimuka/
