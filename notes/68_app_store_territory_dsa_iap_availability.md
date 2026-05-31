# 68. App Store配信地域・EU DSA・IAP Availabilityチェックリスト

最終更新: 2026-05-31

ステータス: Draft v0.1（App Store Connect入力前）

## 目的

App Store初回提出で、配信地域、EU Digital Services Act（DSA）のtrader status、公開される連絡先、IAPの提供地域を、法務・運用・App Store審査の観点で整理する。

この文書はApp Store Connect入力前の判断表であり、コード、App Store Connect設定、IAP商品、公開URL、法務原典docxは変更しない。

公開後に地域Availabilityを変更する、又は全地域から外す判断は `notes/73_app_store_availability_emergency_stop_runbook.md` を使う。

## 1. 公式前提の要点

Apple公式ヘルプ上、App Store Connectでは提出前にアプリのAvailabilityを設定し、All Countries or Regions、Specific Countries or Regions、Pre-Order等から選ぶ。

EU DSAについて、Appleは、EUでアプリを配信するtraderについて連絡先情報を確認し、App Storeの商品ページに表示する旨を案内している。EUに配信しない場合でも、App Store Connect上でtrader statusの申告が求められる。

IAPは、アプリ本体とは別に国・地域ごとのAvailabilityを設定する。初回で有料機能を隠す場合、IAP提供地域の設定は後回しにできるが、有料導線が見える場合はApp Store Connect商品、価格、Availability、特商法表示、App Privacyを一致させる。

## 2. 初回提出の推奨

| 判断 | 推奨 | 理由 |
|---|---|---|
| App Availability | 初回はJapanのみ候補 | 日本語UI、日本語Support、現地交換MVP、法務/サポート負荷を絞る |
| EU配信 | 初回は見送り候補 | DSA trader情報、英語/現地語サポート、公開連絡先の確認が増える |
| DSA trader status | App Store Connectで必ず申告準備 | EU配信しない場合でも申告を求められるため |
| IAP Availability | 有料機能を隠すなら未設定/未提出で可 | StoreKit/IAP/特商法/サーバー検証を後回しにできる |
| All Countries or Regions | 初回は非推奨 | サポート、法務、税務、ローカライズ、DSA、IAP表示の範囲が広がる |
| Pre-Order | 初回は不要 | 審査提出と実機確認を優先 |

初回の勝ち条件は、広域配信ではなく、App Store審査への初回提出完了とする。

## 3. App Availability判断表

| 選択肢 | 使う条件 | 追加確認 | No-Go |
|---|---|---|---|
| Japanのみ | 初回提出を日本向けMVPに絞る | 日本語Support、Privacy、Terms、サポートメール | なし |
| Japan + selected regions | 明確なテスター/ユーザーがいる | 英語メタデータ、サポート対応、法務確認 | サポート不能な地域を選ぶ |
| EU含む | DSA trader情報、公開連絡先、サポート方針が確定 | trader status、住所/電話/メールの表示可否、Privacy/Terms | trader情報未確認 |
| All Countries or Regions | 多地域サポート、法務、ローカライズ、IAPが整う | 各地域の表示、問い合わせ、税務、IAP価格 | 初回MVPで安易に選ぶ |
| Pre-Order | 事前予約を使う明確な理由がある | リリース日、地域、手動公開 | 初回審査提出を遅らせる |

## 4. EU DSA確認

| Check | 確認 | 結果 |
|---|---|---|
| DSA-001 | App Store Connectでtrader status申告が必要か確認した | TODO |
| DSA-002 | Megrum運営者がtraderに該当するか、弁護士/オーナー判断を得た | TODO |
| DSA-003 | EU 27 territoriesへ初回配信するか決めた | TODO |
| DSA-004 | EU配信する場合、表示される住所、電話番号、メールの扱いを確認した | TODO |
| DSA-005 | 代表者情報非公表方針とDSA表示が矛盾しないか確認した | TODO |
| DSA-006 | EU配信しない場合でも、trader status申告の控えを証跡保存した | TODO |
| DSA-007 | DSA表示に使う連絡先が個人情報として不必要に露出しない | TODO |

No-Go:
- EU配信するのにtrader status未申告。
- traderとして表示される住所、電話番号、メールをオーナーが確認していない。
- 特商法では非公表方針なのに、EU DSA表示で公開される情報の扱いを把握していない。
- DSA表示用の実連絡先をリポジトリへ書く。

## 5. 連絡先情報の扱い

公開してよい候補:
- `support@megrum.jp`
- 公開Support URL
- 公開Privacy Policy URL
- 公開Terms URL

公開前に確認が必要:
- 代表者名
- 所在地
- 電話番号
- App Store Connect上で表示される販売者/提供者情報
- EU DSAで表示されるtrader contact information

