# 24. App Store 審査提出パック

最終更新: 2026-05-31

ステータス: Draft（コード変更なしで先に準備できる提出素材）

## 目的

この文書は、開発セッションと衝突せずに先回りで準備できる App Store Connect 入力内容、審査メモ、プライバシー回答、リリース前確認事項を1か所に集約する。

実装完了後は、実アプリの画面・SDK・通信内容と照合してから提出する。

提出全体の実行順と文書マップは `notes/39_release_command_center.md` を使う。

## 前提

- 初回リリースの勝ち条件は、一般公開完了ではなく **App Store 審査への初回提出完了** とする。
- 利用規約・プライバシーポリシーは、`notes/legal/01_terms_of_service_draft.md` と `notes/legal/02_privacy_policy_draft.md` を公開前レビュー用ドラフトとする。
- 弁護士納品の原典は `利用規約など/` 配下の docx とし、公開文面は `notes/17_legal_alignment.md` と照合する。
- AI機能を外部AIサービスへ接続する場合は、送信情報、利用目的、学習利用の有無、第三者提供又は委託の位置付けを画面上でも明示する。
- この文書は提出素材であり、アプリコード、Supabaseスキーマ、ビルド設定は変更しない。

## 1. App Store Connect 入力下書き

提出画面へ入力する前の詳細ワークシートは `notes/31_app_store_connect_metadata_worksheet.md` を使う。
提出直前にコピーする文面は `notes/40_app_store_connect_copy_paste_sheet.md` を使う。
App Store Connectへ実際に入力した値の最終差分照合は `notes/71_app_store_connect_final_input_reconciliation.md` を使う。

有料機能を初回提出に含める場合は、IAP商品設定を `notes/33_iap_product_setup_worksheet.md` で先に固定する。
デモアカウントと審査用データは `notes/35_demo_account_review_data_plan.md` を使う。

### アプリ名

Megrum

### サブタイトル候補

推し活グッズを安心交換

### プロモーションテキスト候補

イベント現地でのグッズ交換を、在庫・Wish・打診・取引チャットでスムーズに管理できます。

### 説明文候補

Megrumは、K-POP、アニメ、イベントグッズなどの推し活グッズを交換したい人のためのアプリです。

手元にあるグッズと探しているグッズを登録し、条件が合う相手へ打診できます。合意までの調整、取引チャット、証跡確認、評価までをひとつの流れで管理できます。

主な機能:
- 在庫とWishの登録
- 条件に合う相手の確認
- 打診、反対提案、合意
- 取引チャット
- 現地交換の待ち合わせ補助
- めぐり、グルーム、スポット掲示板

Megrumは、ユーザー同士の交換を補助するサービスです。金銭売買、チケット転売、盗品又は権利侵害品の取引、法令又は利用規約に反する利用は禁止しています。

### キーワード候補

推し活,グッズ交換,KPOP,アニメ,トレカ,交換,イベント,コレクション,Wish

### カテゴリ候補

- 第一候補: ライフスタイル
- 第二候補: ソーシャルネットワーキング

最終判断は App Store Connect 上の競合表示、審査カテゴリ、アプリの主画面比率を見て決める。

### URL

- プライバシーポリシーURL: `https://megrum.jp/legal/privacy`（要公開）
- サポートURL: `https://megrum.jp/support`（要公開）
- 利用規約URL: `https://megrum.jp/legal/terms`（アプリ内とWebの両方で参照できる状態にする）
- 問い合わせ先: `support@megrum.jp`

### 著作権表記

Copyright (c) 2026 Megrum. All rights reserved.

## 2. 審査メモ下書き

App Review Notes に入れる文面のたたき台:

