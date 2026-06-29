# 43. App Store Connect App Privacy回答シート

> 目的：App Store ConnectのApp Privacy質問に、Megrum初回提出ビルドとして回答しやすい形へ落とし込む。
> コード変更なし。実ビルドのSDK・通信・表示機能と照合してから最終回答する。

最終更新: 2026-06-29
ステータス: Draft v0.25（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / StoreKit・IAP販売可否・復元失敗 / legacy Expo削除済み・APNs主線のDevice ID回答前提 / デバッグログ・Edge Functionエラー・公開証跡secret混入防止 / Keychain・session保存・refresh token / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 精密位置・MapKit/CoreLocation・逆ジオコーディング / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search / 顔特徴量RLS・学習データ可否 / 郵送交換 / 会員間支払い情報の現行コード確認反映）

---

## 1. 現時点の確認事実

| 項目 | 現状 |
|---|---|
| Swift Privacy Manifest | `NSPrivacyTracking=false`、UserDefaults Required Reason `CA92.1` |
| Swift Info.plist | カメラ、位置情報、暗号化免除フラグ、Social Networkingカテゴリ、AdMob app id / ad unit id、SKAdNetworkItemsあり |
| Swift Package | `GoogleMobileAds` 依存あり |
| ネットワーク | Supabase REST / Storage / Auth相当の通信あり |
| 認証リンク / URL scheme | `CFBundleURLSchemes=$(MEGRUM_URL_SCHEME)`、`MegrumAuthEmailRedirectURL`、`MegrumAuthOAuthAuthorizeURL` あり。Google OAuthは `ASWebAuthenticationSession` で `https://megrum.jp/auth/oauth/authorize` を開き、native callback schemeへ戻す。認証callback fragmentはaccess token / refresh token等を含み得る。通知 `linkPath` とdeep link path/queryは画面遷移に使われる |
| Keychain / Auth session | live authでは `KeychainAuthSessionStore` がAuthSessionを端末内Keychainへ保存し、access token、refresh token、expires、token type、user id、emailを保持し得る。refresh tokenでsession更新し、logout時は端末内clear後にSupabase logout APIを呼ぶ。`kSecAttrAccessible` / ThisDeviceOnly方針、バックアップ/復元/他端末session失効は要確認 |
| Logs / Diagnostics / Evidence | Swift DEBUG OSLogで `privacy: .public` のerror description出力箇所あり。Edge Functionは外部API又はSupabase応答本文を含むエラーdetailを返す経路あり。Web管理画面は監査ログのbefore/after/metadata/User-AgentをJSON表示する。token、secret、signed URL、通知本文、通報本文等をログ/証跡/スクショ/PRに残さないことを提出前確認 |
| 写真 / カメラ / 共有 | グッズ、証跡、服装、プロフィール、取引チャット、グルーム、スポット掲示板用途で画像選択・撮影あり。カメラ撮影はJPEG再生成経路がある一方、PhotosPickerの元画像データを対応形式・サイズ上限内でそのまま保存し得る。共有シートは表示名、グッズ画像、グッズ名、グループ名、メンバー名、タグ、グッズ種別、ハッシュタグ等を含む共有用テキスト/生成画像を外部アプリへ渡し得る |
| 位置情報 | 近くのグルーム/掲示板、掲示板作成/返信範囲判定、地図表示、逆ジオコーディング、現在地共有、待ち合わせ候補、現地交換モードで利用あり。`CLLocationManager` はnearest ten meters相当の精度設定、`CLGeocoder` で場所名変換、取引チャット/めぐり/掲示板で緯度経度を送信する経路がある。現在地共有は取引チャットメッセージとして保存され、現地交換モードは最終/設定座標、活動ウィンドウ中心座標、半径、有効時間、持参グッズIDを扱い得る。グルーム/掲示板は作成時の緯度経度、閲覧者座標、公開範囲、1km/3km系距離判定を使うため、30日後の自動削除/非表示ジョブ未確認も含めPrecise Location寄りで回答する |
| 生年月日 / 年齢 | 初回設定で生年月日入力が必須。年齢を算出して保存・表示する経路あり。最低年齢制限、公的年齢確認、身分証確認、保護者同意確認、保護者管理機能は未確認 |
| 性別 / 活動エリア / 公開プロフィール | 初回設定・プロフィール編集で性別と活動エリアを扱う経路あり。公開プロフィール、ホーム候補、交換条件等で、性別、活動エリア、評価、完了取引数、支払い方法要約等が表示され得る。本人確認、法的性別確認、安全確認、支払能力確認ではない |
| ホーム候補 / 検索 / レコメンド | 在庫、wish、個別募集、タグ、推し、交換方法、活動エリア、位置又は日程設定、支払い方法要約、評価、完了取引数、ブロック関係、未読通知、メグルムプラス有効状態等からホーム候補、検索結果、マッチラベル、条件一致ラベル、検索候補、表示順、Product Personalizationを作る経路あり。メグルムプラス優先表示と検索結果への広告挿入も表示順・organic/ad区別に影響する。`search_query_logs` / `record_search_query` / `get_popular_search_terms` のDB/RPC基盤はあるが、Swiftからの検索ログ記録呼び出しは未確認 |
| 評価 / 通報 / ブロック / モデレーション | `user_evaluations`、`reports`、`goods_reports`、`groom_reports`、`meguri_board_reports`、`disputes`、`groom_user_blocks` の経路あり。評価コメント、通報補足、異議申し立て本文、証跡URL、ブロック関係、status、運営対応情報を保存/表示制御/安全対応に使う |
| 削除申出 / 送信防止措置 | 問い合わせ又は通報経由で、権利侵害、名誉毀損、プライバシー侵害等に関する削除申出、送信防止措置希望、発信者確認又は通知の対応履歴を保存し得る |
| 郵送交換 | 宛名、郵便番号、住所、電話番号を `user_mailing_addresses` へ保存し、合意後に郵送先スナップショットを当事者へ表示する経路あり |
| 郵便番号検索 | `PostalCodeAddressClient` からZipCloudへ郵便番号を送信する経路あり |
| 会員間支払い | `user_payment_settings` へ銀行名、支店名、口座種別、口座番号、口座名義、支払い方法、その他メモを保存し、金額指定取引の合意後に `proposals.sender_payment_settings` / `receiver_payment_settings` の支払い情報スナップショットを当事者へ表示する経路あり。PayPayはリンク登録なしの対応可否表示 |
| 退会申請 | 退会理由、任意メモ、申請日時、削除予定日、申請状態を `account_deletion_requests` へ保存する経路あり。30日後実削除、申請取消/復旧、Apple/Google連携解除、APNs token無効化完了は未確認 |
| 通知 | APNs token、platform、push provider、app version、last seen、revoked状態を扱う経路あり。APNs payloadへ通知タイトル/本文/未読バッジ/通知ID/linkPath/soundを送る経路あり |
| IAP | `megrum.plus.monthly` のメグルムプラス購入・復元・同期経路あり。購入ボタン、復元ボタン、StoreKit商品情報照会、価格取得、購入開始、承認待ち、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、ローカル有効表示とサーバー最終権限の差分を確認。管理画面の手動有料権限上書きは最終権限に影響し得るが購入証明ではない。導線が見えるならPurchases回答とOther Data候補を確認 |
| 広告 | Google Mobile Ads SDK / AdMob / SKAdNetworkの構成あり。`MEGRUM_ADS_ENABLED=YES`、AdMob app id、test ads有効、検索native/やりとりbanner unit idあり。広告を有効にするならAdvertising Data等と不適切/年齢不相応広告の通報導線を回答/説明 |
| 広告同意/Tracking | `NSPrivacyTracking=false`、`NSUserTrackingUsageDescription`なし。現行検索ではATT要求、UMP同意管理、非パーソナライズ広告指定、Publisher First-Party ID制御、mediation制御は未確認 |
| 外部AI | `suggest-goods-series` 経由で最大3件の画像又は画像URL、グループ名、メンバー名、グッズ種別、既存候補をOpenAI Responses APIへ送り、`web_search` を必須実行する経路あり。導線が見えるならUser Content / Photos or Videos / Other Data等に反映 |
| 外部画像URL | 既存画像URL又はAI/検索候補画像を表示する場合、外部画像ホスト/CDNへIP、端末/アプリ通信情報、アクセス時刻等が送信される可能性あり |
| 顔候補付け | `VisionFaceDetectionService`、`member_face_profiles`、`face_uploaded_images`、`detected_faces`、`face_match_candidates`、`face_match_corrections` の経路あり。`member_face_profiles` はembedding/source image URLをauthenticated readする設計で、補正履歴の学習データ追加フラグは既定trueの経路あり。顔特徴量又は画像特徴量を生成・保存・照合する導線が見えるならSensitive Info候補 |
| Web管理 / 監査ログ | 管理画面は `admin_roles`、`admin_audit_logs`、ユーザー、通報/異議、推し追加リクエスト、運営通知、課金/権限をservice role経由で扱う。Privacy本文とセキュリティ監査で説明する。App Privacy回答は、iOSアプリ経由で収集されるデータと、最終提出ビルドから到達する機能を中心に判断する |

