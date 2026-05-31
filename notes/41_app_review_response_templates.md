# 41. App Review指摘対応テンプレート

> 目的：App Reviewで指摘が来たときに、慌てず分類・修正・返信・再提出できるようにする。
> コード変更なし。Resolution Center返信の下書きとして使う。

最終更新: 2026-05-31
ステータス: Draft v0.1（未提出）

---

## 1. 基本方針

Appleから指摘が来たら、まず次を記録する。

| 項目 | 記録 |
|---|---|
| 受信日時 | TODO |
| Guideline番号 | TODO |
| Appleの本文 | TODO |
| 指摘画面 | TODO |
| メタデータ修正で済むか | TODO |
| コード修正が必要か | TODO |
| 再提出に新ビルドが必要か | TODO |
| 証跡保存先 | TODO |

対応順:
1. Appleの本文をそのまま保存する。
2. 指摘Guidelineを分類する。
3. 実際に再現する。
4. メタデータ、公開URL、Review Notes、スクショ、コードのどれで直すか分ける。
5. 修正証跡を残す。
6. Resolution Centerへ簡潔に返信する。
7. 必要に応じてResubmit to App Reviewを行う。

---

## 2. 共通返信フォーマット

```
Thank you for reviewing Megrum.

We reviewed the issue and made the following changes:
- [Change 1]
- [Change 2]

How to verify:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Additional notes:
- [If applicable, demo account / URL / feature scope]

Thank you.
```

日本語で内部メモを書く場合:

```
指摘:
修正:
確認手順:
証跡:
再提出に新ビルドが必要:
```

---

## 3. Guideline 2.1 App Completeness

想定指摘:
- デモアカウントでログインできない。
- URLが404。
- プレースホルダー、未完成画面、デバッグ表示がある。
- 主要機能がクラッシュする。
- IAPが見えるが動かない。

先に確認:
- `notes/35` のデモアカウントでログインできるか。
- `notes/37` の公開URLが200応答か。
- TestFlight/提出ビルドで同じ問題が再現するか。
- App Store ConnectのReview Notesが最新か。

返信テンプレート:

```
Thank you for the feedback.

We resolved the app completeness issue by updating the submitted build and/or metadata.

Changes made:
- Confirmed the demo account is active and can sign in.
- Confirmed the Terms, Privacy Policy, and Support URLs are publicly accessible without sign-in.
- Removed or disabled unfinished screens/features from the submitted build.
- Updated Review Notes with the correct review path.

How to verify:
1. Sign in with the demo account provided in App Store Connect.
2. Open Settings > Terms / Privacy / Contact.
3. Follow the review path in the Review Notes.
```

証跡:
- デモアカウントログイン
- URL 200応答
- 該当画面スクショ
- Review Notes最終版

---

## 4. Guideline 1.2 User-Generated Content

想定指摘:
- UGCがあるのに通報機能が見つからない。
- ブロック機能が見つからない。
- 公開連絡先がない。
- モデレーション方針が不明。

先に確認:
- プロフィール、グッズ、グルーム、掲示板、取引チャットの通報入口。
- ブロック入口。
- `support@megrum.jp` とサポートURL。
- `notes/26` の運用SOP。

返信テンプレート:

```
Thank you for the feedback.

Megrum includes user-generated content, and we provide moderation and safety controls.

Changes/clarifications:
- Users can report inappropriate content or users from the relevant profile/content screens.
- Users can block abusive users where user interaction is available.
- Public support contact information is available at https://megrum.jp/support.
- Our support and moderation process is documented and available for user reports.

How to verify:
1. Sign in with the demo account.
2. Open a user profile or UGC screen.
3. Open the report/block entry point.
4. Open Settings > Contact or https://megrum.jp/support.
```

証跡:
- 通報入口スクショ
- ブロック入口スクショ
- サポートURL
- 通報受付の運用メモ

---

## 5. Privacy / App Privacy / Account Deletion

想定指摘:
- App Privacy回答と実装が一致しない。
- Privacy Policy URLが不完全。
- アカウント削除がアプリ内にない。
- 外部AIやSDKのデータ利用説明が不足。

先に確認:
- `notes/27` のApp Privacy照合。
- `notes/legal/02_privacy_policy_draft.md`。
- `notes/25` のアカウント削除ヘルプ。
- 実ビルドの設定画面から削除入口があるか。

返信テンプレート:

```
Thank you for the feedback.

We reviewed the privacy-related issue and updated the relevant information.

Changes made:
- Updated App Privacy answers to match the data collected by the submitted build.
- Confirmed the Privacy Policy URL is publicly accessible.
- Confirmed users can start account deletion in the app.
- Clarified data handling for [location/photos/user content/purchases/AI if applicable].

How to verify:
1. Open https://megrum.jp/legal/privacy.
2. Sign in with the demo account.
3. Open Settings > Account deletion.
4. Review the in-app explanation and deletion entry point.
```

証跡:
- App Privacy回答控え
- Privacy Policy URL
- アカウント削除入口
- PrivacyInfo.xcprivacy確認

---

## 6. Guideline 3.1.1 In-App Purchase

