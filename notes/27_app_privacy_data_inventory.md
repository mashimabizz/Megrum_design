# 27. App Privacy データインベントリ

最終更新: 2026-06-29

ステータス: Draft v0.28（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / StoreKit・IAP販売可否・復元失敗 / Web外部通信先・next/font/google・MapTiler/Nominatim未検出整理 / legacy Expo削除済み・APNs主線のApp Privacy前提 / Web Auth Cookie・Supabase SSR session refresh / デバッグログ・Edge Functionエラー・公開証跡secret混入防止 / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 精密位置・MapKit/CoreLocation・逆ジオコーディング / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI Responses API / web_search / 顔特徴量RLS・学習データ可否 / Storage公開範囲 / 郵送交換 / 会員間支払い情報を反映）

## 目的

App Store Connect の App Privacy、`PrivacyInfo.xcprivacy`、プライバシーポリシー、実アプリの通信・SDK利用を提出直前に突き合わせるための作業表。

この文書は確認用であり、コード、Info.plist、Privacy Manifest は変更しない。

App Store Connectへ転記する回答は `notes/43_app_privacy_connect_answer_sheet.md`、Privacy Manifest/SDKの監査台帳は `notes/44_privacy_manifest_sdk_audit.md` を使う。
外部サービス、委託先、SDK、APIの横断台帳は `notes/48_external_service_vendor_register.md` を使う。
保存期間、削除、匿名化、例外保持の横断整理は `notes/52_data_retention_deletion_matrix.md` を使う。

## 1. 現時点で読めた事実

### Swift Native

- `ios-native/App/PrivacyInfo.xcprivacy`
  - `NSPrivacyTracking=false`
  - Required Reason API: `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1`
- `ios-native/App/Info.plist`
  - `NSCameraUsageDescription` あり
  - `NSLocationWhenInUseUsageDescription` あり
  - `CFBundleURLTypes` / `CFBundleURLSchemes=$(MEGRUM_URL_SCHEME)` あり
  - `MegrumAuthEmailRedirectURL` / `MegrumAuthOAuthAuthorizeURL` あり
  - `ITSAppUsesNonExemptEncryption=false`
  - `LSApplicationCategoryType=public.app-category.social-networking`
  - `GADApplicationIdentifier`、`MegrumAdMob...` 系ad unit id、`SKAdNetworkItems` あり
- `ios-native/Package.swift`
  - `GoogleMobileAds` Swift Package依存あり
- `ios-native/MegrumNative.xcodeproj`
  - `GoogleMobileAds` product linkあり
- `ios-native/Config/MegrumNative.xcconfig` / 広告実行条件
  - チェックイン既定値は `MEGRUM_ADS_ENABLED=YES`、`MEGRUM_AD_PROVIDER=admob`、`MEGRUM_ADMOB_APP_ID` 実値、`MEGRUM_ADMOB_TEST_ADS_ENABLED=YES`
  - `MEGRUM_ADMOB_SEARCH_NATIVE_UNIT_ID` と `MEGRUM_ADMOB_TRADES_BANNER_UNIT_ID` に本番unit idが入る一方、test ads有効時はbanner/nativeがGoogleデモunit idへ差し替わる
  - `MegrumNativeApp` は広告有効、placeholder無効、AdMob provider、app idありなら `MobileAds.shared.start()` を実行する
  - `AdBannerSlot` / `AdMobNativeCardView` はGoogle Mobile Ads SDKの `Request()` で広告リクエストを送る。現行検索では `NSUserTrackingUsageDescription`、ATT要求、UMP同意管理、非パーソナライズ広告指定、Publisher First-Party ID制御、mediation制御、child-directed treatment、test device id指定は未確認
  - 現行設定上、検索結果native広告、やりとり一覧上部banner、preview viewer向けhome banner fallbackが主な広告リクエスト候補。インタースティシャルはplaceholder以外のGoogle SDKロード未接続かつunit id空
- 位置情報 / MapKit / CoreLocation
  - `MegrumLocationState` は `CLLocationManager` を使い、`desiredAccuracy=kCLLocationAccuracyNearestTenMeters`、`distanceFilter=10`、`CLGeocoder.reverseGeocodeLocation` により場所名へ変換する。
  - `HomeLocalCoordinateStorageCodec` は緯度経度を小数8桁で保持できる。
  - `TradeDetailScreenActions.sendLocationMessage` は取引チャットの現在地共有として緯度経度を送信する。
  - `SupabaseHomeLocalModePersistence` は現地交換モードのON/OFF、活動ウィンドウ中心座標、最終/設定座標、半径、有効時間、持参グッズIDを保存する経路がある。
  - `ProposalCreatePayload` は待ち合わせ候補の開始/終了、場所名、緯度経度を最大3件送信する。下書きUI上は候補を最大5件扱うが送信時に有効候補へ丸める。
  - `MegrumAppStateMeguriActions`、`BoardThreadDetailScreen`、`SupabaseGroomPayloads`、`BoardScopeQueryContext` は近くのグルーム、スポット掲示板の閲覧、作成、返信範囲判定へ緯度経度を送信する経路がある。`groom_posts.origin_lat/lng`、`meguri_board_threads.origin_lat/lng`、閲覧者lat/lng、公開範囲、1km/3km系判定はPrecise Location候補として扱う。
- 認証リダイレクト / URL scheme / ディープリンク
  - `MegrumRootView.onOpenURL` は受け取ったURLを `MegrumAuthState.handleOpenURL` へ渡し、`SupabaseAuthRedirectParser` はquery又はfragmentの `access_token`、`refresh_token`、`expires_in`、`expires_at`、`token_type` を読む。
  - Google OAuthは `ASWebAuthenticationSession` で `https://megrum.jp/auth/oauth/authorize` を開き、`callbackURLScheme` は `MEGRUM_AUTH_EMAIL_REDIRECT_URL` の `scheme` queryから導出される。
  - Web側 `auth/oauth/authorize` Routeは `provider=google` と `megrum://auth/callback` / `megrum-preview://auth/callback` のみを許可し、Supabase `/auth/v1/authorize` へ転送する。
  - Web側 `auth/callback?next=mobile&scheme=...` はSupabase codeをsessionへ交換し、native callback schemeへaccess token等をfragmentで返す。callback URL、fragment、error、provider、通知 `linkPath`、deep link path/queryはContact Info / Identifiers / Usage Data / Other Dataへの影響を最終確認する。
- Keychain / session保存
  - live authでは `KeychainAuthSessionStore` が `AuthSession` をKeychainへJSON保存し、`accessToken`、`refreshToken`、`expiresIn`、`expiresAt`、`tokenType`、user id、emailを保持し得る。
  - 保存済みsessionは期限切れ又は期限間近の場合にrefresh tokenで更新され、更新後のsessionが再保存される。ログアウト時は端末内sessionを先にclearし、Supabase logout APIを後続で呼ぶ。
  - 現行コード確認では `kSecAttrAccessible` / ThisDeviceOnlyの明示、端末バックアップ/復元/アンインストール時の挙動、他端末session失効の完了保証は未確認。App PrivacyではIdentifiers / Contact Info / Usage Data / Other Dataへの影響を最終確認する。