---

## 2. App Privacyトップ回答

| App Store Connect欄 | 推奨回答 | 条件 |
|---|---|---|
| Privacy Policy URL | `https://megrum.jp/legal/privacy` | 公開済みであること |
| User Privacy Choices URL | `https://megrum.jp/support/privacy-request` | 任意だが入力推奨 |
| Does this app collect data? | Yes | 認証、投稿、画像、取引チャット等がある |
| Tracking | Conditional | `NSPrivacyTracking=false` だが、AdMob有効時はIDFA、Publisher First-Party ID、パーソナライズ広告、メディエーション、横断追跡該当性を確認してからNo/Yesを決める |

Appleの説明では、アプリが継続的又は主要機能として収集するデータは原則開示対象。問い合わせフォームのように任意・低頻度・主要機能外で、ユーザーが明示的に提供するものだけが任意開示になり得る。Megrumではアプリ機能の中核にあるデータが多いため、広めに開示する。

---

## 3. Data Types選択リスト

初回提出でコア交換、取引チャット、グルーム/掲示板、通知を出す場合の選択候補。

| Category | Data Type | 選択 | 条件 |
|---|---|---|---|
| Contact Info | Name | Yes | 表示名、問い合わせ時の氏名 |
| Contact Info | Email Address | Yes | 認証、問い合わせ |
| Contact Info | Phone Number | Conditional | 郵送交換/住所登録を出す場合 |
| Contact Info | Physical Address | Conditional | 郵送交換/住所登録を出す場合 |
| Financial Info | Payment Info | Conditional | 支払い設定、銀行振込、口座番号入力、金額指定取引、成立後支払い情報スナップショットを出す場合 |
| Sensitive Info | Sensitive Info / Biometric Data | Conditional | 顔検出、顔特徴量、画像特徴量、メンバー候補付け、補正履歴保存、`member_face_profiles` embedding/source image URL、学習データ追加可否を出す場合 |
| Other Data | Other Data Types | Yes | 生年月日、算出年齢又は年代、性別、年齢に基づく安全確認、ブロック関係、通報/モデレーション状態、削除申出/送信防止措置の対応状態、運営対応ログ。管理者監査ログ、操作理由、IP/User-Agent、before/after stateはWeb運用・Privacy本文では対象。iOS App Privacyでは最終UIと収集経路に応じて確認 |
| User Content | Photos or Videos | Yes | グッズ、証跡、服装、投稿、プロフィール画像、取引チャット写真、スポット掲示板画像、共有用生成画像。EXIF/GPS等の画像メタデータ残存も確認 |
| User Content | Emails or Text Messages | Yes | 取引チャット、めぐりメッセージ等の非SMSメッセージ |
| User Content | Customer Support | Yes | 問い合わせ、ユーザー通報、グッズ通報、掲示板通報、グルーム通報、広告通報、異議申し立て、削除申出、送信防止措置希望、証跡URL、運営返信 |
| User Content | Other User Content | Yes | プロフィール文、推し情報、在庫、wish、投稿、掲示板、評価コメント、通報補足、異議申し立て本文、削除申出本文、退会申請の任意メモ、自由記述 |
| Location | Precise Location | Conditional | 現在地共有、位置情報メッセージ、待ち合わせ候補、現地交換モード、近くのグルーム/スポット掲示板、グルーム/掲示板の作成座標、閲覧者座標、掲示板作成/返信範囲判定、地図表示又は逆ジオコーディングで精密座標を保存/送信する場合 |
| Location | Coarse Location | Yes | 都道府県、活動エリア、丸めた位置又はスポット表示 |
| Identifiers | User ID | Yes | Supabase user id、プロフィールID、ユーザー名、Keychain保存session、認証callback、deep link又は通知 `linkPath` に含まれるID |
| Identifiers | Device ID | Conditional | APNs token、広告SDK由来の端末/広告ID等を保存又は送信する場合 |
| Purchases | Purchase History | Conditional | IAP/有料機能、購入ボタン、復元ボタン、価格、購入/復元状態、メグルムプラス権限状態、手動有料権限上書きによる最終権限状態を出す場合 |
| Search History | Search History | Conditional | 検索語、検索条件、検索結果件数、`normalized_term`、`result_count`、検索時刻又は人気検索集計をサーバー保存する場合。現行DB/RPC基盤はあるがSwift呼び出しは未確認 |
| Usage Data | Product Interaction | Conditional | 画面操作/行動分析、安全操作ログ、評価投稿、通報/ブロック/非表示操作、検索候補、候補表示、条件一致ラベル、表示順、Plus優先表示、通知ログ又は広告SDKの表示/クリック等を保存・送信する場合 |
| Usage Data | Advertising Data | Conditional | AdMob広告を有効にする場合。広告通報時の広告枠/表示日時/広告識別子も確認 |
| Diagnostics | Crash Data | Conditional | クラッシュ収集又は広告SDK由来の診断収集を入れる場合 |
| Diagnostics | Performance Data | Conditional | パフォーマンス計測又は広告SDK由来の性能データ収集を入れる場合 |
| Other Data | Other Data Types | Conditional | 外部AI入力/出力ログ、web search利用結果、安全確認ログ、認証callbackのerror/provider、Keychain保存/削除/refresh結果、Edge Function error detail、外部API response text、deep link path/query、通知 `linkPath`、管理者監査metadataなど、他カテゴリで表しにくい場合 |

