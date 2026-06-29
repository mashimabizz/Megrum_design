# 37. 公開URL公開チェックリスト

> 目的：App Store Connectへ入力するサポートURL、プライバシーポリシーURL、利用規約URL、特商法ページ、削除/通報/個人情報請求ページを、提出前に公開できる状態へ整理する。
> コード変更なし。公開作業そのものは別セッションで行う。

最終更新: 2026-06-29
ステータス: Draft v0.6（Keychain・session保存・最新法務ドラフト / UGC・App Review 1.2 / App Store評価・公開レビュー返信 / 漏えい等初動・事故疑い / 広告宣伝メール・販促通知 / 公式連絡・フィッシング / 公開Web / アプリ内法務表示の実装同期監査を反映・公開前）

---

## 0. 現行実装同期監査（2026-06-29）

2026-06-29時点の読み取り確認では、公開予定URLと現行実装に差分がある。コード変更禁止のため、この文書では提出前No-Goとして記録する。

| 対象 | 現行実装で確認した状態 | 提出前の扱い |
|---|---|---|
| `web/src/app/terms/page.tsx` | 実装済みルートは `/terms`。ページ内更新日は `2026年6月26日`。現行法務ドラフト全文ではなく短縮Terms。2026-06-29追加のKeychain/session保存、認証リンク、写真メタデータ、AdMob/ATT、候補表示非保証、外部AI/顔候補付け、UGC・App Review 1.2、App Store評価・公開レビュー返信、漏えい等初動・事故疑い、広告宣伝メール・販促通知、公式連絡・フィッシング、SLA非保証、責任上限等は反映未確認 | App Store / アプリ内リンク / 公開URL方針を `/terms` に合わせて全文へ同期するか、`/legal/terms` を公開し `/terms` から同じ本文へ到達させるまでNo-Go |
| `web/src/app/privacy/page.tsx` | 実装済みルートは `/privacy`。ページ内更新日は `2026年6月26日`。現行法務ドラフト全文ではなく短縮Privacy。Keychain/session保存、access token、refresh token、認証callback fragment、通知linkPath、精密位置、写真メタデータ、外部AI/web_search、AdMob/ATT、公開レビュー返信、漏えい等初動、販促同意/停止履歴、不審連絡/フィッシング報告等は反映未確認。現在地共有/服装写真について30日削除又は非表示を強く読める文言が残る | App StoreのPrivacy Policy URL、公開文書、アプリ内同意リンク、App Privacy回答と同期し、最新Privacyの取得情報/利用目的/外部送信/保持削除、30日削除/非表示を「運用目標・反映遅延あり・保証なし」へ修正するまでNo-Go |
| `web/src/app/support/page.tsx` | 実装済みルートは `/support`。関連リンクは `/privacy` と `/terms`。個別の `/support/account-deletion`、`/support/privacy-request`、`/support/report`、`/support/ai`、`/support/faq`、`/support/ads` は未確認 | 個別URLをApp Store文面やReview Notesへ書く場合、公開実装、アンカー、又はリダイレクト確認までNo-Go。Supportから旧短縮Terms/Privacyだけへ誘導しない |
| `ios-native/Sources/MegrumApp/AuthLegalConsentNotice.swift` | 登録同意文は `https://megrum.jp/terms` と `https://megrum.jp/privacy` へリンクする | 公開正URLを `/legal/*` にするなら、完成ビルド側のリンク更新又は公開リダイレクト方針が必要 |
| `ios-native/Sources/MegrumApp/LegalDocumentContent.swift` / `SettingsLegalViews.swift` | アプリ内法務表示は要約であり、正式本文ではない旨を表示している | アプリ内要約と公開本文が矛盾しないかを確認。要約だけを正式規約として扱わない |
| `ios-native/App/PrivacyInfo.xcprivacy` | `NSPrivacyTracking=false` とUserDefaults Required Reason APIのみ | Privacy ManifestだけでApp Privacy回答が完結するわけではない。App Store Connect回答、公開Privacy、SDK/通信監査の一致を別途確認 |
| `ios-native/Config/MegrumNative.xcconfig` / AdMob | `MEGRUM_ADS_ENABLED=YES`、AdMob app id、`MEGRUM_ADMOB_TEST_ADS_ENABLED=YES`、検索native/やりとりbanner unit idあり。`NSUserTrackingUsageDescription`、ATT要求、UMP同意管理は未確認 | 広告を出す場合は公開Privacy/Support/Review Notes/App Privacy/Privacy Manifest/ATT/Google公式開示/test ads除去を一致させる。広告を出さない場合はSDK初期化/広告リクエストが発生しないことを確認するまでNo-Go |