- ログ / エラー / 監査証跡
  - Swift Nativeでは `MegrumAppLogger.general` と `NativePush` loggerがあり、DEBUG時に `privacy: .public` で `String(describing: error)` 又は `error.localizedDescription` を出す箇所がある。現行確認箇所はAPNs登録失敗、顔候補付け解析失敗、推し保存失敗、初期snapshot section失敗、member face profile取得失敗、個別募集load/create/update/archive失敗。
  - `suggest-goods-series` Edge FunctionはOpenAI失敗時に `openai_failed:${status}:${await response.text()}` を作り、`messageOf(error)` をJSON responseの `detail` に返す。`send-apns-notification` Edge FunctionもSupabase response textを含むエラーを作り、`messageOf(error)` を返す経路がある。
  - Web管理画面は `admin_audit_logs` の `before_state`、`after_state`、`metadata`、`user_agent` をJSON表示する。`writeAdminAuditLog` は操作理由、IP、User-Agent、before/after state、metadataを保存する。
  - これらはDiagnostics / Usage Data / Other Data / Customer Support / Security目的への該当性を最終確認する。token、secret、password、認証code、signed URL、画像URL、通知本文、通報本文、削除申出本文をログ、スクショ、公開証跡、PR、サポート返信へ残さないことを提出前No-Goにする。
- アカウント設定 / プロフィール
  - 初回設定で生年月日入力が必須。未来日以外の最低年齢制限、公的年齢確認、身分証確認、保護者同意確認、保護者管理機能は未確認
  - 生年月日から算出した年齢を保存・表示する経路あり。プロフィール、ホーム、検索、めぐり等で年齢又は年齢に基づく派生情報が表示され得る
  - 初回設定・プロフィール編集で性別と活動エリアを扱う経路あり。公開プロフィール、ホーム候補、交換条件等で、性別、活動エリア、評価、完了取引数、支払い方法要約等が表示され得る
  - これらは自己入力又は利用状況に基づく表示であり、公的本人確認、法的性別確認、年齢認証、安全確認、支払能力確認ではない
- ホーム候補 / 検索 / レコメンド
  - `HomeCandidateComposer` / `SupabaseHomeClient` は、閲覧者と相手会員の在庫、wish、個別募集、listing wish options、推し、inventory tags、活動予定、local mode settings、支払い方法要約、評価、完了取引数、未読通知、メグルムプラス有効ユーザー、ブロック関係、テストアカウント除外等を用いてホーム候補を構成する
  - `HomeDiscoveryCandidateSorter` は、メグルムプラス優先、タグ一致数、グッズ条件、交換条件、支払い条件、リンク数、タイトル等で表示順を調整する
  - `HomeDiscoveryMatchPolicy` / `HomeMutualMatchConditionReviewPolicy` は、wish一致、個別募集一致、郵送交換可否、現地交換の都道府県/日程一致、支払い方法互換性等から「全一致」「確認が必要」等の参考ラベルを作る
  - `SearchResultFilterPolicy` は、メンバー、グッズ種別、タグ、支払い方法、交換方法、都道府県、wish一致、個別募集一致、閲覧者条件で検索結果を絞り込み、`newest` / `title` の表示順でもメグルムプラス優先表示を行う
  - `SearchSuggestionBuilder` は、閲覧者の推し、wish、在庫タグから検索候補を作る。`GoodsSearchModels` は「マッチしてるよ！」「交換できるかも？」「マッチなし」のbucket表示を持つ
  - `search_query_logs`、`record_search_query`、`get_popular_search_terms` のmigrationは検索語、`normalized_term`、`result_count`、30日人気検索集計を扱うが、2026-06-29時点のSwift検索では `record_search_query` 呼び出しは未確認
  - 候補表示、検索結果、表示順、レコメンド、Product Personalization、Plus優先表示、広告挿入は参考表示であり、本人性、安全性、信用、所有権、真贋、取引成立、支払い、発送又は現地合流を保証しない
- 評価 / 通報 / ブロック / モデレーション
  - 取引完了後の評価は `user_evaluations` に1-5 starsと任意コメントを保存し、公開プロフィールの評価一覧RPCでは評価者公開情報、星、コメント、評価日をログイン済みユーザーへ返す経路あり
  - `reports`、`goods_reports`、`groom_reports`、`meguri_board_reports`、`disputes` に、通報者、対象ユーザー、対象グッズ/取引/メッセージ/投稿/返信、理由、補足本文、証跡URL、status、運営対応情報を保存する経路あり
  - `groom_user_blocks` にブロック関係を保存し、検索結果、ホーム候補、公開プロフィール、グルーム、めぐりメッセージ、掲示板、通知等の表示/送信抑制に使う経路あり
  - 問い合わせ又は通報経由で、権利侵害、名誉毀損、プライバシー侵害その他違法又は不適切情報に関する削除申出、送信防止措置の申出、発信者確認又は通知の対応履歴を保存し得る
  - 評価、通報、ブロック、モデレーション状態は安全対応と表示制御の参考情報であり、本人確認、安全確認、信用保証、支払能力確認、真実性確認、法的判断又は緊急通報の代替ではない
- StoreKit / IAP
  - `megrum.plus.monthly` を現行のメグルムプラス商品ID候補として、StoreKitの商品情報照会、価格取得、購入ボタン表示、復元ボタン表示、購入開始、承認待ち、キャンセル、購入失敗、復元失敗、`Transaction.currentEntitlements` 読み込みの経路あり
  - `SubscriptionSettingsContent` はStoreKitの `offer.priceText` と固定フッター文言「価格は月額500円です。App Storeのサブスクリプションとして更新・解約できます。」を同時に表示し得るため、App Store Connect価格、販売地域、販売停止状態、公開特商法、FAQ、Review Notes、App Privacyを照合する
  - 購入成功時に `sync_megrum_plus_purchase_for_viewer` へproduct id、transaction id、Original Transaction ID、期限を同期する経路あり。商品未取得、未完了、キャンセル、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、App Store Server APIによるサーバー検証、Server Notificationsによる更新/返金/取消/期限切れ/請求失敗/猶予期間同期は未確認
  - 購入直後のサーバー同期失敗時にローカルでメグルムプラス有効表示へ倒すフォールバックがあるため、App Privacy/法務/サポートではローカル表示とサーバー上の最終権限を分けて説明する
  - Web管理画面には `entitlements.manage` 権限で `plan_overrides` と `user_entitlements.source='manual_override'` を使う有料権限手動上書き経路があり、対象ユーザー、feature key、active/inactive、期限、理由、変更前後、作成者、override id、監査ログを扱う。これはIAP購入証明ではないが、最終的な有料機能表示に影響し得るため、Privacy本文とApp PrivacyのPurchases / Identifiers / Other Data候補で確認する
- 外部AI
  - `suggest-goods-series` Edge Function経由で、最大3件の画像データ又は画像URL、グループ名、メンバー名、グッズ種別、既存候補をOpenAI Responses APIへ送り、`web_search` を必須実行する経路あり
  - `GoodsBulkTagSheet` には「画像からシリーズ名称の候補を出す」ボタンがあるが、現行読み取りではOpenAI、外部AI、web search、保持、学習利用、第三者/未成年/権利未処理画像禁止を送信前に明示する画面文言は未確認
