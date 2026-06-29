# 66. 法務レビュー後公開文面最終化Runbook

最終更新: 2026-06-29

ステータス: Draft v0.9（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / Keychain・session保存・最新法務ドラフト / UGC・App Review 1.2 / App Store評価・公開レビュー返信 / 漏えい等初動・事故疑い / 広告宣伝メール・販促通知 / 公式連絡・フィッシング / 公開Web / アプリ内法務表示の実装同期監査を反映・弁護士回答受領後に使用）

## 目的

弁護士レビュー回答を受け取った後、利用規約、プライバシーポリシー、特商法表示、公開サポート、FAQ、App Store説明文、Review Notes、App Privacy回答へ反映漏れが起きないように、最終化手順を整理する。

この文書は公開文面の反映手順であり、コード、公開URL、App Store Connect設定、法務原典docx、実アカウント情報は変更しない。

## 1. 使うタイミング

使うタイミング:
- 弁護士から、規約、Privacy、特商法、サポート文面、AI、UGC、IAP、削除、現地交換安全に関する回答を受け取った。
- 回答要点を `notes/58_legal_review_response_tracker.md` へ記録する準備ができている。
- App Store提出前に、公開URLへ流し込む最終文面を確定したい。

使わないタイミング:
- 弁護士回答の原文を安全な場所に保存していない。
- 回答の要点、判断、反映先が未整理。
- 初回提出で出す/隠す機能が未確定。
- 開発側Release CandidateのVersion、Build、commit SHAが不明。

## 2. 反映の原則

- 弁護士回答の全文は公開リポジトリに貼らない。要点、判断、反映先、未決論点だけを記録する。
- 法務原典docxは保管し、公開前ドラフトは現行仕様と初回提出スコープに合わせて更新する。
- 回答を1か所だけに反映して終わりにしない。Terms、Privacy、Support、FAQ、App Store文面、Review Notes、App Privacyの横断確認を行う。
- Markdown原稿とWord改訂案を更新しても、公開Webの `/terms`、`/privacy`、`/support`、アプリ内同意リンク、App Store Connect入力値が古い短縮本文を指す限り提出可能とは扱わない。
- 初回で隠す機能は、公開ページとApp Store文面でも利用可能な機能として断定しない。
- 特商法の代表者情報非公表、価格、返金、解約、個人情報請求、外部AI、外部画像URL、写真メタデータ、顔候補付け、UGCの扱いは、弁護士回答とApp Store提出文面を必ず照合する。
- 実パスワード、secret、実ユーザー情報、実代表者情報、個人住所、個人電話番号はこのRunbookに書かない。

## 3. 反映フロー

| Step | 作業 | 完了条件 | 参照 |
|---|---|---|---|
| LR-PUB-001 | 弁護士回答を安全な場所に保存 | 原文保存先と受領日時だけを記録 | `notes/58` |
| LR-PUB-002 | 回答要点を台帳へ転記 | LR-ID、論点、要約、影響文書、判断が埋まる | `notes/58` |
| LR-PUB-003 | 初回提出への影響を分類 | Must before submit / Can defer / Not applicable | 本文書 |
| LR-PUB-004 | 公開文面を更新 | Terms、Privacy、Support、FAQ、Commerce候補が更新済み | `notes/legal`, `notes/25`, `notes/55` |
| LR-PUB-005 | App Store文面を更新 | Description、Review Notes、質問票、App Privacyが一致 | `notes/40`, `notes/46`, `notes/43` |
| LR-PUB-006 | アプリ内コピー影響を整理 | 実装側へ渡す文言変更があるか分類 | `notes/56`, `notes/65` |
| LR-PUB-006a | 公開実装との差分を確認 | Web公開ページ、アプリ内同意リンク、法務要約、Privacy Manifest、App Privacy回答の同期差分が整理済み | `notes/37`, `notes/63` |
| LR-PUB-007 | レダクションQA | secret、実データ、未確定機能、未確定価格がない | `notes/63` |
| LR-PUB-008 | URL公開前QA | ログイン不要、HTTPS、200応答、最終更新日 | `notes/37` |
| LR-PUB-009 | Go / No-Goへ反映 | G5、G6、G7、G8、G9、G13、G14が更新済み | `notes/50` |
| LR-PUB-010 | 証跡を保存 | manifestへ反映日、commit、対象URLを記録 | `notes/64` |

