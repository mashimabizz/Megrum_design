# 48. 外部サービス・委託先データ台帳

最終更新: 2026-06-29

ステータス: Draft v0.24（会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / 運営通知・通知本文統制 / Web外部通信先・next/font/google・MapTiler/Nominatim未検出整理 / legacy Expo削除済み・APNs主線の委託先前提 / Web Auth Cookie・Supabase SSR session refresh / ローカルenv・Vercel env・Supabase secrets・server-only key境界 / デバッグログ・Edge Functionエラー・公開証跡secret混入防止 / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 精密位置・MapKit/CoreLocation・逆ジオコーディング / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI Responses API / web_search / 顔特徴量RLS・学習データ既定true / 郵送交換 / 会員間支払い情報を反映）

## 目的

Megrumの初回App Store提出前に、外部サービス、SDK、API、ホスティング、決済、通知、地図、AI候補を一覧化し、プライバシーポリシー、App Privacy、Privacy Manifest、法務レビュー、サポート運用と照合できる状態にする。

この文書は確認台帳であり、コード、DB、SDK、契約、外部サービス設定は変更しない。

## 1. 現行リポジトリから読めた事実

| 領域 | 読み取り結果 |
|---|---|
| Swift Native | `ios-native/Package.swift` 上は `GoogleMobileAds` 依存あり。Xcode projectでも `GoogleMobileAds` をlink |
| Swift Native | `Info.plist` にカメラ、位置情報、`ITSAppUsesNonExemptEncryption=false`、AdMob app id / ad unit id build setting、SKAdNetworkItems |
| Swift Native / Ads | `MegrumNative.xcconfig` のチェックイン既定値は `MEGRUM_ADS_ENABLED=NO`、`MEGRUM_AD_PROVIDER=admob`、AdMob app id/unit id/test unit id空、`MEGRUM_ADMOB_TEST_ADS_ENABLED=NO`。Google Mobile Ads SDK linkとSKAdNetworkItemsは残るが、既定では `MobileAds.shared.start()` とbanner/native `Request()` の起動条件を満たさない |
| Swift Native / Ads | `NSUserTrackingUsageDescription`、ATT要求、UMP同意管理、非パーソナライズ広告指定、Publisher First-Party ID制御、mediation制御、child-directed treatment、test device id指定は現行検索で未確認 |
| Swift Native | Supabase REST/Storage/Auth相当の独自クライアント、APNs端末登録、Google OAuth URL構築、Apple Sign-In処理が存在 |
| Swift Native / Auth Links | `CFBundleURLSchemes=$(MEGRUM_URL_SCHEME)`、`MegrumAuthEmailRedirectURL`、`MegrumAuthOAuthAuthorizeURL`、`ASWebAuthenticationSession`、`MegrumRootView.onOpenURL`、`SupabaseAuthRedirectParser` が存在。認証callback fragmentはaccess token / refresh token等を含み得る |
| Swift Native | MapKit、CoreLocation、CLGeocoder、PhotosUI、カメラ利用箇所が存在。位置情報はnearest ten meters相当の精度設定、逆ジオコーディング、近くのグルーム/掲示板、現在地共有、掲示板作成/返信範囲判定へ使われ得る |
| Swift Native / Camera Photos Share | `PhotosPickerItem.loadTransferable(type: Data.self)` で読み込んだ写真を、対応形式・サイズ上限内で元データのまま保存し得る。`NativeCameraCaptureView` はカメラ撮影画像をJPEG再生成する経路あり。`GoodsShareActivitySheet` は `UIActivityViewController` で共有用テキスト/生成画像を外部アプリへ渡す |
| Swift Native | StoreKitでメグルムプラス購入・復元・`currentEntitlements`を扱う経路が存在。ただしチェックイン既定は `MEGRUM_PLUS_IAP_ENABLED=NO` で、購入/復元ボタン、StoreKit商品情報照会、購入、復元actionを停止する。IAP有効化時はproduct id、transaction id、Original Transaction ID、期限をサーバーRPCへ同期するが、Server API検証とServer Notifications同期は未確認 |
| Swift Native / Home/Search | ホーム候補、検索結果、検索候補、マッチ/条件一致ラベル、表示順、レコメンドは、在庫、wish、個別募集、タグ、推し、交換方法、活動エリア、位置又は日程設定、支払い方法要約、評価、完了取引数、ブロック関係、通知状態、メグルムプラス有効状態等を使う経路あり。Plus優先表示と広告挿入は表示順/organic-ad区別へ影響する |
| Swift Native | Apple Visionによる顔矩形検出、顔特徴量モデル境界、`member_face_profiles` / `face_uploaded_images` / `detected_faces` / `face_match_candidates` / `face_match_corrections` の保存境界が存在。Face ID / 生体認証APIではない。現行GoodsEditorでは候補補正をdraft/memberIDへ反映する経路はあるが、補正履歴DB保存呼び出しは未確認 |
| Swift Native | `member_face_profiles` のselectには `embedding`、`embedding_model`、`source_image_url`、`consent_recorded_at` が含まれ、RLSはactive profileをauthenticated userに読ませる設計。実在人物データを格納する場合はSensitive Info / biometric data相当として公開前No-Go候補 |
| Swift Native | `user_mailing_addresses` へ宛名、郵便番号、住所、電話番号を保存し、合意後に郵送先スナップショットを当事者へ表示する経路が存在 |
| Swift Native | `PostalCodeAddressClient` からZipCloudへ郵便番号を送信して住所候補を取得する経路が存在 |
| Swift Native | `user_payment_settings` へ銀行名、支店名、口座種別、口座番号、口座名義、支払い方法、任意メモを保存し、金額指定取引の合意後に支払い情報スナップショットを当事者へ表示する経路が存在。PayPayは現行UI上リンク登録ではなく対応可否の表示。成立後スナップショットは、ユーザーが後で支払い設定を変更又は削除しても、取引確認・問い合わせ・紛争・通報・不正防止・監査・法令対応のため残る場合がある |
| Swift Native / Backend | 退会申請で理由、任意メモ、申請日時、削除予定日、申請状態を `account_deletion_requests` へ保存する経路が存在。APNs tokenはログアウト時のclient-side revokeとAPNs失効応答時のEdge Function revoke経路あり。30日後実削除、申請取消/復旧、Apple/Google連携解除、退会申請/削除完了に連動した全端末token無効化完了は未確認 |
| Backend | Supabase migrations、Storage、Auth、Edge Function、APNs通知Functionが存在 |
| Backend / Storage | `goods-photos` と `avatars` はpublic bucket。`chat-photos` はproposal参加者限定のprivate bucketだが、取引チャット写真・服装写真・証跡写真のsigned URL有効期限はコード上365日。`groom-posts` は後続migrationでprivate化し、`meguri-message-media` は送受信者限定、`meguri-board-media` はprivate bucketだがauthenticated select policyあり |
| Backend | `suggest-goods-series` Edge FunctionからOpenAI Responses APIへ画像等を送る経路が存在 |
| Backend / External AI | `suggest-goods-series` は認証済みユーザー確認後、最大3件の画像データ又は画像URL、グループ名、メンバー名、グッズ種別、既存候補をOpenAI Responses APIへ送信し、`web_search` を必須実行する |
| Backend / Logs | `suggest-goods-series` はOpenAI失敗時に外部API応答本文を含むエラーを作り、JSON `detail` に返す経路あり。`send-apns-notification` もSupabase応答本文を含むエラーを作り、JSON `detail` に返す経路あり |
| Backend / Search logs | `search_query_logs`、`record_search_query`、`get_popular_search_terms` は検索語、`normalized_term`、`result_count`、30日人気検索集計を扱う。2026-06-29時点のSwift検索ではRPC呼び出し未確認 |
| Swift Native / External AI UI | `GoodsBulkTagSheet` は「画像からシリーズ名称の候補を出す」と表示するが、2026-06-29時点の読み取りではOpenAI、外部AI、web_search、保持、学習利用、第三者/未成年/権利未処理画像禁止を送信前に明示する画面文言は未確認 |
| Web | Supabase SSR/Auth Cookie、Next.js公開ページ、Stripe webhook候補、`next/font/google` が存在。2026-06-29時点の `web/src` ではMapTiler、Leaflet、Nominatim proxyの実装は未検出 |
| Web / 管理画面 | `admin_roles`、`admin_audit_logs`、ユーザー一覧、通報/異議申し立て、推し追加リクエスト、運営通知、有料権限、サブスクリプション、手動有料権限上書き、Stripe webhook候補を扱う。手動有料権限上書きは `entitlements.manage` 権限で `plan_overrides` と `user_entitlements.source='manual_override'` を使い、対象ユーザー、feature key、active/inactive、期限、理由、変更前後、作成者、override id、監査ログを扱う。運営通知は `notifications.send` 権限で、全有効ユーザー又は指定ユーザーへ `admin_announcement` を作成し、title/body/link_path/reason/audience/recipient_countを扱う。読み書きはサーバー側service role client経由の経路がある |
| Web / 監査ログ表示 | 管理画面の監査ログ詳細は `before_state`、`after_state`、`metadata`、`user_agent` をJSON表示する。reason、metadata、before/afterにsecretや過剰な個人情報を入れない運用が必要 |
| Local / deploy env | `.env.local`、`.vercel/.env.production.local`、`web/.env.local` 等に実運用secretが入り得る。`web/.env.local.example` はplaceholderだが、`SUPABASE_SECRET_KEY`、`STRIPE_WEBHOOK_SECRET`、MapTiler key等の境界を示す。MapTilerは現行 `web/src` では未使用候補 |
| Server-only secrets | Supabase service role、OpenAI API key、APNs private key/dispatch secret、SMTP password、OAuth client secret、Stripe webhook secret、S3 secret等は、server/Edge Function/Dashboard/secret manager専用として扱う。提出証跡は実値ではなくキー名だけ |
| Legacy Expo | `mobile/` は削除済み。Supabase migrationやDB互換列、過去ビルドにはExpo Push等の前提が残り得るため、再導入又は別環境で使う場合だけ別監査 |
| External AI | アプリ機能としてのOpenAI送信経路あり。グッズシリーズ候補機能の露出、同意、保持、学習利用、送信データを公開前に確定する |