- 外部画像URL
  - グッズ画像はSupabase Storageの公開URLに正規化されるほか、既存の絶対URLを表示対象として保持する経路あり。外部画像URLを表示する場合、画像ホスト/CDNへIP、端末/アプリ通信情報、アクセス時刻等が送信される可能性を確認する
- カメラ / 写真ライブラリ / 共有シート
  - `ios-native/App/Info.plist` には `NSCameraUsageDescription` と `NSPhotoLibraryUsageDescription` がある。現行文言は証跡写真、グルーム投稿、グッズ写真中心だが、コード上の用途はプロフィール画像、取引チャット写真、服装写真、スポット掲示板画像、共有用画像、AI/顔候補付け用途にも広がるため、提出前に権限文言と実用途の一致を確認する
  - `NativeCameraCaptureView` はカメラ撮影画像を `UIImage.jpegData(compressionQuality: 0.88)` でJPEG化する経路あり。一方、`PhotosPickerItem.loadTransferable(type: Data.self)` で読み込む写真ライブラリ画像は、`normalizedPhotoUpload` / `normalizedChatPhotoUpload` が対応形式かつサイズ上限内なら元データのまま保存し得る
  - 写真ライブラリ由来のJPEG/PNG/GIF/WebP等には、EXIF、GPS位置情報、撮影日時、端末情報その他画像メタデータが残る可能性がある。Photos or VideosだけでなくLocation / Device Info回答への影響を最終ビルドで確認する
  - `GoodsShareActivitySheet` は `UIActivityViewController` で共有用テキストと生成画像を外部アプリへ渡す。共有物には表示名、グッズ画像、グッズ名、グループ名、メンバー名、グッズ種別、タグ、ハッシュタグ等が含まれ得る
- Supabase Storage / media
  - `goods-photos` と `avatars` はmigration上public bucketで、`goods-photos` はグッズ写真、`avatars` はプロフィール画像の公開表示用途。`GoodsPhotoURLResolver` と `SupabaseProfilePhotoStorage` は公開Storage URLを生成する経路あり
  - `chat-photos` はprivate bucketで、proposal参加者だけread/uploadできるpolicy。取引チャット写真、服装写真、証跡写真はこのbucketを使い、現行コードではsigned URLの有効期限が365日
  - `groom-posts` は初期publicから後続migrationでprivateへ変更され、`can_view_groom_object()` による閲覧制御へ寄せている
  - `meguri-message-media` はprivate bucketで、メッセージ送受信者だけが対象objectを閲覧できるpolicy
  - `meguri-board-media` はprivate bucketだが、Storage policy上はauthenticated userがbucket内objectをselectできる。アプリ側は表示可能thread/replyのimage pathだけsigned URL化する設計のため、公開前にpath推測・一覧・閲覧範囲の妥当性確認が必要
  - 画像は公開URL、signed URL、端末キャッシュ、スクリーンショット、相手会員の保存、通知、通報/証跡コピー、バックアップ等により、削除又は非表示後も一定期間残る可能性がある
- 顔検出 / メンバー候補付け
  - `VisionFaceDetectionService` がApple Visionの `VNDetectFaceRectanglesRequest` でグッズ画像内の顔矩形を検出する経路あり。README上、Face ID又は生体認証APIは使わない
  - `member_face_profiles` には `embedding`、`embedding_model`、`source_image_url`、`consent_recorded_at` を持つ運営管理の顔特徴量プロフィールがあり、service role / 管理バックエンド登録前提。ただしRLSはactive profileをauthenticated userへ読ませる設計で、selectにもembedding/source image URLが含まれるため、実在人物データを入れる場合はアクセス最小化がP0
  - `face_uploaded_images`、`detected_faces`、`face_match_candidates`、`face_match_corrections` に、ユーザー画像、検出矩形、候補、補正履歴、学習データ追加可否を保存する経路あり。補正draftの `shouldAddTrainingData` は既定trueの経路があるため、導線露出時は任意性/同意/削除を確認
  - 最終ビルドで顔特徴量又は画像特徴量の生成・保存・照合が到達可能な場合、App Privacy上は `Sensitive Info`（biometric data相当）も回答候補に上げる
- 郵送交換 / 住所
  - `user_mailing_addresses` に宛名、郵便番号、都道府県、市区町村、番地、補足住所、電話番号を保存する経路あり
  - 郵送交換では `proposals.sender_mailing_address` / `receiver_mailing_address` に合意時点の郵送先スナップショットを保存し、合意後に当事者へ表示する設計
  - `PostalCodeAddressClient` が `https://zipcloud.ibsnet.co.jp/api/search` へ郵便番号を送信して住所候補を取得する経路あり
- 会員間支払い / 口座情報
  - `user_payment_settings` に支払い方法、銀行名、支店名、口座種別、口座番号、口座名義、その他メモを保存する経路あり
  - 金額指定を含む取引では、合意時に `proposals.sender_payment_settings` / `receiver_payment_settings` へ支払い情報スナップショットを保存し、成立後の当事者向け画面で口座情報を表示する経路あり。設定変更後も合意済み取引のスナップショットは別途残り得る
  - これはApple IAPのカード番号ではないが、App Privacy上は銀行口座番号等のPayment Infoに該当し得るため、支払い設定導線を出す場合はFinancial Info / Payment Infoを回答候補へ上げる
  - PayPayは現行Swift Native上、リンク登録なしの対応可否表示として確認。PayPayアカウント、送金リンク、QRコード、外部ID、口座名義、残高、送金可否、受領可否、不正利用確認又は支払能力確認をMegrumが扱うものとして説明しない
- 退会申請
  - 設定画面から退会理由と任意メモを送信し、`account_deletion_requests` に理由、任意メモ、申請日時、30日後の削除予定日、申請状態を保存する経路あり
  - ログアウト時に登録済みAPNs tokenへ `revoked_at` を入れるclient-side revoke経路と、APNs失効応答時にEdge Functionがdeviceをrevokeする経路あり
  - 30日後の実削除ジョブ、削除申請キャンセル、Apple/Google連携解除、退会申請/削除完了に連動した全端末APNs token無効化完了は未確認。過去又は別環境でExpo Pushを使う場合はExpo token無効化も別途確認する
- Push通知 / APNs
  - `MegrumNativeApp` はログイン後に通知許可を確認し、許可済み又は許可された場合にAPNs登録を行う。Push通知の許可はアプリ利用の必須条件にしない
  - `notification_devices` には `platform='ios'`、`push_provider='apns'`、`native_device_token`、`app_version`、`last_seen_at`、`revoked_at` を保存又は更新する経路あり
  - `send-apns-notification` は `notifications.title/body/link_path`、未読数、`notificationId`、`linkPath`、`sound` をAPNsへ送る経路あり
  - 取引チャットのテキスト本文は短縮プレビューとして通知bodyに入り得る。写真、服装写真、現在地共有、到着状況、証跡、評価、キャンセル要請等は出来事の概要が入る
  - めぐり、グルーム、スポット掲示板系は本文を入れない経路が多いが、タイトルだけでも相手、行動又は文脈が推測されるためUser Content/Usage Data影響として照合する