```
Megrum is a goods exchange app for fan communities. Users can register items they have, items they want, send proposals, negotiate exchange details, and complete transactions through an in-app trade chat.

The app does not sell physical goods directly. It provides matching and communication tools for user-to-user exchanges. Paid features, if enabled in this build, are limited to app functionality such as premium features or boosts and use Apple's in-app purchase where required.

User-generated content areas include profiles, item images, trade chat, Groom posts, and the spot board. The app provides reporting/blocking flows and operational moderation for inappropriate content or users.

If AI-assisted item registration is available in this build, it is used to help extract item information from user-provided images/text. External AI processing, if enabled, is disclosed to the user before transmission.

Demo account:
Email: [TODO]
Password: [TODO]

Suggested review path:
1. Sign in with the demo account.
2. Open inventory and Wish.
3. Create or inspect a proposal.
4. Open trade chat.
5. Open Settings > Terms / Privacy / Contact.
6. Open Settings > Account deletion.
```

提出前に、実際のビルドで有効な機能だけに削る。未完成の有料機能、未完成のAI機能、未完成の掲示板が露出している場合は提出前に非表示又は説明追加が必要。

## 3. App Privacy 回答下書き

App Store Connect の App Privacy は、実際の収集・送信・第三者SDK利用と一致させる。下表は現時点の想定であり、提出直前に `PrivacyInfo.xcprivacy`、Supabase、Firebase/Analytics、Push通知、AIサービス、課金SDKと照合する。

詳細な照合作業表は `notes/27_app_privacy_data_inventory.md`、App Store Connectへの回答シートは `notes/43_app_privacy_connect_answer_sheet.md`、Privacy Manifest/SDK監査は `notes/44_privacy_manifest_sdk_audit.md` を使う。

| カテゴリ | 想定データ | 目的 | ユーザーに紐づくか | トラッキング |
|---|---|---|---|---|
| 連絡先情報 | メールアドレス、表示名 | アカウント、問い合わせ | はい | いいえ |
| ユーザーコンテンツ | プロフィール、グッズ画像、投稿、取引チャット、通報内容 | アプリ機能、安全確保、サポート | はい | いいえ |
| 位置情報 | 待ち合わせ・現在地共有でユーザーが任意共有する位置 | 取引相手との合流補助 | はい | いいえ |
| 識別子 | ユーザーID、端末通知トークン等 | 認証、通知、安全確保 | はい | いいえ |
| 購入 | アプリ内課金の購入状態 | 有料機能の提供、復元 | はい | いいえ |
| 使用状況データ | 画面操作、機能利用状況 | 品質改善、不正対策 | 原則はい | いいえ |
| 診断 | クラッシュログ、パフォーマンスログ | 不具合解析、品質改善 | SDK設定による | いいえ |
| その他 | AI機能の入力・出力・ログ | AI機能提供、安全確保、品質改善 | 入力内容による | いいえ |

注意:
- `NSPrivacyTracking` は、広告識別子や他社データと結合した追跡をしない限り `false` 方針。
- 外部AIサービスへ画像・本文・プロフィール情報等を送る場合は、App Privacy とプライバシーポリシーの委託/第三者提供欄に反映する。
- 汎用AIモデルの学習利用にユーザー入力を使う場合は、初回提出前のP0として別途同意設計が必要。初回リリースでは使わない方針を推奨する。

## 4. PrivacyInfo.xcprivacy 照合メモ

現在確認済みの論点:
- `ios-native/App/PrivacyInfo.xcprivacy` は `NSPrivacyTracking=false` と UserDefaults の Required Reason API を宣言している。
- 提出前に、実際にリンクしている Apple SDK / Supabase / Firebase / Analytics / 画像処理 / Push通知 / 課金 / AI SDK が追加の Privacy Manifest 又は Required Reason API 宣言を必要としないか確認する。
- App Store Connect の App Privacy、アプリ内プライバシーポリシー、`PrivacyInfo.xcprivacy`、実際の通信内容が矛盾しないようにする。