## 4. 論点別反映マップ

| 論点 | 反映先 | App Store影響 | No-Go |
|---|---|---|---|
| 現地交換安全/免責 | Terms, Support, FAQ, Review Notes | Safety説明、サポート導線 | 事故時の責任分界や緊急時案内がない |
| 位置情報/服装写真 | Privacy, Data Retention, App Privacy, Review Notes | Location / Photos / user content回答 | 保存期間や共有範囲が矛盾。30日後の自動削除、完全削除、即時反映を未確認のまま保証 |
| 近距離公開/作成位置 | Terms, Privacy, FAQ, App Privacy, Data Retention, Review Notes | Precise Location回答、Safety説明 | 作成位置、閲覧者位置、現地交換モード、待ち合わせ候補、1km/3km非保証、生活圏推測リスクがない |
| 未成年利用 | Terms, FAQ, Age Rating, Safety | Age Rating、Review Notes | 保護者同意や安全注意が未整理 |
| UGC/評価/通報/ブロック/モデレーション | Terms, Trust & Safety, Support, FAQ, Review Notes, App Privacy | Guideline 1.2説明、評価コメント注意、通報者秘匿の限界、緊急時外部連絡 | UGCや評価が見えるのに通報/ブロック/モデレーション説明不能。通報者絶対秘匿や削除保証をしている |
| 公開法務ページ同期 | Terms, Privacy, Support, FAQ, App Store URLs, アプリ内同意リンク | Privacy Policy URL、Support URL、License Agreement、Review Notes | `2026年6月26日` の短縮Terms/Privacy、又は `/terms` / `/privacy` と `/legal/terms` / `/legal/privacy` の分裂を残したまま提出する |
| App Store評価・公開レビュー返信 | Terms, Privacy, Review Response Runbook, Support, FAQ | 公開返信、concern report、レビュー誘導 | 公開レビュー返信で個人情報、認証情報、取引情報、返金/補償/責任承認、評価変更依頼、マーケティングを出す |
| 漏えい等初動・事故疑い | Terms, Privacy, Incident Runbook, Support, FAQ | App Privacy、Support URL、Review Notes | 初回連絡、受付番号、機能停止、本人通知、関係機関報告を責任承認、補償、復旧、再発防止保証として書く |
| 広告宣伝メール・販促通知 | Terms, Privacy, FAQ, In-app Copy, App Review Matrix | Push 4.5.4、App Privacy、Support URL | 同意記録、送信者情報、問い合わせ先、停止手段なしに販促Push又は広告宣伝メールを送る説明になっている |
| 公式連絡・フィッシング | Terms, Privacy, FAQ, Support Templates, In-app Copy | Support URL、Review Notes、公開レビュー返信 | Megrum公式がパスワード、認証コード、認証リンク、金融機関ログイン情報、暗証番号、カード番号、送金用QRコード、送金リンク、外部決済サービスIDを求めるように読める |
| 会員間支払い・金融規制境界 | Terms, Privacy, FAQ, Support Templates, In-app Copy, App Privacy, Review Notes, Vendor Register, Security Checklist | Payment Info、App Review 3.1.3(e) / 3.2.2(viii)、Support URL | 支払い方法、銀行口座、口座名義、金額指定又は成立後支払い情報スナップショットが見えるのに、合意後表示、保持、相手保存リスク、目的外利用禁止、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR確認の非関与が反映されていない |
| アカウント削除 | Terms, Privacy, Support, FAQ | Guideline 5.1.1(v)説明 | アカウント作成があるのに削除導線が説明不能。30日後完了、復旧、外部連携解除を未確認のまま保証 |
| AI/外部AI/顔候補付け | Terms, Privacy, AI page, App Privacy, Review Notes | 送信画像/画像URL/文脈、OpenAI等の送信先、Web検索・外部情報参照、濫用監視ログ、保持/削除可否、学習利用、任意性、Privacy回答、Face ID非利用、Sensitive Info候補 | 外部AIが見えるのに送信情報、送信先、Web検索、保持/削除、学習利用、私的画像・第三者画像の禁止が説明されない。顔特徴量や補正履歴が本人確認/Face IDに見える又はSensitive Info未回答 |
| 通知本文/ロック画面 | Terms, Privacy, FAQ, Safety, App Privacy, Review Notes | APNs/Expo token、通知本文、未読バッジ、ロック画面表示、User Content/Usage Data回答 | Push通知が見えるのに通知本文・ロック画面表示・App Privacy説明が不一致 |
| 外部画像URL/AI候補画像 | Terms, Privacy, FAQ, Safety, App Privacy, Content Rights, Review Notes | 外部ホスト通信、第三者ポリシー、権利確認責任、Content Rights説明 | 公式素材又は権利確認済み素材のように見える。外部画像URLが見えるのにPrivacy/App Privacy説明がない |
| 写真メタデータ | Terms, Privacy, FAQ, Safety, App Privacy, Data Retention | EXIF、撮影日時、GPS位置情報、端末情報、Location / Device Info回答 | 写真アップロードが見えるのにメタデータ残存経路、削除可否、ユーザー注意がない |
| 有料機能/IAP | Terms, Privacy, Commerce, IAP, FAQ, Metadata | IAP同時提出、価格、解約、復元、Purchases回答 | 有料導線が見えるのにIAP/特商法が未整備。購入ボタン、復元ボタン、固定価格、StoreKit価格、サーバー同期失敗、Privacy/App Privacyが不一致 |
| 代表者情報非公表 | Commerce, Support templates, Owner Ops | 有料機能を出す場合の公開表示 | 請求時の開示フローがない |
| 個人情報請求 | Privacy, Support, Data Retention | Privacy URL、Support URL | 窓口、本人確認、対応範囲が不明 |
| 外部サービス/委託 | Privacy, Vendor Register, App Privacy | SDK/外部送信回答 | 外部サービス台帳とPrivacyが不一致 |
| 禁止物/権利侵害 | Terms, FAQ, Safety, Metadata | IP/Content Rights説明 | 公式提供や権利侵害を誘発する表現 |

