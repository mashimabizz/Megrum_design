# 60. App Storeローカライズ・メタデータQA

最終更新: 2026-05-31

ステータス: Draft v0.1（提出前・入力前）

## 目的

App Store Connectへ入力する日本語メタデータ、English (U.S.) 追加候補、Review Notes、スクリーンショット、公開URLの説明が、完成ビルドと矛盾しないかを確認する。

この文書はQA台帳であり、コード、ローカライズファイル、App Store Connect設定、公開URLは変更しない。

## 1. 初回提出の方針

| 項目 | 方針 |
|---|---|
| Primary Language | Japanese |
| English (U.S.) | 初回は後回しでも可。ただしReview Notesは英語で用意する |
| App Store説明文 | 日本語を正とする |
| Review Notes | 英語で審査員が辿れる説明を用意する |
| 公開URL | 日本語ページでよいが、Support/Privacy/Termsの役割が分かる構成にする |
| スクリーンショット | 日本語UIでよい。実在IP、実住所、内部ID、debug表示を含めない |

## 2. 日本語メタデータQA

| 欄 | 現在の下書き | QA |
|---|---|---|
| Name | Megrum | 30文字以内。表記ゆれなし |
| Subtitle | 推し活グッズを安心交換 | 初回スコープと一致。過剰保証に見えないか確認 |
| Promotional Text | イベント現地でのグッズ交換を、在庫・Wish・打診・取引チャットでスムーズに管理できます。 | 初回で現地交換MVPを出す場合は可 |
| Description | `notes/40` の初回最小スコープ版 | グルーム/掲示板を隠す場合は該当段落を削る |
| Keywords | 推し活,グッズ交換,KPOP,アニメ,トレカ,交換,イベント,コレクション,Wish | 100 bytes以内、実在IP/他社名なし |
| Privacy Policy URL | `https://megrum.jp/legal/privacy` | 200応答、ログイン不要 |
| Support URL | `https://megrum.jp/support` | 200応答、FAQ/削除/通報へ辿れる |

## 3. English (U.S.) 追加候補QA

English (U.S.) を初回で追加する場合、次を使う。追加しない場合も、Review Notesとの表現差を確認する。

| 欄 | 候補 | QA |
|---|---|---|
| Name | Megrum | 日本語版と同じ |
| Subtitle | Trade fan goods safely | 安全を保証する印象が強い場合は `Organize fan goods trades` へ変更候補 |
| Promotional Text | Organize fan goods, wishlists, proposals, and trade chats for smoother in-person exchanges. | in-person exchangesが初回スコープと一致 |
| Keywords | fan goods,trade,kpop,anime,photocard,collectibles,event,wishlist | 100 bytes以内、他社名なし |

### English Description 候補

初回最小スコープ用:

```text
Megrum is an app for fans who want to exchange K-pop, anime, event, and collectible goods in person.
Register items you have and items you want, send proposals to people with matching conditions, and manage the flow from negotiation to trade chat, proof, and ratings.

Main features:
- Register items you can trade
- Manage your wishlist
- Find potential trade matches
- Send and receive proposals
- Negotiate and agree on trade conditions
- Use trade chat for the final in-person exchange
- Reporting, blocking, and support flows

Megrum helps users coordinate user-to-user exchanges. Sales, ticket resale, stolen goods, counterfeit items, rights-infringing items, and uses that violate laws or the Terms of Service are prohibited.
```

削る条件:
- グルーム/掲示板を隠す場合、community featureの説明を入れない。
- 有料機能を隠す場合、premium/boost/IAPを入れない。
- 外部AIを隠す場合、AI-assistedを入れない。
- 未完成3Dを隠す場合、3D/avatarを入れない。

## 4. Review Notes英語QA

Review Notesは、App Store Connectの審査員向け説明として英語で用意する。