初回で隠す/使わないなら選ばない候補:
- Purchases: 有料機能を完全に隠す場合
- Payment Info: 支払い設定、銀行振込、口座番号入力、金額指定取引、成立後支払い情報スナップショット表示へ到達できない場合
- Other Data Types / Photos or Videos / User ContentのAI関連回答: 外部AIを完全に隠し、画像又は画像URLを外部AIへ送らない場合
- Sensitive Info: 顔検出、顔特徴量、画像特徴量、メンバー候補付け、補正履歴保存へ到達できず、`member_face_profiles` のembedding/source image URLもユーザー機能から読ませず、顔特徴量等を収集・保存・照合しない場合
- Phone Number / Physical Address: 郵送交換、住所登録、郵便番号検索、合意後の郵送先表示へ到達できない場合
- Advertising Data / Product Interaction / Diagnostics / Performance Data: AdMob又は分析・診断SDKを無効にし、実ビルドで送信しない場合
- Search History / Usage Data / Diagnostics: 実装・SDKで保存しない場合。ただし候補表示、検索候補、表示順、Product Personalization、Plus優先表示、検索ログ又は人気検索を有効にする場合は再度選択候補へ戻す

---

## 4. Data Type別の回答

### 4.1 Contact Info / Name

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support |
| Examples | 表示名、問い合わせ時の氏名 |