提出前チェック:
- [ ] 収集データのカテゴリが App Privacy と一致している
- [ ] トラッキング有無が実装・SDK設定と一致している
- [ ] Required Reason API が不足していない
- [ ] 外部SDKの Privacy Manifest を確認した
- [ ] AIサービス、分析、クラッシュレポート、Push通知、課金の扱いを確認した

## 5. AI機能の提出前確認

初回提出でAI機能を出す場合:
- [ ] AI機能がオンデバイス完結か、外部AIサービスへ送信するかを確定した
- [ ] 外部送信するデータを画面上で明示した
- [ ] 外部AIサービス名、利用目的、保存期間、学習利用の有無を説明できる
- [ ] 利用規約とプライバシーポリシーのAI条項と実装が一致している
- [ ] AI出力の誤りをユーザーが確認・修正できる
- [ ] 児童、センシティブ情報、権利侵害、なりすまし等に関わる禁止利用を規約・運用で扱える

初回提出では、外部AIに個人情報や画像を送る機能を無理に出さず、オンデバイス又は手入力補助に閉じる方が審査・法務リスクは小さい。

## 6. UGC / 通報 / ブロック / モデレーション

UGCがあるビルドで提出する場合、次を提出前P0として確認する。

- [ ] プロフィール、グッズ画像、投稿、スポット掲示板、取引チャットから不適切コンテンツを通報できる
- [ ] 相手ユーザーをブロック又は非表示にできる
- [ ] 通報が運営側で確認できる
- [ ] 問い合わせ先がアプリ内とWebで確認できる
- [ ] 明らかに不適切な投稿・画像を削除又は非表示にできる運用がある
- [ ] 未完成のUGC導線は初回提出ビルドで露出しない

審査メモには、UGC領域と通報・ブロック・モデレーション体制を簡潔に書く。

## 7. アカウント削除

Apple審査前のP0:
- [ ] アプリ内の設定からアカウント削除を開始できる
- [ ] 削除対象データ、猶予期間、復旧可否を確認画面で説明している
- [ ] Apple / Google / メール等のログイン連携解除方針を説明できる
- [ ] 削除申請後のログアウト、再ログイン、削除予定状態が破綻しない
- [ ] サポート窓口だけに誘導する設計になっていない

`notes/09_state_machines.md` のアカウント削除状態と、実装・規約・プライバシーポリシーを一致させる。
削除対象、保持対象、Sign in with Apple token revoke、個人情報請求の運用は `notes/45_account_deletion_privacy_request_runbook.md` で確認する。

## 8. 公開URLと法務ページ

提出前に公開状態で確認する:

- [ ] `https://megrum.jp/legal/terms`
- [ ] `https://megrum.jp/legal/privacy`
- [ ] `https://megrum.jp/legal/commerce`
- [ ] `https://megrum.jp/support`
- [ ] `https://megrum.jp/support/account-deletion`
- [ ] `https://megrum.jp/support/privacy-request`
- [ ] `https://megrum.jp/support/report`
- [ ] `support@megrum.jp` が受信できる

特商法表示では、代表者名・住所・電話番号は原典方針どおり「請求があれば遅滞なく開示」とする。課金額、支払方法、解約、返金、提供時期は実際のアプリ内課金設定と合わせる。

公開ページ文面は `notes/25_public_legal_support_pages.md` を下書きとする。公開作業の受け入れ基準は `notes/37_public_url_publication_checklist.md`、問い合わせ一次返信は `notes/34_support_response_templates.md` を使う。

## 9. 権限説明文の下書き

Info.plist 等へ入れる前の文案。実装側が触るため、この文書では文面だけを管理する。

| 権限 | 文案 |
|---|---|
| カメラ | グッズ写真や取引証跡を撮影するためにカメラを使用します。 |
| 写真ライブラリ | グッズ写真、プロフィール画像、取引証跡を選択するために写真へのアクセスを使用します。 |
| 位置情報 | 待ち合わせや現在地共有で、あなたが選んだ相手に位置を共有するために使用します。 |
| 通知 | 打診、取引チャット、合意、取引状況の更新をお知らせするために通知を送信します。 |