### Legacy Expo / React Native

現行リポジトリでは `mobile/` と旧JSX mockupは削除済みで、ユーザー向けiOS実装は `ios-native/` を正とする。Swift Native初回提出では、legacy Expo / React NativeのSDK、権限、OTA配信、Expo Pushを「現在の最終バイナリに含まれるもの」としてApp Privacyへ足さない。

ただし、DB migrationや `notification_devices` にはlegacy Expo互換の `push_provider='expo'` / Expo push token列又は履歴が残り得る。過去ビルドの運用、別環境のExpo配送、又はExpo系実装を再導入する場合は、Swift Nativeとは別の提出対象として、Expo Camera、Image Picker / Media Library、Location、Notifications、Apple Authentication、IAP、Maps、Updates等のSDK・権限・通信を再監査する。

### Web / 運用

- Web側にはSupabase SSR/Auth Cookie、Next.js公開ページ、Stripe webhook候補、`next/font/google` が存在する。Map系ライブラリは2026-06-29時点の `web/src` では未検出。
- Web管理画面やサポート運用で取得する情報は、プライバシーポリシー上は対象だが、App Store Connect の「アプリが収集するデータ」はiOSアプリ経由の収集実態を中心に回答する。
- Web管理画面は `admin_roles` のロール/権限、MFA要求、`admin_audit_logs` のactor/action/target/reason/before_state/after_state/request_ip/user_agent/metadata、ユーザー一覧のメール、ハンドル、表示名、活動エリア、アカウント状態、有料権限、通報/異議申し立て、推し追加リクエスト、運営通知、サブスクリプション、手動有料権限上書きを扱う。
- 管理画面の読み書きはサーバー側service role clientを使う経路があり、RLSを迂回し得るため、App Store提出前のセキュリティ監査では、server-only、secret管理、MFA、権限分離、監査ログ、退会後の監査ログ保持を確認する。
- 2026-06-29時点の `web/src` では `next/font/google` の `Noto_Sans_JP` / `Inter_Tight` を使う。ローカルNext.js 16 docsではGoogle Fontsはビルド時にCSS/フォントファイルを取得して静的assetとしてself-hostし、ブラウザからGoogleへrequestを送らない説明になっている。ただし実デプロイHTML/Networkに `fonts.googleapis.com` / `fonts.gstatic.com` が出ないことは公開前に確認する。
- 2026-06-29時点の `web/src` と `supabase/functions` ではMapTiler、Leaflet、Nominatim / OpenStreetMap geocode proxyの実装は未検出。`web/.env.local.example` にMapTiler keyのplaceholderは残るため、再導入又は別ブランチで使う場合はLocation / 外部地図APIとして別途再監査する。

## 2. App Privacy 回答候補

| App Privacyカテゴリ | Megrumでの例 | 収集 | ユーザーに紐づく | 目的候補 | トラッキング |
|---|---|---|---|---|---|
| Contact Info / Email Address | 登録メール、問い合わせメール | あり | はい | App Functionality, Account Management, Customer Support | いいえ |
| Contact Info / Name | 表示名、問い合わせ時の氏名 | あり | はい | App Functionality, Customer Support | いいえ |
| Contact Info / Physical Address | 郵送先住所、郵便番号、宛名 | 郵送交換を出すならあり | はい | App Functionality, Safety, Customer Support | いいえ |
| Contact Info / Phone Number | 郵送先電話番号 | 郵送交換を出すならあり | はい | App Functionality, Safety, Customer Support | いいえ |
| Financial Info / Payment Info | 銀行名、支店名、口座種別、口座番号、口座名義、支払い方法、支払いメモ、金額指定、成立後支払い情報スナップショット | 支払い設定又は金額指定取引を出すならあり | はい | App Functionality, Safety, Customer Support | いいえ |
| Sensitive Info / Biometric Data | 顔特徴量、画像特徴量、顔検出結果、顔候補付け補正履歴 | 顔候補付け又は特徴量照合を出すなら条件付きであり | はい | App Functionality, Safety | いいえ |
| Other Data / Other Data Types | 生年月日、生年月日から算出した年齢又は年代、性別、年齢に基づく安全確認ログ、ブロック関係、通報/モデレーション状態、削除申出/送信防止措置の対応状態、優先度、安全確認ログ、運営対応ログ | あり | はい | App Functionality, Safety, Product Personalization, Customer Support | いいえ |
| Other Data / Other Data Types | 管理者権限、MFA要求、運営担当者の操作理由、監査ログ、変更前後の状態、手動有料権限上書き、plan override、付与又は停止理由、運営通知、Webhook/決済同期、IPアドレス、User-Agent | Web/運用ではあり。iOS App Privacy回答では最終提出UIと収集経路に応じて確認 | はい | App Functionality, Safety, Customer Support, Analytics又はOther Purposes | いいえ |
| Search History | 検索語、検索条件、検索結果件数、検索時刻、`normalized_term`、`result_count`、人気検索集計 | 検索ログ又は人気検索を有効にするならあり。DB/RPC基盤はあるがSwift呼び出しは未確認 | はい又は集計後は非識別 | App Functionality, Product Personalization, Analytics | いいえ |
| User Content / Photos or Videos | グッズ写真、証跡写真、取引チャット写真、服装写真、グルーム写真、スポット掲示板画像、めぐりメッセージ画像、プロフィール画像、共有用生成画像、写真ライブラリ由来の元画像又は再圧縮画像、画像メタデータ | あり | はい | App Functionality, Safety, Customer Support | いいえ |
| User Content / Other User Content | プロフィール文、推し情報、投稿、返信、取引チャット、通知本文、評価コメント、通報本文、通報補足、異議申し立て本文、削除申出本文、問い合わせ本文、広告通報本文、運営返信本文 | あり | はい | App Functionality, Safety, Customer Support | いいえ |
| Location / Precise Location | 現在地共有、位置情報メッセージ、待ち合わせ候補の緯度経度、現地交換モードの最終/設定座標、活動ウィンドウ中心座標、近くのグルーム/スポット掲示板表示、グルーム/掲示板の作成座標、閲覧者座標、掲示板作成/返信範囲判定、1km/3km等の距離判定、地図表示、逆ジオコーディング | あり | はい | App Functionality, Safety | いいえ |
| Location / Coarse Location | 都道府県、スポット、活動エリア | あり | はい | App Functionality, Personalization | いいえ |
| Identifiers / User ID | Supabase user id、プロフィールID | あり | はい | App Functionality, Safety, Analytics | いいえ |
| Identifiers / Device ID | APNs device token、push provider、端末通知登録状態等。過去又は別環境でExpo Pushを使う場合はExpo push tokenも別途確認 | 通知を出すならあり | はい | App Functionality | いいえ |
| Purchases | IAP商品情報照会、価格取得、購入ボタン表示、復元ボタン表示、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、IAP購入状態、サブスクリプション状態、transaction id、Original Transaction ID、期限、返金/取消/期限切れ/請求失敗/猶予期間、復元、サーバー同期状態、サーバー同期失敗、販売地域、販売停止、最終権限状態、手動有料権限上書きの有無 | 有料機能を出すならあり | はい | App Functionality, Customer Support | いいえ |
| Usage Data / Product Interaction | 画面操作、検索、投稿、評価投稿、通報/ブロック操作、非表示操作、通知配信/開封、未読バッジ、通知設定、通知リンク遷移、候補表示、条件一致ラベル、検索候補、表示順、Plus優先表示、広告表示/クリック等 | 分析、通知ログ、安全操作ログ、候補表示/表示順ログ又は広告SDKを出すならあり | 原則はい | Analytics, App Functionality, Product Personalization, Safety, Customer Support, Third-Party Advertising | IDFA/横断追跡の有無で再確認 |
| Usage Data / Advertising Data | 表示された広告、広告反応、広告配信関連データ、広告通報時の広告枠/表示日時/広告識別子 | AdMobを有効にするならあり | SDK設定による | Third-Party Advertising, Analytics, Customer Support | IDFA/横断追跡の有無で再確認 |
| Diagnostics / Crash Data | クラッシュ、エラー、パフォーマンス | クラッシュ収集又は広告SDK由来であり得る | SDK設定による | App Functionality, Analytics, Third-Party Advertising | いいえ又は条件付き |
| Sensitive Info | 要配慮個人情報 | 積極取得なし | 該当時のみ | Safety / Legal | いいえ |
| Other Data | AI入力・出力・ログ、外部AI安全確認ログ、web search利用結果 | AI機能を出すならあり | 入力内容による | App Functionality, Safety | いいえ |

