# 71. App Store Connect最終入力差分QA

最終更新: 2026-06-29

ステータス: Draft v1.2（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 古物営業・チケット不正転売 / 精密位置・MapKit・CoreLocation・逆ジオコーディング / AdMob実設定・ATT・テスト広告No-Go / 公開Web / アプリ内法務表示の実装同期監査を追加）

## 目的

App Store Connectへ実際に入力した値を、完成候補build、`notes/31`、`notes/40`、公開URL、App Privacy回答、Review Notes、スクリーンショット、商品ページ素材QAと照合し、Submit for Review直前の取り違えを防ぐ。

この文書は最終照合台帳であり、コード、App Store Connect設定、Apple Developer設定、公開URL、証跡ファイル自体は変更しない。

Bundle ID、Apple Developer側App ID、Capabilities、entitlements、provisioning profile、certificateの事前確認は `notes/75_apple_developer_signing_capabilities_preflight.md` を使う。

## 1. 公式前提の要点

Apple公式ヘルプ上、App Store提出には必要なmetadataと対象versionのbuild選択が必要になる。提出操作は、対象app versionで正しいbuildを確認し、Add for ReviewでDraft Submissionへ入れ、最後にSubmit for Reviewを押す流れになる。

App informationには、Name、Subtitle、Bundle ID、SKU、Primary Language、Category、Content Rights、License Agreement等の共有propertyが含まれる。Nameは2〜30文字、Subtitleは30文字以内。Privacy Policy URLはiOS/macOS appで必須。Bundle IDはbuild upload後に変更できず、Xcode project側のBundle IDと一致する必要がある。SKUもapp record追加後は変更できない。

Platform version informationには、Screenshots、App Preview、Promotional Text、Description、Keywords、Support URL、Marketing URL、Version Number、Copyright等が含まれる。Screenshotsは必須でlocalize可能。App Previewは任意で、localization/device sizeごとに最大3本。Promotional Textは170文字以内。Descriptionは4000文字以内、plain textでHTML不可。Keywordsは100 bytes以内で、app name/company nameの重複や他app/company名の利用を避ける必要がある。Support URLは必須で、protocolを含む完全なURLが必要。

初回提出のLicense Agreementは、代表者情報公開や独自EULA最低条項の抜け漏れを避けるため、Apple標準EULAを推奨する。独自EULAを使う場合は、Apple Minimum Terms、Megrum利用規約、弁護士レビュー、公開URL、App Store Connect入力値を照合する。

## 2. 使うタイミング

使う:
- App Store Connectへmetadata、screenshots/App Preview、App Privacy、Review Notes、build、IAP等を入力した後。
- Add for Reviewを押す前。
- Metadata Rejected後に、同じbuildでmetadataだけ修正した後。

使わない:
- 完成候補buildが未確定。
- App Store Connectへ未入力。
- デモアカウントや公開URLが未確定。
- 実パスワード、secret、tokenを記録しそうな状態。

## 3. 入力スナップショット

| 項目 | 値 |
|---|---|
| 照合日 | TODO |
| 照合者 | TODO |
| App Store Connect app record | Megrum |
| Version | TODO |
| Build Number | TODO |
| Bundle ID | TODO |
| Primary Language | TODO |
| Localizations | Japanese / English (U.S.) / Other |
| Draft Submission ID又は画面上の識別 | TODO |
| 同時提出item | None / IAP / In-App Event / Other |
| 証跡保存先 | TODO |

保存しない:
- Demo account password
- 2FA code
- secret、token、private key
- 実代表者情報、個人住所、個人電話番号
- App Store Connect担当者の個人情報が大きく写った管理画面

## 4. App Information差分QA

