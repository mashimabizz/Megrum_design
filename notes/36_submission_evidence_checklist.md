# 36. App Store提出証跡チェックリスト

> 目的：TestFlight内部確認からApp Review提出までに、あとで見返せる証跡を揃える。
> コード変更なし。提出当日に「確認したはず」を減らすための記録台帳。

最終更新: 2026-06-29
ステータス: Draft v1.6（公開Web外部アセット・next/font/google・MapTiler/Nominatim未検出整理 / legacy Expo削除済み・APNs主線のPush証跡前提 / ローカルenv・Vercel env・Supabase secrets・server-only key境界 / デバッグログ・Edge Functionエラー・公開証跡secret混入防止 / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 古物営業・チケット不正転売 / 精密位置・MapKit・CoreLocation・逆ジオコーディング / EU DSA・配信地域 / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search / 顔特徴量RLS・学習データ可否 / 未成年・生年月日・広告通報を反映・提出前）

---

## 1. 証跡保管方針

| 項目 | 方針 |
|---|---|
| 保存先 | `notes/release_evidence/` 又はオーナー管理のDrive |
| 実パスワード | 証跡に含めない |
| 個人情報 | 実在ユーザーの情報を含めない |
| スクショ | 必要箇所だけ。住所、メール、内部IDは隠す |
| ログ/エラー | token、secret、認証code、signed URL、画像URL、通知本文、通報本文、削除申出本文、外部API response textの実値を貼らない |
| env / secret | `.env.local`、`.vercel/.env.production.local`、`web/.env.local`、Supabase/Vercel/Apple/Stripe/Google等のsecret実値は保存しない。証跡はキー名、環境、確認日時、Pass/Failだけ |
| 命名 | `YYYY-MM-DD_appstore_vX.Y_buildN_項目` |

この文書はチェックリストであり、証跡ファイル自体はまだ作成しない。
証跡フォルダの構成、命名、manifest、保存してよい情報/保存しない情報は `notes/64_release_evidence_folder_index.md` を使う。

---

## 2. 提出メタ情報

| 項目 | 値 |
|---|---|
| 提出日 | TODO |
| App Version | TODO |
| Build Number | TODO |
| Bundle ID | TODO |
| Xcode / Transporter / EASなどのアップロード方法 | TODO |
| App Store Connect提出者 | TODO |
| 初回提出の範囲 | TODO |

---

## 3. 必須証跡