## 3. 目的別の回答方針

| 目的 | 回答方針 |
|---|---|
| App Functionality | 認証、プロフィール、在庫、wish、打診、取引、通知、めぐりに必要なデータ |
| Analytics | 実際に分析SDK又は自社ログで行動分析をする場合だけ選択 |
| Product Personalization | マッチング、表示順、検索候補、人気検索、Plus優先表示、近くの投稿、推し/地域/タグ/wish/在庫/交換条件/支払い条件ベースの候補表示に使う場合だけ選択 |
| Developer's Advertising or Marketing | 広告配信やキャンペーンに使う場合だけ選択 |
| Third-Party Advertising | AdMob等の第三者広告を有効にする場合は選択候補。広告SDKが最終ビルドで初期化されない場合だけ非選択を検討 |
| Other Purposes | 法令対応、Trust & Safety、AI安全確認など、通常カテゴリに入らない場合に検討 |

## 4. トラッキング回答

現行Swift Nativeの注意:

- `PrivacyInfo.xcprivacy` は `NSPrivacyTracking=false`
- Info.plistに `NSUserTrackingUsageDescription` は現時点で未確認
- Google Mobile Ads SDK / AdMob / SKAdNetwork設定が存在するため、広告が有効なビルドではGoogle公式データ開示、AdMob設定、IDFA、Publisher First-Party ID、パーソナライズ広告、メディエーション有無を必ず再確認する
- 生年月日、年齢又は性別はApp Store Connect上の専用Data Typeが明確でないため、最終UIでは `Other Data Types` 又はAppleの最新説明に沿った関連カテゴリで、プロフィール表示・安全確認・候補表示目的として過不足なく開示する

TrackingをNoにできる条件:

- IDFAを利用しない
- 他社アプリ/サイトのデータと結合した追跡をしない
- データブローカーへ共有しない
- 広告配信がコンテキスト広告又は非パーソナライズ広告として整理できる
- マッチングデータ、取引履歴、位置情報を広告会社へ販売しない

次のどれかを入れる場合は、App PrivacyとATTの再確認が必要。

- IDFA
- 外部広告ネットワーク
- リターゲティング
- 他社データと結合した広告効果測定
- 広告SDKによるトラッキング
- AdMobのPublisher First-Party ID又は広告IDが、Apple定義のTrackingに該当する使われ方をしている場合

## 5. Privacy Manifest 照合

### 現在のSwift Native

| 項目 | 現状 | 提出前確認 |
|---|---|---|
| `NSPrivacyTracking` | `false` | 最終SDK構成でもfalseでよいか |
| Collected Data Types | Swift Native manifestには未記載 | App Store Connect回答で足りるか、manifestに宣言が必要なSDKがないか |
| Required Reason API / UserDefaults | `CA92.1` | 利用目的と一致しているか |
| Required Reason API / File Timestamp | Swift Native manifestには未記載 | 追加SDKが使う場合は要確認 |
| Required Reason API / Disk Space | Swift Native manifestには未記載 | 追加SDKが使う場合は要確認 |
| Required Reason API / System Boot Time | Swift Native manifestには未記載 | 追加SDKが使う場合は要確認 |

### Legacy Expoとの差分

legacy `mobile/ios/MegrumPreview/PrivacyInfo.xcprivacy` は削除済み旧実装側の参照情報であり、Swift Native初回提出でExpoを含めない場合、この内容をそのまま移す必要はない。Expo版又は過去ビルドを再提出対象にする場合は、legacy manifest相当のRequired Reason APIとApp Privacyを別途再照合する。

## 6. 外部サービス別チェック