想定指摘:
- デジタル機能の購入にIAPを使っていない。
- IAP商品が見えるがApp Store Connectで未設定。
- IAPが審査員から見つけられない。
- 復元導線がない。

初回提出の最短対応:
- 有料機能を出さない方針なら、購入導線と価格表示を隠す。
- 有料機能を出す方針なら、`notes/33` のIAP商品、復元、Sandbox購入、特商法、App Privacyをそろえる。

返信テンプレート（隠す場合）:

```
Thank you for the feedback.

Paid features are not enabled in this submitted build.
We removed/disabled the paid feature entry points and any price or purchase UI from the app and metadata.

How to verify:
1. Sign in with the demo account.
2. Navigate through Settings and the main feature screens.
3. Confirm no paid feature purchase UI is available in this build.
```

返信テンプレート（IAPを出す場合）:

```
Thank you for the feedback.

We updated the In-App Purchase setup and review information.

Changes made:
- Configured the relevant In-App Purchase products in App Store Connect.
- Confirmed the purchase entry points are visible in the app.
- Confirmed purchase restoration is available.
- Updated Review Notes with the path to review the IAP.

How to verify:
1. Sign in with the demo account.
2. Open [paid feature screen].
3. Open the purchase screen.
4. Use the restore purchase option from Settings.
```

証跡:
- IAP商品ステータス
- 購入画面
- 復元入口
- 特商法ページ
- App Privacy Purchases回答

---

## 7. Physical Goods / Digital Goods整理

想定指摘:
- グッズ交換アプリなので、物理商品の売買や決済と誤解された。
- ブースト等のデジタル機能と物理グッズの交換が混同された。

返信テンプレート:

```
Thank you for the feedback.

Megrum does not sell physical goods directly and does not process payments for physical goods in the app.
The app provides matching, proposal, negotiation, and trade chat tools for user-to-user goods exchanges.

If paid app functionality is enabled, it is limited to digital app features and uses Apple's In-App Purchase where required.
```

証跡:
- App説明文
- Review Notes
- アプリ内に物理商品決済がない画面
- IAP商品がデジタル機能だけであること

---

## 8. Metadata / Screenshots

想定指摘:
- スクショに未完成機能が写っている。
- スクショや説明文と実ビルドが違う。
- 実在IPや権利物が写っている。
- URLや説明文が不正確。

返信テンプレート:

```
Thank you for the feedback.

We updated the metadata and screenshots to match the submitted build.

Changes made:
- Removed references to features not available in this build.
- Replaced screenshots with images using fictional sample data only.
- Removed any real artist, character, address, internal ID, or debug information.
- Confirmed Support and Privacy URLs are publicly accessible.
```

証跡:
- 新スクショ一式
- 説明文最終版
- 削除した機能表現の差分

---

## 9. AI機能

想定指摘:
- AIへ送るデータが説明されていない。
- AI出力が保証されているように見える。
- Privacy Policy / App Privacyと実装が一致しない。

初回提出の最短対応:
- 外部AIを出さないなら、AIボタン、AI処理画面、AI説明を隠す。
- 出すなら送信前説明、送信情報、利用目的、学習利用の有無、ユーザー修正導線をそろえる。

返信テンプレート（隠す場合）:

```
Thank you for the feedback.

External AI processing is not enabled in this submitted build.
We removed/disabled external AI entry points and updated Review Notes and metadata accordingly.
```

返信テンプレート（出す場合）:

```
Thank you for the feedback.

We clarified the AI-assisted feature in the app and privacy materials.

Changes made:
- Added pre-transmission disclosure for external AI processing.
- Clarified what information is sent and the purpose of processing.
- Clarified that AI output is assistive and users can review and edit results.
- Updated the Privacy Policy and App Privacy answers to match the submitted build.
```

---

## 10. Public URLs

想定指摘:
- Support URL / Privacy Policy URLが開けない。
- ログインが必要。
- 工事中、空ページ、仮文言が残っている。

返信テンプレート:

```
Thank you for the feedback.

We fixed the public URL issue.

The following URLs are publicly accessible without sign-in:
- Support: https://megrum.jp/support
- Privacy Policy: https://megrum.jp/legal/privacy
- Terms: https://megrum.jp/legal/terms
- Account deletion help: https://megrum.jp/support/account-deletion
```

証跡:
- `curl -I` 結果
- モバイルブラウザ表示
- App Store Connect入力値

---

## 11. 再提出チェック

Guidelineごとの提出前・再提出前の証跡確認は `notes/53_app_review_guideline_compliance_matrix.md` を使う。

| チェック | 完了 |
|---|---|
| Appleの本文を保存した | 未 |
| Guidelineを分類した | 未 |
| 修正方針を決めた | 未 |
| 新ビルドが必要か判断した | 未 |
| メタデータ修正を反映した | 未 |
| 公開URLを再確認した | 未 |
| Review Notesを更新した | 未 |
| 証跡を `notes/36` 形式で残した | 未 |
| Resubmit to App Reviewを実行した | 未 |

---

## 12. 公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple Manage unresolved issues: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/manage-a-submission-with-unresolved-issues
- Apple Submit an In-App Purchase: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/
- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