### 4.2 Contact Info / Email Address

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Account Management, Customer Support |
| Examples | 登録メール、問い合わせメール |

### 4.2.5 Other Data / 生年月日・年齢

App Store Connectに生年月日又は年齢専用のData Typeが明確に用意されていない場合、`Other Data Types` 又はAppleの最新UIで最も近いカテゴリとして開示する。

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Safety, Product Personalization |
| Examples | 生年月日、算出年齢又は年代、プロフィール/ホーム/検索/めぐりでの年齢表示、安全確認又は利用制限判断 |

No-Go: 実装上は自己申告の生年月日であり、公的年齢確認、身分証確認、保護者同意確認又は本人確認が完了したと説明しない。

### 4.3 Contact Info / Physical Address

郵送交換、住所登録又は合意後の郵送先表示を出す場合は選択する。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety |
| Examples | 郵便番号、都道府県、市区町村、番地・建物名、補足住所、郵送先スナップショット |

提出前に、住所登録、郵便番号検索、郵送交換、取引成立後の郵送先表示の導線を実機で確認する。

### 4.4 Contact Info / Phone Number

郵送交換、住所登録又は合意後の郵送先表示を出す場合は選択する。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety |
| Examples | 郵送先電話番号、配送トラブル時の補助連絡先 |

提出前に、電話番号入力が必須又は任意で表示される範囲を確認する。

### 4.5 User Content / Photos or Videos

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety |
| Examples | グッズ写真、証跡写真、取引チャット写真、服装写真、プロフィール画像、投稿画像、スポット掲示板画像、共有用生成画像、元画像データ、再圧縮画像、EXIF、撮影日時、GPS位置情報、端末情報その他画像メタデータ |

写真ライブラリから読み込んだ元データをそのまま保存する経路がある場合、画像ファイル内のGPS位置情報や端末情報が残る可能性がある。再エンコードで削除される経路と残る経路を実ビルドで確認し、Location / Device Info回答への影響を判断する。

`PhotosPickerItem.loadTransferable(type: Data.self)` から読み込んだ写真は、対応形式かつサイズ上限内で元データのまま保存され得る。`NativeCameraCaptureView` はJPEG再生成経路を持つが、全ての端末、OS、画像処理、外部共有先で画像メタデータ削除を保証できるものとして回答しない。

共有シートで生成画像又は共有文を外部アプリへ渡す場合、共有物自体はUser Content / Photos or Videosの範囲に含める。共有後の保存、公開範囲、再共有、削除、広告利用、アクセス解析、メタデータ利用は共有先サービスの取扱いであり、Megrumが制御できるように説明しない。

取引チャット写真、証跡写真、服装写真はprivate bucketと署名URLで表示される経路があるが、現行コードでは長期署名URL、端末キャッシュ、相手会員による保存、通報/証跡コピー、バックアップにより、削除又は非表示後も一定期間残る可能性がある。PrivacyとFAQでは30日後の自動削除又は完全削除を保証しない。

### 4.6 User Content / Emails or Text Messages

Appleは、SMSではないアプリ内のユーザー間プライベートメッセージもこのデータタイプへ含める説明をしている。Megrumの取引チャット、めぐりメッセージ等が見える場合は選ぶ。

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety |
| Examples | 取引チャット、めぐりメッセージ、通報対象メッセージ |

### 4.7 User Content / Customer Support

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | Customer Support, Safety, App Functionality |
| Examples | 問い合わせ、ユーザー通報、グッズ通報、グルーム通報、掲示板通報、広告通報、異議申し立て、削除申出、送信防止措置希望、証跡URL、対応status、運営返信内容 |

### 4.8 User Content / Other User Content

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety, Product Personalization |
| Examples | プロフィール文、推し情報、在庫、wish、グルーム、掲示板、評価コメント、通報補足、異議申し立て本文、削除申出本文、退会申請の任意メモ、自由記述 |