| ID | 領域 | 証跡 | 関連 |
|---|---|---|---|
| EV-001 | Build | App Store Connectで提出ビルドがProcessing完了 | `notes/32` |
| EV-002 | Auth | デモアカウントでログインできる | `notes/35` |
| EV-002.5 | Auth Links | `MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Supabase Redirect URLs、Google OAuth設定、Web中継Route、Review Notesの一致と、認証リンク/認証コード共有禁止説明 | `notes/24`, `notes/27`, `notes/48`, `notes/54`, `notes/75` |
| EV-002.6 | Keychain Session | 保存済みsession復元、refresh token更新、ログアウト時local clear、token実値がログ/証跡/スクショへ出ないこと、Keychain accessibility方針の確認 | `notes/17`, `notes/27`, `notes/45`, `notes/48`, `notes/52`, `notes/54`, `notes/75` |
| EV-002.7 | Logs / Error Evidence | Swift DEBUG OSLog、Function logs、外部API error detail、管理者監査JSON、App Review証跡、サポート返信にtoken、secret、signed URL、画像URL、通知本文、通報/削除申出本文の実値が入らないこと | `notes/27`, `notes/43`, `notes/48`, `notes/52`, `notes/54`, `notes/64` |
| EV-002.8 | Secret / Env Boundary | `.env.local`、`.vercel`、Supabase secrets、Vercel env、APNs private key、Google OAuth secret、Stripe webhook secret、OpenAI API key、service role keyを証跡・PR・公開ページへ入れず、キー名だけで確認できること | `notes/48`, `notes/54`, `notes/61`, `notes/64`, `notes/75` |
| EV-003 | Legal URL | Terms、Privacy、Support、Commerceが開き、提出に使う最新版ドラフトと本文・最終更新日・URLが一致する。2026-06-26短縮ページを2026-06-29改訂案の代替として使わない | `notes/25`, `notes/63` |
| EV-003.5 | Public Web External Assets | 公開WebのHTML/Networkに `fonts.googleapis.com` / `fonts.gstatic.com`、MapTiler、Nominatim等の未使用外部サービスが出ていないこと。`next/font/google` はself-host前提だが、デプロイ済み成果物で確認する | `notes/48`, `notes/63` |
| EV-004 | App Privacy | App Store Connect回答の控え | `notes/27` |
| EV-005 | Privacy Manifest | 実ビルドのPrivacyInfo.xcprivacy確認 | `notes/27` |
| EV-006 | Account Deletion | アプリ内削除入口が見える | `notes/26` |
| EV-007 | UGC Safety | 通報、ブロック入口が見える。直接ボタンがないUGC対象はsupport@フォールバックを説明できる | `notes/26` |
| EV-008 | Core Flow | 在庫、wish、打診、取引チャットが通る | `notes/32` |
| EV-009 | Screenshot | App Store用スクショ一式 | `notes/28` |
| EV-009.5 | Product Page Assets | App icon、App Preview、poster frame、Product Page PreviewのQA結果 | `notes/70` |
| EV-010 | Review Notes | App Review Notes最終本文 | `notes/31` |
| EV-010.5 | ASC Final Input | App Store Connect実入力値と提出docs/buildの最終差分QA | `notes/71` |
| EV-011 | Copy Sheet | App Store Connectへ入力した最終文面 | `notes/40` |
| EV-012 | Security Audit | RLS、Storage、secret、APNs、公開URL、管理者権限の監査結果 | `notes/54` |
| EV-013 | Release Control | 承認後のRelease option、PDR gate、Release This Version、公開初日監視の記録 | `notes/72` |
| EV-014 | Signing / Capabilities | Bundle ID、App ID、Capabilities、profile/certificate照合 | `notes/75` |
| EV-015 | Territory / DSA / IAP Availability | App Availability、EU DSA trader status、商品ページ表示連絡先、IAP Availabilityの証跡 | `notes/68`, `notes/71` |

---

## 4. 条件付き証跡

| ID | 条件 | 証跡 | 関連 |
|---|---|---|---|
| EV-101 | 有料機能を出す | IAP商品、価格、購入復元、Sandbox購入 | `notes/33` |
| EV-102 | 外部AIを出す | 送信前説明、OpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否、第三者/未成年/権利未処理画像禁止、AI結果修正、App Privacy回答 | `notes/legal`, `notes/24`, `notes/27`, `notes/43`, `notes/56` |
| EV-102.5 | 外部画像URL又はAI/検索候補画像を出す | 外部ホスト通信、第三者ポリシー、Content Rights、権利確認責任、FAQ/Privacy/Review Notes整合 | `notes/24`, `notes/46`, `notes/53`, `notes/56` |
| EV-102.6 | 写真アップロードを出す | カメラ/写真ライブラリのInfo.plist権限文言、EXIF/GPS/撮影日時/端末情報など画像メタデータの残存経路、削除可否、App Privacy影響 | `notes/24`, `notes/27`, `notes/43`, `notes/52` |
| EV-102.7 | 位置情報/地図を出す | Precise Location回答、MapKit/CoreLocation/CLGeocoder、精密座標の送信/保存、場所名/距離/近接判定の非保証、保持/削除例外、Privacy/FAQ/Review Notes整合 | `notes/24`, `notes/27`, `notes/43`, `notes/48`, `notes/55`, `notes/56` |
| EV-103 | 現地交換スコープ | 住所登録系導線が見えない、削除/問い合わせ導線がある | `notes/26`, `notes/35` |
| EV-104 | グルーム/掲示板を出す | 通報、ブロック、モデレーション確認。掲示板はスレッド/返信のSwift通報導線又はsupport@フォールバックを確認 | `notes/26` |
| EV-105 | Push通知を出す | 通知許可文言、APNs token、push provider、app version、last seen、revoked状態、通知タイトル/本文、通知ID、linkPath、sound、未読バッジ、ロック画面/通知センター/連携端末表示、通知受信、Push任意性、販促Push同意/停止手段。過去又は別環境でExpo Pushを使う場合はExpo push tokenも別途証跡化 | `notes/27`, `notes/43`, `notes/48`, `notes/52`, `notes/56` |
| EV-106 | 個人情報・セキュリティ事故疑いがある | 受付番号、初動記録、法務確認、本人通知/PPC報告判断 | `notes/49` |
| EV-107 | 広告を出す | 広告表示画面、不適切/年齢不相応広告の通報導線、サポート説明、App Privacy回答、Google公式データ開示、Privacy Manifest、ATT/Tracking回答、SKAdNetworkItems、test ads除去、同意管理要否 | `notes/25`, `notes/27`, `notes/40`, `notes/43`, `notes/44`, `notes/48`, `notes/53`, `notes/56` |
| EV-108 | 生年月日入力又は年齢表示を出す | 生年月日入力、年齢/年代表示、自己申告年齢の説明、未成年者の保護者同意・現地交換安全説明、Age Rating/App Privacy回答 | `notes/25`, `notes/43`, `notes/46`, `notes/53` |
| EV-109 | 顔候補付けを出す | Face IDではない説明、Sensitive Info回答、第三者画像禁止、`member_face_profiles`読み取り範囲、`shouldAddTrainingData`又は学習データ追加可否、削除/利用停止説明 | `notes/27`, `notes/43`, `notes/52`, `notes/56` |
| EV-110 | グッズ交換/現金差額/チケット禁止を出す | 売買マーケット、古物商、古物市場、古物競りあっせん、オークション、買取、販売代理、チケット譲渡、入場資格保証、決済代行、エスクローではない説明と、チケット/盗品/反復継続販売禁止の証跡 | `notes/legal/01`, `notes/24`, `notes/40`, `notes/50`, `notes/55`, `notes/56` |
| EV-111 | ホーム候補/検索/レコメンドを出す | 候補表示、検索結果、マッチ/条件一致ラベル、検索候補、人気検索、表示順、Plus優先表示、広告挿入、Product Personalizationの説明、非保証文言、Search History / Usage Data / Product Personalization回答、検索ログ保存有無の証跡 | `notes/legal/01`, `notes/legal/02`, `notes/24`, `notes/27`, `notes/43`, `notes/55`, `notes/56` |
| EV-112 | 共有シート/外部SNS共有を出す | 共有用テキスト/生成画像に含まれる表示名、グッズ画像、グッズ名、グループ/メンバー、タグ、ハッシュタグ、リンクの確認、外部共有後の保存/公開/再共有/削除非管理説明 | `notes/legal/01`, `notes/legal/02`, `notes/24`, `notes/27`, `notes/43`, `notes/48`, `notes/55`, `notes/56` |
| EV-113 | 通知linkPath/deep linkを出す | 通知 `linkPath`、ID付きdeep link、未知path fallback、リンクに含まれるID/path/queryの説明、認証callbackと混同しない導線確認 | `notes/24`, `notes/27`, `notes/43`, `notes/48`, `notes/54`, `notes/56` |

---

## 5. 内部スモークテスト記録フォーマット

| 項目 | 値 |
|---|---|
| 実施日時 | TODO |
| 実施者 | TODO |
| 端末 | TODO |
| iOS | TODO |
| App Version / Build | TODO |
| アカウント1 | TODO |
| アカウント2 | TODO |
| 結果 | Pass / Fail |
| 未確認 | TODO |

結果メモ:

```
SM-001 Auth:
SM-002 Inventory:
SM-003 Wish:
SM-004 Listing:
SM-005 Matching:
SM-006 Proposal:
SM-007 Negotiation:
SM-008 Trade:
SM-009 Legal:
SM-010 Scope:
SM-011 Safety:
SM-012 Account:
SM-013 Privacy:
SM-014 Scope:
```

---

## 6. App Review提出記録フォーマット

```
Submitted at:
Submitted by:
Version:
Build:
Submission status:
Included IAP:
Review Notes final:
Known exclusions:
  - Paid features:
  - External AI:
  - Non-local exchange flows:
  - Groom / board:
Evidence folder:
```

---

## 7. リジェクト時に残す証跡

| 項目 | 記録 |
|---|---|
| Resolution Centerの本文 | 全文を保存 |
| 指摘されたGuideline | 番号と本文要約 |
| 該当画面 | スクショ又は画面名 |
| Appleへの返信 | 送信前の下書きと送信後の本文 |
| 修正内容 | コード変更、文言変更、メタデータ変更を分ける |
| 対応判断 | 同じbuildで直す/new build/却下item削除/appeal候補を分ける |
| 再提出日時 | App Store Connectの状態と一緒に保存 |

---

## 8. 提出直前No-Go

次のどれかが未確認なら、提出を止める。

最終判定は `notes/50_release_go_no_go_decision_matrix.md` で行う。

- デモアカウントでログインできない。
- 利用規約、プライバシーポリシー、サポートURLが404。
- 公開Webに未説明の外部アセット、`fonts.googleapis.com` / `fonts.gstatic.com`、MapTiler、Nominatim等へのブラウザ直通信があり、Privacy/委託先台帳/証跡と一致していない。
- App Privacyと実ビルドのSDK/通信が矛盾している。
- ホーム候補、検索結果、「マッチしてるよ！」「交換できるかも？」「全一致」等が見えるのに、参考表示であり本人性、安全性、信用、所有権、真贋、支払い、発送、現地合流又は取引成立を保証しない説明の証跡がない。
- 検索語、`normalized_term`、`result_count`、検索時刻、人気検索、検索候補、表示順、Plus優先表示、広告挿入又はProduct Personalizationが有効なのに、App Privacy、Privacy、FAQ、Review Notesへ反映した証跡がない。
- App Store説明文、FAQ、スクショ、Review Notes又はアプリ内コピーで、Megrumが売買マーケット、古物商、古物市場、古物競りあっせん、オークション、買取、販売代理、チケット譲渡、入場資格保証、決済代行、エスクロー又は正規/公式流通確認サービスのように見える。
- 近くのグルーム、スポット掲示板、現在地共有、地図表示、逆ジオコーディング、場所名又は距離表示が見えるのに、Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標の送信/保存、場所名/距離/近接判定の非保証、保持/削除例外の証跡がない。
- 生年月日を収集し、年齢又は年代を表示するのに、App Privacy、Age Rating、FAQ、Review Notes、公開サポートが自己申告年齢として一致していない。
- 年齢確認機構、身分証確認、保護者同意確認又は保護者管理機能が未実装なのに、年齢確認済み、本人確認済み、保護者同意確認済みと説明している。
- Bundle ID、App ID、Capabilities、entitlements、provisioning profile、certificate、App Store Connect app recordが矛盾している。
- RLS、Storage公開範囲、secret、APNs通知の監査でNo-Goが残っている。
- `.env.local`、`.vercel/.env.production.local`、`web/.env.local`、Supabase secrets、Vercel env、APNs private key、OAuth client secret、Stripe webhook secret、OpenAI API key、service role keyの実値又はスクショが提出証跡、PR、公開ページ、サポート返信、App Review添付に残っている。
- アカウント作成があるのにアプリ内削除入口がない。
- 退会申請の30日後実削除、申請取消/復旧、Apple/Google連携解除、APNs token無効化が未確認なのに、公開ページやReview Notesで完了又は復旧を保証している。
- UGCがあるのに通報/ブロック/問い合わせ導線が説明できない。
- 有料機能が見えるのにIAP商品と価格が一致していない。
- 外部AIが見えるのにOpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否、送信前説明とPrivacy回答がない。
- Push通知が見えるのに、APNs token、通知本文、未読バッジ、ロック画面表示、App Privacy回答、アプリ内コピーの証跡がない。過去又は別環境でExpo Pushを使う場合は、Expo push tokenの証跡もない。
- Push通知を許可しないと登録又は主要機能を使えない、正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文をPush本文へ出す、又は販促Pushに同意・停止手段がない。
- 外部画像URL又はAI/検索候補画像が見えるのに、外部ホスト通信、第三者ポリシー、Content Rights、権利確認責任、FAQ/Privacy/Review Notes整合の証跡がない。
- 写真アップロードが見えるのに、EXIF/GPS/撮影日時/端末情報など画像メタデータの残存経路、削除可否、App Privacy影響の証跡がない。
- カメラ/写真ライブラリの権限文言が実用途より狭い、又は共有シート/外部SNS共有が見えるのに共有用画像/テキストに含まれる情報と外部共有後の非管理を説明した証跡がない。
- 顔候補付け、顔特徴量又は画像特徴量保存が見えるのにSensitive Info回答、Face ID非利用説明、`member_face_profiles`読み取り範囲、学習データ追加可否、削除/利用停止説明がない。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、不適切又は年齢に合わない広告の通報導線、サポート説明、App Privacy回答、Google公式データ開示、ATT/Tracking回答、test ads除去、同意管理要否の証跡がない。
- 住所登録又は住所表示の未完成導線が見える。
- スクショに実在IP、実住所、内部ID、デバッグ表示がある。

---

## 9. 関連文書

- リリーストリアージ: `notes/22_release_triage_tracker.csv`
- App Store提出パック: `notes/24_app_store_submission_pack.md`
- Trust & Safety SOP: `notes/26_trust_safety_release_sop.md`
- App Privacy照合: `notes/27_app_privacy_data_inventory.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- 提出前セキュリティ監査チェックリスト: `notes/54_prelaunch_security_audit_checklist.md`
- アカウント削除・個人情報請求ランブック: `notes/45_account_deletion_privacy_request_runbook.md`
- App Store質問票回答シート: `notes/46_app_store_questionnaire_answer_sheet.md`
- ドメイン・メール・公開URL運用ランブック: `notes/47_domain_email_publication_runbook.md`
- 外部サービス・委託先データ台帳: `notes/48_external_service_vendor_register.md`
- 個人情報・セキュリティ事故初動ランブック: `notes/49_privacy_security_incident_response_runbook.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- 提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- 公開URLチェックリスト: `notes/37_public_url_publication_checklist.md`
- TestFlight協力者向け案内: `notes/38_testflight_tester_comms.md`
- スクリーンショット台本: `notes/28_app_store_screenshot_storyboard.md`
- 商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- App Review Guideline適合マトリクス: `notes/53_app_review_guideline_compliance_matrix.md`
- App Store Connect入力表: `notes/31_app_store_connect_metadata_worksheet.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- 承認後・手動公開制御Runbook: `notes/72_app_store_approval_release_control_runbook.md`
- Apple Developer署名・Capabilities事前確認Runbook: `notes/75_apple_developer_signing_capabilities_preflight.md`
- TestFlight/App Review提出ランブック: `notes/32_testflight_review_submission_runbook.md`
- デモアカウント計画: `notes/35_demo_account_review_data_plan.md`
- 提出コントロールボード: `notes/39_release_command_center.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Review指摘対応テンプレート: `notes/41_app_review_response_templates.md`
- App Reviewリジェクト/追加情報要求Runbook: `notes/69_app_review_rejection_triage_runbook.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