## 2. 初回提出の回答方針

| 方針 | 内容 |
|---|---|
| 正とするバイナリ | Swift Native初回提出を正とする |
| Legacy Expo | 削除済み旧実装。Expo系の過去ビルド、別環境又は再導入版で提出する場合のみ別監査 |
| Web | 管理/運用/公開ページとして別扱い。ただしプライバシーポリシー、委託先台帳、セキュリティ監査には載せる。管理画面のservice role、MFA、権限、監査ログは提出前No-Go |
| IAP | 現行コードにメグルムプラス購入経路あり。チェックイン既定はIAP OFF。導線を有効化して見せるならApple IAP / App Privacy / 特商法 / サポート / Server API検証 / Server Notifications / 価格固定文言 / 手動有料権限上書きとの区別をP0で整合 |
| 広告 | 現行コードにGoogle Mobile Ads SDK / AdMob / SKAdNetwork構成あり。広告が有効ならApp Privacy、ATT、Google公式開示、SDK Privacy Manifest、不適切/年齢不相応広告の通報導線をP0で整合 |
| ホーム候補/検索/レコメンド | 候補表示、検索結果、検索候補、人気検索、表示順、Plus優先表示、広告挿入、Product Personalizationを出す場合、Search History / Usage Data / Product Personalization、非保証説明、検索ログ保存有無、organic/ad区別をP0で整合 |
| 評価/通報/ブロック/モデレーション | 現行コードに `user_evaluations`、`reports`、`goods_reports`、`groom_reports`、`meguri_board_reports`、`disputes`、`groom_user_blocks` 経路あり。Supabase、サポートツール、必要な外部機関対応の範囲と保持をP0で整合 |
| 外部AI | 現行コードに外部AI送信経路あり。導線が見えるなら同意/説明、送信先、画像又は画像URL、web search利用、学習利用、保持期間、削除可否、濫用監視ログ、第三者/未成年/権利未処理画像禁止をP0で整合 |
| 顔候補付け | 顔検出、顔特徴量、画像特徴量、メンバー候補付け又は補正履歴保存が見えるなら、Sensitive Info / biometric data候補、Face IDではない説明、同意記録、削除、外部送信有無、`member_face_profiles` 読み取り範囲、`shouldAddTrainingData` 既定trueの扱いをP0で整合 |
| 地図/位置情報 | 現地交換・めぐり・スポット掲示板・現在地共有で使う場合、Precise Location、MapKit/CoreLocation/CLGeocoder、サーバー送信/保存、地図・距離・場所名の非保証、保持/削除例外を回答 |
| カメラ/写真/共有シート | 画像アップロード又は共有を出す場合、Info.plist権限文言、画像メタデータ、共有用テキスト/生成画像、外部共有先の非管理をP0で整合 |
| 認証リンク/URL scheme/deep link | メール認証、パスワードリセット、Google OAuth、通知 `linkPath` 又はdeep linkを出す場合、Supabase Redirect URLs、Google OAuth設定、`MEGRUM_URL_SCHEME`、Web中継Route、Review Notes、FAQ、リンク秘密性をP0で整合 |
| 郵送交換/住所 | 郵送交換を出す場合、Physical Address / Phone Number、合意後表示、ZipCloud送信、保持期間をP0で整合 |
| 会員間支払い/口座情報 | 支払い設定、銀行振込、口座番号、口座名義、PayPay対応可否、現金交換、金額指定取引を出す場合、Financial Info / Payment Info、合意後表示、成立後スナップショット、目的外利用禁止、外部サービス非検証、決済/送金/収納代行/回収/返金/チャージバック/エスクロー非関与をP0で整合 |
| 管理者権限/監査ログ | 管理画面を使う場合、service roleのserver-only、管理者ロール、MFA要求、最小権限、操作理由、before/after state、IP/User-Agent、退会後保持、secret管理をP0で整合 |
| secret/config境界 | `.env.local`、Vercel env、Supabase secrets、APNs/Stripe/Google/OpenAI等のsecretは、公開ページ、App Review証跡、PR、サポート返信へ実値を出さず、キー名・保管場所・権限・ローテーション判断だけをP0で整合 |
| 通知 | APNs token、push provider、app version、last seen、revoked状態、通知タイトル/本文、通知リンク先、未読バッジ、通知ID、sound、Edge Function、Apple endpoint、運営通知の宛先区分、対象件数、送信理由、監査ログ、ロック画面/通知センター/連携端末表示リスクを回答対象に含める |
| 退会申請/外部連携解除 | 削除申請中状態、削除予定日、保持対象、Apple/Google連携解除、APNs token無効化、Supabase Auth/Storage削除手順をP0で整合。APNs tokenの一部revoke経路があっても、退会申請/削除完了との連動が未確認の間は完了や復旧を保証しない。過去又は別環境でExpo Pushを使う場合はExpo token無効化も別途確認する |
| Keychain/session保存 | iOS Keychainに保存されるAuthSession、access token、refresh token、expires、user id、email、refresh token更新、logout API、端末紛失・バックアップ・復元・他端末sessionの説明をP0で整合 |
| ログ/証跡 | Swift DEBUG OSLog、Function logs、外部API error response、管理者監査ログ、App Review証跡、サポート返信にtoken、secret、signed URL、画像URL、通知本文、通報/削除申出本文を残さないことをP0で整合 |