Product Personalizationは、推し、位置、wish等を使って候補表示・おすすめ表示を行う場合だけ選ぶ。単なる保存/表示だけならApp Functionality中心にする。

性別、活動エリア、年齢、評価、完了取引数、支払い方法要約が公開プロフィール、ホーム候補、交換条件等に表示される場合は、Other Data / Other Data Types、Location / Coarse Location、User Content / Other User Content のどこで回答するかを最終UIで確認する。評価コメントは公開プロフィールや取引チャット内カードに表示され得るため、単なる内部Customer Support情報としてだけ扱わない。いずれの場合も、本人確認済み、安全確認済み、法的性別確認済み、支払能力確認済みとは説明しない。

### 4.9 Location / Precise Location

現在地座標、作成座標、閲覧者座標、待ち合わせ候補座標、現地交換モードの活動座標を保存又は送信する場合。現行Swift Nativeの近くのグルーム/スポット掲示板、掲示板作成/返信範囲判定、現在地共有、待ち合わせ候補、現地交換モード、地図表示、逆ジオコーディングは精密座標を扱い得るため、該当導線が見えるビルドではPrecise Location寄りで回答する。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Safety |
| Examples | 現在地共有、位置情報メッセージ、待ち合わせ候補、現地交換モードの最終/設定座標、活動ウィンドウ中心座標、近くのグルーム/スポット掲示板、グルーム/掲示板の作成座標、閲覧者座標、掲示板作成/返信範囲判定、1km/3km等の距離判定、地図表示、逆ジオコーディング、場所名 |

端末内だけで処理し、サーバーへ送らない場合はApp Privacy上の「収集」には該当しない可能性がある。ただし、現行読み取りでは取引チャットの現在地共有、待ち合わせ候補、現地交換モード、近くのグルーム/掲示板、掲示板作成/返信範囲判定で緯度経度をサーバーへ送る経路があるため、これらが見える場合は選ぶ。保持期間は「30日を目安に削除又は非表示化する運用目標」であり、現行コード上30日後の自動削除又は非表示ジョブは未確認であることをPrivacy、FAQ、Review Notesと一致させる。MapKit/CoreLocation/CLGeocoder等のOS・地図関連処理、地図・距離・場所名の非保証、1km/3kmが匿名化、安全確認、本人確認、所在確認又は推測防止を保証しないことも公開説明と揃える。

### 4.10 Location / Coarse Location

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Product Personalization |
| Examples | 都道府県、スポット、活動エリア、丸めた位置 |

### 4.11 Identifiers / User ID

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Account Management, Customer Support, Safety |
| Examples | Supabase user id、プロフィールID、表示ID |

### 4.12 Identifiers / Device ID

APNs token、Google Mobile Ads SDK由来の端末ID又は広告ID等を保存又は送信する場合。過去又は別環境でExpo Pushを使う場合は、Expo push tokenも別途確認する。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality |
| Examples | APNs device token、過去又は別環境で使うExpo push token、広告SDK由来の端末ID又は広告ID |

IDFAを使う場合はATTとTracking回答を別途確認する。Info.plistに`NSUserTrackingUsageDescription`がない状態でIDFAを使う構成にしてはいけない。

プッシュ通知を出す場合、Device IDだけでなく、通知タイトル/本文/リンク先/未読バッジ/通知ID/soundがAPNsへ送信される。過去又は別環境でExpo Pushを使う場合も同等に確認する。現行Swift Nativeでは、取引チャット本文の短縮プレビュー、写真共有、服装写真共有、現在地共有、到着状況、証跡、評価、キャンセル要請等の概要が通知bodyに入り得る。グルーム、めぐりメッセージ、スポット掲示板系で本文を入れない場合でも、タイトルだけで相手、行動又は文脈が推測されるため、User Content / Other User Content、Usage Data / Product Interaction、Privacy Policy、FAQ、アプリ内コピー、ロック画面表示の説明を同時に照合する。

Push通知を許可しないと登録できない、又は主要機能を使えない設計にしない。正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文を通知本文に入れない。プロモーション又は直接マーケティング目的のPush通知を行う場合は、明示的同意とオプトアウト手段を用意する。

### 4.13 Purchases / Purchase History

有料機能を出す場合のみ。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support |
| Examples | StoreKit商品情報照会、価格取得、購入ボタン表示、復元ボタン表示、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、IAP購入状態、サブスクリプション状態、取引ID、Original Transaction ID、期限、販売地域、販売停止、返金/取消/期限切れ/請求失敗/猶予期間、購入復元、ブースト購入履歴、最終権限状態、手動有料権限上書きの有無 |

