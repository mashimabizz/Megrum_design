# 37. 公開URL公開チェックリスト

> 目的：App Store Connectへ入力するサポートURL、プライバシーポリシーURL、利用規約URL、特商法ページ、削除/通報/個人情報請求ページを、提出前に公開できる状態へ整理する。
> コード変更なし。公開作業そのものは別セッションで行う。

最終更新: 2026-05-31
ステータス: Draft v0.1（公開前）

---

## 1. 公開必須URL

| URL | App Store提出上の役割 | 初回提出 | 原稿 |
|---|---|---|---|
| `https://megrum.jp/support` | Support URL | 必須 | `notes/25` |
| `https://megrum.jp/legal/privacy` | Privacy Policy URL | 必須 | `notes/legal/02_privacy_policy_draft.md` |
| `https://megrum.jp/legal/terms` | 利用規約 | 必須 | `notes/legal/01_terms_of_service_draft.md` |
| `https://megrum.jp/legal/commerce` | 特商法表示 | 有料機能を出すなら必須 | `notes/25` / `notes/17` |
| `https://megrum.jp/support/account-deletion` | アカウント削除ヘルプ | 必須 | `notes/25` |
| `https://megrum.jp/support/privacy-request` | 個人情報請求 | 必須 | `notes/25` |
| `https://megrum.jp/support/report` | 通報・ブロック・安全 | UGCを出すなら必須 | `notes/25` |
| `https://megrum.jp/support/ai` | AI機能説明 | AI機能を出すなら必須 | `notes/25` |
| `https://megrum.jp/support/faq` | よくある質問 | 必須 | `notes/55` |

提出時にApp Store Connectへ直接入力するのは、少なくともPrivacy Policy URLとSupport URL。利用規約、特商法、アカウント削除、通報、個人情報請求は、アプリ内リンクとサポートページから辿れる状態にする。

---

## 2. 公開ページ共通要件

| 要件 | 合格条件 |
|---|---|
| ログイン不要 | 未ログインブラウザで開ける |
| HTTPS | 証明書エラーが出ない |
| 200応答 | 404、500、Basic認証、工事中ではない |
| モバイル表示 | iPhone幅で横スクロールなし |
| 連絡先 | `support@megrum.jp` が表示されている |
| 最終更新日 | ページ内に日付がある |
| アプリ内導線 | 設定、法務、ヘルプから辿れる |
| 内容一致 | 実ビルドで出す機能と矛盾しない |
| 不要情報 | 実パスワード、内部ID、実住所、秘密鍵を含まない |

---

## 3. ページ別受け入れ基準

### 3.1 サポートトップ

必須:
- 問い合わせ先
- 受付時間又は返信目安
- アカウント、取引、安全、個人情報、購入、AI、不具合のカテゴリ
- 利用規約、プライバシーポリシー、アカウント削除、通報、個人情報請求へのリンク

No-Go:
- 問い合わせ先がない
- サポートURLがアプリ紹介だけで、問題解決先になっていない
- ログインしないと見られない

### 3.2 プライバシーポリシー

必須:
- 取得する情報
- 利用目的
- 第三者提供/委託
- 外部AI利用時の扱い
- App Privacy回答と矛盾しない説明
- 個人情報請求窓口

No-Go:
- 位置情報、写真、通知、購入、AIの扱いが実装と矛盾する
- 問い合わせ先がない

### 3.3 利用規約

必須:
- ユーザー間取引の位置付け
- 禁止事項
- 通報/ブロック/アカウント制限
- 有料機能を出す場合の決済/返金/解約
- AI結果の非保証
- 退会/アカウント削除

No-Go:
- 旧用語が残っている
- 初回ビルドで存在しない機能を断定的に書いている

### 3.4 特商法表示

有料機能を初回提出で出す場合は必須。有料機能を隠す場合も、将来公開用の下書きを残す。