## 3. サービス別台帳

| サービス / SDK | 使う場面 | データ候補 | App Privacy影響 | 初回状態 | 要確認 |
|---|---|---|---|---|---|
| Supabase Auth | 認証、メール、OAuth、callback session交換、refresh、logout | メール、ユーザーID、認証状態、認証code、access token、refresh token、callback URL、provider、error情報、logout request、session refresh結果 | Contact Info, Identifiers, Usage Data / Other Dataの可能性 | 使用候補 | DPA、リージョン、Redirect URLs、refresh token rotation、削除手順、退会時Auth削除/無効化、他端末session失効 |
| Supabase SSR / Web Auth Cookie | Web管理画面ログイン、公開Web認証callback、password reset、Google OAuth callback、Next.js proxy/middlewareのsession refresh | Supabase Auth Cookie、認証code、session refresh結果、Cookie設定/更新/削除、IP、User-Agent、error情報 | Contact Info, Identifiers, Usage Data / Other Dataの可能性 | 使用候補 | Cookie説明、Cookie無効時の制限、logout時Cookie削除、認証callback/ブラウザ履歴、Cookie値/token実値のログ・証跡混入防止 |
| Supabase Database | プロフィール、在庫、wish、打診、取引、評価、通報、異議申し立て、ブロック、モデレーション状態、設定、郵送先住所、支払い情報、銀行口座情報、成立後の支払い情報スナップショット、検索ログ、候補表示/表示順に使う内部フラグ、退会申請理由/任意メモ/削除予定日、管理者ロール、監査ログ、手動有料権限上書き、plan override、付与又は停止理由、運営通知の宛先区分、対象ユーザー、通知タイトル/本文、リンク先、送信理由、対象件数 | User Content, Identifiers, Contact Info, Financial Info, Purchases, Search History, Usage Data, Other Data | User Content, Identifiers, Contact Info, Financial Info, Search History, Customer Support, Other User Content, Other Data Types, Product Interaction, Product Personalization | 使用候補 | RLS、service role、保持期間、削除対象、通報者保護、検索ログ保存有無、人気検索集計、成立後スナップショットの保持・閲覧範囲、管理者MFA、権限分離、手動有料権限の理由/期限/監査ログ、運営通知本文統制、監査ログ、退会申請完了/取消処理 |
| Supabase Storage | グッズ写真、プロフィール画像、取引チャット写真、服装写真、証跡、グルーム画像、スポット掲示板画像、めぐりメッセージ画像 | Photos or Videos, Storage path, 公開URL, signed URL | User Content, Photos or Videos, 場合によりLocation/Sensitive Info | 使用候補 | public/private bucketの妥当性、signed URL期限、削除/キャッシュ、相手保存、`meguri-board-media`のauthenticated select |
| Supabase Edge Functions | APNs通知、将来API | 通知ID、user_id、APNs token参照、通知タイトル/本文、リンク先、未読数、sound、配送結果、token末尾ログ | Identifiers, User Content, Usage Dataの一部 | 使用候補 | secrets管理、ログ保持、payload最小化。運営通知を含め、正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文をpayloadに入れない |
| Supabase Edge Function logs / error detail | APNs通知、OpenAI候補生成、外部API失敗時の調査 | status、外部API response text、Supabase response text、通知ID、APNs token末尾、画像URL又は署名URLの一部、AI/通知エラー、Function logs | Diagnostics, Usage Data, Other Dataの可能性 | 使用候補 | `messageOf(error)` や `response.text()` にsecret、token、ユーザー入力、画像URL、通知本文が混ざらないこと。公開証跡にdetail全文を貼らない |
| Local env / secret manager | 開発、管理画面、Edge Function、デプロイ、外部サービス設定 | `SUPABASE_SECRET_KEY`、`SUPABASE_SERVICE_ROLE_KEY`、`OPENAI_API_KEY`、`MEGRUM_APNS_PRIVATE_KEY`、`MEGRUM_APNS_DISPATCH_SECRET`、`STRIPE_WEBHOOK_SECRET`、SMTP password、OAuth client secret、S3 secret等の開発者secret | App Privacy直接対象外。ただし漏えい時はセキュリティ事故・安全管理措置・委託先管理の対象 | 使用候補 | 実値をリポジトリ、証跡、PR、公開ページ、チャット、サポート返信へ出さない。証跡はキー名、環境、権限者、確認日時だけ |
| Next.js / 公開Web hosting | 公開法務ページ、サポートページ、管理画面、認証callback、password reset、Google OAuth中継 | IP、User-Agent、URL path/query、Cookie、認証code、session refresh結果、アクセスログ、エラーログ、ホスティング/プロキシログ | Web/Privacy/安全管理措置の対象。iOS App Privacyでは最終アプリ経由の収集と分ける | 使用候補 | ホスティング委託先、ログ保持、Cookie、secret/env、公開ページのsecret混入、App Reviewへ出す公開URLを確認 |
| Next.js Google Fonts / `next/font/google` | 公開WebのNoto Sans JP / Inter Tight | ビルド時に取得されるフォントCSS/ファイル、フォント名・weight・subset。ローカルNext.js docs上はself-hostでブラウザからGoogleへrequestを送らない | 通常はApp Privacy直接対象外。公開Webの実NetworkでGoogle Fonts直接通信があれば外部サービス説明を再確認 | 使用候補 | デプロイ済みHTML/Networkで `fonts.googleapis.com` / `fonts.gstatic.com` が出ないこと、CSP/asset host、フォント取得時のビルド環境ログを確認 |
| Apple Sign in | 認証 | Apple user id、メール、identity token | Contact Info, Identifiers | 使用候補 | token revoke、削除時処理 |
| Google OAuth | 認証 | Google user id、メール、プロフィール名候補、OAuth認可URL、redirect_to、callback結果 | Contact Info, Identifiers | 使用候補 | 初回Swiftで有効か、Google Cloud / Supabase / Web中継Route / native callback scheme一致、削除時連携解除 |
| ASWebAuthenticationSession / Custom URL Scheme | Google OAuth、メールcallback、native session復元、deep link | `megrum://auth/callback`、`megrum-preview://auth/callback`、access token、refresh token、path/query/fragment、error/provider、リンク開封結果 | Contact Info, Identifiers, Usage Data / Other Dataの可能性 | 使用候補 | callback scheme、URL scheme衝突リスク、Universal Linksではない説明、リンク/認証コード共有禁止、ログ最小化 |
| iOS Keychain / Security framework | ログイン状態維持、保存済みsession復元、refresh後session再保存、ログアウト時clear | AuthSession JSON、access token、refresh token、expires、token type、user id、email、保存/削除結果 | Contact Info, Identifiers, Usage Data / Other Dataの可能性 | 使用候補 | `kSecAttrAccessible` / ThisDeviceOnly方針、バックアップ/復元/アンインストール/端末紛失時説明、tokenログ混入防止 |
| Apple APNs | 端末通知 | APNs device token、通知タイトル/本文、リンク先、未読バッジ、通知ID、sound | Identifiers, User Content, Usage Dataの一部 | 使用候補 | token失効、通知本文の個人情報、ロック画面/通知センター/連携端末表示。Push通知を利用必須にしない |
| Apple StoreKit / IAP | メグルムプラス | purchase state、transaction id、original transaction id、expires_at、復元、返金/取消/期限切れ/請求失敗/猶予期間、サーバー同期状態、最終権限状態 | Purchases | 経路あり。チェックイン既定は `MEGRUM_PLUS_IAP_ENABLED=NO` で購入/復元/商品照会停止 | App Store Connect商品、価格表示一致、復元、解約説明、Server API検証、Server Notifications、返金/取消/期限切れ同期、manual overrideとの区別。OFF提出時はStoreKit通信なしを確認 |
| Apple Vision / Core ML候補 | グッズ画像の顔検出、将来の顔特徴量又は画像特徴量生成 | 顔検出矩形、信頼度、特徴量、候補スコア、補正履歴、学習データ追加可否、`member_face_profiles` のembedding/source image URL | Sensitive Info / Biometric Data, User Content | 経路あり | Face IDではない説明、オンデバイス/サーバー処理、外部送信有無、削除、同意記録、authenticated readの最小化 |
| Google Mobile Ads / AdMob | 広告表示、広告測定、広告通報対応 | IP、端末/広告ID、広告表示/クリック、広告通報時の広告枠/表示日時/広告識別子、診断、パフォーマンス、test ads / production unit id、広告リクエスト等 | Device ID, Advertising Data, Product Interaction, Diagnostics等 | SDK/構成あり。現行既定では広告ON/test ads ON | ATT、IDFA、Publisher First-Party ID、パーソナライズ広告、メディエーション、UMP同意管理、Google公式開示、test ads除去、不適切/年齢不相応広告の報告手順 |
| Apple SKAdNetwork | 広告測定 | SKAdNetwork conversion info | Advertising / Measurement | Info.plist構成あり | SKAdNetworkItems更新、広告ネットワーク追加時確認 |
| Stripe | Web/将来課金、webhook | customer id、subscription id、event payload | Purchases, Identifiers | iOS初回では非表示候補 | iOS課金との棲み分け、特商法 |
| 会員利用の金融機関 / 決済サービス | 会員間支払い、銀行振込、PayPay、現金交換、外部サービスID・送金リンク・送金用QR等がメモ等に入力される可能性 | 銀行口座情報、支払い方法、金額、口座名義、外部サービス名又は外部ID、取引相手への合意後表示、成立後支払い情報スナップショット | Payment Info | アプリ内支払い設定経路あり | Megrumが資金受領/保管/送金/収納代行/回収/返金/チャージバック/エスクローをしないこと、口座名義・本人性・残高・支払能力・外部ID・送金リンク・QRの真正性を確認しないこと、ユーザー間表示の範囲、規約/ポリシー文言 |
| MapKit / CoreLocation / CLGeocoder | 現地交換、めぐり、スポット掲示板、地図表示、逆ジオコーディング、現在地共有 | 精密な緯度経度、精度、時刻、場所名、距離又は範囲判定に必要な情報 | Precise Location / Coarse Location | 使用候補 | 現行Swift Nativeは精密座標を扱い得る。App Privacy、権限文言、OS/地図サービス処理、サーバー送信/保存、地図・距離・場所名の非保証、保持/削除例外 |
| Apple Camera / PhotosUI | カメラ撮影、写真ライブラリ選択、画像アップロード | 画像、元画像データ、再圧縮画像、content type、ファイルサイズ、EXIF、撮影日時、GPS位置情報、端末情報 | Photos or Videos, Location, Device Infoの可能性 | 使用候補 | Info.plist権限文言、PhotosPicker元データ保存経路、カメラJPEG再生成経路、メタデータ削除有無、App Privacy回答 |
| Apple Share Sheet / 外部SNS | 共有用画像/テキストの外部共有 | 表示名、グッズ画像、グッズ名、グループ名、メンバー名、グッズ種別、タグ、ハッシュタグ、リンク | User Content, Photos or Videos, Other Dataの可能性 | 使用候補 | 共有後の保存、公開、再共有、削除、広告利用、アクセス解析、画像メタデータ利用は共有先規約に従う説明 |
| MapTiler | Web地図候補 | 地図表示、座標、API key | Locationの可能性 | 現行 `web/src` では未検出。`web/.env.local.example` にplaceholderあり | 再導入又は別ブランチで使う場合、公開ページ/管理画面での使用範囲、送信情報、API key公開範囲を確認 |
| Nominatim / OpenStreetMap | Web geocode proxy候補 | クエリ、緯度経度 | Locationの可能性 | 現行 `web/src` / `supabase/functions` では未検出 | 再導入又は別ブランチで使う場合、利用ポリシー、キャッシュ、User-Agent、Location回答を確認 |
| ZipCloud | 郵便番号検索、住所補完候補 | 郵便番号、住所候補 | Physical Address / Contact Info | 使用候補 | 利用ポリシー、送信情報、失敗時表示、プライバシー説明 |
| Expo Notifications | legacy通知（現行Swift Native初回提出では対象外） | 過去又は別環境でExpo Pushを利用する場合のExpo push token、通知タイトル/本文、リンク先、未読バッジ、通知ID | Identifiers, User Content, Usage Dataの一部 | 現行リポジトリの `mobile/` は削除済み。Swift初回では対象外候補 | Expo系の過去ビルド、別環境又は再導入版を提出/運用する場合だけ回答。legacy経路が残る場合はAPNsと同じpayload最小化・同意/停止方針に合わせる |
| Expo Updates / EAS | legacy配布（現行Swift Native初回提出では対象外） | update id、device/app metadata | Identifiers/Usageの可能性 | `mobile/` 削除済み。Swift初回では対象外候補 | Expo系ビルドを再提出又は運用する場合だけ回答 |
| Expo Camera / Image Picker / Location / IAP | legacy権限（現行Swift Native初回提出では対象外） | 写真、位置、購入 | 複数 | `mobile/` 削除済み。Swift初回では対象外候補 | Expo系ビルドを再提出又は運用する場合だけ回答 |
| Analytics / Crash SDK | 品質改善 | 操作ログ、クラッシュ | Usage Data, Diagnostics | 未導入候補 | SDK有無を最終確認 |
| OpenAI Responses API | グッズシリーズ候補AI補助 | 最大3件の画像/画像URL、グループ名、メンバー名、グッズ種別、既存候補、AI出力、web search利用結果 | User Content, Photos or Videos, Other Data | 経路あり | 送信情報、web search利用、汎用モデル学習不使用、濫用監視等の保持、削除可否、送信前同意又は任意性、第三者/未成年/権利未処理画像禁止 |
| External image hosts / CDN | 外部画像URLの表示、AI検索候補又はユーザー登録画像URLの読み込み | IP、端末/アプリ通信情報、アクセス時刻、画像URL、HTTPレスポンス等 | User Content / Other Data / Device Infoの可能性 | 経路あり | 外部画像URL露出、権利処理、通信先、画像プロキシ有無、第三者ポリシー |
| OpenAI API Key in Supabase secrets | Edge Function認証 | 開発者secret | App Privacy直接対象外 | 使用候補 | secrets漏えい防止、ログ出力禁止、ローテーション |
| Supabase service role / Web管理画面 | 管理者画面、Stripe webhook、運営処理 | service role key、管理者操作ログ、IP、User-Agent、before/after state、手動有料権限上書き、運営通知送信 | App Privacy直接対象外だがPrivacy/安全管理措置/セキュリティ監査対象 | 使用候補 | server-only、secret漏えい防止、MFA、最小権限、監査ログ、誤操作時の復旧、退会後保持、手動上書きを購入/返金保証にしない |