## 5. 公開文面更新チェック

| 文書 | 更新観点 | 結果 |
|---|---|---|
| `notes/legal/01_terms_of_service_draft.md` | 免責、禁止事項、UGC、評価、通報、ブロック、モデレーション、公開レビュー返信、事故初動、販促通知、公式連絡、AI、外部画像URL、写真メタデータ、顔候補付け、IAP、削除、安全 | TODO |
| `notes/legal/02_privacy_policy_draft.md` | 取得情報、利用目的、外部サービス、評価/通報/ブロック/モデレーション、公開レビュー返信、事故疑い、販促同意/停止履歴、不審連絡/フィッシング報告、AI、外部画像URL、写真メタデータ、顔候補付け、保持/削除、請求窓口 | TODO |
| `notes/25_public_legal_support_pages.md` | Support、削除、通報、ブロック、評価、緊急時案内、公開レビュー返信、事故初動、販促通知、公式連絡、AI、外部画像URL、特商法候補 | TODO |
| `notes/55_public_help_faq_draft.md` | 初回で出す機能だけ説明。隠す機能は削る | TODO |
| `notes/56_in_app_legal_safety_copy_deck.md` | 実装へ渡す同意/安全/権限文言 | TODO |
| `notes/40_app_store_connect_copy_paste_sheet.md` | App Store説明、Review Notes、Known exclusions | TODO |
| `notes/43_app_privacy_connect_answer_sheet.md` | App Privacy回答 | TODO |
| `notes/46_app_store_questionnaire_answer_sheet.md` | Age Rating、Content Rights、Export Compliance | TODO |

