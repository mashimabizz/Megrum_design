# 59. 初回提出スコープ露出監査表

最終更新: 2026-05-31

ステータス: Draft v0.1（完成ビルド確認前）

## 目的

App Store初回提出ビルドで「出す機能」と「隠す機能」が、アプリ画面、App Storeメタデータ、スクリーンショット、公開FAQ、利用規約、プライバシーポリシー、App Privacy、Review Notesで一致しているかを確認する。

この文書は監査表であり、コード、画面、App Store Connect設定、公開URLは変更しない。

## 1. 初回提出の原則

初回提出の勝ち条件は、一般公開完了ではなく、App Store審査への初回提出完了。

初回提出では、次を優先する。

- 現地交換MVPとして説明できること。
- デモアカウントで主要フローを通せること。
- 未完成機能を画面、説明文、FAQ、スクショ、Review Notesから外すこと。
- 見えている機能は、法務、Privacy、App Review、運用で説明できること。

## 2. 機能露出マトリクス

| 領域 | 初回提出の推奨 | 見える場合の必須 | 隠す場合の確認 | No-Go |
|---|---|---|---|---|
| Auth / Account | 出す | 登録、ログイン、削除、問い合わせが通る | なし | デモアカウントで入れない |
| 在庫 / wish | 出す | 作成、編集、削除、検索候補が通る | なし | コアフローが途中で止まる |
| 打診 / ネゴ / 合意 | 出す | 2アカウントで送受信、合意、取引チャット遷移 | なし | 相手に届かない、状態不整合 |
| 取引チャット | 出す | メッセージ、写真、位置共有、到着、完了確認 | 未実装の操作を隠す | 取引安全に必要な連絡ができない |
| 現地交換安全 | 出す | 通報、ブロック、安全注意、緊急時案内 | なし | 危険時の導線がない |
| グルーム | 出すならUGC対応必須 | 投稿、通報、ブロック、モデレーション | 未完成投稿導線を隠す | UGCが見えるのに通報不可 |
| スポット掲示板 | 未完成なら隠す | 投稿、返信、通報、ブロック、削除/非表示 | タブ、説明、FAQ、スクショから外す | 未完成投稿画面が見える |
| めぐり | 3Dなしで出す候補 | 3Dなしでも主要体験が破綻しない | 未完成3D導線を外す | 未完成3Dが表示される |
| 有料機能 | IAP未完なら隠す | IAP商品、価格、復元、解約、特商法、Purchases回答 | Premium、めぐりPlus、ブースト導線を外す | 有料導線が見えるのにIAP未設定 |
| 外部AI | 初回は隠す又はオンデバイス限定推奨 | 送信情報、送信先、同意、Privacy、App Privacy | AI送信ボタン、説明、FAQ露出を外す | 外部送信が見えるのに説明/同意なし |
| 住所/電話番号入力 | 初回では出さない | 出すならPrivacy/App Privacy/法務レビューやり直し | 入力欄、設定、FAQ、App Privacyから外す | 収集しない前提なのに入力欄が見える |
| 未完成管理/デバッグ | 隠す | なし | debug表示、内部ID、fixture、管理画面導線を外す | スクショや画面に内部情報が出る |

## 3. 画面監査チェック

完成候補ビルドで、次を1つずつ確認する。