リポジトリに書かない:
- 個人住所
- 個人電話番号
- 個人メールアドレス
- 本人確認書類
- App Store Connect上の本人確認情報

代表者情報、所在地、電話番号の非公表方針は `notes/17_legal_alignment.md` と `notes/66_legal_review_publication_runbook.md` で確認する。

## 6. IAP Availability確認

有料機能を初回で隠す場合:

| Check | 確認 | 結果 |
|---|---|---|
| IAP-AV-001 | アプリ内に有料機能ボタン、価格、購入画面が見えない | TODO |
| IAP-AV-002 | App Store説明文、FAQ、Review Notesで有料機能を利用可能として断定していない | TODO |
| IAP-AV-003 | App PrivacyでPurchasesを選ばない根拠がある | TODO |
| IAP-AV-004 | 特商法ページを公開しない又は将来用下書き扱いにしている | TODO |

有料機能を初回で出す場合:

| Check | 確認 | 結果 |
|---|---|---|
| IAP-AV-101 | IAP商品がApp Store Connectで作成済み | TODO |
| IAP-AV-102 | IAP AvailabilityがApp Availabilityと矛盾しない | TODO |
| IAP-AV-103 | 価格、通貨、地域、開始日が確定 | TODO |
| IAP-AV-104 | サブスクリプションのグループと商品IDが確定 | TODO |
| IAP-AV-105 | StoreKit購入、復元、期限切れ、返金、サーバー検証が通る | TODO |
| IAP-AV-106 | 特商法表示、利用規約、Support、FAQ、Review Notesが一致 | TODO |
| IAP-AV-107 | App PrivacyでPurchasesを回答している | TODO |
| IAP-AV-108 | IAPをApp ReviewのSubmissionへ同時に含める必要があるか確認した | TODO |

No-Go:
- アプリ本体はJapanのみなのに、IAP Availabilityが広く開いている。
- IAP価格と特商法表示が違う。
- IAPが見えるのにPurchasesをApp Privacyで回答していない。
- IAP商品がReady to Submit相当でないのに有料導線が見える。

## 7. App Store Connect入力前チェック

| Check | 確認 | 結果 |
|---|---|---|
| AV-001 | App AvailabilityをJapanのみ / selected / all のどれにするか決めた | TODO |
| AV-002 | All Countries or Regionsを選ばない理由又は選ぶ根拠を記録した | TODO |
| AV-003 | EU 27 territoriesを含めるか決めた | TODO |
| AV-004 | DSA trader status申告を確認した | TODO |
| AV-005 | DSAで表示される連絡先情報を確認した | TODO |
| AV-006 | Support/Privacy/Termsの公開URLが選択地域のユーザーに説明可能 | TODO |
| AV-007 | Primary Languageと追加localizationが配信地域と矛盾しない | TODO |
| AV-008 | IAP AvailabilityとApp Availabilityの整合を確認した | TODO |
| AV-009 | 配信地域、DSA、IAPの証跡を `notes/64` のmanifestへ入れる | TODO |

## 8. Go / No-Go

Go:
- 初回配信地域が明確。
- DSA trader status申告の要否と内容を確認済み。
- EU配信する場合、公開される連絡先情報をオーナーが確認済み。
- IAPを隠す場合、アプリ、FAQ、Review Notes、スクショから有料導線を外している。
- IAPを出す場合、IAP Availability、価格、特商法、App Privacy、Review Notesが一致している。

No-Go:
- 配信地域が未決。
- EU配信するのにDSA情報が未確認。
- App Store商品ページに表示される連絡先情報を把握していない。
- IAP Availabilityとアプリ本体Availabilityが矛盾。
- 有料機能が見えるのにIAP/特商法/App Privacyが未整備。

## 9. 関連文書

- App Store Connect入力ワークシート: `notes/31_app_store_connect_metadata_worksheet.md`
- App Store質問票回答シート: `notes/46_app_store_questionnaire_answer_sheet.md`
- IAP商品設定ワークシート: `notes/33_iap_product_setup_worksheet.md`
- 法務レビュー後公開文面最終化: `notes/66_legal_review_publication_runbook.md`
- リリース権限・運用アカウント: `notes/61_release_access_owner_registry.md`
- App Review手動提出チェック: `notes/62_app_review_manual_submission_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
- App Store公開停止・Availability変更: `notes/73_app_store_availability_emergency_stop_runbook.md`

## 10. 公式参照

- Apple Manage availability for your app on the App Store: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store
- Apple Set availability for In-App Purchases: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-availability-for-in-app-purchases/
- Apple Manage European Union Digital Services Act trader requirements: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/
- Apple In-App Purchase and subscriptions pricing and availability: https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-and-subscriptions-pricing-and-availability/