| 項目 | 必須 | QA |
|---|---|---|
| App purpose | Yes | goods exchange app for fan communitiesと説明 |
| Account reason | Yes | inventory, wishlist, proposal, trade chat, reporting, deletionに必要と説明 |
| Demo account | Yes | 実パスワードはApp Store Connectだけに入力 |
| Review path | Yes | 実機で辿れる順番にする |
| Paid features | 条件付き | 隠すならnot enabled、出すならIAP経路を説明 |
| External AI | 条件付き | 隠すならnot enabled、出すなら送信前説明を説明 |
| UGC safety | Yes | reporting/blocking/moderationを説明 |
| Account deletion | Yes | Settingsから辿れる説明 |
| Public URLs | Yes | Support/Privacy/Termsがログイン不要と説明 |

No-Go:
- Review Notesに、完成ビルドで辿れない画面名を書く。
- 有料機能や外部AIを隠すのに、enabledのように読める文章が残る。
- Demo accountの実パスワードをリポジトリに書く。

## 5. スクリーンショット日英整合

| スクショ | 日本語UIで見ること | English説明と矛盾しないか |
|---|---|---|
| Home | 現地交換MVPの導線が分かる | in-person exchange説明と一致 |
| Inventory | 在庫登録が見える | item registration説明と一致 |
| Wish | wishが見える | wishlist説明と一致 |
| Proposal | 打診/条件調整が見える | proposal/negotiation説明と一致 |
| Trade Chat | 取引チャットが見える | trade chat説明と一致 |
| Safety | 通報/ブロック/問い合わせが見える | reporting/blocking説明と一致 |
| Settings | Terms/Privacy/Support/Deleteが見える | public URL/account deletion説明と一致 |

No-Go:
- 日本語UIに出ていない機能を英語説明だけで訴求する。
- スクショに未完成機能、実在IP、実住所、内部ID、debug表示がある。

## 6. 公開URL日英整合

| URL | 日本語ページでの要件 | 英語Review Notesでの説明 |
|---|---|---|
| `/support` | 問い合わせ、FAQ、削除、通報、Privacy請求へ辿れる | Support page is public without sign-in |
| `/legal/privacy` | App Privacy回答と一致 | Privacy Policy URL is public |
| `/legal/terms` | 初回スコープと一致 | Terms URL is public |
| `/support/faq` | 初回で見える機能だけ説明 | FAQ page is public |
| `/support/account-deletion` | アプリ内削除導線と一致 | Account deletion help is public |
| `/support/report` | UGC安全導線と一致 | Reporting/blocking help is public |

## 7. byte/文字数チェック

提出前に確認する。

| 項目 | 制限 | 確認 |
|---|---|---|
| App Name | 30文字以内 | TODO |
| Subtitle | 30文字以内 | TODO |
| Promotional Text | 170文字以内 | TODO |
| Description | 4000文字以内 | TODO |
| Keywords | 100 bytes以内 | TODO |
| Review Notes | 実際の入力欄で読みやすい長さ | TODO |

## 8. 監査結果フォーマット

| 項目 | 値 |
|---|---|
| 監査日 | TODO |
| 監査者 | TODO |
| App Version / Build | TODO |
| Primary Language | TODO |
| English (U.S.) 追加有無 | TODO |
| 日本語メタデータ | Pass / Conditional / Fail |
| 英語メタデータ | Pass / Conditional / Fail |
| Review Notes | Pass / Conditional / Fail |
| スクショ | Pass / Conditional / Fail |
| 公開URL | Pass / Conditional / Fail |
| 修正が必要な欄 | TODO |

## 9. 関連文書

- App Store Connect入力ワークシート: `notes/31_app_store_connect_metadata_worksheet.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- スクリーンショット台本: `notes/28_app_store_screenshot_storyboard.md`
- 公開URL公開チェックリスト: `notes/37_public_url_publication_checklist.md`
- 初回提出スコープ露出監査: `notes/59_initial_release_scope_exposure_audit.md`
- App Review指摘対応テンプレート: `notes/41_app_review_response_templates.md`