| サービス / SDK | 使う情報 | App Privacy影響 | 提出前状態 |
|---|---|---|---|
| Supabase Auth | メール、ユーザーID、認証情報、認証code、access token、refresh token、callback URL、provider、error情報、logout request、session refresh結果 | Contact Info, Identifiers, Usage Data / Other Dataの可能性 | Redirect URLs、OAuth中継、native callback scheme、リンク秘密性、refresh token rotation、削除/失効手順を要最終確認 |
| Supabase Database | プロフィール、在庫、wish、打診、取引、投稿、評価、通報、異議申し立て、ブロック関係、モデレーション状態、郵送先住所、支払い情報、銀行口座情報、有料権限、手動有料権限上書き、plan override、監査ログ | User Content, Identifiers, Contact Info, Financial Info, Purchases, Usage Data, Other Data | 要最終確認 |
| Supabase Storage | 公開グッズ写真、公開プロフィール画像、取引チャット写真、服装写真、証跡写真、グルーム画像、スポット掲示板画像、めぐりメッセージ画像、公開URL、signed URL、Storage path | User Content, Photos or Videos, 場合によりLocation/Sensitive Info | public/private bucket、signed URL期限、相手保存、削除/キャッシュ、`meguri-board-media`のauthenticated selectを要最終確認 |
| Supabase Edge Function / APNs | 通知内容、APNs token。DBにはlegacy Expo互換のprovider/token列が残り得るが、Swift Native初回提出ではAPNsを主線として確認する | Identifiers, User Contentの一部 | 要最終確認。Expo配送を過去又は別環境で使う場合は別監査 |
| Apple Vision / Core ML候補 | 顔矩形、顔特徴量又は画像特徴量、候補スコア | Sensitive Info, User Content | 顔候補付け導線の露出、オンデバイス/サーバー処理、外部送信有無を確認 |
| Apple Sign in | Apple user id、メール | Contact Info, Identifiers | 実装有無確認 |
| Google Sign in | Google user id、メール | Contact Info, Identifiers | 初回Swiftに出すか確認 |
| Web Auth Cookie / Supabase SSR session | Supabase Auth Cookie、session refresh結果、Cookie設定/更新/削除、Web callback、password reset、Google OAuth callback、IP/User-Agent | Contact Info, Identifiers, Usage Data / Other Dataの可能性 | 公開Web/管理画面を使う場合はCookie説明、ログアウト、Cookie無効時の制限、token/Cookie値の証跡混入防止を確認 |
| Custom URL Scheme / ASWebAuthenticationSession / Deep Links | `megrum://auth/callback`、`megrum-preview://auth/callback`、認証callback fragment、通知 `linkPath`、画面遷移path/query、エラー情報 | Contact Info, Identifiers, Usage Data, Other Dataの可能性 | `MEGRUM_URL_SCHEME`、Supabase Redirect URLs、Google OAuth設定、Review Notes、FAQの整合確認 |
| iOS Keychain / AuthSessionStore | 端末内に保存されるaccess token、refresh token、expires、token type、user id、email、保存/削除結果 | Contact Info, Identifiers, Usage Data / Other Dataの可能性 | `kSecAttrAccessible`方針、ThisDeviceOnly要否、バックアップ/復元/端末紛失時説明、logout時clear、tokenログ混入防止を確認 |
| App Store IAP / StoreKit | 商品情報照会、価格取得、購入ボタン表示、復元ボタン表示、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、購入状態、サブスク状態、transaction id、original transaction id、期限、復元、返金/取消/期限切れ/請求失敗/猶予期間、サーバー同期状態、サーバー同期失敗、販売地域、販売停止、最終権限状態 | Purchases | メグルムプラス導線露出、固定価格/StoreKit価格一致、App Store Connect価格、IAP Availability、公開特商法、Server API/Notifications、手動上書きとの区別確認 |
| Stripe | Web又は外部決済 | Purchases, Contact Info | iOSアプリ内課金との棲み分け確認 |
| MapKit / CoreLocation / CLGeocoder | 精密な緯度経度、精度、時刻、場所名、逆ジオコーディング | Precise Location / Coarse Location | 現行実装は精密座標を扱い得る。権限文言、OS/地図サービス処理、サーバー送信、作成位置、閲覧者位置、保持/削除、場所名/距離の非保証、1km/3kmが匿名化又は安全保証ではない説明を確認 |
| ZipCloud / 郵便番号検索 | 郵便番号、住所候補 | Physical Address / Contact Info | 郵送交換を出すなら確認 |
| Camera / Photos | グッズ写真、プロフィール画像、取引チャット写真、服装写真、証跡写真、グルーム画像、スポット掲示板画像、AI/顔候補付け用途の画像、EXIF、撮影日時、GPS位置情報、端末情報その他画像メタデータ | User Content / Photos or Videos / Location / Device Infoの可能性 | Info.plist権限文言、PhotosPicker元データ保存経路、カメラJPEG再生成経路、メタデータ除去有無、App Privacy回答確認 |
| Apple Share Sheet / 外部SNS | 共有用テキスト、生成画像、表示名、グッズ画像、グッズ名、グループ名、メンバー名、グッズ種別、タグ、ハッシュタグ、リンク | User Content / Photos or Videos / Other Dataの可能性。共有後は外部サービス側の取扱い | `UIActivityViewController`露出、共有物の内容、外部サービス規約/ポリシー、削除/公開範囲/再共有/広告利用/アクセス解析の非管理説明確認 |
| Analytics / Crash | 操作ログ、クラッシュ | Usage Data, Diagnostics | 導入有無確認 |
| Google Mobile Ads / AdMob | IP、広告ID又は端末/アプリID、広告表示/クリック、広告通報時の広告枠/表示日時/広告識別子、診断、パフォーマンス等 | Device ID, Advertising Data, Product Interaction, Diagnostics等 | AdMob有効化、ATT、App Privacy、SDK Privacy Manifest、広告通報導線確認 |
| External AI / OpenAI Responses API | 最大3件の画像又は画像URL、グループ名、メンバー名、グッズ種別、既存候補、web search利用結果等 | User Content / Photos or Videos / Other Data | グッズシリーズ候補機能の露出、同意/任意性、web search利用、汎用モデル学習不使用、濫用監視等の保持、削除可否、第三者/未成年/権利未処理画像禁止確認 |
| External image hosts / CDN | 外部画像URLの取得時に送信されるIP、端末/アプリ通信情報、アクセス時刻等 | User Content / Other Data / Device Infoの可能性 | 画像URL表示の露出、通信先、第三者ポリシー、App Privacy回答への影響確認 |

## 7. 送信/保存される可能性が高いデータ