| Check | App Store Connect欄 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-FI-001 | Name | `Megrum`。`notes/31` / `notes/40` と一致 | TODO | TODO |
| ASC-FI-002 | Subtitle | 初回スコープと一致、30文字以内、過剰保証なし | TODO | TODO |
| ASC-FI-003 | Bundle ID | 完成候補build、開発側ハンドオフ、Xcode設定と一致 | TODO | `notes/65` |
| ASC-FI-003a | Apple Developer App ID / Capabilities | `notes/75` の署名・Capabilities確認と一致 | TODO | `notes/75` |
| ASC-FI-004 | SKU | 内部管理値として妥当。変更不可であることを理解 | TODO | TODO |
| ASC-FI-005 | Primary Language | Japanese方針と一致 | TODO | `notes/31` |
| ASC-FI-006 | Primary/Secondary Category | `notes/31` / `notes/46` の判断と一致 | TODO | TODO |
| ASC-FI-007 | Privacy Policy URL | 公開済み、HTTPS、ログイン不要、`notes/37` と一致 | TODO | `notes/37` |
| ASC-FI-007a | Privacy Policy URL route/content | App Store入力URL、公開Web route、登録同意リンク、Supportリンクが同じ最新版Privacy本文へ到達 | TODO | `notes/37`, `notes/63`, `notes/66` |
| ASC-FI-007b | Terms route/content | License Agreement方針、利用規約URL、登録同意リンク、Supportリンクが同じ最新版Terms本文へ到達 | TODO | `notes/37`, `notes/66` |
| ASC-FI-008 | Content Rights | 架空データ/UGC/権利侵害禁止/外部画像URL/AI候補画像の説明と一致 | TODO | `notes/46` |
| ASC-FI-009 | Age Rating | 質問票回答、UGC、チャット、IAP、AI露出、生年月日/年齢表示、Age Assuranceなしと一致 | TODO | `notes/46` |
| ASC-FI-010 | License Agreement | 初回はApple標準EULA推奨。独自EULAならApple Minimum Terms、利用規約、弁護士レビュー、公開URL方針と一致 | TODO | `notes/31`, `notes/46` |
| ASC-FI-011 | App Availability / DSA | 初回Japan-only方針、EU DSA trader status、商品ページ表示連絡先、IAP Availabilityと一致 | TODO | `notes/68` |

No-Go:
- Bundle ID、Name、Primary Language、Categoryの取り違えがある。
- Content Rightsで、外部画像URL又はAI/検索候補画像を公式素材、権利確認済み素材又は運営提供素材のように扱っている。
- Privacy Policy URLが404、ログイン必須、又は別内容。
- App Store Connectが `/legal/privacy` を指す一方、現行公開ページ又は登録同意リンクが `/privacy` の旧短縮本文を指している。
- Terms又はPrivacyのWebページ更新日/本文が、提出に使う2026-06-29版法務ドラフトと一致していない。
- Content Rightsがスクショ/初期データ/UGC実態と矛盾している。
- 生年月日又は年齢表示が見えるのに、Age RatingやReview Notesで自己申告年齢として説明していない。
- 初回Japan-only方針なのに、EU又はAll Countries or Regionsを含むApp Availability、未確認のDSA trader status、又は広すぎるIAP Availabilityで提出する。

## 5. Version Metadata差分QA

| Check | App Store Connect欄 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-VM-001 | Version Number | 開発側ハンドオフ、TestFlight確認buildと一致 | TODO | `notes/65` |
| ASC-VM-002 | Promotional Text | `notes/40` の最終候補と一致、170文字以内 | TODO | TODO |
| ASC-VM-003 | Description | 出す機能だけ説明、4000文字以内、HTMLなし | TODO | `notes/40` |
| ASC-VM-004 | Keywords | 100 bytes以内、app名/company名重複なし、他社名なし | TODO | TODO |
| ASC-VM-005 | Support URL | 公開済み、HTTPS、ログイン不要、連絡導線あり | TODO | `notes/37`, `notes/47` |
| ASC-VM-006 | Marketing URL | 入れる場合、公開済みで初回スコープと一致 | TODO | `notes/37` |
| ASC-VM-007 | Copyright | オーナー確認済み表記。Appleがsymbolを付ける前提で過不足なし | TODO | TODO |
| ASC-VM-008 | Screenshots/App Preview | `notes/70` の商品ページ素材QAと一致 | TODO | `notes/70` |
| ASC-VM-009 | Localization | `notes/60` と一致。English (U.S.)を出す場合は英語文面/素材も確認 | TODO | `notes/60` |