Apple IAPのカード番号等をMegrumが直接取得せず、購入状態・履歴だけを扱う場合、このPurchases欄で整理する。一方、会員間支払いのために銀行口座番号等を保存・表示する場合は、次のFinancial Info / Payment Infoも確認する。StoreKit購入導線が見える場合、商品情報照会、価格取得、購入開始、承認待ち、未完了、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止、サーバー同期、購入復元、返金/取消/期限切れ/請求失敗/猶予期間のイベント情報もPurchases又は関連するIdentifiers/Other Dataとして確認する。管理画面の手動有料権限上書きは、購入証明ではないが最終権限状態に影響し得るため、Purchases、Identifiers又はOther Dataのどこで回答するか実UIとApp Store Connectの最新UIで確認する。

### 4.14 Financial Info / Payment Info

支払い設定、銀行振込、口座番号入力、金額指定取引又は合意後の支払い情報表示を出す場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety |
| Examples | 銀行名、支店名、口座種別、口座番号、口座名義、支払い方法、支払いメモ、金額指定、成立後支払い情報スナップショット |

Apple IAPのカード番号はMegrumが直接取得しない。一方で、会員間支払いのために銀行口座番号等をアプリ側で保存・表示する場合は、このPayment Infoを選択候補へ上げる。

銀行振込、PayPay、現金交換その他外部の金融機関又は決済サービスへの対応可否を表示する場合でも、Megrumが送金、受領、返金、残高、本人確認、口座名義確認、支払能力確認、外部アカウント、外部ID、送金リンク又はQRコードの安全性を確認するものとして説明しない。現行コード上、PayPayはリンク登録なしの対応可否表示であり、外部サービス上の送金処理は当該外部サービス及び会員間の責任範囲として整理する。

### 4.15 Sensitive Info / Biometric Data

顔検出、顔特徴量、画像特徴量、メンバー候補付け又は補正履歴保存を出す場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Safety |
| Examples | 顔検出矩形、顔特徴量、画像特徴量、候補メンバー、候補スコア、補正履歴、学習データ追加可否、同意確認済みメンバー顔特徴量プロフィール、source image URL |

Megrumの顔候補付けはFace ID認証、本人確認、年齢確認、出入場管理ではない。ただし、実在人物の顔特徴量又は画像特徴量を生成・保存・照合する導線が実ビルドで到達可能なら、AppleのSensitive Info / biometric data相当として回答候補に上げる。オンデバイスの顔矩形検出だけでサーバー保存も外部送信もない場合でも、最終実装を確認してから選択可否を決める。`member_face_profiles` にembedding又はsource image URLがありauthenticated userが読める状態、又は補正履歴の学習データ追加が既定trueの状態で顔候補付けを出す場合は、回答、同意、任意性、削除/利用停止、アクセス制御をP0として確認する。

### 4.16 Search History / Search History

検索語又は保存検索をサーバー保存する場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Product Personalization |
| Examples | グッズ検索語、保存検索条件 |

端末内だけで検索し保存しない場合は選ばない。

### 4.17 Usage Data / Product Interaction

分析ログを保存する場合。AdMobを有効にする場合は、Google Mobile Ads SDKが広告表示、クリック、アプリ起動、動画再生等の接点情報を収集し得るため、この欄の要否を確認する。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | 原則Yes |
| Tracking? | No |
| Purposes | Analytics, App Functionality, Third-Party Advertising, Customer Support |
| Examples | 画面操作、機能利用、通知開封、投稿/検索利用状況、評価投稿、通報/ブロック/非表示操作、広告表示/クリック、広告通報時の表示画面 |

初回でAnalytics SDKや行動ログを入れないなら選ばない。

### 4.18 Usage Data / Advertising Data

AdMob等の第三者広告を有効にする場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | SDK設定による |
| Tracking? | IDFA/横断追跡の有無で判断 |
| Purposes | Third-Party Advertising, Analytics, Customer Support |
| Examples | 表示された広告、広告リクエスト、広告クリック、広告反応、広告通報時の広告枠、表示日時、広告識別子 |

広告SDKを最終ビルドに含めるだけでなく、SDK初期化又は広告リクエストが発生するかを実機で確認する。広告を無効化して提出する場合は、`MegrumAdsEnabled`、ad provider、ad unit id、SDK起動条件も確認する。現行チェックイン設定では `MEGRUM_ADS_ENABLED=YES` かつ `MEGRUM_ADMOB_TEST_ADS_ENABLED=YES` のため、検索native広告、やりとり一覧上部banner、preview viewer向けhome banner fallbackがGoogleデモunit idへ広告リクエストを送る可能性がある。広告を有効にする場合は、不適切又は年齢に合わない広告の通報導線、通報時に取得する広告枠/表示日時/スクリーンショット等の扱い、Google公式データ開示、テスト広告除去、ATT/Tracking回答を確認する。

### 4.18 Diagnostics / Crash Data

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | SDK設定による |
| Tracking? | No |
| Purposes | App Functionality, Analytics |
| Examples | クラッシュログ |

Appleのクラッシュ情報のみで開発者が追加収集しない場合、App Store Connect回答上どう扱うかは実際の取得方法で判断する。

