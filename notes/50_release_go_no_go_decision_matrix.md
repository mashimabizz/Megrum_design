# 50. App Store初回提出 Go / No-Go 判定表

最終更新: 2026-06-29

ステータス: Draft v2.2（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / legacy Expo削除済み・APNs主線のPush判定前提 / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 古物営業・チケット不正転売 / 精密位置・MapKit/CoreLocation・逆ジオコーディング / EU DSA・配信地域 / StoreKit・IAP販売可否・復元失敗 / AdMob実設定・ATT・テスト広告No-Go / Storage公開範囲・署名URL / 管理者権限・監査ログ / 公開Web / アプリ内法務表示の実装同期監査を反映・完成ビルド到着前）

## 目的

完成候補ビルドが来た後、App Store初回提出へ進むか止めるかを、機能、法務、プライバシー、運用、証跡の観点で判定する。

この文書は判断表であり、コード、DB、ビルド設定、外部サービス設定は変更しない。

## 1. 判定ルール

| 判定 | 意味 | 次の行動 |
|---|---|---|
| Go | 初回提出に進める | App Store Connectで提出する |
| Conditional Go | 露出しない機能又はメタデータ削除で回避できる | 隠す、説明を削る、証跡を残して提出 |
| No-Go | 提出すると審査又は公開後に重大リスク | 修正、非表示、公開URL修正、法務確認後に再判定 |

基本方針:
- 初回の勝ち条件は「一般公開完了」ではなく「App Store審査への初回提出完了」。
- 見えている機能は、実機で動く、説明できる、規約/プライバシー/App Privacyと一致する必要がある。
- 見せない機能は、App Store説明文、スクショ、Review Notes、公開ページからも外す。
- P0は原則Passが必要。P1は提出後対応でもよいものと、提出前に担当/手順だけ決めればよいものに分ける。

## 2. Gate一覧