No-Go:
- 2026-06-29版のMarkdown/Wordだけを更新し、公開Webの `/terms`、`/privacy`、`/support` が古い短縮本文又は旧リンクのまま残っている。
- 弁護士回答で修正が必要になった文言が、App Store説明又はReview Notesに古いまま残っている。
- Privacyで説明した取得情報とApp Privacy回答が一致しない。
- 現在地共有又は服装写真について、Privacy、FAQ、Review Notes、App Privacy回答、公開Web実装のどこかで30日後自動削除又は完全削除を保証している。
- 近く、1km圏内、3km圏内、同じスポット又は同じ都道府県を、匿名化、安全確認、本人確認、所在確認又は推測防止として説明している。
- 現地交換モード、待ち合わせ候補、グルーム、掲示板が見えるのに、作成位置、閲覧者位置、半径、距離、公開範囲、保持例外、生活圏推測リスクをPrivacy、FAQ、Review Notes、App Privacyへ反映していない。
- 通知本文、未読バッジ、ロック画面表示、APNs/Expo token、アプリ内通知履歴の説明がTerms/Privacy/FAQ/App Privacyで不一致。
- 外部画像URL又はAI/検索候補画像の外部ホスト通信、第三者ポリシー、権利確認責任がTerms/Privacy/FAQ/Content Rightsで不一致。
- 写真メタデータの残存、削除可否、ユーザー注意、App Privacy回答が不一致。
- 評価、通報、異議申し立て、ブロック、モデレーションが見えるのに、緊急通報、法的判断、本人確認、安全確認、信用保証、削除/解決保証ではない説明がない。
- 通報者情報を絶対非開示と保証している、又はブロックで過去取引、チャット、証跡、評価、通報記録が当然に削除されるように説明している。
- 会員間支払い情報、銀行口座、口座名義、成立後支払い情報スナップショット、外部決済サービス非関与、金融規制境界がTerms/Privacy/FAQ/App Privacy/Review Notes/Supportで不一致。
- 特商法表示の価格、解約、返金、提供時期がIAP設定と一致しない。
- アプリ内の特定商取引法に基づく表記要約又は設定内入口だけで、正式な公開特商法ページを公開済みとして扱う。
- メグルムプラスの購入ボタン、復元ボタン、価格、特典説明又は状態表示が見えるのに、App Store Connect商品、IAP Availability、特商法、Privacy/App Privacy、サーバー検証、返金/取消/期限切れ同期が未確認。

## 6. 公開URL反映前の最終確認

公開URLへ流し込む直前に確認する。

| Check | 確認 | 結果 |
|---|---|---|
| PUB-001 | `notes/58` のMust before submitが全て反映済み | TODO |
| PUB-002 | 未反映又は要再確認の論点が初回提出に影響しない | TODO |
| PUB-003 | 初回で隠す有料機能、外部AI、外部画像URL、顔候補付け、未完成3D、住所/電話番号入力を断定説明していない | TODO |
| PUB-004 | 代表者情報非公表の請求対応フローがある | TODO |
| PUB-005 | 特商法表示を公開する場合、価格とApp Store設定が一致 | TODO |
| PUB-006 | Privacy Policy URLの内容がApp Privacy回答と一致 | TODO |
| PUB-007 | Support URLから削除、通報、Privacy請求へ辿れる | TODO |
| PUB-008 | 公開ページレダクションQAがPass | TODO |
| PUB-009 | App Store Connectへ転記する文面が最終版 | TODO |
| PUB-010 | 証跡保存先とmanifestが決まっている | TODO |
| PUB-011 | `/terms` / `/privacy` / `/legal/terms` / `/legal/privacy` のどれを開いても提出対象の同じ正式本文へ到達する、又は使わないURLからリダイレクトされる | TODO |

## 6.1 公開実装同期チェック

弁護士回答をMarkdown原稿へ反映しただけでは提出可能にならない。公開前に、実装済みWebページ、アプリ内同意リンク、アプリ内法務要約、Privacy Manifest、App Store Connect入力予定値を同じ前提へそろえる。