## 4. 委託/第三者提供の整理

| 分類 | 対象候補 | 文書上の扱い |
|---|---|---|
| 委託先候補 | Supabase、メール/サポートツール、ホスティング、OpenAI、分析/クラッシュ、Map API | プライバシーポリシーの委託先/外部サービス欄で説明 |
| プラットフォーム提供者 | Apple、Google | 認証、IAP、通知、OS権限、カメラ/写真ライブラリ/共有シート、広告SDKとして説明 |
| 独立した第三者候補 | Google AdMob、Stripe、OpenAI、地図/ジオコーディングAPI、外部画像ホスト/CDN、会員が利用する金融機関/決済サービス、外部SNS、共有先アプリ/サービス | 利用態様に応じて第三者提供/委託/ユーザー送信の整理を法務確認。会員が任意に使う金融機関/決済サービスはMegrumの委託先又は決済代行先として説明しない |
| ユーザー間表示 | 取引相手へのプロフィール、取引チャット、証跡、合意後の郵送先情報、支払い情報、成立後支払い情報スナップショット等 | アプリ機能上の表示としてプライバシーポリシーに説明。相手方によるスクリーンショット、保存、転記、外部送信を完全には防げない前提で注意文と禁止事項を整合 |

## 5. 契約・設定チェック