| Gate | 領域 | Go条件 | No-Go条件 | 参照 |
|---|---|---|---|---|
| G0 | スコープ | 初回提出範囲が現地交換MVPで固定 | 未完成スコープが画面/説明/スクショに残る | `notes/39`, `notes/42` |
| G1 | Auth | 新規登録、ログイン、ログアウト、セッション維持が通る | デモアカウント又は審査員が入れない | `notes/35`, `notes/42` |
| G2 | Core Flow | 在庫、wish、打診、ネゴ、取引チャット、評価までP0が通る | コア交換フローが途中で止まる | `notes/42` |
| G3 | Safety | 通報、ブロック、問い合わせ、評価コメント注意、モデレーション説明、削除申出/送信防止措置の受付方針、緊急時外部連絡案内がある。画面内通報がない対象はsupport@フォールバックを説明できる | UGCや評価が見えるのに安全導線、虚偽通報対策、削除申出対応、緊急時案内が説明できない。掲示板等でDB通報関数だけがありSwift画面導線又はsupport@フォールバックが説明できない。又は7日以内削除、常時監視、申出どおり削除、発信者情報開示を未確認のまま保証している | `notes/26`, `notes/34` |
| G4 | Account | アカウント削除、削除申請中状態、保持対象、個人情報請求を説明できる | アカウント作成があるのに削除入口がない。30日後完了、復旧、外部連携解除を未確認のまま保証している | `notes/45` |
| G5 | Legal URL | Terms、Privacy、Support、CommerceがHTTPSで開き、App Store入力値、公開Web route、アプリ内同意リンク、Supportリンクが同じ最新版本文へ到達 | URLが404、ログイン必須、実ビルドと矛盾。又は公開予定URLと現行Web実装/アプリ内リンクが分裂し、古い短縮本文や30日自動削除保証に読めるPrivacyを正式本文として指している | `notes/25`, `notes/37`, `notes/47`, `notes/63` |
| G6 | App Privacy | App Privacy、Privacy Manifest、実通信/SDKが一致 | 収集データ、生年月日/年齢、性別、活動エリア、公開プロフィール、評価コメント、通報/ブロック/モデレーション状態、精密位置/MapKit/CoreLocation/逆ジオコーディング、通知、外部SDK、外部画像URL、写真メタデータ、顔候補付け/Sensitive Info回答に漏れ | `notes/27`, `notes/43`, `notes/44`, `notes/48` |
| G7 | App Store Metadata | 説明文、スクショ、Review Notes、質問票が実ビルドと一致 | 未完成機能、年齢確認済み、法的性別確認済み、安全確認済み、通報/評価/削除申出の削除保証や緊急通報代替等の誤説明、誤ったデータ取扱いを説明している | `notes/31`, `notes/40`, `notes/46` |
| G8 | IAP | 有料機能が見えるならIAP/価格/復元/特商法/Privacy/App Privacy/返金・取消・期限切れ同期が一致し、手動有料権限上書きの理由、期限、対象確認、監査ログ、非保証説明がある | 有料導線が見えるのにIAP未整備、App Store価格とアプリ内固定文言が不一致、アプリ内の特商法要約だけを正式公開ページ扱い、購入開始/承認待ち/キャンセル/復元失敗/サーバー同期失敗のPrivacy/App Privacy説明不足、サーバー検証や返金/取消/期限切れ/請求失敗同期が未確認、手動上書きが購入完了/返金確定/無償継続保証に見える | `notes/33`, `notes/63` |
| G9 | AI / 顔候補付け / 外部画像 | 外部AI、AI/検索候補画像、外部画像URL又は顔候補付けが見えるなら説明、同意/任意性、送信情報、OpenAI等の送信先、web search利用、外部ホスト通信、Privacy回答が一致 | 「画像からシリーズ名称の候補を出す」等の導線が見えるのに、OpenAI/外部AI、画像又は画像URL送信、web search利用、学習利用、保持、濫用監視ログ、削除可否、第三者/未成年/権利未処理画像禁止の説明がない。外部画像URL通信や権利確認責任を説明していない。顔候補付けが本人確認/Face IDに見える、Sensitive Info回答がない、`member_face_profiles` のembedding/source image URL読み取り範囲や`shouldAddTrainingData`既定trueを説明できない | `notes/24`, `notes/27`, `notes/48`, `notes/56` |
| G10 | Evidence | Build、URL、App Privacy、スクショ、Review Notesの控えがある | 何を確認したか追えない | `notes/36` |
| G11 | Incident | 事故疑いがない。ある場合は初動記録と法務確認済み | 事故疑いが未処理 | `notes/49` |
| G12 | Security | RLS、Storage公開範囲、signed URL期限、secret、APNs、管理者権限、service role、監査ログ、MFA、最小権限、運営通知及び有料権限手動上書きの提出前監査がPass | 他人データ表示、参加者限定画像のpublic露出、`meguri-board-media` 等の閲覧範囲矛盾、長期signed URLの再共有リスク未説明、secret露出、任意通知送信、管理者権限濫用、手動有料権限の理由なし付与/停止、監査ログ未保存、MFA未確認、service roleのclient露出の疑い | `notes/54` |
| G13 | Legal Review | 法務レビュー回答が反映済み、又は未反映論点が初回提出に影響しない | 弁護士回答の未反映/要再確認が残っている | `notes/58` |
| G14 | Scope Exposure | 出す/隠す機能が画面、文面、FAQ、App Privacy、スクショで一致 | 隠すはずの機能が画面やメタデータに残る | `notes/59` |
| G15 | RC Handoff | Version、Build、commit SHA、検証結果、出す/隠す機能が開発側から共有済み | 提出候補ビルドの由来やスコープが追えない | `notes/65` |
| G16 | Legal Publication | 弁護士回答が公開文面、Web公開実装、アプリ内法務リンク、App Store文面へ横断反映済み | Terms、Privacy、Support、FAQ、Review Notes、App Privacy、公開Web実装、アプリ内同意リンクのどこかに古い前提又は別URLが残る | `notes/66` |
| G17 | Support Inbox | support@の受信、App Review連絡、P0分類、削除/個人情報請求、事故疑いの担当が決まっている | 審査員連絡、削除請求、通報、事故疑いを受けられない | `notes/67` |
| G18 | Territory / DSA | 初回Japan-only等の配信地域、EU DSA trader status、App Store商品ページ表示連絡先、IAP Availabilityが確定 | 配信地域、EU DSA trader status、公開連絡先、IAP提供地域が未確認。Japan-only方針なのにEU又はAll Countries or Regionsを含む | `notes/68` |
| G19 | Review Response | App Review指摘時の本文保存、分類、返信、再提出、取り下げ、appeal判断の担当と手順がある | リジェクト時に新build要否や返信方針を判断できない | `notes/69` |
| G20 | Product Page Assets | App icon、スクショ、App Preview、poster frame、Product Page Previewが完成build、メタデータ、初回スコープと一致 | 商品ページ素材に古いUI、実データ、権利物、未完成機能、poster frame未確認が残る | `notes/70` |
| G21 | ASC Final Input | App Store Connect実入力値が提出docs、完成build、公開URL、App Privacy、Review Notes、同時提出itemと一致 | 実入力値に未露出機能、誤build、URL不一致、Privacy回答漏れ、IAP同時提出漏れが残る | `notes/71` |
| G22 | Release Control | 承認後のRelease option、PDR gate、`Release This Version` 操作、公開初日監視が整理済み | 手動公開設定や公開直前gateが未確認で、意図しない自動公開又は公開タイミング誤りが起きうる | `notes/72` |
| G23 | Availability Stop | 公開後のP0事故疑いに対するAvailability変更、Remove App From Sale、new build判断が整理済み | 公開継続が危険な時に停止/復帰/サポート告知の判断ができない | `notes/73` |
| G24 | Ratings / Reviews | 公開後のApp Store評価・レビュー確認、公開返信、concern report、overview rating reset判断が整理済み。アプリ内評価コメントとの混同を避ける | 公開返信で個人情報、未確認事実、補償、内部情報を書いてしまう | `notes/74` |
| G25 | Signing / Capabilities | Bundle ID、App ID、Capabilities、entitlements、provisioning profile、certificate、App Store Connect app recordが一致 | Build upload失敗、Invalid Binary、APNs不達、Apple login不具合が起きうる | `notes/75` |
| G26 | Advertising | 広告が見える又はAdMob SDKが初期化/広告リクエストするなら、Google公式データ開示、App Privacy、Privacy Manifest、ATT/Tracking回答、SKAdNetworkItems、テスト広告除去、不適切又は年齢に合わない広告の通報導線、サポート説明が一致 | `MEGRUM_ADS_ENABLED=YES` のまま広告SDK初期化や広告リクエストが発生するのにApp Privacy/ATT/Google開示を説明できない。`MEGRUM_ADMOB_TEST_ADS_ENABLED=YES` やGoogleデモunit idのまま一般公開する。IDFA/Tracking/PFPI/パーソナライズ/メディエーション/同意管理が未整備。広告が見えるのに通報導線又は広告SDK回答が説明できない | `notes/25`, `notes/27`, `notes/36`, `notes/43`, `notes/44`, `notes/48`, `notes/53`, `notes/56` |
| G27 | Home/Search Personalization | ホーム候補、検索結果、マッチ/条件一致ラベル、検索候補、人気検索、表示順、Plus優先表示、広告挿入、Product Personalizationの根拠データと非保証説明がPrivacy、FAQ、Review Notes、App Privacyと一致 | 候補表示が本人確認済み、安全確認済み、信用保証、真贋確認済み、取引成立保証又は運営推薦に見える。検索ログ、`normalized_term`、`result_count`、人気検索、Plus優先表示、広告挿入をApp Privacy/Privacyに反映しない | `notes/24`, `notes/27`, `notes/43`, `notes/55`, `notes/56` |
| G28 | Camera / Photo Library / Share Sheet | カメラ、写真ライブラリ、写真アップロード、共有シートを出すなら、Info.plist権限文言、画像メタデータ、Photos or Videos / Location / Device Info回答、共有用画像/テキスト、外部共有後の非管理説明が一致 | 権限文言が実用途より狭い。写真ライブラリ元データのEXIF/GPS/撮影日時/端末情報が残る経路を未確認。共有後もMegrumが公開範囲、削除、保存、再共有、広告利用、アクセス解析、画像メタデータ利用を管理できるように見える | `notes/24`, `notes/27`, `notes/36`, `notes/43`, `notes/48`, `notes/55`, `notes/56` |
| G29 | Auth Links / URL Scheme / Deep Links | メール認証、パスワードリセット、Google OAuth、native callback、Web中継Route、Supabase Redirect URLs、Google OAuth設定、通知 `linkPath`、FAQ、Review Notesが一致し、認証リンク/認証コード/認証callbackを共有しない説明がある | `MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Supabase Redirect URLs、Google OAuth設定、Web中継Route、App Store提出メモが不一致。custom URL schemeをUniversal Links同等に安全保証している。認証callbackのaccess token/refresh token、通知linkPath、ID付きdeep linkを公開・転送してよいように見える | `notes/24`, `notes/27`, `notes/36`, `notes/43`, `notes/48`, `notes/54`, `notes/75` |
| G30 | Keychain Session / Refresh Token | AuthSessionのKeychain保存、access token/refresh token、refresh更新、logout時clear、`kSecAttrAccessible`方針、ThisDeviceOnly要否、端末紛失/バックアップ/復元/他端末session説明がPrivacy、FAQ、Security checklistと一致 | tokenをログ、スクショ、公開証跡、問い合わせテンプレートへ出す。Keychain accessibility/backups/復元/他端末session未確認のまま、ログアウト又は退会ですべてのsession/tokenが即時完全削除されると説明する | `notes/17`, `notes/27`, `notes/48`, `notes/52`, `notes/54`, `notes/55`, `notes/75` |
| G31 | Member Payment / Financial Boundary | 支払い方法、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定、成立後支払い情報スナップショットの表示範囲、保持、App Privacy、FAQ、Review Notes、規約/Privacyが一致し、Megrumが資金受領、保管、送金、収納代行、回収、返金、チャージバック、エスクロー、本人確認、口座名義確認、支払能力確認をしない説明がある | 口座情報又は支払いスナップショットが見えるのにPayment Info回答や保持説明がない。Megrumが決済代行、資金移動、収納代行、回収、返金、チャージバック、エスクロー、口座名義確認、支払能力確認、外部ID/送金リンク/QRの真正性確認をするように見える。又はログ/通知/サポート証跡に銀行口座、送金リンク、送金用QR、外部サービスIDを不用意に含める | `notes/legal/01`, `notes/legal/02`, `notes/25`, `notes/27`, `notes/43`, `notes/48`, `notes/52`, `notes/54`, `notes/55`, `notes/56` |
| G32 | Location Scope / Creation Location | 現在地共有、待ち合わせ候補、グルーム/掲示板の作成座標、閲覧者座標、半径、距離、公開範囲、1km/3km非保証、生活圏推測リスク、保持/削除例外がTerms、Privacy、FAQ、App Privacy、Review Notes、アプリ内コピー、Security checklistと一致 | 近く、1km圏内、3km圏内、同じスポット、同じ都道府県が匿名化、安全確認、本人確認、所在確認、ストーカー防止又は推測防止に見える。作成位置、閲覧者位置又は待ち合わせ候補座標を扱うのにPrecise Location、保持例外、相手保存/通知/スクリーンショットリスクを説明していない | `notes/legal/01`, `notes/legal/02`, `notes/25`, `notes/27`, `notes/43`, `notes/52`, `notes/54`, `notes/55`, `notes/56`, `notes/59`, `notes/63` |

## 3. P0トラッカー対応

| 領域 | P0 ID | 判定に使う文書 | Go条件 |
|---|---|---|---|
| Auth | RL-001, RL-002 | `notes/42` | 登録、ログイン、ログアウト、再起動後復帰がPass |
| 在庫/wish | RL-003, RL-004, RL-005, RL-022 | `notes/42` | 作成、編集、削除、推し追加復帰がPass |
| 個別条件/マッチ | RL-006, RL-007 | `notes/42` | 表示、保存、候補遷移がPass |
| 打診/ネゴ/取引 | RL-008, RL-009, RL-010, RL-011, RL-012 | `notes/42` | 2アカウントで主要フローがPass |
| 法務/URL | RL-013, RL-036, RL-045, RL-056 | `notes/25`, `notes/37`, `notes/47`, `notes/58` | 公開URL、サポートメール、法務回答反映が確認済み |
| App Store提出 | RL-014, RL-015, RL-027, RL-034, RL-038, RL-040 | `notes/31`, `notes/32`, `notes/35`, `notes/40`, `notes/42` | ビルド、デモアカウント、転記文面、P0台本が揃う |
| 公開制御 | RL-049, RL-070 | `notes/51`, `notes/72` | 承認後の手動公開、PDR gate、公開初日監視が整理済み |
| 公開停止 | RL-071 | `notes/73` | 公開後のAvailability変更、Remove App From Sale、new build判断が整理済み |
| 評価・レビュー | RL-072 | `notes/74` | 公開後のレビュー分類、公開返信、concern report、rating reset判断が整理済み |
| 署名・Capabilities | RL-073 | `notes/75` | Bundle ID、App ID、Capabilities、entitlements、profile/certificate、app recordが一致 |
| スコープ | RL-019, RL-020, RL-021, RL-057 | `notes/39`, `notes/42`, `notes/59` | 現地交換MVP、露出範囲、App Privacy回答が一致 |
| 3D/めぐり | RL-017 | `notes/22_release_triage_tracker.csv` | 未完成3Dが露出しない |
| UGC安全 | RL-030 | `notes/26`, `notes/42` | 通報/ブロック/問い合わせが説明できる |
| アカウント | RL-031, RL-043 | `notes/45` | 削除入口、保持対象、請求導線が説明できる |
| IAP | RL-032 | `notes/33` | 出すならIAP完備。未完なら隠す |
| AI / 顔候補付け | RL-028 | `notes/24`, `notes/27`, `notes/48`, `notes/56` | 外部AI又は顔候補付けを出すなら説明/同意又は任意性/回答完備。未完なら隠す |
| Privacy/Security | RL-029, RL-041, RL-042, RL-046, RL-052 | `notes/27`, `notes/43`, `notes/44`, `notes/48`, `notes/54` | 実ビルド、回答、RLS/Storage/secret監査が一致 |
| 質問票 | RL-044 | `notes/46` | Age Rating、Content Rights、Export Compliance回答済み |

## 4. Conditional Goの扱い

次は「機能を完全に隠し、説明文・スクショ・Review Notesから削れば」提出可能にできる。

| 条件付き項目 | 隠す場合の確認 | 出す場合の必須 |
|---|---|---|
| 有料機能 | メグルムプラス、Premium、めぐりPlus、ブーストの購入ボタン、復元ボタン、価格、特典説明、状態表示が画面に出ない。チェックイン既定は `MEGRUM_PLUS_IAP_ENABLED=NO` で購入/復元/商品照会を停止 | IAP商品、価格、復元、正式な公開特商法ページ、Purchases回答、購入開始/承認待ち/キャンセル/復元失敗/サーバー同期失敗のPrivacy反映、返金/取消/期限切れ同期、手動上書きの理由/期限/監査ログ/非保証説明 |
| 外部AI | AI送信画面、説明、ボタンが出ない | 送信情報、送信先、OpenAI等外部AI名、画像又は画像URL、web search利用、学習利用、濫用監視ログ、保持、削除可否、同意又は任意性、Privacy回答、規約反映、第三者/未成年/権利未処理画像禁止 |
| 外部画像URL | 外部画像URL、AI/検索候補画像、外部画像プレビューが出ない | 外部ホスト通信、第三者ポリシー、Content Rights、権利確認責任、Privacy回答確認 |
| 写真メタデータ / 共有シート | 写真アップロード導線と共有シート導線が出ない | Info.plist権限文言、EXIF/GPS/撮影日時/端末情報の残存経路、削除可否、ユーザー注意、App Privacy影響、共有用画像/テキスト、外部共有後の非管理説明 |
| 認証リンク / deep link | 外部認証、メールcallback、通知linkPath、ID付きdeep linkが出ない | URL scheme、Supabase/Google redirect設定、Web中継Route、callback token、リンク秘密性、公式ドメイン確認、App Privacy/FAQ/Review Notes整合 |
| 顔候補付け | 顔候補付け画面、候補保存、顔特徴量/画像特徴量保存が出ない | 本人確認/Face IDではない説明、第三者画像禁止、Sensitive Info回答、削除/利用停止、Privacy回答、`member_face_profiles` のembedding/source image URL読み取り範囲、補正履歴/学習データ追加可否 |
| グルーム/掲示板 | 未完成投稿導線が出ない | 投稿、通報、ブロック、モデレーション |
| 評価/通報/ブロック | 評価コメント、通報、ブロック導線を隠すなら、プロフィール、取引詳細、検索/ホーム、FAQ、Review Notes、App Privacyからも外す | 評価コメント注意、虚偽/報復通報禁止、通報者秘匿の限界、過去記録保持、緊急時外部連絡、App Privacy回答 |
| 未完成3D | 3D画面、スクショ、説明が出ない | 表示崩れなし、審査説明、Privacy影響確認 |
| Push通知 | 通知許可、通知送信が出ない | APNs token、push provider、app version、last seen、revoked状態、通知タイトル/本文、通知ID、linkPath、sound、未読バッジ、ロック画面/通知センター/連携端末表示、Push任意性、販促Push同意/停止手段、Identifiers/User Content/Usage Data回答。過去又は別環境でExpo Pushを使う場合はExpo push tokenも別途確認 |
| Storage画像 | 写真/画像アップロード導線が出ない | public/private bucket、signed URL期限、削除/キャッシュ、相手保存、画像メタデータ、Photos or Videos回答 |
| 位置情報 | 現在地共有/近くの表示/地図/場所名/逆ジオコーディング/待ち合わせ候補/近距離投稿が出ない | Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標の送信/保存、作成位置、閲覧者位置、半径、距離、公開範囲、権限文言、共有範囲、保持/削除例外、地図/距離/場所名の非保証、1km/3kmが匿名化又は安全保証ではない説明 |
| 生年月日 / 年齢表示 | 生年月日入力又は年齢表示を完全に隠すなら、プロフィール設定・表示導線・App Store文面からも外す | 自己申告年齢としての説明、App Privacy/Other Data候補、Age Rating、未成年者の保護者同意・現地交換安全説明 |
| 公開プロフィール / 性別 / 活動エリア | プロフィール・候補表示を隠すなら、画面/説明/FAQ/Review Notesからも外す | 表示範囲、自己申告性、非保証、目的外利用禁止、App Privacy分類 |
| 広告 | 広告枠、AdMob、スポンサー表示、広告通報説明が出ない | 広告表示証跡、不適切/年齢不相応広告の通報導線、App Privacy回答 |
| ホーム候補/検索/レコメンド | ホーム候補、検索候補、人気検索、条件一致ラベル、Plus優先表示、広告挿入、候補表示ログが出ない | Product Personalization、Search History、Usage Data、Plus優先表示、広告/organic区別、非保証説明、検索ログ保存有無の証跡 |
| 会員間支払い | 支払い設定、銀行振込、口座番号、口座名義、PayPay対応可否、現金交換、金額指定、成立後支払い情報スナップショットが画面、FAQ、Review Notes、App Store文面に出ない | Payment Info回答、利用規約/Privacy/FAQ、合意後表示、スナップショット保持、相手保存リスク、目的外利用禁止、金融/決済サービス非関与、口座名義/本人性/支払能力/外部ID/送金リンク/QR非保証の説明 |

Conditional Goにする場合は、`notes/36` に「隠した証跡」と「説明文から削除した箇所」を残す。

## 5. Owner Sign-off

提出直前に、次を1行ずつ埋める。

| 項目 | 判定 | 証跡 | 署名/日付 |
|---|---|---|---|
| G0 Scope | TODO | TODO | TODO |
| G1 Auth | TODO | TODO | TODO |
| G2 Core Flow | TODO | TODO | TODO |
| G3 Safety | TODO | TODO | TODO |
| G4 Account | TODO | TODO | TODO |
| G5 Legal URL | TODO | TODO | TODO |
| G6 App Privacy | TODO | TODO | TODO |
| G7 Metadata | TODO | TODO | TODO |
| G8 IAP | TODO | TODO | TODO |
| G9 AI | TODO | TODO | TODO |
| G10 Evidence | TODO | TODO | TODO |
| G11 Incident | TODO | TODO | TODO |
| G12 Security | TODO | TODO | TODO |
| G13 Legal Review | TODO | TODO | TODO |
| G14 Scope Exposure | TODO | TODO | TODO |
| G15 RC Handoff | TODO | TODO | TODO |
| G16 Legal Publication | TODO | TODO | TODO |
| G17 Support Inbox | TODO | TODO | TODO |
| G18 Territory / DSA | TODO | TODO | TODO |
| G19 Review Response | TODO | TODO | TODO |
| G20 Product Page Assets | TODO | TODO | TODO |
| G21 ASC Final Input | TODO | TODO | TODO |
| G22 Release Control | TODO | TODO | TODO |
| G23 Availability Stop | TODO | TODO | TODO |
| G24 Ratings / Reviews | TODO | TODO | TODO |
| G25 Signing / Capabilities | TODO | TODO | TODO |
| G26 Advertising | TODO | TODO | TODO |
| G27 Home/Search Personalization | TODO | TODO | TODO |
| G28 Camera / Photo Library / Share Sheet | TODO | TODO | TODO |
| G29 Auth Links / URL Scheme / Deep Links | TODO | TODO | TODO |
| G30 Keychain Session / Refresh Token | TODO | TODO | TODO |
| G31 Member Payment / Financial Boundary | TODO | TODO | TODO |
| G32 Location Scope / Creation Location | TODO | TODO | TODO |

最終判定:

```
Decision: Go / Conditional Go / No-Go
Version:
Build:
Submitted by:
Submitted at:
Known exclusions:
Evidence folder:
```

## 6. No-Go即時停止リスト

- デモアカウントでログインできない。
- コア交換フローが途中で止まる。
- App Privacyと実ビルドが矛盾している。
- App Store説明文、FAQ、スクショ、Review Notes又はアプリ内コピーで、Megrumが売買マーケット、古物商、古物市場、古物競りあっせん、オークション、買取、委託売買、販売代理、チケット譲渡、入場資格保証、決済代行、エスクロー又は正規/公式流通確認サービスであるように見える。
- チケット、入場用QRコード、抽選権、アカウント、盗品、不正取得品、権利侵害品、反復継続的販売又は古物営業のおそれがある取引が見えるのに、禁止説明、通報導線、非保証説明が公開文面と一致していない。
- 近くのグルーム、スポット掲示板、現在地共有、地図表示、逆ジオコーディング、場所名又は距離表示が見えるのに、Precise Location、MapKit/CoreLocation/CLGeocoder等の外部処理、精密座標のサーバー送信/保存、保持/削除例外、地図/距離/場所名の非保証がApp Privacy、Privacy、FAQ、Review Notesで一致していない。
- 待ち合わせ候補、近距離投稿、グルーム/掲示板の作成座標、閲覧者座標、半径、距離、公開範囲が見えるのに、作成位置、閲覧者位置、生活圏推測リスク、保持/削除例外、相手保存/スクリーンショット/通知リスクを説明していない。
- 近く、1km圏内、3km圏内、同じスポット又は同じ都道府県を、匿名化、安全確認、本人確認、所在確認、ストーカー防止又は推測防止として説明している。
- 生年月日を収集し、年齢又は年代を表示するのに、App Privacy、Age Rating、FAQ、Review Notes、公開サポートが自己申告年齢として一致していない。
- 年齢確認機構、身分証確認、保護者同意確認又は保護者管理機能が未実装なのに、年齢確認済み、本人確認済み、保護者同意確認済みと説明している。
- 性別、活動エリア、評価、完了取引数、支払い方法要約が見えるのに、本人確認済み、安全確認済み、法的性別確認済み、支払能力確認済み、運営推薦ではない説明がない。
- ホーム候補、検索結果、「マッチしてるよ！」「交換できるかも？」「全一致」等が見えるのに、プロフィール、在庫、wish、個別条件、タグ、交換方法、活動エリア、位置又は日程設定、支払い方法要約、評価、完了取引数、ブロック関係、通知状態、有料権限等に基づく参考表示であり、本人性、安全性、信用、所有権、真贋、支払い、発送、現地合流又は取引成立を保証しない説明がない。
- 検索語、`normalized_term`、`result_count`、検索時刻、人気検索集計、検索候補、表示順、Plus優先表示、広告挿入又はProduct Personalizationが有効なのに、App Privacy、Privacy、FAQ、Review Notesが一致していない。
- 評価コメント、通報、異議申し立て、ブロック、モデレーションが見えるのに、緊急通報、法的判断、本人確認、安全確認、信用保証、削除/解決保証ではない説明がない。
- 通報者情報を絶対非開示と保証している、又は通報/ブロックで過去取引、チャット、証跡、評価、通報記録が当然に削除されるように説明している。
- 顔候補付け、顔特徴量又は画像特徴量保存が見えるのに、Sensitive Info回答、Face ID非利用説明、削除/利用停止、外部送信有無の説明がない。
- 「画像からシリーズ名称の候補を出す」等の外部AI導線が見えるのに、OpenAI/外部AI、画像又は画像URL送信、web search、保持、学習利用、濫用監視ログ、削除可否、第三者/未成年/権利未処理画像禁止の送信前説明がない。
- 顔候補付けが見えるのに、`member_face_profiles` のembedding/source image URLがauthenticated userへ読める状態、補正履歴の学習データ追加が既定trueの状態、又は削除/利用停止/任意性が未説明の状態で提出しようとしている。
- RLS、Storage公開範囲、secret、APNs通知の監査でNo-Goが残っている。
- 管理画面がservice roleでユーザー、通報、課金、権限、通知、監査ログを扱うのに、MFA、最小権限、監査ログ、owner冗長性、secretのserver-only、退会後保持が未確認。
- 法務レビュー回答の未反映又は要再確認が残っている。
- 提出候補ビルドのVersion、Build、commit SHA、検証結果、出す/隠す機能が不明。
- 弁護士回答を受けたのに、公開文面又はApp Store文面への反映漏れが残っている。
- `support@megrum.jp` の受信、App Review連絡確認、P0問い合わせ分類、削除/個人情報請求の担当が未決。
- 配信地域、EU DSA trader status、IAP Availability、App Store商品ページに表示される連絡先情報が未確認。
- 初回Japan-only方針なのに、EU又はAll Countries or Regionsを含むApp Availability、又はIAPだけ広域販売されるAvailabilityで提出しようとしている。
- App Review指摘時の本文保存、Guideline分類、new build要否、返信/再提出/取り下げ/appeal判断の手順が未整備。
- App icon、スクショ、App Preview、poster frame、Product Page Previewが未確認、又は完成build/初回スコープ/メタデータと矛盾している。
- App Store Connect実入力値が、提出docs、完成build、公開URL、App Privacy、Review Notes、同時提出itemと未照合又は矛盾している。
- App Store Connect又は公開文書では `/legal/privacy` / `/legal/terms` を使う一方、現行Web又は登録同意リンクが `/privacy` / `/terms` の旧短縮本文を指している。
- Privacy Policy URL又はTerms URLが200応答でも、2026-06-29版ドラフトで追加した郵送交換、会員間支払い情報、成立後支払い情報スナップショット、金融/決済サービス非関与、通知、広告、評価/通報/削除申出、顔候補付け等を説明していない。
- Privacy Policy URL、FAQ又はReview Notesで、現在地共有又は服装写真の30日後自動削除、完全削除、即時反映を未確認のまま保証している。
- Bundle ID、App ID、Capabilities、entitlements、provisioning profile、certificate、App Store Connect app recordが未照合又は矛盾している。
- 承認後のRelease option、`Pending Developer Release` gate、`Release This Version` 操作、公開初日監視が未整備。
- 公開後のP0事故疑いに対するAvailability変更、Remove App From Sale、new build、復帰判断が未整備。
- 公開後の評価・レビュー返信方針が未整備で、公開返信に個人情報や未確認事実を書くおそれがある。
- 隠すはずの機能が画面、FAQ、App Store文面、スクショ、Review Notesに残っている。
- Privacy Policy URL又はSupport URLが404。
- アカウント削除入口がない。
- 退会申請の30日後実削除、申請取消/復旧、Apple/Google連携解除、退会申請/削除完了に連動したAPNs token無効化が未確認なのに、公開ページやReview Notesで完了又は復旧を保証している。過去又は別環境でExpo Pushを使う場合はExpo token無効化も未確認のまま保証しない。
- UGCが見えるのに通報/ブロック/問い合わせがない。
- 評価コメントが見えるのに個人情報、名誉毀損、権利侵害、虚偽又は報復目的利用の禁止が説明されていない。
- 有料導線が見えるのにIAPが未整備。
- Push通知が見えるのに、通知本文、未読バッジ、ロック画面表示、APNs token、App Privacy回答、アプリ内説明が一致していない。過去又は別環境でExpo Pushを使う場合はExpo push tokenの扱いも一致していない。
- Push通知を許可しないと登録又は主要機能を使えない、正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文をPush本文へ出す、又は販促Pushに同意・停止手段がない。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、Google公式データ開示、App Privacy、Privacy Manifest、ATT/Tracking回答、SKAdNetworkItems、test ads除去、不適切又は年齢に合わない広告の通報導線、サポート説明がない。
- 外部AIが見えるのにOpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否、説明/同意又は任意性、Privacy回答がない。
- 外部画像URL又はAI/検索候補画像が見えるのに、外部ホスト通信、第三者ポリシー、Content Rights、権利確認責任、Privacy回答が未確認。
- 写真アップロードが見えるのに、EXIF/GPS/撮影日時/端末情報など画像メタデータの残存経路、削除可否、ユーザー注意、App Privacy影響が未確認。
- カメラ/写真ライブラリの権限文言が実用途より狭い、又は共有シート/外部SNS共有が見えるのに共有用画像/テキストに含まれる情報と外部共有後の保存・公開・再共有・削除非管理を説明していない。
- メール認証、パスワードリセット、Google OAuth、native callback、Web中継Route、Supabase Redirect URLs、Google OAuth設定、Review Notesのscheme/URLが不一致、又は認証callback token、認証リンク、通知linkPath、ID付きdeep linkを第三者へ共有してよいように説明している。
- access token、refresh token、Keychain保存session、認証code、password reset tokenをログ、スクショ、公開証跡、問い合わせテンプレートへ出す、又はKeychain accessibility/backups/復元/他端末session未確認のままlogout/退会で即時完全削除を保証する。
- 顔候補付けが本人確認、年齢確認、Face ID認証、出入場管理、真贋鑑定、信用判断のように見える。
- 未成年の現地交換、位置情報、服装写真、郵送先情報、会員間支払い情報、取引チャットについて、保護者相談・同伴推奨や安全上の制限可能性を公開文面で説明していない。
- 住所登録又は住所表示の未完成導線が見える。
- 支払い方法、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定又は成立後支払い情報スナップショットが見えるのに、Financial Info / Payment Info回答、合意後表示、スナップショット保持、相手保存リスク、目的外利用禁止、外部決済サービス非関与、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR真正性確認の非保証が説明できない。
- 個人情報・セキュリティ事故疑いが未処理。
- スクショに実住所、実在IP、内部ID、デバッグ表示がある。

## 7. 関連文書

- 提出コントロールボード: `notes/39_release_command_center.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- App Review Guideline適合マトリクス: `notes/53_app_review_guideline_compliance_matrix.md`
- 提出前セキュリティ監査チェックリスト: `notes/54_prelaunch_security_audit_checklist.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- 外部サービス・委託先データ台帳: `notes/48_external_service_vendor_register.md`
- 個人情報・セキュリティ事故初動ランブック: `notes/49_privacy_security_incident_response_runbook.md`
- 法務レビュー回答反映台帳: `notes/58_legal_review_response_tracker.md`
- 初回提出スコープ露出監査表: `notes/59_initial_release_scope_exposure_audit.md`
- Release Candidateハンドオフ: `notes/65_release_candidate_handoff.md`
- 法務レビュー後公開文面最終化Runbook: `notes/66_legal_review_publication_runbook.md`
- サポート受信トリアージRunbook: `notes/67_support_inbox_triage_runbook.md`
- App Store配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`
- App Reviewリジェクト/追加情報要求Runbook: `notes/69_app_review_rejection_triage_runbook.md`
- App Store商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- 提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`
- 承認後・手動公開制御Runbook: `notes/72_app_store_approval_release_control_runbook.md`
- 公開停止・Availability変更Runbook: `notes/73_app_store_availability_emergency_stop_runbook.md`
- App Store評価・レビュー返信Runbook: `notes/74_app_store_ratings_reviews_response_runbook.md`
- Apple Developer署名・Capabilities事前確認Runbook: `notes/75_apple_developer_signing_capabilities_preflight.md`
- データ保持・削除マトリクス: `notes/52_data_retention_deletion_matrix.md`