位置情報は任意共有であること、共有範囲が取引相手に限られることを、権限前のアプリ内文脈でも補足する。

## 10. スクリーンショット構成案

初回提出用の候補:

1. ホーム / マッチ候補
2. 在庫登録
3. Wish登録
4. 打診作成
5. ネゴ / 合意
6. 取引チャット
7. めぐり又はスポット掲示板
8. 安全機能又は設定

完成ビルドの見た目で撮影し、未完成機能や審査で説明しづらい導線を写さない。

Appleの仕様上、スクリーンショットは1〜10枚、形式は `.jpeg` / `.jpg` / `.png`。App Previewは任意で、出す場合は各デバイスサイズ・言語ごとに最大3本まで。初回提出では動画より、主要フローが伝わる静止画を優先する。

スクショ撮影前チェック:
- [ ] デモアカウントの個人情報が見えない
- [ ] 未完成機能、仮文言、内部ID、デバッグ表示が見えない
- [ ] 規約違反になり得るグッズや第三者画像が写っていない
- [ ] 有料機能が写る場合、App Storeの価格・IAP設定と一致している
- [ ] 位置情報が写る場合、サンプルデータである

具体的な撮影順、デモデータ、コピー候補は `notes/28_app_store_screenshot_storyboard.md` を使う。

## 11. 提出前ブロッカー

少なくとも次が未完了なら提出しない。

- [ ] 新規登録、ログイン、ログアウトが実機で通る
- [ ] 在庫、Wish、打診、合意、取引完了が実機で通る
- [ ] 利用規約、プライバシーポリシー、問い合わせ導線が切れていない
- [ ] App Privacy、Privacy Manifest、プライバシーポリシーが矛盾していない
- [ ] UGCの通報、ブロック、モデレーションが説明できる
- [ ] アプリ内アカウント削除がある
- [ ] 未完成の3D、未完成の有料機能、未完成の外部AI機能が露出していない
- [ ] TestFlightで2アカウント以上の往復確認が済んでいる

TestFlight配布からApp Review提出までの具体手順は `notes/32_testflight_review_submission_runbook.md` を使う。
有料機能を出す場合は、`notes/33_iap_product_setup_worksheet.md` のGo / No-Goを通過してから提出する。
提出時に残す証跡は `notes/36_submission_evidence_checklist.md` で管理する。
TestFlight協力者向けの案内とフィードバック項目は `notes/38_testflight_tester_comms.md` を使う。
App Reviewで指摘が来た場合の返信下書きは `notes/41_app_review_response_templates.md` を使う。
Age Rating、Content Rights、Export Complianceの質問票は `notes/46_app_store_questionnaire_answer_sheet.md` を使う。
外部サービス、委託先、SDK、APIの最終照合は `notes/48_external_service_vendor_register.md` を使う。
個人情報・セキュリティ事故時の初動は `notes/49_privacy_security_incident_response_runbook.md` を使う。
Apple Guideline別の提出前適合確認は `notes/53_app_review_guideline_compliance_matrix.md` を使う。
RLS、Storage、secret、APNs、管理者権限の提出前監査は `notes/54_prelaunch_security_audit_checklist.md` を使う。
アプリ内の同意、権限説明、安全注意、AI/IAP文言は `notes/56_in_app_legal_safety_copy_deck.md` を使う。
初回提出で出す/隠す機能の露出監査は `notes/59_initial_release_scope_exposure_audit.md` を使う。

## 12. 公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple In-App Purchase: https://developer.apple.com/in-app-purchase/
- Apple In-App Purchase information: https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-information/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple Privacy Manifest: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple Product Page / Screenshots: https://developer.apple.com/app-store/product-page/
- Apple Screenshot Specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- 個人情報保護委員会 通則ガイドライン: https://www.ppc.go.jp/personalinfo/legal/guidelines_tsusoku/
