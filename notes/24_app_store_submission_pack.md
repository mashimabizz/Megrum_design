# 24. App Store 審査提出パック

最終更新: 2026-06-29

ステータス: Draft v2.3（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / UGC・App Review 1.2 / 公開Web同期監査 / Keychain・session保存・refresh token / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / APNs主線・legacy Expo条件付き・Push通知4.5.4 / 古物営業・チケット不正転売 / 精密位置・MapKit/CoreLocation・逆ジオコーディング / EU DSA・配信地域 / 公式非提携・権利物 / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search送信前説明 / 顔特徴量RLS・学習データ既定true / 郵送先・会員間支払い情報を反映・コード変更なし）

## 目的

この文書は、開発セッションと衝突せずに先回りで準備できる App Store Connect 入力内容、審査メモ、プライバシー回答、リリース前確認事項を1か所に集約する。

実装完了後は、実アプリの画面・SDK・通信内容と照合してから提出する。

提出全体の実行順と文書マップは `notes/39_release_command_center.md` を使う。
承認後の手動公開、`Pending Developer Release`、`Release This Version`、公開初日監視は `notes/72_app_store_approval_release_control_runbook.md` を使う。

## 前提

- 初回リリースの勝ち条件は、一般公開完了ではなく **App Store 審査への初回提出完了** とする。
- 利用規約・プライバシーポリシーは、`notes/legal/01_terms_of_service_draft.md` と `notes/legal/02_privacy_policy_draft.md` を公開前レビュー用ドラフトとする。
- 弁護士納品の原典は `利用規約など/` 配下の docx とし、公開文面は `notes/17_legal_alignment.md` と照合する。
- AI機能を外部AIサービスへ接続する場合は、送信情報、利用目的、Web検索その他外部情報参照、学習利用の有無、保持、削除可否、第三者提供又は委託の位置付けを画面上でも明示する。
- 「画像からシリーズ名称の候補を出す」等の導線を出す場合は、送信前にOpenAIその他外部AIへ画像データ又は画像URL、グループ名、メンバー名、グッズ種別、既存候補名が送られ、`web_search` 相当の外部情報参照を行うこと、汎用モデル学習に使うか、濫用監視等で保持される可能性、第三者の顔・未成年者・住所・チケット・注文履歴・秘密情報・権利未処理画像を送らないことを明示する。
- 外部画像URL又はAI/検索候補画像を表示する場合は、候補が公式情報又は権利確認済み素材ではないこと、外部画像ホスト/CDNへ通信情報が送信され得ること、権利確認責任を画面、FAQ、Privacy、Content Rights回答で揃える。
- 実在のアーティスト、グループ、メンバー、作品、キャラクター、商品名、商標等を使う場合、本アプリが権利者、所属事務所、興行主、公式ストア又は公式ファンクラブの公式/公認/提携サービスではないこと、名称は検索・分類・識別のための参考表示であることをメタデータ、FAQ、Review Notesで誤解なく説明する。
- カメラ、写真ライブラリ、写真アップロード、共有シートを出す場合は、`NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` が実際の用途、すなわちグッズ写真、プロフィール画像、取引チャット写真、服装写真、証跡写真、グルーム画像、スポット掲示板画像、共有用画像、AI又は顔候補付け用途と矛盾しないことを確認する。写真ライブラリ由来の元画像データはEXIF、GPS位置情報、撮影日時、端末情報等の画像メタデータを含み得るため、Photos or Videos、Location、Device Info回答への影響を確認する。
- 共有シート又は外部SNS共有を出す場合は、共有用テキスト、生成画像、表示名、グッズ画像、グッズ名、グループ名、メンバー名、グッズ種別、タグ、ハッシュタグ等が外部アプリへ渡され得ること、共有後の保存、公開、再共有、削除、広告利用、アクセス解析、画像メタデータ利用は共有先の規約/ポリシーに従うことをPrivacy、FAQ、Review Notes、アプリ内コピーで揃える。
- メール認証、パスワードリセット、Appleログイン、Googleログイン、OAuth中継、カスタムURL scheme、ディープリンク又は通知 `linkPath` を出す場合は、`MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Supabase Redirect URLs、Google OAuth設定、`https://megrum.jp/auth/oauth/authorize`、native callback scheme、App Store提出メモが一致することを確認する。認証callbackのfragment、access token、refresh token、通知リンク先、ID付きdeep linkを公開・転送してよいように説明しない。
- カスタムURL schemeはOS、端末、外部ブラウザ、メールアプリ、認証事業者、インストール済みアプリに依存するため、Universal Linksや本人確認済みリンクと同等の安全保証をしない。Review NotesとFAQでは、公式ドメイン確認、認証リンク/認証コードを共有しない注意、外部認証サービス依存、失敗時のサポート導線を説明する。
- ログイン状態を維持する場合は、AuthSessionの端末内Keychain保存、access token、refresh token、session更新、logout時local clear、`kSecAttrAccessible`方針、端末紛失/バックアップ/復元/他端末sessionの説明をPrivacy、FAQ、Review Notes、Security checklistで揃える。ログアウト又は退会で全session/tokenが即時完全削除されるように説明しない。
- ホーム候補、検索結果、マッチ表示、条件一致表示、検索候補、人気検索、表示順、レコメンド、Product Personalization、メグルムプラス優先表示又は広告挿入を出す場合は、プロフィール、推し、在庫、wish、個別条件、タグ、交換方法、活動エリア、位置又は日程設定、支払い方法要約、評価、完了取引数、ブロック関係、通知状態、利用状況、検索語、有料権限等に基づく参考表示であり、取引成立、安全性、本人性、信用、所有権、真贋、支払い、発送又は現地合流を保証しない説明をPrivacy、FAQ、Review Notes、App Privacyで揃える。
- グルーム、スポット掲示板、取引チャット、評価コメント、プロフィール、グッズ画像等のUGCを出す場合は、Apple App Review Guideline 1.2に合わせ、投稿前/投稿時の不適切コンテンツ対策、通報入口、ブロック入口、公開連絡先、運用SOP、対応目安を実ビルドとReview Notesで説明できる状態にする。入力制限、投稿頻度制限、URL/画像/添付形式/アカウント状態/通報履歴/NGワード等に基づくフィルタリング、自動検知、手動確認、投稿保留又は投稿拒否のうち、未実装のものをReview Notesへ書かない。
- めぐり、グルーム、スポット掲示板又は取引チャットを、ランダム/匿名チャット、Chatroulette風体験、出会い、性的接触、実在人物の外見評価、脅迫、いじめ、嫌がらせ又は晒し目的に見せない。投稿前/投稿時の不適切コンテンツ対策、通報、ブロック、公開連絡先が未確認の場合、UGC機能は提出スクショ、App Store説明、Review Notes、デモデータから外す。
- 検索ログ又は人気検索を有効にする場合は、検索語、`normalized_term`、`result_count`、検索時刻、30日人気検索集計等をSearch History / Usage Data / Product Personalizationとして回答候補に上げる。現行読み取りではDB/RPC基盤はあるがSwift呼び出しは未確認のため、提出直前に実ビルドで到達可否を確認する。
- Megrumを売買マーケット、古物商、古物市場、古物競りあっせん、オークション、買取、委託売買、販売代理、チケット譲渡、入場資格保証又は正規/公式流通確認サービスのように説明しない。チケット、入場用QRコード、抽選権、アカウント、盗品、不正取得品、権利侵害品、反復継続的販売又は古物営業のおそれがある取引を禁止する説明を、Description、FAQ、Review Notes、スクショ、アプリ内コピーで揃える。
- Push通知を出す場合は、APNs token、platform、push provider、app version、last seen、revoked状態、通知タイトル/本文、通知リンク先、未読バッジ、ロック画面/通知センター/連携端末表示、App PrivacyのIdentifiers/User Content/Usage Data回答をPrivacy、FAQ、アプリ内コピー、Review Notesで揃える。過去又は別環境でExpo Pushを使う場合は、Expo push tokenも別途照合する。
- Push通知はアプリ利用の必須条件にしない。通知本文へ正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文、その他機微な個人情報又は秘密情報を入れない。プロモーション又は直接マーケティング目的のPush通知を行う場合は、明示的同意とオプトアウト手段を用意する。
- 近くのグルーム、スポット掲示板、現在地共有、位置情報メッセージ、待ち合わせ候補、現地交換モード、地図表示又は逆ジオコーディングを出す場合は、Precise Location回答、MapKit/CoreLocation/CLGeocoder等のOS・地図関連処理、精密座標のサーバー送信・保存有無、作成位置、閲覧者位置、半径、距離、公開範囲、30日削除保証ではない保持/削除説明、地図・場所名・距離の非保証、1km/3kmが匿名化又は安全保証ではないことをPrivacy、FAQ、Review Notes、権限前コピーで揃える。現行Swift Nativeは精密座標を扱い得るため、「粗い地域だけ」として提出しない。
- 顔又はキャラクター候補付けを出す場合は、本人確認、年齢確認、Face ID認証、出入場管理、真贋鑑定、信用判断ではないことを画面、FAQ、Review Notes、App Privacyで揃える。`member_face_profiles` のembedding、source image URL、consent記録の読み取り範囲、補正履歴、`shouldAddTrainingData` / `should_add_training_data`、削除/利用停止/任意性が説明できない場合は非表示にする。
- 生年月日又は年齢表示を出す場合は、自己申告年齢であり、公的年齢確認、身分証確認、保護者同意確認又は本人確認が完了したことを意味しない説明を、FAQ、Review Notes、App Privacy、Age Ratingで揃える。
- 郵送交換、郵送先住所、電話番号、郵便番号検索、合意後の郵送先表示を出す場合は、Physical Address / Phone Number / Contact Info回答、ZipCloud等の外部送信、住所確認・本人確認・配送保証ではない説明を、Privacy、FAQ、Review Notesで揃える。
- 銀行振込、口座番号、口座名義、PayPay対応可否、現金交換、金額指定、合意後の支払い情報表示又は成立後支払い情報スナップショットを出す場合は、Financial Info / Payment Info回答候補へ上げる。Megrumが資金の受領、保管、送金、回収、返金、チャージバック、決済代行、収納代行、エスクロー、本人確認、口座名義確認、支払能力確認、外部決済アカウント/外部サービスID/送金リンク/QRコード/残高/送金可否/受領可否の確認を行うように説明しない。
- 初回提出では、代表者情報の公開リスクと独自EULAの最低条項照合漏れを避けるため、App StoreのLicense AgreementはApple標準EULAを使う方針を推奨する。独自EULAを選ぶ場合は、AppleのMinimum Terms、利用規約、弁護士レビュー、公開URL、App Store Connect入力値を照合してから提出する。
- 初回配信地域はJapanのみ候補とし、All Countries or Regions又はEU 27 territoriesを含める場合は、EU DSA trader status、App Store商品ページに表示されるProvider/Seller/contact情報、代表者情報非公表方針との差分、英語/現地語サポート可否をオーナー確認済みにする。DSA用の住所、電話番号、本人確認情報などの実値はリポジトリへ書かない。
- AdMob等の広告を表示する場合は、不適切又は年齢に合わない広告をユーザーが報告できる導線、報告受付後の広告枠/表示日時/スクリーンショット確認手順、広告配信事業者への報告手順を実ビルドと公開FAQで説明する。
- 現行読み取りでは `MEGRUM_ADS_ENABLED=YES`、AdMob app id、`MEGRUM_ADMOB_TEST_ADS_ENABLED=YES`、検索結果native広告unit id、やりとり一覧上部banner unit id、SKAdNetworkItemsが存在し、`NSUserTrackingUsageDescription`、ATT要求、UMP同意管理、非パーソナライズ広告指定は未確認。公開提出前に、テスト広告を一般公開しないこと、Google公式データ開示、App Privacy、Privacy Manifest、ATT/Tracking回答、SKAdNetworkItems、広告通報導線を実ビルドと一致させる。
- この文書は提出素材であり、アプリコード、Supabaseスキーマ、ビルド設定は変更しない。