| データ | 保存先候補 | 公開範囲 | 保持/削除の注意 |
|---|---|---|---|
| メールアドレス | Supabase Auth | 非公開 | アカウント管理、問い合わせ |
| 端末内Auth session | iOS Keychain / Supabase Auth | 非公開想定。ただし端末共有、紛失、バックアップ、復元、OS仕様に依存 | access token、refresh token、expires、user id、emailを含み得る。ログアウト時clear、refresh後再保存、他端末session、バックアップ、アンインストール、外部認証側失効を最終確認 |
| Web Auth Cookie / browser session | Supabase Auth / Next.js proxy / Web callback / ブラウザCookie | 非公開想定。ただし共有端末、ブラウザ履歴、Cookie同期、開発ログ、スクリーンショットに残る可能性 | Web管理画面や公開Webのログイン状態維持に使う。Cookie無効時の機能制限、logout時Cookie削除、session refresh、認証code交換、Cookie値/token実値を証跡へ貼らない説明を確認 |
| プロフィール | Supabase DB | 公開範囲に応じて表示 | 表示名、ユーザーID、プロフィール文、画像、性別、活動エリア、年齢又は年代等、評価、完了取引数、推し情報等。本人確認済み/安全確認済み/法的性別確認済みとは説明しない |
| 退会申請理由 / 任意メモ | Supabase DB | 非公開、運営確認 | 問い合わせ、不正利用防止、監査、法令対応のため保存可能。任意メモに不要な個人情報を書かせない |
| 在庫 / wish | Supabase DB / Storage | 他会員に表示 | 取引・通報時は一部保存可能 |
| カメラ/写真ライブラリ由来画像 | Supabase Storage / DB / 端末 / 外部共有先 | 公開範囲、取引参加者、閲覧対象者、共有先に応じて表示 | 写真ライブラリ由来の元画像はEXIF/GPS/撮影日時/端末情報等が残る可能性。カメラ撮影で再圧縮される経路があっても全経路で削除保証しない |
| 共有用生成画像/共有文 | 端末 / 外部SNS / 外部チャット / 外部サービス | ユーザーが選んだ共有先の公開範囲 | 表示名、グッズ画像、グッズ名、グループ/メンバー、タグ、ハッシュタグ等を含み得る。共有後の保存、公開、再共有、削除、広告利用、アクセス解析は共有先の規約に従う |
| 認証callback / deep link | Supabase Auth / Web callback / iOS app / 外部ブラウザ / メールアプリ / 端末ログ | 非公開想定。ただしリンク転送、スクリーンショット、ブラウザ履歴、通知、外部アプリに残る可能性 | access token、refresh token、provider、error、path、query、fragment、通知 `linkPath` を含み得る。リンク/認証コードを共有しない説明、redirect allowlist、scheme整合、ログ最小化を確認 |
| 取引チャット | Supabase DB | 当事者、運営確認 | 紛争対応のため保存可能 |
| 証跡写真 | Supabase Storage | 当事者、運営確認 | 取引終了後の保存期間確認 |
| 評価 | Supabase DB | 当事者、プロフィール閲覧者、運営確認 | 評価者公開情報、星、コメント、評価日がプロフィール評価一覧等へ表示され得る。信用、安全、本人確認、支払能力又は商品品質を保証しない |
| 通報 / 異議 / 削除申出 / モデレーション | Supabase DB / Storage / サポートツール | 通報者、申出者、対象者、関係当事者、運営確認、必要に応じた外部機関 | 通報理由、補足、削除申出本文、送信防止措置希望、証跡URL、status、運営対応情報を安全・監査・法令対応・虚偽通報対策のため保存可能。通報者/申出者の直接表示は避けるが、文脈、発信者確認又は法令対応で推測又は開示される場合がある |
| ブロック関係 | Supabase DB | 非公開、表示/通知制御、運営確認 | 検索、候補、プロフィール、めぐり、掲示板、通知等の抑制に使う。過去の取引、チャット、証跡、評価、通報、異議、監査記録を当然には削除しない |
| 現在地 / 精密座標 | Supabase DB、RPC、端末内、MapKit/CoreLocation/CLGeocoder | 任意共有時の取引相手、近くのグルーム/掲示板の範囲判定、近距離公開の閲覧対象者、運営確認 | 現行コードは取引チャットの現在地共有、待ち合わせ候補、現地交換モードの最終/設定座標と活動ウィンドウ中心座標、グルーム/掲示板の作成座標、閲覧者座標、作成/返信範囲判定で緯度経度を送信し得る。1km/3km、近く、同じスポット等は表示/投稿/返信フィルタであり、匿名化、安全確認、所在確認、推測防止を保証しない。現行コードでは30日後の自動削除/非表示ジョブ未確認のため、即時削除、完全削除、自動削除完了は保証しない |
| 郵送先情報 | Supabase DB / proposals snapshot / ZipCloud | 合意後の当事者、運営確認 | 郵送交換、配送、紛争対応のため保存可能 |
| 支払い情報 / 口座情報 | Supabase DB / proposals snapshot | 合意後の当事者、運営確認 | 会員間支払い、紛争対応、監査のため保存可能。運営者が決済、送金、収納代行、返金、口座名義確認、支払能力確認又はエスクローをするものではない |
| 顔候補付けデータ | 端末内処理 / Supabase DB / Storage / 将来Core ML又は外部API | 原則本人、運営確認、候補付けに必要な範囲。ただし `member_face_profiles` はauthenticated read設計のため提出前確認 | 顔特徴量はSensitive Info候補。本人確認やFace IDではないこと、外部送信、同意、削除/非表示、`shouldAddTrainingData` 既定true、embedding/source image URL読み取り範囲を確認 |
| グルーム / 掲示板 | Supabase DB / Storage | 公開範囲に応じて表示 | 投稿本文、画像、匿名表示名、匿名avatar、作成時の緯度経度、公開範囲、距離判定、閲覧/返信可否、反応、返信、通報、ブロック、非表示、モデレーション時は安全・監査目的で保存可能。投稿時刻と位置から生活圏、会場、イベント参加が推測され得る |
| APNs token / Push通知payload | Supabase DB / Supabase Edge Function / APNs | 非公開。ただし通知タイトル/本文は端末ロック画面、通知センター、連携端末等に表示され得る | `platform`、`push_provider`、`native_device_token`、`app_version`、`last_seen_at`、`revoked_at`、通知タイトル/本文、未読バッジ、通知ID、リンク先を扱う。ログアウト時又はAPNs失効応答時に無効化する経路あり。退会申請/削除完了との連動と全端末処理は要確認 |
| IAP状態 | App Store / DB | 非公開 | 会計・権限管理・復元・返金/取消/期限切れ/請求失敗対応 |
| 広告関連データ | Google Mobile Ads / AdMob / サポート | 非公開 | App Privacy、ATT、Google設定、SDK Privacy Manifest、不適切/年齢不相応広告の通報導線と一致させる |
| AI入力/出力ログ | Supabase Edge Function / OpenAI | 非公開 | 外部AI送信、OpenAI等の送信先、画像又は画像URL、web search、同意/説明、学習利用、保持期間、濫用監視ログ、削除可否確認 |
| 管理者権限 / 監査ログ | Supabase DB / Web管理画面 | 非公開、権限を持つ運営担当者 | ロール、権限、MFA要求、操作理由、変更前後の状態、IP、User-Agent、metadataを保存。退会後もセキュリティ、会計、法令対応、内部統制、監査のため保持され得る |

## 8. 提出前オープン質問

- [ ] 初回提出バイナリはSwift Nativeのみか、legacy Expo要素を含むか
- [ ] Apple Sign in / Google Sign in を初回提出で出すか
- [ ] メール認証、パスワードリセット、Google OAuth、native callback、Web中継Route、Supabase Redirect URLs、Google OAuth設定、App Store Review Notesのscheme/URLが一致しているか
- [ ] メグルムプラス、IAP、Stripe関連導線を初回提出で出すか。出す場合、購入ボタン、復元ボタン、価格固定文言、StoreKit価格、商品情報照会、価格取得、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、App Store Connect価格、IAP Availability、Server API/Notifications、返金/取消/期限切れ/請求失敗同期を確認する
- [ ] Analytics / Crash SDK を入れるか
- [ ] カメラ/写真ライブラリ/共有シートを出す場合、Info.plist権限文言、画像メタデータ、共有用画像/テキストのApp Privacy影響を確認する
- [ ] AdMob広告を初回提出で有効にするか。無効ならSDK初期化/広告リクエストが発生しないか
- [ ] AdMob広告を出す場合、不適切又は年齢に合わない広告の通報導線、広告通報時に取得する情報、広告配信事業者への報告手順を公開FAQ/Review Notesと一致させるか
- [ ] 評価コメント、通報補足、異議申し立て本文、削除申出本文、ブロック関係、モデレーション状態、送信防止措置の対応状態が、Customer Support / Other User Content / Other Data / Product Interaction のどこに入るかApp Store Connectの最新UIで確認するか
- [ ] 管理者画面を初回提出/運用で使う場合、service roleのserver-only確認、管理者MFA、最小権限、監査ログ、IP/User-Agent保存、退会後保持、サポート担当者のアクセス範囲がPrivacy/セキュリティ監査と一致しているか
- [ ] 評価、通報、ブロック、モデレーションを本人確認、安全確認、信用保証、真実性確認、緊急通報又は法的判断の代替として説明していないか
- [ ] 通報者情報を「絶対に相手へ開示しない」と保証せず、文脈上の推測、法令対応、外部機関対応の例外を公開文面と一致させるか
- [ ] 外部AIサービスへ画像・本文を送る機能を初回提出で出すか
- [ ] 顔検出、顔特徴量、画像特徴量、メンバー候補付け、補正履歴保存を初回提出で出すか。出す場合、Sensitive Info / Biometric Data回答、利用目的、削除、外部送信有無、Face IDではない説明を整える
- [ ] 郵送交換、住所登録、電話番号入力、郵便番号検索、合意後の郵送先表示を初回提出で出すか
- [ ] 支払い方法設定、銀行振込、口座番号入力、金額指定、合意後の支払い情報表示を初回提出で出すか
- [ ] PhotosPicker利用時に写真ライブラリ権限文言が必要な実装か
- [ ] 近くのグルーム/スポット掲示板、現在地共有、待ち合わせ候補、現地交換モード、地図表示、逆ジオコーディングを出す場合、Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標のサーバー送信/保存、作成位置、閲覧者位置、半径、距離、公開範囲、地図・距離・場所名の非保証、1km/3kmが匿名化又は安全保証ではないことをPrivacy/FAQ/Review Notesへ反映するか
- [ ] App Privacyの`Analytics`目的を選ぶほどの行動分析をしているか
- [ ] App Store ConnectのカテゴリをInfo.plistのSocial Networkingに合わせるか、ライフスタイルへ変更するか