No-Go:
- App Store Connectに `https://megrum.jp/legal/privacy` を入力する一方で、実際に公開済みなのが `https://megrum.jp/privacy` の旧短縮ページだけである。
- 登録同意画面が `/terms` / `/privacy` を指す一方で、審査提出文書や公開チェックリストが `/legal/terms` / `/legal/privacy` を正としている。
- 2026-06-29版の規約・プライバシーポリシーで追加した、Keychain/session保存、access token、refresh token、認証callback、通知linkPath、精密位置、写真メタデータ、共有シート、郵送交換、会員間支払い情報、顔候補付け、外部AI/web_search、AdMob/ATT/test ads、通知、年齢/性別/活動エリア、評価/通報/削除申出等が公開Web本文に反映されていない。
- 2026-06-29版の規約・プライバシーポリシーで追加した、UGC・App Review 1.2、App Store評価・公開レビュー返信、漏えい等初動・事故疑い、広告宣伝メール・販促通知、公式連絡・フィッシング、サポートSLA・専門助言非保証、責任上限・存続条項が公開Web本文に反映されていない。
- 現在地共有又は服装写真について、30日後の自動削除、完全削除、即時反映を未確認のまま公開Web、FAQ、Review Notes、App Privacy説明で保証している。
- 存在しない個別サポートURLをReview Notes、FAQ、App Store説明、サポート返信に書く。

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

公開前に、内部情報、secret、未確定機能、未確定価格、実データが混ざっていないかは `notes/63_public_page_redaction_qa.md` でも確認する。
弁護士レビュー回答を反映してから公開する場合は、`notes/66_legal_review_publication_runbook.md` でTerms、Privacy、Support、FAQ、App Store文面、App Privacyへの反映漏れを確認する。

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
- 顔候補付けを出す場合の扱い、Face ID非利用、Sensitive Info候補
- Keychain/session保存、access token、refresh token、認証callback、通知linkPath、端末復元/バックアップ/他端末session、ログアウト/退会後の即時完全失効非保証
- App Privacy回答と矛盾しない説明
- 個人情報請求窓口
- 公開レビュー返信、事故疑い、販促同意/停止履歴、不審連絡/フィッシング報告、通報/削除申出の記録

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
- Keychain/session管理、認証リンク/認証コード/callback URLの秘密性、候補表示/検索/位置/安全/取引の非保証
- UGC・App Review 1.2、公開レビュー返信、事故疑い時の一時制限と責任非承認、販促通知の同意/停止、公式連絡で秘密情報を求めないこと
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
- 有料導線が見える場合、購入ボタン、復元ボタン、価格、StoreKit商品、App Store Connect価格、IAP Availability、サーバー検証、返金/取消/期限切れ同期、Privacy/App Privacyとの一致

No-Go:
- App Store Connectの価格と異なる
- 請求時の開示フローがない
- アプリ内の特定商取引法に基づく表記要約又は設定内入口だけで、ログイン不要の正式な公開特商法ページを公開済みとして扱う
- メグルムプラスの購入ボタン、復元ボタン、価格、特典説明又は状態表示が見えるのに、IAP/特商法/App Privacy/サーバー検証/返金取消同期が未整備

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
- 画面内に直接通報ボタンがない対象の連絡方法
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
- 外部AIへ送る情報、OpenAI等の送信先、画像又は画像URL、web search利用
- 学習利用、保持、濫用監視ログ、削除可否
- ユーザーが修正できること
- 第三者の顔、未成年者、住所、チケット、注文履歴、QRコード、秘密情報、権利未処理画像を送らないこと
- 顔候補付けを出す場合、本人確認/Face IDではないこと、第三者画像禁止、顔特徴量又は画像特徴量の保存・外部送信・削除方法、学習データ追加可否

No-Go:
- 外部AIへ送る情報、OpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否が不明
- AI結果の正確性を保証している
- 顔候補付けを本人確認、年齢確認、Face ID認証、出入場管理、真贋鑑定、信用判断のように見せている

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
| 10 | AI機能説明ページを公開又はAI/顔候補付け非表示を確認 | 未 |
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
- 公開ページレダクションQA: `notes/63_public_page_redaction_qa.md`
- 法務レビュー後公開文面最終化Runbook: `notes/66_legal_review_publication_runbook.md`
- サポート返信テンプレート: `notes/34_support_response_templates.md`
- 提出証跡: `notes/36_submission_evidence_checklist.md`
- App Store提出パック: `notes/24_app_store_submission_pack.md`
- ドメイン・メール・公開URL運用ランブック: `notes/47_domain_email_publication_runbook.md`