## 1. App Store Connect 入力下書き

提出画面へ入力する前の詳細ワークシートは `notes/31_app_store_connect_metadata_worksheet.md` を使う。
提出直前にコピーする文面は `notes/40_app_store_connect_copy_paste_sheet.md` を使う。
App Store Connectへ実際に入力した値の最終差分照合は `notes/71_app_store_connect_final_input_reconciliation.md` を使う。
承認後に公開へ進めるかの最終読み合わせは `notes/72_app_store_approval_release_control_runbook.md` を使う。

有料機能を初回提出に含める場合は、IAP商品設定を `notes/33_iap_product_setup_worksheet.md` で先に固定する。価格固定文言、App Store Connect価格、特商法、FAQ、Review Notes、Server API/Notifications、返金/取消/期限切れ/請求失敗同期、手動有料権限上書きの理由/期限/監査ログ/非保証説明が揃うまでは有料導線を隠す。
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

Megrumは、ユーザー同士の交換を補助するサービスです。売買マーケット、古物商、買取、販売代理、オークション、チケット譲渡又は決済代行サービスではありません。金銭売買、チケット転売、盗品又は権利侵害品の取引、法令又は利用規約に反する利用は禁止しています。

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

現行Web実装の `/terms` / `/privacy` は2026-06-26短縮版であり、App Store提出時の正式本文としては未同期。App Store Connectへ入力するURL、登録同意リンク、Support関連リンク、公開リダイレクトを、2026-06-29版のTerms/Privacy本文へ到達する状態にしてから提出する。