### 4.19 Diagnostics / Performance Data

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | SDK設定による |
| Tracking? | No |
| Purposes | App Functionality, Analytics |
| Examples | 起動時間、エラー、パフォーマンス |

### 4.20 Other Data / Other Data Types

外部AI入力/出力ログ、ブロック関係、通報/モデレーションstatus、削除申出/送信防止措置の対応状態、運営対応ログ、認証callbackのerror/provider、deep link path/query、通知 `linkPath` など、他カテゴリで表しにくいデータを保存する場合。`suggest-goods-series` を出す場合は、画像、画像URL、グループ名、メンバー名、グッズ種別、既存候補、AI出力、web search利用、濫用監視ログ、削除可否を含めて確認する。画像そのものはUser Content / Photos or Videosでも回答候補に上げる。

認証callbackのfragmentにはaccess token、refresh token、expires情報、token type等が含まれ得る。これらは通常App PrivacyではContact Info / Identifiers / App Functionality寄りで整理するが、リンク開封ログ、callback失敗、provider、error、通知 `linkPath`、ID付きdeep link path/queryを保存又は外部サービスへ送る場合は、Usage Data / Other Data Typesとしても最終確認する。ユーザー向け説明では、認証リンク、callback URL、認証コード、スクリーンショットを共有しないことを明記する。

端末内Keychainに保存されるAuthSessionには、access token、refresh token、expires、token type、user id、emailが含まれ得る。通常はApp Functionality目的のContact Info / Identifiersとして整理するが、保存失敗、削除失敗、refresh失敗、logout失敗、Keychain status、端末紛失対応ログを保存又は送信する場合はUsage Data / Other Data Types / Diagnosticsへの該当性も最終確認する。token実値はApp Review証跡や問い合わせテンプレートへ残さない。

Web管理画面の管理者ロール、MFA要求、操作理由、監査ログ、変更前後の状態、IPアドレス、User-Agent、手動有料権限上書き、plan override、付与又は停止理由、運営通知、Webhook又は決済同期ログはプライバシーポリシーと提出前セキュリティ監査の対象にする。ただし、App Store Connect App Privacyでは、最終iOSビルドからユーザーに紐づけて収集されるデータ型と目的を中心に回答し、Web運用だけの内部監査ログをiOSアプリの主要機能由来データと混同しない。

外部画像URLを表示する場合、Megrumが保存する画像URLやサーバーログはUser Content / Other Data候補、画像ホスト側に送られるIP、端末/アプリ通信情報、アクセス時刻等は第三者サービス側の取扱いとして、プライバシーポリシー、通信先監査、App Privacy回答の要否を照合する。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | 入力内容による。原則Yes寄せ |
| Tracking? | No |
| Purposes | App Functionality, Safety, Customer Support |
| Examples | AI入力、AI出力、AI安全確認ログ、グッズシリーズ候補生成ログ、web search利用結果、外部AIエラー、認証callback error/provider、deep link path/query、通知linkPath、ブロック関係、通報status、削除申出/送信防止措置の対応状態、モデレーション優先度、運営対応ログ、手動有料権限上書き、plan override、付与又は停止理由 |

初回で外部AIを完全に隠し、画像又は画像URLを外部AIへ送らないならAI関連のOther Dataは選ばない。ただし、外部AI導線が見える場合は、User Content / Photos or Videos / Other Dataの各カテゴリで回答漏れがないか確認する。

---

## 5. 選ばない候補

初回提出の現行前提では、次は原則選ばない。

| Data Type | 理由 |
|---|---|
| Payment Info | 支払い設定、銀行振込、口座番号入力、金額指定取引、成立後支払い情報スナップショット表示を完全に隠し、Apple IAPのカード番号等もMegrumが取得しない場合のみ選ばない |
| Credit Info | 取得しない |
| Health / Fitness | 取得しない |
| Contacts | 端末連絡先を取得しない |
| Browsing History | オープンWeb閲覧履歴を取得しない |
| Advertising Data | AdMobを無効化し、SDK初期化・広告リクエスト・広告表示/クリックデータ送信が発生しない場合のみ選ばない |
| Sensitive Info | 顔検出、顔特徴量、画像特徴量、メンバー候補付け、補正履歴保存を完全に隠し、実ビルドで収集・保存・照合せず、`member_face_profiles` のembedding/source image URLもユーザー機能から読ませない場合のみ選ばない |
| Audio Data | 録音機能なし前提 |
| Environment Scanning / Hands / Head | 空間・身体トラッキングなし前提 |

---

## 6. App Store Connect入力順

1. App Privacyを開く。
2. Privacy Policy URLへ `https://megrum.jp/legal/privacy` を入れる。
3. User Privacy Choices URLへ `https://megrum.jp/support/privacy-request` を入れるか判断する。
4. Data CollectionでYesを選ぶ。
5. §3のData Typesを、実ビルドで見えている機能に合わせて選ぶ。
6. 各Data Typeで、Linked to user、Tracking、Purposesを§4に沿って回答する。
7. Product Page Previewを確認する。
8. `notes/36` に回答控えを保存する。