No-Go:
- 未完成の有料機能、外部AI、未完成3D、現地外の交換手段を説明している。
- DescriptionやReview Notesだけに、完成buildで辿れない機能が残る。
- Keywordsに実在IP、他app名、他社名、過剰な検索語が入る。
- Support URLに問い合わせ、削除、通報、Privacy請求へ辿る導線がない。

## 6. App Review Information差分QA

| Check | App Store Connect欄 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-AR-001 | Contact name | 審査中に対応できる担当。公開docsに実名を転記しない | TODO | TODO |
| ASC-AR-002 | Contact phone | 審査対応可能。公開リポジトリに書かない | TODO | TODO |
| ASC-AR-003 | Contact email | 受信確認済み。`support@megrum.jp` 又は審査用連絡先 | TODO | `notes/47`, `notes/67` |
| ASC-AR-004 | Demo account username | `notes/35` の方針と一致。実値はApp Store Connectだけ | TODO | `notes/35` |
| ASC-AR-005 | Demo account password | リポジトリや証跡に保存しない | TODO | TODO |
| ASC-AR-006 | Review Notes | `notes/40` / `notes/60` の最終Review Notesと一致 | TODO | TODO |
| ASC-AR-007 | Attachment | 必要な場合のみ。secretや個人情報を含まない | TODO | TODO |

Review NotesのNo-Go:
- Demo account passwordを公開リポジトリや証跡へ残す。
- 審査員が辿れない機能、隠した機能、未完成機能を説明する。
- UGC、安全、削除、公開URLの説明が実buildと違う。
- 評価、通報、ブロック、モデレーションの説明が実build、Terms/Privacy、FAQ、App Privacyと違う。
- ホーム候補、検索結果、マッチ/条件一致ラベル、検索候補、人気検索、表示順、Plus優先表示、広告挿入又はProduct Personalizationの説明が実build、Terms/Privacy、FAQ、App Privacyと違う。
- カメラ、写真ライブラリ、共有シートの説明が実build、Info.plist権限文言、Terms/Privacy、FAQ、App Privacyと違う。
- メール認証、パスワードリセット、Google OAuth、native callback、通知linkPath又はdeep linkの説明が実build、URL scheme、Supabase Redirect URLs、Google OAuth設定、Web中継Route、Terms/Privacy、FAQ、App Privacyと違う。
- 退会申請の30日後実削除、申請取消/復旧、Apple/Google連携解除、APNs token無効化が未確認なのに、Review Notes又はSupport URLで完了又は復旧を保証している。

## 7. App Privacy / 質問票 / IAP差分QA