### 著作権表記

Copyright (c) 2026 Megrum. All rights reserved.

## 2. 審査メモ下書き

App Review Notes に入れる文面のたたき台:

```
Megrum is a goods exchange app for fan communities. Users can register items they have, items they want, send proposals, negotiate exchange details, and complete transactions through an in-app trade chat.

The app does not sell physical goods directly. It provides matching and communication tools for user-to-user exchanges. Paid features, if enabled in this build, are limited to app functionality such as premium features or boosts and use Apple's in-app purchase where required.

Home candidates, search results, match labels, condition labels, recommendations, and display order are generated from user-provided profile/item/wish/listing/tag/exchange/payment/location or date settings, app usage signals, block/report state, and paid entitlement state. These displays are helper information only and do not guarantee identity, safety, authenticity, ownership, payment, delivery, meeting arrangements, or transaction completion. If Megrum Plus priority display, ads, search logs, popular search, or product personalization are enabled in this build, App Privacy answers and the Privacy Policy reflect that behavior.

Megrum is not an official, endorsed, sponsored, or affiliated service of any artist, idol group, character owner, publisher, event organizer, agency, label, official store, or fan club unless explicitly stated. Names of artists, groups, members, works, characters, products, trademarks, or events are used only to help users search, classify, and describe fan goods. They do not imply endorsement, rights clearance, authenticity verification, or permission to trade.

User-generated content areas include profiles, item images, trade chat, Groom posts, spot board threads/replies, evidence photos, and rating comments. These surfaces are account-based and are intended for fan-goods exchange and related local information sharing. They are not random or anonymous chat, dating, objectification, threat, bullying, or adult-content features.

The submitted build includes the UGC safeguards that are visible in the app: reporting flows, blocking flows, published support contact information, operational moderation, and the implemented pre-posting or posting-time controls described in the review evidence. We do not claim unimplemented filters or real-time monitoring. If any UGC surface in this build does not have a visible report/block path or support fallback, that surface is hidden from the submitted build and omitted from screenshots and metadata.

If AI-assisted item registration is available in this build, it is used to help extract or suggest item information from user-provided images/text. If the image-based series suggestion feature is enabled, selected images or image URLs and item context may be sent through our backend to OpenAI Responses API with web search enabled. This external AI processing is disclosed to the user before transmission, including what is sent, whether web search is used, training-use policy, retention/abuse-monitoring caveats, and a warning not to submit third-party/private/minor/unlicensed images or sensitive information.

Face/member candidate suggestions, if enabled, are used only to help users tag item photos. They do not use Face ID or biometric authentication and are not used for identity verification, age verification, venue access, authenticity checks, or credit decisions. If face embeddings, profile source images, correction history, or training-data flags are stored or readable in this build, those data types are disclosed in App Privacy and the in-app explanation describes consent, optionality, deletion/use-stop handling, and that users must not submit unauthorized third-party or minor face images.

The app may ask users to enter their birthdate during profile setup and may show derived age or age-range information in profile/discovery surfaces. This is self-reported information and is not official identity verification, age assurance, parental consent verification, or ID document verification.

If postal exchange or member-to-member payment support is enabled in this build, users may enter postal addresses, phone numbers, payment methods, bank transfer details, or cash adjustment amounts for completing a user-to-user trade. These are user-provided trade details shared only where the feature requires it. Megrum does not process payments, transfer funds, hold escrow, verify postal addresses, verify payment accounts, verify payment capacity, or guarantee delivery, payment, refunds, chargebacks, or external payment service safety.

If location-based features are enabled in this build, the app may request location permission for nearby Groom posts, spot board visibility/replies, meetup candidates, local mode, map display, and optional current-location messages in trade chat. The app may handle precise latitude/longitude, accuracy, timestamp, place labels, creation location, viewer location, radius, distance, visibility scope, and reverse geocoding through iOS location/map services and our backend. Location sharing is user-initiated for trade chat, but nearby features may use current or creation coordinates to determine visibility, posting, replies, or distance. "Nearby", "within 1 km", "within 3 km", same spot, or same prefecture are filtering concepts, not anonymity, identity verification, safety verification, or anti-stalking guarantees. Location, map, distance, and place labels are helper information and are not guaranteed to be exact or safe meeting guidance.

If camera, photo library, or sharing features are enabled in this build, users may capture or select images for item photos, profile images, trade chat photos, outfit photos, evidence photos, Groom posts, spot board images, and generated share images. Photo library images may retain EXIF, capture time, GPS location, device information, or other image metadata depending on image format, size, processing path, and external share destination. Generated share images/text may include display name, item images, item names, group/member names, tags, goods type, and hashtags. Once a user chooses an external app or service from the iOS share sheet, that external service controls publication, storage, reshare, deletion, analytics, and metadata handling under its own policies.

Authentication links and deep links are used for email verification, password reset, Google OAuth, notification routing, and in-app navigation. Google OAuth starts at https://megrum.jp/auth/oauth/authorize and returns to the native callback scheme configured for the build. Email/mobile auth callbacks may bridge through https://megrum.jp/auth/callback and then back to megrum://auth/callback or megrum-preview://auth/callback. Before submission, we verify that the app URL scheme, Supabase redirect allowlist, Google OAuth settings, and hosted relay route match the submitted build. Auth callback fragments may contain session tokens, so users are told not to share verification/reset links, callback URLs, screenshots, or authentication codes. Notification link paths and deep links are convenience navigation only and do not guarantee identity, safety, or transaction completion.

The app may store an authenticated session in the iOS Keychain for app functionality, including login persistence and refresh-token based session renewal. Logging out clears the local stored session first and then attempts the backend logout request. We do not ask users to share session tokens, and release evidence must not include token values in screenshots, logs, or support templates.

If AdMob ads are enabled in this build, Google Mobile Ads SDK may be initialized and ad requests may be sent for enabled ad placements. Before release, we confirm whether the build uses test ads or production ad units, whether IDFA or Apple-defined tracking is used, whether consent management is required for the target regions, and whether App Privacy answers match Google Mobile Ads SDK data disclosure. Users can report inappropriate or age-unsuitable ads through the app/support channel.

If ads are enabled in this build, users can report inappropriate or age-inappropriate ads from the in-app reporting/support flow. The support page explains how to include the screen, time, and screenshot for ad review.

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
| その他データ候補 | 生年月日、算出年齢又は年代 | プロフィール表示、安全確認、表示制御 | はい | いいえ |
| ユーザーコンテンツ | プロフィール、グッズ画像、投稿、取引チャット、通知本文、通報内容、共有用テキスト/生成画像 | アプリ機能、安全確保、サポート、共有機能 | はい | いいえ |
| 連絡先情報 | 郵送交換の宛名、郵便番号、住所、電話番号 | 郵送交換、配送トラブル対応、サポート | はい | いいえ |
| 財務情報 | 銀行名、支店名、口座種別、口座番号、口座名義、支払い方法、金額指定 | 会員間支払い、取引履行、紛争対応 | はい | いいえ |
| 位置情報 | 現在地共有、待ち合わせ候補、現地交換モード、近くのグルーム/スポット掲示板、地図表示、投稿/返信範囲判定、作成位置、閲覧者位置、1km/3km等の距離判定、逆ジオコーディングで扱う精密な緯度経度、精度、時刻、場所名 | 合流補助、近隣表示、掲示板/グルーム機能、安全対応 | はい | いいえ |
| 識別子 | ユーザーID、APNs通知トークン等。過去又は別環境でExpo Pushを使う場合はExpo通知トークンも別途確認 | 認証、通知、安全確保 | はい | いいえ |
| 購入 | アプリ内課金の購入状態、最終権限状態、手動有料権限上書きの有無 | 有料機能の提供、復元、問い合わせ対応 | はい | いいえ |
| 検索履歴/使用状況データ | 検索語、検索条件、検索結果件数、`normalized_term`、`result_count`、画面操作、機能利用状況、通知開封、未読バッジ、候補表示又は表示順に関するログ | 検索、候補表示、Product Personalization、品質改善、不正対策、通知機能 | 原則はい | いいえ |
| 診断 | クラッシュログ、パフォーマンスログ | 不具合解析、品質改善 | SDK設定による | いいえ |
| その他 | AI機能の入力・出力・ログ | AI機能提供、安全確保、品質改善 | 入力内容による | いいえ |
| Sensitive Info候補 | 顔検出結果、候補メンバー、補正履歴、顔特徴量又は画像特徴量 | グッズ画像の候補付け、安全確保、品質改善 | はい | いいえ |

注意:
- `NSPrivacyTracking` は、広告識別子や他社データと結合した追跡をしない限り `false` 方針。
- 外部AIサービスへ画像・本文・プロフィール情報等を送る場合は、App Privacy とプライバシーポリシーの委託/第三者提供欄に反映する。特にOpenAI Responses APIへ画像又は画像URLを送り、web searchを使うビルドでは、User Content / Photos or Videos / Other Data候補として、外部送信、保持、学習利用、濫用監視、削除可否を説明する。
- 外部画像URL又はAI/検索候補画像を表示する場合は、画像URL保存、外部ホスト/CDNへの通信、第三者ポリシー、端末キャッシュをApp Privacyと公開説明で確認する。
- 生年月日又は算出年齢/年代は、App Store Connect上の専用Data Typeが明確でない場合、Other Data Types又はAppleの最新UIで最も近いカテゴリとして開示する。Age Assurance、Parental Controls、Kidsカテゴリの回答と矛盾させない。
- 写真ライブラリから読み込んだ元データを保存する経路がある場合、EXIF、撮影日時、GPS位置情報、端末情報などの画像メタデータが残る可能性を確認し、Location / Device Info回答への影響を判断する。カメラ撮影画像でJPEG再生成される経路があっても、全経路でメタデータ削除を保証しない。
- 共有シートで外部アプリへ共有用画像、テキスト、ハッシュタグ又はリンクを渡す場合、外部サービス側の保存、公開範囲、再共有、削除、広告利用、アクセス解析、画像メタデータ利用をMegrumが管理できるように説明しない。
- 現在地共有、服装写真、取引チャット写真の保存期間説明は、30日後自動削除又は完全削除保証ではなく、運用目標・反映遅延あり・例外保持ありとしてPrivacy、FAQ、Review Notesと一致させる。
- 近くのグルーム/スポット掲示板、現在地共有、位置情報メッセージ、待ち合わせ候補、現地交換モード、作成位置、閲覧者位置又は逆ジオコーディングを出す場合、Precise Locationを回答候補へ上げる。実装上、精密座標をサーバーへ送る導線があるのに、Coarse Locationだけ又は端末内処理だけとして説明しない。
- 郵送交換を出す場合、郵送先住所、電話番号、郵便番号検索、合意後の郵送先表示がApp Privacy、Privacy、FAQ、Review Notesと一致していることを確認する。
- 支払い設定、銀行振込、PayPay対応可否、現金交換、口座番号入力、口座名義、金額指定、合意後の支払い情報表示又は成立後支払い情報スナップショットを出す場合、Financial Info / Payment Info回答候補、目的外利用禁止、外部決済サービス非関与、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR真正性確認の非保証をPrivacy、FAQ、Review Notesと一致させる。
- 有料機能を出す場合、手動有料権限上書きは購入証明、返金確定、補償又は無償提供継続ではなく、サポート又は運営上の暫定・補正手段であることを、Privacy、FAQ、Support、Review Notesと一致させる。
- 顔候補付けを出す場合、Apple Vision / Core ML / backend embedding のどれを使うか、顔特徴量又は画像特徴量を保存するか、外部送信するか、削除できるかを提出前に確定し、App PrivacyのSensitive Info候補として扱う。`member_face_profiles` のembedding/source image URLが認証済みユーザーに読める状態又は補正履歴の学習データ追加が既定trueで説明されない状態はNo-Go。
- 汎用AIモデルの学習利用にユーザー入力を使う場合は、初回提出前のP0として別途同意設計が必要。初回リリースでは使わない方針を推奨する。

## 4. PrivacyInfo.xcprivacy 照合メモ

現在確認済みの論点:
- `ios-native/App/PrivacyInfo.xcprivacy` は `NSPrivacyTracking=false` と UserDefaults の Required Reason API を宣言している。
- 提出前に、実際にリンクしている Apple SDK / Supabase / Firebase / Analytics / 画像処理 / Apple Vision / Core ML / Push通知 / 課金 / AI SDK が追加の Privacy Manifest 又は Required Reason API 宣言を必要としないか確認する。
- App Store Connect の App Privacy、アプリ内プライバシーポリシー、`PrivacyInfo.xcprivacy`、実際の通信内容が矛盾しないようにする。
- 顔候補付けを出す場合、顔検出結果、候補、補正履歴、顔特徴量又は画像特徴量が App Privacy / Privacy Manifest / Privacy Policy / 公開FAQ のどの項目で説明されるかを照合する。

提出前チェック:
- [ ] 収集データのカテゴリが App Privacy と一致している
- [ ] トラッキング有無が実装・SDK設定と一致している
- [ ] Required Reason API が不足していない
- [ ] 外部SDKの Privacy Manifest を確認した
- [ ] AIサービス、分析、クラッシュレポート、Push通知、課金の扱いを確認した
- [ ] 外部画像URL又はAI/検索候補画像を出す場合、外部ホスト通信、第三者ポリシー、画像URL保存、端末キャッシュを確認した
- [ ] 生年月日/年齢表示を出す場合、自己申告年齢説明、Age Rating、App Privacy、未成年者の保護者同意/現地交換安全説明を確認した
- [ ] 写真のEXIF、GPS位置情報、撮影日時、端末情報などの画像メタデータが残る経路とApp Privacy影響を確認した
- [ ] カメラ/写真ライブラリのInfo.plist権限文言が、グッズ写真、プロフィール画像、取引チャット写真、服装写真、証跡写真、グルーム画像、掲示板画像、AI/顔候補付け用途と矛盾しないことを確認した
- [ ] 共有シート又は外部SNS共有を出す場合、共有用テキスト/生成画像に含まれる情報と外部サービス移転後の非管理をReview Notes、FAQ、Privacy、アプリ内コピーで確認した
- [ ] 顔候補付けを出す場合、Sensitive Info候補、Face ID非利用、削除・利用停止導線を確認した
- [ ] 郵送交換を出す場合、Physical Address / Phone Number、郵便番号検索外部送信、住所確認・配送保証ではない説明を確認した
- [ ] 会員間支払いを出す場合、Payment Info、成立後支払い情報スナップショット、外部決済サービス非関与、決済代行・送金・収納代行・回収・返金・チャージバック・エスクロー・本人確認・口座名義確認・支払能力確認・外部ID/送金リンク/QR真正性確認ではない説明を確認した
- [ ] 広告を出す場合、不適切又は年齢に合わない広告の報告導線、広告通報データの取扱い、広告SDKのApp Privacy回答を確認した

## 5. AI機能の提出前確認

初回提出でAI機能を出す場合:
- [ ] AI機能がオンデバイス完結か、外部AIサービスへ送信するかを確定した
- [ ] 外部送信するデータを画面上で明示した
- [ ] 外部AIサービス名、利用目的、保存期間、学習利用の有無を説明できる
- [ ] 利用規約とプライバシーポリシーのAI条項と実装が一致している
- [ ] AI/検索候補画像を公式又は権利確認済み素材のように表示していない
- [ ] 外部画像URLを表示する場合、外部ホスト通信と権利確認責任を説明している
- [ ] AI出力の誤りをユーザーが確認・修正できる
- [ ] 顔候補付けを出す場合、本人確認/Face IDではない説明、第三者画像禁止、顔特徴量又は画像特徴量の保存・外部送信・削除方法を説明している
- [ ] 児童、センシティブ情報、権利侵害、なりすまし等に関わる禁止利用を規約・運用で扱える

初回提出では、外部AIに個人情報や画像を送る機能を無理に出さず、オンデバイス又は手入力補助に閉じる方が審査・法務リスクは小さい。
顔特徴量又は画像特徴量を生成・保存・照合する機能は、初回提出では非表示にするか、ユーザーへの説明、削除導線、App Privacy回答、Review Notesが揃ってから出す。

## 6. UGC / 通報 / ブロック / モデレーション

UGCがあるビルドで提出する場合、次を提出前P0として確認する。

- [ ] プロフィール、グッズ画像、投稿、スポット掲示板、取引チャットから不適切コンテンツを通報できる。画面内通報ボタンがない対象はsupport@フォールバックをReview Notes/FAQで説明できる
- [ ] 第三者の顔写真、未成年者画像、権利侵害画像、個人情報入り画像を通報・削除できる
- [ ] 相手ユーザーをブロック又は非表示にできる
- [ ] 広告を表示する場合、不適切又は年齢に合わない広告の通報/問い合わせ導線を説明できる
- [ ] 通報が運営側で確認できる
- [ ] 問い合わせ先がアプリ内とWebで確認できる
- [ ] 明らかに不適切な投稿・画像を削除又は非表示にできる運用がある
- [ ] 未完成のUGC導線は初回提出ビルドで露出しない

審査メモには、UGC領域と通報・ブロック・モデレーション体制を簡潔に書く。

## 7. アカウント削除

Apple審査前のP0:
- [ ] アプリ内の設定からアカウント削除を開始できる
- [ ] 削除対象データ、保持対象、削除予定日の意味、復旧/取消が保証されないことを確認画面又は公開ページで説明している
- [ ] Apple / Google / メール等のログイン連携解除方針を説明できる
- [ ] 削除申請後の通常利用停止、再ログイン時の表示、削除申請中状態が破綻しない
- [ ] 30日後の実削除ジョブ、手動処理手順、削除完了通知、申請取消/復旧処理の有無を、公開文面と矛盾なく説明できる
- [ ] 現在地共有、服装写真、取引チャット写真について、30日後自動削除/完全削除保証ではなく、運用目標と例外保持として説明できる
- [ ] 近くのグルーム/スポット掲示板、現在地共有、位置情報メッセージ、待ち合わせ候補、現地交換モード、地図表示、逆ジオコーディングを出す場合、Precise Location回答、MapKit/CoreLocation/CLGeocoder等の外部処理、精密座標の送信/保存、作成位置、閲覧者位置、半径、距離、公開範囲、地図・距離・場所名の非保証、1km/3km非保証を説明できる
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
- [ ] `https://megrum.jp/support/ads`（広告を出す場合）
- [ ] `support@megrum.jp` が受信できる
- [ ] 現行 `/terms` / `/privacy` / `/support` から辿れるTerms/Privacyが、2026-06-29版の正式本文又は同等リダイレクトへ同期済み
- [ ] 公開PrivacyにKeychain/session保存、access token、refresh token、認証callback、通知linkPath、精密位置、作成位置、閲覧者位置、現地交換モード、1km/3km非保証、写真メタデータ、外部AI/web_search、AdMob/ATT、30日保持目標と非保証が反映済み