## 9. 提出前の推奨回答メモ

- 初回提出でAdMob、メグルムプラス、外部AIを見せる場合は、App Privacyと公開ポリシーに必ず反映する。隠す場合でも、SDK初期化、広告リクエスト、購入導線、AI送信が発生しないことを実機で確認する。
- 郵送交換を出す場合、Physical Address / Phone Numberを回答する。隠す場合でも住所設定、郵便番号検索、郵送先表示へ到達できないことを実機で確認する。
- 支払い設定、銀行振込、口座番号、金額指定取引、成立後支払い情報スナップショットを出す場合、Financial Info / Payment Infoを回答する。隠す場合でも支払い設定、口座入力、合意後の支払い情報表示へ到達できないことを実機で確認する。
- 銀行振込、PayPay、現金交換その他外部サービスへの対応可否を出す場合、Megrumが決済代行、資金移動、収納代行、返金、エスクロー、本人確認、口座名義確認、支払能力確認、外部アカウント/リンク/QRコード/外部ID/残高/送金可否/受領可否の確認を行うようにApp Privacy、FAQ、Review Notesで説明しない。
- 性別、活動エリア、年齢、評価、完了取引数、支払い方法要約がプロフィール、ホーム候補、交換条件等に表示される場合、公開範囲、自己申告性、非保証をプライバシーポリシー、FAQ、Review Notesと一致させる。
- 現在地共有、待ち合わせ候補、現地交換モード、近くのグルーム/スポット掲示板、グルーム/掲示板の作成座標、掲示板作成/返信範囲判定、地図表示、逆ジオコーディングを出す場合、Precise Locationを「任意利用又は機能利用時」「App Functionality / Safety」「Linked to user」「Not tracking」で回答する。現行実装のように精密座標をサーバーへ送る導線がある場合、Coarse Locationだけ又は端末内処理だけとして回答しない。
- 取引チャット、投稿、画像、評価コメント、通報補足、異議申し立て本文はUser Contentとして広めに回答する。
- ブロック関係、通報status、モデレーション優先度、運営対応ログはOther Data Types又はCustomer Supportのどちらで回答するか、App Store Connectの実UIで過少申告にならない側へ寄せる。
- APNs token、push provider、端末通知登録状態やユーザーIDはIdentifiersとして回答する。過去又は別環境でExpo Pushを使う場合は、Expo push tokenも別途回答対象として再確認する。
- Push通知を出す場合、通知タイトル/本文/リンク先/未読バッジ/通知ID/soundがAPNsへ送信され、ロック画面・通知センター・連携端末に表示され得る。過去又は別環境でExpo Pushを使う場合も同等に確認する。Device IDだけでなく、User Content / Other User Content、Usage Data / Product Interaction、Privacy Policy、FAQ、アプリ内通知説明を同時に照合する。
- Push通知を許可しないと登録できない、又は主要機能を使えない設計にしない。正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文を通知本文に入れない。プロモーション又は直接マーケティングPushは明示的同意とオプトアウト手段なしで送らない。
- メグルムプラスを出す場合、Purchasesを回答する。購入状態だけでなく、商品情報照会、価格取得、購入開始、承認待ち、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止も、Purchases、Identifiers又はOther Dataのどこで扱うか実ビルドとApp Store Connectの最新UIで確認する。
- AdMobを有効にする場合、Google Mobile Ads SDKの公式データ開示に沿ってAdvertising Data、Device ID、Product Interaction、Diagnostics、Performance Data等の要否を回答する。現行設定のようにSDK初期化と広告リクエストが発生し得る場合、「広告を出していない」前提の回答にしない。
- 広告を有効にする場合、不適切又は年齢に合わない広告の通報導線を用意し、広告通報時の画面、日時、スクリーンショット、広告識別子等をCustomer Support / Advertising Dataのどちらで説明するかをApp Privacyとプライバシーポリシーで揃える。
- `NSPrivacyTracking=false` かつ `NSUserTrackingUsageDescription` 未設定のまま、IDFA、Apple定義のTracking、Publisher First-Party ID、パーソナライズ広告、広告メディエーション又は第三者広告目的の横断利用を有効にしない。これらを使うならATT、Tracking回答、App Privacy、同意管理を先に揃える。
- `MEGRUM_ADMOB_TEST_ADS_ENABLED=YES` 又はGoogleデモunit idを、一般公開ビルドの実広告として残さない。公開ビルドではproduction unit id、審査用test設定、App Store Review Notesのどれを使うかを明示して証跡化する。
- 外部AIを出す場合、画像/画像URL/グッズ関連情報の外部送信と、汎用モデル学習利用の有無をアプリ内表示又はプライバシーポリシーで説明する。
- 顔候補付けを出す場合、単なる写真アップロードとして片付けず、顔特徴量又は画像特徴量の生成・保存・照合があるかを確認する。到達可能ならSensitive Info / Biometric Dataを回答候補に上げ、Face ID認証や本人確認ではないことをReview Notesとプライバシーポリシーで説明する。

## 10. 公式参照

- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple Privacy Manifest: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- 個人情報保護委員会 通則ガイドライン: https://www.ppc.go.jp/personalinfo/legal/guidelines_tsusoku/
- e-Gov 資金決済に関する法律: https://laws.e-gov.go.jp/law/421AC0000000059
- 消費者庁 消費者契約法: https://www.caa.go.jp/policies/policy/consumer_system/consumer_contract_act/
- Google Mobile Ads SDK data disclosure: https://developers.google.com/admob/ios/privacy/data-disclosure
- Google Mobile Ads iOS privacy strategies: https://developers.google.com/admob/ios/privacy/strategies