| Check | 領域 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-PI-001 | App Privacy | `notes/27` / `notes/43` / 実SDK/通信と一致 | TODO | TODO |
| ASC-PI-002 | Privacy Policy URL | App Privacy欄とApp Information欄で同じ公開URL | TODO | TODO |
| ASC-PI-002a | Privacy Policy content sync | App Privacy回答で選ぶデータ型が、公開Privacy本文、Web実装、法務ドラフト、外部サービス台帳にある | TODO | `notes/27`, `notes/37`, `notes/43`, `notes/48`, `notes/63` |
| ASC-PI-003 | Export Compliance | `notes/46`、Info.plist、実buildと一致 | TODO | TODO |
| ASC-PI-004 | Age Rating | `notes/46` と一致 | TODO | TODO |
| ASC-PI-005 | Content Rights | `notes/46`、スクショ、初期データ、UGC方針と一致 | TODO | TODO |
| ASC-PI-006 | IAP | 出す/隠す判断、価格、Availability、特商法表示と一致 | TODO | `notes/33`, `notes/68` |
| ASC-PI-007 | DSA / Territory | 初回配信地域、DSA status、商品ページ表示連絡先、代表者情報非公表方針、IAP Availabilityと一致 | TODO | `notes/68` |
| ASC-PI-008 | Sensitive Info / 顔候補付け | 顔候補付け露出、App Privacy、Privacy Policy、Review Notesが一致 | TODO | `notes/27`, `notes/43`, `notes/52` |
| ASC-PI-008.5 | Push通知 | APNs/Expo token、push provider、app version、last seen、revoked状態、通知本文、通知ID、linkPath、sound、未読バッジ、ロック画面/通知センター/連携端末表示、Push任意性、販促Push同意/停止手段、Identifiers/User Content/Usage Data回答が一致 | TODO | `notes/27`, `notes/43`, `notes/48`, `notes/52`, `notes/56` |
| ASC-PI-008.6 | Location / MapKit | 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示と、Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標の送信/保存、作成位置、閲覧者位置、保持/削除例外、地図/距離/場所名の非保証、1km/3km非保証が一致 | TODO | `notes/27`, `notes/43`, `notes/48`, `notes/55`, `notes/56` |
| ASC-PI-008.7 | 生年月日 / 年齢表示 | Other Data Types候補、Age Assuranceなし、Parental Controlsなし、自己申告年齢説明が一致 | TODO | `notes/25`, `notes/43`, `notes/46`, `notes/55` |
| ASC-PI-008.8 | 評価 / 通報 / ブロック / モデレーション | Customer Support / Other User Content / Other Data Types / Product Interaction候補、通報者秘匿の限界、緊急時外部連絡、保持/削除説明が一致 | TODO | `notes/25`, `notes/26`, `notes/43`, `notes/52`, `notes/55`, `notes/56` |
| ASC-PI-008.9 | Prohibited trades / 古物・チケット | 売買マーケット、古物商、オークション、買取、販売代理、チケット譲渡、決済代行ではない説明と、チケット/盗品/反復継続販売禁止が一致 | TODO | `notes/legal/01`, `notes/24`, `notes/40`, `notes/50`, `notes/55`, `notes/56` |
| ASC-PI-008.9a | Member Payment / Financial Boundary | 支払い設定、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定、成立後支払い情報スナップショット、Payment Info、合意後表示、保持、相手保存リスク、外部決済サービス非関与、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR非保証が一致 | TODO | `notes/legal/01`, `notes/legal/02`, `notes/24`, `notes/27`, `notes/40`, `notes/43`, `notes/48`, `notes/50`, `notes/52`, `notes/55`, `notes/56` |
| ASC-PI-008.10 | Home/Search/Product Personalization | ホーム候補、検索結果、検索候補、人気検索、表示順、Plus優先表示、広告挿入、Search History / Usage Data / Product Personalization、非保証説明、検索ログ保存有無が一致 | TODO | `notes/legal/01`, `notes/legal/02`, `notes/24`, `notes/27`, `notes/43`, `notes/55`, `notes/56` |
| ASC-PI-008.11 | Camera/Photos/Share Sheet | カメラ/写真ライブラリ権限文言、写真ライブラリ元画像データ、画像メタデータ、共有用生成画像/テキスト、外部共有後の保存/公開/再共有/削除非管理が一致 | TODO | `notes/legal/01`, `notes/legal/02`, `notes/24`, `notes/27`, `notes/43`, `notes/48`, `notes/55`, `notes/56` |
| ASC-PI-008.12 | Auth Links / URL Scheme / Deep Links | メール認証、パスワードリセット、Google OAuth、native callback、通知linkPath、ID付きdeep link、URL scheme、Supabase Redirect URLs、Google OAuth設定、Web中継Route、認証リンク/認証コード共有禁止説明が一致 | TODO | `notes/legal/01`, `notes/legal/02`, `notes/24`, `notes/27`, `notes/43`, `notes/48`, `notes/54`, `notes/55`, `notes/56`, `notes/75` |
| ASC-PI-008.13 | Keychain Session / Refresh Token | Keychain保存session、access token、refresh token、expires、user id、email、refresh更新、logout時local clear、Keychain accessibility方針、端末紛失/バックアップ/他端末session説明が一致 | TODO | `notes/legal/01`, `notes/legal/02`, `notes/17`, `notes/27`, `notes/43`, `notes/48`, `notes/52`, `notes/54`, `notes/55`, `notes/75` |
| ASC-PI-009 | Draft Submission items | 同時提出itemの有無が `notes/62` と一致 | TODO | TODO |
| ASC-PI-010 | Advertising / ad reporting | 広告露出、Age Rating、App Privacy、Review Notes、広告通報導線、サポート説明が一致 | TODO | `notes/25`, `notes/36`, `notes/53`, `notes/56` |