特商法表示では、代表者名・住所・電話番号は原典方針どおり「請求があれば遅滞なく開示」とする。課金額、支払方法、解約、返金、提供時期は実際のアプリ内課金設定と合わせる。

公開ページ文面は `notes/25_public_legal_support_pages.md` を下書きとする。公開作業の受け入れ基準は `notes/37_public_url_publication_checklist.md`、問い合わせ一次返信は `notes/34_support_response_templates.md` を使う。

## 9. 権限説明文の下書き

Info.plist 等へ入れる前の文案。実装側が触るため、この文書では文面だけを管理する。

| 権限 | 文案 |
|---|---|
| カメラ | グッズ写真や取引証跡を撮影するためにカメラを使用します。 |
| 写真ライブラリ | グッズ写真、プロフィール画像、取引証跡を選択するために写真へのアクセスを使用します。 |
| 位置情報 | 待ち合わせや現在地共有で、あなたが選んだ相手に位置を共有するために使用します。 |
| 通知 | 打診、取引チャット、合意、取引状況の更新をお知らせするために通知を送信します。通知はロック画面、通知センター、連携端末に表示される場合があります。許可しなくてもアプリは利用できます。 |

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
- [ ] AI/検索候補画像、公式画像、権利未確認の外部画像URLが写っていない
- [ ] 有料機能が写る場合、App Storeの価格・IAP設定・アプリ内固定文言・特商法・FAQ・Review Notesが一致している
- [ ] 位置情報が写る場合、サンプルデータである