| 画面/導線 | 見ること | 判定 |
|---|---|---|
| Welcome / Auth | Terms / Privacyリンク、ログイン方法、未完成機能訴求なし | TODO |
| Onboarding | 不要な個人情報、住所、電話番号を求めていない | TODO |
| Home | 現地交換MVPの説明と実機状態が一致 | TODO |
| Inventory | 在庫登録が正常。公式画像利用を促していない | TODO |
| Wish | wish登録が正常。初回スコープ外の条件を出しすぎない | TODO |
| Search / Match | 候補表示が空でも破綻しない。未完成3Dへ飛ばない | TODO |
| Proposal | 打診内容、待ち合わせ、交換条件が現地交換前提 | TODO |
| Negotiation | 条件調整、合意、キャンセルが説明できる | TODO |
| Trade Chat | 現地合流、服装写真、現在地共有、安全注意がある | TODO |
| Completion / Rating | 完了、評価、異議申し立てが説明できる | TODO |
| Report / Block | UGCから通報/ブロックできる | TODO |
| Account Deletion | アプリ内削除入口がある | TODO |
| Settings / Legal | Terms、Privacy、Support、FAQへ辿れる | TODO |
| Paid surfaces | 初回で隠すなら導線なし。出すならIAP文書と一致 | TODO |
| AI surfaces | 初回で隠すなら導線なし。出すなら同意/説明あり | TODO |
| Meguri / 3D | 未完成3Dが露出しない | TODO |

## 4. メタデータ監査チェック

| 対象 | 見ること | 判定 |
|---|---|---|
| App Name / Subtitle | 初回で出す機能だけを表す | TODO |
| Promotional Text | 外部AI、有料機能、未完成機能を訴求していない | TODO |
| Description | 現地交換MVPと実ビルドが一致 | TODO |
| Keywords | 実在IPに寄りすぎない。未完成機能を入れない | TODO |
| Review Notes | デモアカウント、主要フロー、安全/UGC/削除説明がある | TODO |
| Screenshots | 実住所、実在IP、内部ID、debug、未完成機能がない | TODO |
| Age Rating | UGC、チャット、位置情報、IAP、AIの実態と一致 | TODO |
| App Privacy | 実ビルドで収集するデータだけ回答 | TODO |
| Public URLs | Support、Privacy、Terms、FAQが200で開く | TODO |

## 5. 公開文書監査チェック

| 文書 | 見ること | 判定 |
|---|---|---|
| Terms | 初回で出す機能と矛盾しない。AI/IAPは条件付き説明 | TODO |
| Privacy | 実ビルドの収集データ、外部サービス、保存期間と一致 | TODO |
| Support | 問い合わせ先、削除、通報、Privacy請求へ辿れる | TODO |
| FAQ | 初回で出さない有料機能/外部AI/未完成機能を断定しない | TODO |
| Commerce | 有料機能を出す場合だけ価格/解約/返金が一致 | TODO |
| App Review response | 指摘時に説明する機能範囲が実ビルドと一致 | TODO |

## 6. 証跡フォーマット

| 項目 | 値 |
|---|---|
| 監査日 | TODO |
| 監査者 | TODO |
| App Version / Build | TODO |
| TestFlight build | TODO |
| デモアカウント | TODO |
| 対象commit | TODO |
| Scope判定 | Pass / Conditional / Fail |
| 隠した機能 | TODO |
| 出す機能 | TODO |
| メタデータ修正要否 | TODO |
| 公開文書修正要否 | TODO |
| No-Go残件 | TODO |

## 7. No-Go

次に該当する場合は提出しない。

- 初回で隠すはずの有料機能、外部AI、未完成3D、未完成掲示板、住所/電話番号入力が画面に見える。
- 画面には見えないが、App Store説明文、スクショ、FAQ、Review Notesで未完成機能を説明している。
- App Privacyで回答しないデータを、実ビルドで入力又は送信している。
- UGCが見えるのに通報、ブロック、問い合わせ導線がない。
- アカウント作成があるのにアプリ内削除入口がない。
- スクショに実住所、実在IP、内部ID、debug表示がある。

## 8. 関連文書

- App Store提出パック: `notes/24_app_store_submission_pack.md`
- オーナー作業表: `notes/30_owner_release_action_sheet.md`
- スクリーンショット台本: `notes/28_app_store_screenshot_storyboard.md`
- App Store Connect転記: `notes/40_app_store_connect_copy_paste_sheet.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- App Privacy回答: `notes/43_app_privacy_connect_answer_sheet.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
- 公開FAQ下書き: `notes/55_public_help_faq_draft.md`
- アプリ内法務・安全コピー: `notes/56_in_app_legal_safety_copy_deck.md`