No-Go:
- App Privacy回答と実buildのSDK/通信が違う。
- ホーム候補、検索結果、「マッチしてるよ！」「交換できるかも？」「全一致」等が見えるのに、参考表示であり本人性、安全性、信用、所有権、真贋、支払い、発送、現地合流又は取引成立を保証しない説明がApp Privacy、Privacy、FAQ、Review Notesで一致していない。
- 検索語、`normalized_term`、`result_count`、検索時刻、人気検索、検索候補、表示順、Plus優先表示、広告挿入又はProduct Personalizationが有効なのに、App Privacy、Privacy、FAQ、Review Notesで一致していない。
- App Store説明文、FAQ、スクショ、Review Notes又はアプリ内コピーで、Megrumが売買マーケット、古物商、古物市場、古物競りあっせん、オークション、買取、販売代理、チケット譲渡、入場資格保証、決済代行、資金移動、収納代行、回収代行、返金窓口、チャージバック窓口、エスクロー又は正規/公式流通確認サービスであるように見える。
- Privacy Policy URLが実在しても、本文が旧短縮版で、App Privacy回答に必要な郵送先、支払い情報、成立後支払い情報スナップショット、通知、広告、評価/通報、削除申出、顔候補付け等を説明していない。
- 支払い設定、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定又は成立後支払い情報スナップショットが見えるのに、Payment Info、合意後表示、保持、相手保存リスク、金融/決済サービス非関与、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR非保証がApp Privacy、Privacy、FAQ、Review Notesで一致していない。
- 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示が見えるのに、Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標の送信/保存、作成位置、閲覧者位置、保持/削除例外、地図/距離/場所名の非保証、1km/3km非保証がApp Privacy、Privacy、FAQ、Review Notesで一致していない。
- Push通知が見えるのに、通知本文、未読バッジ、ロック画面表示、APNs/Expo token、App Privacy回答、Review Notesが一致していない。
- Push通知を許可しないと登録又は主要機能を使えない、正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文をPush本文へ出す、又は販促Pushに同意・停止手段がない。
- 生年月日又は年齢表示が見えるのに、App Privacy、Age Rating、FAQ、Review Notesで自己申告年齢として一致していない。
- 年齢確認機構、身分証確認、保護者同意確認又は保護者管理機能が未実装なのに、年齢確認済み、本人確認済み、保護者同意確認済みと説明している。
- 評価コメント、通報、異議申し立て、ブロック、モデレーションが見えるのに、緊急通報、法的判断、本人確認、安全確認、信用保証、削除/解決保証ではない説明がない。
- 通報者情報を絶対非開示と保証している、又はブロックで過去取引、チャット、証跡、評価、通報記録が当然に削除されるように説明している。
- カメラ/写真ライブラリの権限文言が実用途より狭い、写真ライブラリ由来のEXIF/GPS/撮影日時/端末情報を確認していない、又は共有シート/外部SNS共有後の保存・公開・再共有・削除非管理を説明していない。
- 認証リンク、callback URL、access token、refresh token、認証コード、通知linkPath、ID付きdeep linkを第三者へ共有してよいように説明している、又はURL scheme / Supabase Redirect URLs / Google OAuth設定 / Web中継Route / Review Notesが不一致。
- Keychain保存session、refresh token更新、logout時local clear、Keychain accessibility/backups/復元/他端末sessionの説明がPrivacy、FAQ、Security checklistと不一致、又はlogout/退会で全session/tokenの即時完全削除を保証している。
- 顔候補付け、顔特徴量又は画像特徴量保存が見えるのにSensitive Info回答又は説明がない。
- 有料機能が見えるのにIAPが未提出又は価格/Availabilityが未確認。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、不適切又は年齢に合わない広告の通報導線、サポート説明、App Privacy回答、Google公式データ開示、ATT/Tracking回答、test ads除去、同意管理要否がない。
- DSAや配信地域の判断が未確定のままAll Countries等を選んでいる。