---

## 7. No-Go

次に該当する場合は、App Privacy回答を確定しない。

- 実ビルドに含まれるSDKが未確認。
- Google Mobile Ads SDK / AdMobが有効なのにAdvertising Data、Device ID、Diagnostics、ATT、SKAdNetwork、Google公式データ開示を確認していない。
- `NSPrivacyTracking=false` 又は `NSUserTrackingUsageDescription` なしの状態で、IDFA、Apple定義のTracking、Publisher First-Party ID、パーソナライズ広告、広告メディエーション又は第三者広告目的の横断利用を有効にしている。
- `MEGRUM_ADMOB_TEST_ADS_ENABLED=YES`、Googleデモunit id又は審査用でないtest ads設定のまま一般公開しようとしている。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、不適切又は年齢に合わない広告の通報導線、通報時に取得する情報、サポート説明、Google公式データ開示、ATT/Tracking回答、test ads除去、同意管理要否を確認していない。
- 外部AIが見えるのにOpenAI等の送信先、画像又は画像URL、web search利用、送信情報、学習利用、濫用監視ログ、保持、削除可否が未確定。
- 外部画像URL又はAI/検索候補画像が見えるのに、外部画像ホスト/CDNへの通信、画像URL保存、第三者ポリシー、App Privacy影響を確認していない。
- 写真のEXIF、GPS位置情報、撮影日時、端末情報などの画像メタデータが残る経路を確認していない。
- カメラ/写真ライブラリの権限文言が実用途より狭い。又は写真ライブラリ由来の元画像メタデータ、共有用生成画像、外部共有後の保存/再共有/削除非管理をApp Privacy、Privacy、FAQ、Review Notesで説明していない。
- 顔候補付け、顔特徴量又は画像特徴量の保存・照合が見えるのにSensitive Info / biometric dataを回答候補に上げていない。`member_face_profiles` のembedding/source image URLがauthenticated userへ読める、又は補正履歴の学習データ追加が既定trueなのに、回答、同意、任意性、削除/利用停止、アクセス制御が未確認の場合もNo-Go。
- 性別、活動エリア、年齢、評価、支払い方法要約が見えるのに、公開範囲、自己申告性、非保証の説明をプライバシーポリシー/FAQ/Review Notesと一致させていない。
- 評価コメントがプロフィール、取引チャット又は通知に表示されるのに、Other User Content / Customer Support / Product Interactionの影響を確認していない。
- 通報、異議申し立て、削除申出、送信防止措置、ブロック、モデレーション状態があるのに、Customer Support / Other User Content / Other Data Types / Product Interactionの影響を確認していない。
- 管理画面のservice role、管理者権限、MFA、監査ログ、IP/User-Agent、before/after stateをPrivacy本文とセキュリティ監査に反映せず、又はiOS App Privacy回答とWeb運用の範囲を混同している。
- 通報者情報を絶対非開示と保証している、又は通報/ブロックを緊急通報、法的判断、本人確認、安全確認、信用保証の代替として説明している。
- 有料機能、購入ボタン、復元ボタン、価格、購入/復元状態又はメグルムプラス権限状態が見えるのにPurchasesを回答していない。
- StoreKit商品情報照会、価格取得、購入開始、承認待ち、キャンセル、商品未取得、購入失敗、復元失敗、サーバー同期失敗、販売地域、販売停止を、Purchases、Identifiers又はOther Dataのどこで回答するか未整理のまま有料導線を出している。
- 手動有料権限上書きが最終権限状態へ影響するのに、Purchases、Identifiers又はOther Dataのどこで回答するか未整理のまま有料導線を出している。
- 住所を扱う導線があるのにPhysical Addressを回答していない。
- 口座番号、銀行振込又は支払い情報表示を扱う導線があるのにPayment Infoを回答していない。
- PayPay、銀行振込又は現金交換の表示を、Megrumによる送金、決済代行、収納代行、本人確認、口座名義確認、支払能力確認、残高確認、返金又はエスクローの保証のように説明している。
- 取引チャットがあるのにEmails or Text Messagesを回答していない。
- 位置情報、作成位置、閲覧者位置又は現地交換モードの活動座標をサーバー送信するのにLocationを回答していない。
- Analytics/Crash SDKがあるのにUsage Data/Diagnosticsの要否を確認していない。
- TrackingをNoにする根拠が崩れている。

---

## 8. 参照

- App Privacyインベントリ: `notes/27_app_privacy_data_inventory.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple App Privacy Reference: https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy
- Apple Manage App Privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Apple Privacy Manifest Files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Google Mobile Ads SDK data disclosure: https://developers.google.com/admob/ios/privacy/data-disclosure
- Google Mobile Ads iOS privacy strategies: https://developers.google.com/admob/ios/privacy/strategies