必須:
- サービス名
- 販売事業者
- 連絡先メール
- 販売価格
- 支払方法
- 提供時期
- 解約
- 返金
- 動作環境
- 代表者名、住所、電話番号を非公表にする場合の個別開示方針

No-Go:
- App Store Connectの価格と異なる
- 請求時の開示フローがない

### 3.5 アカウント削除

必須:
- アプリ内削除導線
- 削除対象
- 保存が続く情報
- 有料サブスクリプションは別途解約が必要という説明
- アプリ内で削除できない場合の窓口

No-Go:
- サポートへメールするしかない説明になっている
- アプリ内削除導線と説明が矛盾している

### 3.6 通報・安全

必須:
- 通報対象
- ブロック説明
- 通報後の流れ
- 緊急時は会場スタッフ、施設管理者、警察等へ相談する案内
- 虚偽通報の禁止

No-Go:
- UGCがあるのに通報先がない
- 相手方への処分を必ず開示すると書いている

### 3.7 AI機能説明

AI機能を初回提出で出す場合は必須。外部AIを出さない場合はサポートトップから隠す選択も可。

必須:
- AIの用途
- AI結果は補助であること
- 外部AIへ送る情報
- 学習利用の有無
- ユーザーが修正できること

No-Go:
- 外部AIへ送る情報が不明
- AI結果の正確性を保証している

---

## 4. 公開作業チェック

| # | 作業 | 完了 |
|---|---|---|
| 1 | `megrum.jp` の公開先を決める | 未 |
| 2 | `support@megrum.jp` の受信を確認 | 未 |
| 3 | サポートトップを公開 | 未 |
| 4 | 利用規約を公開 | 未 |
| 5 | プライバシーポリシーを公開 | 未 |
| 6 | 特商法表示を公開又は有料機能非表示を確認 | 未 |
| 7 | アカウント削除ヘルプを公開 | 未 |
| 8 | 個人情報請求ページを公開 | 未 |
| 9 | 通報・安全ページを公開 | 未 |
| 10 | AI機能説明ページを公開又はAI非表示を確認 | 未 |
| 11 | App Store ConnectへPrivacy Policy URLを入力 | 未 |
| 12 | App Store ConnectへSupport URLを入力 | 未 |
| 13 | 完成ビルドのアプリ内リンクから開けるか確認 | 未 |
| 14 | FAQを公開し、Supportトップから辿れるか確認 | 未 |
| 15 | 証跡を `notes/36` の形式で残す | 未 |

---

## 5. 確認コマンド案

公開後にPCで確認する場合:

```bash
curl -I https://megrum.jp/support
curl -I https://megrum.jp/legal/privacy
curl -I https://megrum.jp/legal/terms
curl -I https://megrum.jp/legal/commerce
curl -I https://megrum.jp/support/account-deletion
curl -I https://megrum.jp/support/privacy-request
curl -I https://megrum.jp/support/report
curl -I https://megrum.jp/support/ai
curl -I https://megrum.jp/support/faq
```

合格:
- `HTTP/2 200` 又は `HTTP/1.1 200`
- `content-type` がHTML
- リダイレクトがある場合、最終的に200へ到達

---

## 6. App Review Notes補足文

```
Terms, Privacy Policy, Support, account deletion help, privacy request help, and reporting/blocking help are publicly available without sign-in.
Support URL: https://megrum.jp/support
Privacy Policy URL: https://megrum.jp/legal/privacy
```

有料機能を出す場合:

```
Commerce disclosure for paid features is available at https://megrum.jp/legal/commerce.
```

---

## 7. 関連文書

- 公開ページ文面: `notes/25_public_legal_support_pages.md`
- 公開ヘルプFAQ下書き: `notes/55_public_help_faq_draft.md`
- サポート返信テンプレート: `notes/34_support_response_templates.md`
- 提出証跡: `notes/36_submission_evidence_checklist.md`
- App Store提出パック: `notes/24_app_store_submission_pack.md`
- ドメイン・メール・公開URL運用ランブック: `notes/47_domain_email_publication_runbook.md`