具体的な撮影順、デモデータ、コピー候補は `notes/28_app_store_screenshot_storyboard.md` を使う。

## 11. 提出前ブロッカー

少なくとも次が未完了なら提出しない。

- [ ] 新規登録、ログイン、ログアウトが実機で通る
- [ ] 在庫、Wish、打診、合意、取引完了が実機で通る
- [ ] 利用規約、プライバシーポリシー、問い合わせ導線が切れていない
- [ ] App Privacy、Privacy Manifest、プライバシーポリシーが矛盾していない
- [ ] App Availability、EU DSA trader status、商品ページ表示連絡先、IAP Availabilityが初回Japan-only方針と矛盾していない
- [ ] 外部画像URL又はAI/検索候補画像を出す場合、Content Rights、Privacy、FAQ、Review Notesが矛盾していない
- [ ] 写真メタデータの残存、削除可否、ユーザー向け注意、App Privacy回答が矛盾していない
- [ ] 顔候補付けを出す場合、Sensitive Info候補、Face ID非利用、外部送信、削除・利用停止、FAQ説明が揃っている
- [ ] Bundle ID、App ID、Capabilities、署名、profile/certificateが矛盾していない
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
配信地域、EU DSA trader status、IAP Availabilityは `notes/68_app_store_territory_dsa_iap_availability.md` を使う。
外部サービス、委託先、SDK、APIの最終照合は `notes/48_external_service_vendor_register.md` を使う。
個人情報・セキュリティ事故時の初動は `notes/49_privacy_security_incident_response_runbook.md` を使う。
Apple Guideline別の提出前適合確認は `notes/53_app_review_guideline_compliance_matrix.md` を使う。
RLS、Storage、secret、APNs、管理者権限の提出前監査は `notes/54_prelaunch_security_audit_checklist.md` を使う。
Apple Developer側のBundle ID、App ID、Capabilities、署名、profile/certificate確認は `notes/75_apple_developer_signing_capabilities_preflight.md` を使う。
アプリ内の同意、権限説明、安全注意、AI/IAP文言は `notes/56_in_app_legal_safety_copy_deck.md` を使う。
初回提出で出す/隠す機能の露出監査は `notes/59_initial_release_scope_exposure_audit.md` を使う。

## 12. 公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Apple Minimum Terms for Developer's EULA: https://www.apple.com/legal/internet-services/itunes/dev/minterms/
- Apple In-App Purchase: https://developer.apple.com/in-app-purchase/
- Apple In-App Purchase information: https://developer.apple.com/help/app-store-connect/reference/in-app-purchase-information/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple Privacy Manifest: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple Product Page / Screenshots: https://developer.apple.com/app-store/product-page/
- Apple Screenshot Specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- 個人情報保護委員会 通則ガイドライン: https://www.ppc.go.jp/personalinfo/legal/guidelines_tsusoku/