## 8. 差分対応判断

| 差分 | 対応 | 提出可否 |
|---|---|---|
| 誤字、軽微な表現ゆれ | `notes/40` 又はApp Store Connectの入力値を合わせる | 修正後に可 |
| 説明文に未露出機能が残る | 説明文、スクショ、Review Notesから削る | 削除後に可 |
| App Privacy回答漏れ | `notes/43` とApp Store Connect回答を修正し、実buildと再照合 | 修正後に可 |
| Build/Version取り違え | 正しいbuildへ差し替え、`notes/65` と証跡を再確認 | 修正後に可 |
| コード修正が必要な差分 | 開発側セッションへnew build依頼 | 現buildではNo-Go |
| 法務レビュー回答と矛盾 | `notes/58` / `notes/66` へ戻して公開文面も修正 | 修正後に再判定 |
| 削除申請の完了/復旧を過剰保証 | Review Notes、Support URL、FAQ、Terms/Privacyを `notes/45` に合わせる | 修正後に可 |
| 年齢確認/保護者同意を過剰保証 | Review Notes、Support URL、FAQ、Terms/Privacyを自己申告年齢前提へ合わせる | 修正後に可 |
| 評価/通報/ブロックの削除保証や通報者絶対秘匿を過剰保証 | Review Notes、Support URL、FAQ、Terms/Privacy、App Privacyを `notes/25` / `notes/43` / `notes/52` に合わせる | 修正後に可 |
| 候補表示/検索結果を過剰保証 | Review Notes、Support URL、FAQ、Terms/Privacy、App Privacyを参考表示・Product Personalization・Search History方針へ合わせる | 修正後に可 |
| 写真/共有の説明漏れ | Review Notes、Support URL、FAQ、Terms/Privacy、App Privacyをカメラ/写真ライブラリ権限、画像メタデータ、外部共有後の非管理方針へ合わせる | 修正後に可 |
| 認証リンク/Deep Linkの説明漏れ | Review Notes、Support URL、FAQ、Terms/Privacy、App PrivacyをURL scheme、認証callback、リンク秘密性、redirect設定方針へ合わせる | 修正後に可 |
| 実パスワードやsecretを証跡に保存した | 証跡を破棄し、安全な記録へ作り直す | 作り直しまでNo-Go |

## 9. 最終サインオフ

| 項目 | 判定 | 証跡 |
|---|---|---|
| App Information | Pass / Conditional / Fail | TODO |
| Version Metadata | Pass / Conditional / Fail | TODO |
| Screenshots / App Preview | Pass / Conditional / Fail | TODO |
| App Privacy | Pass / Conditional / Fail | TODO |
| Review Notes | Pass / Conditional / Fail | TODO |
| Review Contact / Demo Account | Pass / Conditional / Fail | TODO |
| IAP / 同時提出item | Pass / Conditional / Fail / Not exposed | TODO |
| DSA / Territory | Pass / Conditional / Fail | TODO |
| Draft Submission | Pass / Conditional / Fail | TODO |

最終判定:

```text
Decision: Go / Conditional Go / No-Go
Version:
Build:
Reviewed by:
Reviewed at:
Required fixes before Submit:
Evidence folder:
```

## 10. 関連文書

- App Store提出パック: `notes/24_app_store_submission_pack.md`
- App Store Connect入力ワークシート: `notes/31_app_store_connect_metadata_worksheet.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Storeローカライズ・メタデータQA: `notes/60_app_store_localization_metadata_qa.md`
- App Store商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- App Review手動提出チェック: `notes/62_app_review_manual_submission_checklist.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- 承認後・手動公開制御Runbook: `notes/72_app_store_approval_release_control_runbook.md`
- Release Candidateハンドオフ: `notes/65_release_candidate_handoff.md`
- 配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`

## 11. 公式参照

- Apple Required, localizable, and editable properties: https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties
- Apple App information: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Apple Platform version information: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Apple Minimum Terms for Developer's EULA: https://www.apple.com/legal/internet-services/itunes/dev/minterms/