| 項目 | 状態 |
|---|---|
| SupabaseのDPA/リージョン/サブプロセッサ確認 | 未 |
| `.env.local`、`.vercel/.env.production.local`、`web/.env.local`、Supabase secrets、Vercel envの保管場所、権限者、ローテーション手順、証跡に実値を残さない運用確認 | 未 |
| Apple Developer契約とAPNs/IAP利用確認 | 未 |
| Google OAuthの設定、プライバシーURL、削除時連携解除確認 | 未 |
| Supabase Redirect URLs、Google OAuth redirect、`MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Web中継Route、Review Notes、FAQの一致確認 | 未 |
| Keychain保存sessionの `kSecAttrAccessible` 方針、ThisDeviceOnly要否、logout時clear、refresh token更新、端末バックアップ/復元/紛失時案内、tokenログ混入防止の確認 | 未 |
| 退会申請後のSupabase Auth削除/無効化、Storage削除、Apple/Google連携解除、APNs token無効化、完了通知又は手動処理記録の運用確認。過去又は別環境でExpo Pushを使う場合はExpo token無効化も別途確認 | 未（一部APNs token revoke経路は確認済み。退会申請/削除完了への連動は未確認） |
| Google AdMobのデータ処理、パーソナライズ広告、Publisher First-Party ID、メディエーション、UMP同意管理、ATT要否、`NSUserTrackingUsageDescription`要否確認 | 未 |
| 広告を有効化する場合の `MEGRUM_ADMOB_TEST_ADS_ENABLED=YES` / Googleデモunit idを一般公開ビルドから外す確認 | 未（チェックイン既定は広告OFF） |
| 不適切又は年齢に合わない広告の通報導線、広告配信事業者への報告手順、サポート説明確認 | 未 |
| 評価コメント、通報補足、異議申し立て本文、ブロック関係、モデレーションstatusの保持、削除、App Privacy分類確認 | 未 |
| Google Mobile Ads SDKのPrivacy Manifest / App Privacy Data Disclosure確認 | 未 |
| メグルムプラス商品ID、App Store Connect商品、価格、配信国、審査メモ、アプリ内固定価格文言確認 | 未 |
| App Store Server API / Server Notificationsによる更新、返金、取消、期限切れ、請求失敗、猶予期間同期確認 | 未 |
| Stripeを初回iOSで見せない又はIAPへ寄せる判断 | 未 |
| 会員間支払いについて、運営者が決済代行、資金移動、収納代行、回収、返金、チャージバック、エスクロー、前払式支払手段発行、暗号資産交換、金融商品取引、債権回収として関与しない運用・文言確認 | 未 |
| 会員間支払いの口座名義、本人性、支払能力、残高、外部サービスID、送金リンク、送金用QRをMegrumが確認済み又は保証済みと読める文言がないか確認 | 未 |
| ZipCloudの利用ポリシー、郵便番号送信、住所補完時の表示確認 | 未 |
| MapTiler/Nominatimは現行 `web/src` では未検出。`web/.env.local.example` のplaceholderや別ブランチから再導入する場合の初回露出有無確認 | 未 |
| OpenAI APIの契約、API経由データ保持、学習利用、web_search利用、濫用監視ログ、削除可否、画像URL/画像base64の扱い確認 | 未 |
| Supabase Storageのpublic bucket、private bucket、signed URL期限、画像キャッシュ、削除時の孤児ファイル、`meguri-board-media`のauthenticated select妥当性確認 | 未 |
| カメラ/写真ライブラリのInfo.plist権限文言、写真ライブラリ元データ保存経路、EXIF/GPS等画像メタデータ、共有シート外部送信の説明確認 | 未 |
| Apple Vision / Core ML / 顔特徴量について、Face IDではない説明、Sensitive Info回答、同意記録、削除/保持、外部送信有無、`member_face_profiles` のauthenticated read、`shouldAddTrainingData` 既定true確認 | 未 |
| Analytics/Crash SDK導入有無確認 | 未 |
| サポートメール/問い合わせ管理ツールの委託先確認 | 未 |
| 公開ページホスティングの委託先確認 | 未 |
| 管理者画面のMFA、最小権限、owner冗長性、監査ログ閲覧権限、IP/User-Agent保存、service role secretのserver-only確認 | 未 |

## 6. App Privacyへの反映

| データ | 関連サービス | App Privacy候補 |
|---|---|---|
| メール、OAuth ID | Supabase Auth、Apple、Google | Contact Info, Identifiers |
| Web Auth Cookie / browser session | Supabase Auth、Next.js proxy/middleware、Web callback、ブラウザCookie | Contact Info, Identifiers, Usage Data / Other Dataの可能性 |
| 認証callback / deep link | Supabase Auth、ASWebAuthenticationSession、Web callback、OS URL scheme、メール/外部ブラウザ | Contact Info, Identifiers, Usage Data / Other Dataの可能性 |
| プロフィール、在庫、wish、投稿、チャット | Supabase DB/Storage | User Content |
| 画像 | Supabase Storage、Camera/Photos、Apple Share Sheet、外部SNS | Photos or Videos、場合によりLocation / Device Info / Other Data |
| 顔検出結果、顔特徴量、画像特徴量、候補・補正履歴 | Apple Vision / Core ML候補、Supabase face tables | Sensitive Info / Biometric Data, User Content |
| 位置情報 | CoreLocation、MapKit、CLGeocoder。MapTiler/Nominatimは現行未検出だが再導入時は別途確認 | Precise Location / Coarse Location |
| 郵送先住所、宛名、電話番号 | Supabase DB、ZipCloud、取引相手への合意後表示 | Physical Address, Phone Number, Name |
| 支払い方法、銀行口座番号、口座名義、金額指定、成立後支払い情報スナップショット | Supabase DB、取引相手への合意後表示、問い合わせ・紛争・通報・不正防止・監査・法令対応 | Financial Info / Payment Info |
| 検索語、検索結果件数、候補表示、表示順、Plus優先表示 | Supabase DB、Swift NativeのHome/Search/Ads/Entitlements | Search History, Usage Data / Product Interaction, Product Personalization |
| 通知token | Supabase、APNs。過去又は別環境でExpo Pushを使う場合のみExpo legacyも別途確認 | Identifiers |
| 購入状態 | StoreKit、Stripe候補 | Purchases |
| 広告表示/クリック/広告ID等 | Google Mobile Ads / AdMob / SKAdNetwork / サポート | Device ID, Advertising Data, Product Interaction, Diagnostics, Customer Support |
| 操作ログ/クラッシュ | Analytics/Crash SDK候補 | Usage Data, Diagnostics |
| 外部AI入力/出力 | OpenAI Responses API | User Content, Other Data |

## 7. Privacy Manifest / SDK監査への反映

`notes/44_privacy_manifest_sdk_audit.md` で最終ビルドを確認する。
RLS、Storage、secret、APNs、管理者権限の提出前監査は `notes/54_prelaunch_security_audit_checklist.md` で確認する。

特に見るもの:
- Swift Nativeに外部SDKが追加されていないか。
- Required Reason APIが増えていないか。
- `NSPrivacyTracking=false` の根拠が崩れていないか。
- Google Mobile Ads / Analytics / Crash / Advertising SDKのデータ開示がApp Privacyと一致しているか。
- 評価、通報、異議申し立て、ブロック、モデレーション記録がCustomer Support / Other User Content / Other Data Types / Product Interaction候補としてPrivacyと一致しているか。
- 管理者権限、監査ログ、手動権限上書き、運営通知、service role経由の処理がPrivacy、安全管理措置、セキュリティ監査と一致しているか。
- 顔候補付けが見える場合、Apple Vision/Core ML/外部API/DB保存境界、Sensitive Info回答、同意・削除・保持の説明が一致しているか。
- Expo系の過去ビルド、別環境又は再導入版で提出する場合、legacy manifest相当のRequired Reason APIとApp PrivacyをSwift Nativeとは別に再照合する。

## 8. No-Go

- 外部AIへ画像・本文・取引情報を送るのに、説明、同意、App Privacy、プライバシーポリシーが未整備。
- 顔特徴量又は画像特徴量を扱うのに、Sensitive Info / biometric data回答、Face IDではない説明、削除/保持、同意記録、外部送信有無が未整備。
- AdMobを有効にするのに、Google公式データ開示、ATT、Advertising Data、Device ID、Diagnostics、SKAdNetwork、Privacy Manifestを確認していない。
- `NSPrivacyTracking=false` 又は `NSUserTrackingUsageDescription` なしのまま、IDFA、Apple定義のTracking、Publisher First-Party ID、パーソナライズ広告、広告メディエーション又は第三者広告目的の横断利用を有効にしている。
- `MEGRUM_ADMOB_TEST_ADS_ENABLED=YES`、Googleデモunit id又は審査用でないtest ads設定のまま一般公開しようとしている。
- AdMob広告を表示するのに、不適切又は年齢に合わない広告の通報導線、広告通報時の取得情報、広告配信事業者への報告手順を確認していない。
- 評価、通報、異議申し立て、ブロック、モデレーション記録がSupabase又はサポート運用に保存されるのに、App Privacy分類、保持/削除、通報者保護、外部機関対応範囲が未確認。
- Analytics/Crash SDKが入っているのにUsage Data/Diagnosticsを確認していない。
- Stripeや有料導線が見えているのにIAP/特商法/App Privacy/価格表示/Server API又はServer Notificationsが未整備。
- 支払い設定、銀行振込、口座番号、口座名義、PayPay対応可否、現金交換、金額指定取引又は成立後支払い情報スナップショットが見えているのにPayment Info、目的外利用禁止、合意後表示、スナップショット保持、外部サービス非検証、決済/送金/収納代行/回収/返金/チャージバック/エスクロー非関与が未整備。
- ホーム候補、検索結果、検索候補、人気検索、表示順、Plus優先表示、広告挿入又はProduct Personalizationが見えているのに、Search History / Usage Data / Product Personalization、非保証説明、検索ログ保存有無、organic/ad区別が未整備。
- 管理画面がservice roleでユーザー、通報、課金、権限、通知、監査ログを扱うのに、MFA、最小権限、監査ログ、server-only secret管理、退会後保持、Privacy説明が未整備。
- 近くのグルーム、スポット掲示板、現在地共有、位置情報メッセージ、地図表示又は逆ジオコーディングが見えるのに、Precise Location回答、MapKit/CoreLocation/CLGeocoder等のOS・地図関連処理、精密座標のサーバー送信/保存、保持/削除例外、地図・距離・場所名の非保証が未整備。
- MapTiler/Nominatim等の外部地図・ジオコーディングAPIを再導入し、位置クエリを送るのにLocation回答とプライバシーポリシーが未整備。
- APNs tokenを保存するのにIdentifiers回答や退会申請/削除完了時の無効化が未確認。一部revoke経路だけをもって削除完了保証にしない。
- Push通知を許可しないと登録できない、又は主要機能を使えない設計にする。正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文を通知本文又は運営通知本文に入れる。プロモーション又は直接マーケティングPushを同意・停止手段なしで送る。運営通知の全体送信で宛先、対象件数、本文、リンク先、送信理由、監査ログを確認できない。
- メール認証、パスワードリセット、Google OAuth、native callback、Web中継Route、Supabase Redirect URLs、Google OAuth設定、App Store Review Notesのscheme/URLが一致していない。又は認証リンク、callback URL、access token、refresh token、認証コード、通知 `linkPath` を第三者へ共有してよいように説明している。
- Keychain保存session、refresh token更新、logout API、他端末session、端末バックアップ/復元/紛失時の扱いを確認しないまま、ログアウト又は退会ですべてのtoken/sessionが即時完全削除されると説明している。
- 住所補完APIや住所入力が見えているのに、初回MVPのApp Privacyで住所を選ばない方針のまま提出する。
- Supabase service role key、APNs秘密鍵、Stripe webhook secret、Map API keyを公開ページや証跡に出す。
- `.env.local`、`.vercel/.env.production.local`、`web/.env.local`、Supabase/Vercel/Apple/Stripe/Google/OpenAI等のsecret実値又はスクショを、提出証跡、PR、Issue、チャット、公開ページ、App Review添付、サポート返信へ残す。

## 9. 提出前の最小確認コマンド

```bash
rg -n "Supabase|supabase|Stripe|stripe|Firebase|Analytics|Crash|Sentry|PostHog|Mixpanel|Amplitude|OpenAI|Anthropic|GoogleMobileAds|AdMob|GAD|SKAdNetwork|MapTiler|maptiler|Nominatim|next/font|font/google|ZipCloud|StoreKit|APNs|expo-notifications|user_payment_settings|bank_account|payment_settings|Vision|VNDetectFace|FaceEmbedding|member_face_profiles|detected_faces|face_match" ios-native web supabase --glob '!**/node_modules/**' --glob '!web/.next/**'
plutil -p ios-native/App/PrivacyInfo.xcprivacy
plutil -p ios-native/App/Info.plist
sed -n '1,120p' ios-native/Package.swift
```

## 10. 関連文書

- App Privacy回答: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査: `notes/44_privacy_manifest_sdk_audit.md`
- アカウント削除・個人情報請求: `notes/45_account_deletion_privacy_request_runbook.md`
- App Store質問票: `notes/46_app_store_questionnaire_answer_sheet.md`
- ドメイン・メール・公開URL: `notes/47_domain_email_publication_runbook.md`
- プライバシーポリシードラフト: `notes/legal/02_privacy_policy_draft.md`
- 個人情報・セキュリティ事故初動: `notes/49_privacy_security_incident_response_runbook.md`
- 提出前セキュリティ監査: `notes/54_prelaunch_security_audit_checklist.md`
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- e-Gov 資金決済に関する法律: https://laws.e-gov.go.jp/law/421AC0000000059
- 財務省関東財務局 資金移動業関係: https://lfb.mof.go.jp/kantou/kinyuu/pagekt_cnt_20250516001sikinidou.html
- 金融庁 令和7年資金決済法改正に係る政令の公布及びパブリックコメントの結果等: https://www.fsa.go.jp/news/r7/sonota/20260522/20260522.html