| 対象 | 確認すること | No-Go |
|---|---|---|
| `web/src/app/terms/page.tsx` | 公開するTerms URL、最終更新日、本文が最新ドラフトと一致。Keychain/session保存、認証リンク、候補表示非保証、AdMob/外部AI/写真メタデータ、UGC・App Review 1.2、公開レビュー返信、事故初動、販促通知、公式連絡・フィッシング等の最新追加論点が反映済み | 2026-06-26短縮版のままApp Store又はアプリ内リンクで正式本文として使う |
| `web/src/app/privacy/page.tsx` | Privacy Policy URL、App Privacy回答、外部サービス台帳、SDK/通信監査、Keychain/session保存、access token、refresh token、認証callback、通知linkPath、現在地共有/服装写真の保持文言、近距離公開、作成位置、閲覧者位置、現地交換モード、1km/3km非保証、公開レビュー返信、事故疑い、販促同意/停止履歴、不審連絡/フィッシング報告と一致 | 2026-06-29版で追加した取得情報又は利用目的が公開Privacyにない。又は30日後自動削除/完全削除を未確認のまま保証している |
| `web/src/app/support/page.tsx` | Support URLから削除、個人情報請求、通報、安全、AI、FAQ、広告報告、最新Terms/Privacy、公式連絡・フィッシング注意、販促通知停止案内へ辿れる | 存在しない個別URLをReview Notesや公開サポートで公開済みと書く。又はSupport関連リンクが旧短縮Terms/Privacyだけへ誘導する。又は公式が秘密情報を求めるように読める |
| `ios-native/Sources/MegrumApp/AuthLegalConsentNotice.swift` | 登録同意リンクが公開正URLへ向いている | App Storeでは `/legal/privacy`、登録同意では `/privacy` のように分裂している |
| `ios-native/Sources/MegrumApp/LegalDocumentContent.swift` / `SettingsLegalViews.swift` | アプリ内要約が正式本文ではない旨と、正式本文リンクが整合 | 要約表示だけで正式な公開規約/Privacy要件を満たした扱いにする |
| `ios-native/App/PrivacyInfo.xcprivacy` | Required Reason API、Tracking、SDK利用、App Privacy回答の役割分担が整理済み | Privacy Manifestが最小だから収集データなしと誤判定する |
| App Store Connect | Privacy Policy URL、Support URL、Review Notes、App Privacy、License Agreementが公開URLと一致 | 入力値が旧URL、未公開URL、又は古い短縮本文を指す |

実装同期が未完了の場合は、提出判断では `G5 Legal URL`、`G16 Legal Publication`、`G21 ASC Final Input` をNo-Go又はConditional Goにする。

## 7. 反映後の確認コマンド

```bash
rg -n "TODO|TBD|未反映|要再確認|●●|予定価格" notes/legal notes/25_public_legal_support_pages.md notes/55_public_help_faq_draft.md notes/40_app_store_connect_copy_paste_sheet.md notes/43_app_privacy_connect_answer_sheet.md
```

```bash
rg -n "password|passwd|secret|token|private key|api[_-]?key|SUPABASE|service_role|anon key|debug|stack trace|localhost|127\\.0\\.0\\.1" notes/legal notes/25_public_legal_support_pages.md notes/55_public_help_faq_draft.md
```

```bash
git diff --check -- notes
```

注意:
- Draft段階のTODOは管理上残せるが、公開HTML、App Store Connect転記文、Review Notes最終版には残さない。
- 実パスワード、secret、実ユーザー情報、実代表者情報を検索で見つけた場合は、公開作業を止める。

## 8. 反映完了記録テンプレート

```text
Legal review publication finalization

Review response received:
Owner:
Source saved at:
Tracker IDs:
Must before submit resolved:
Deferred items:

Updated docs:
- Terms:
- Privacy:
- Support:
- FAQ:
- Commerce:
- App Store copy:
- App Privacy:

Public URL status:
- Support:
- Privacy:
- Terms:
- Commerce:
- Account deletion:
- Report:
- FAQ:

No-Go remaining:
Evidence folder:
Decision: Ready for publication / Conditional / Stop
```

## 9. 公的・公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- 消費者庁 特定商取引法ガイド 通信販売広告: https://www.no-trouble.caa.go.jp/what/mailorder/advertising.html
- 消費者庁 特定商取引法ガイド 通信販売広告Q&A: https://www.no-trouble.caa.go.jp/qa/advertising.html
- 個人情報保護委員会 法令・ガイドライン等: https://www.ppc.go.jp/personalinfo/legal/
- 個人情報保護委員会 ガイドラインQ&A: https://www.ppc.go.jp/personalinfo/faq/APPI_QA/

## 10. 関連文書

- 法務レビュー依頼メモ: `notes/29_legal_review_brief.md`
- 法務レビュー回答反映台帳: `notes/58_legal_review_response_tracker.md`
- 法的文書整合性管理: `notes/17_legal_alignment.md`
- 公開法務・サポートページ: `notes/25_public_legal_support_pages.md`
- 公開ヘルプFAQ: `notes/55_public_help_faq_draft.md`
- 公開ページレダクションQA: `notes/63_public_page_redaction_qa.md`
- 公開URL公開チェックリスト: `notes/37_public_url_publication_checklist.md`
- App Store Connect転記: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Privacy回答: `notes/43_app_privacy_connect_answer_sheet.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
