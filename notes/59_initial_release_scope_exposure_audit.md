# 59. 初回提出スコープ露出監査表

最終更新: 2026-06-29

ステータス: Draft v1.6（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 公開Web同期監査 / Keychain・session保存・refresh token / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / 精密位置・MapKit/CoreLocation・逆ジオコーディング / 公式非提携・権利物 / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search / 顔特徴量RLS・学習データ可否 / 公開プロフィール / 外部画像URLを反映・完成ビルド確認前）

## 目的

App Store初回提出ビルドで「出す機能」と「隠す機能」が、アプリ画面、App Storeメタデータ、スクリーンショット、公開FAQ、利用規約、プライバシーポリシー、App Privacy、Review Notesで一致しているかを確認する。

この文書は監査表であり、コード、画面、App Store Connect設定、公開URLは変更しない。

## 1. 初回提出の原則

初回提出の勝ち条件は、一般公開完了ではなく、App Store審査への初回提出完了。

初回提出では、次を優先する。

- 現地交換MVPとして説明できること。
- デモアカウントで主要フローを通せること。
- 未完成機能を画面、説明文、FAQ、スクショ、Review Notesから外すこと。
- 見えている機能は、法務、Privacy、App Review、運用で説明できること。

## 2. 機能露出マトリクス

| 領域 | 初回提出の推奨 | 見える場合の必須 | 隠す場合の確認 | No-Go |
|---|---|---|---|---|
| Auth / Account | 出す | 登録、ログイン、削除、問い合わせが通る。メール認証/パスワードリセット/Google OAuthを出す場合はURL scheme、Redirect URLs、公式ドメイン、リンク秘密性説明、Keychain/session保存、refresh token更新、logout時local clearの説明が一致 | なし | デモアカウントで入れない。認証リンク、callback URL、認証コード、access token、refresh tokenを共有してよいように見える。ログアウト/退会で全端末session/tokenが即時完全失効すると誤説明している |
| 在庫 / wish | 出す | 作成、編集、削除、検索候補が通る | なし | コアフローが途中で止まる |
| 打診 / ネゴ / 合意 | 出す | 2アカウントで送受信、合意、取引チャット遷移 | なし | 相手に届かない、状態不整合 |
| 取引チャット | 出す | メッセージ、写真、現在地共有、到着、完了確認、相手保存/スクリーンショット/通知/端末キャッシュの説明 | 未実装の操作を隠す | 取引安全に必要な連絡ができない。現在地共有が安全確認済み又は短期完全削除保証に見える |
| 現地交換安全 | 出す | 通報、ブロック、安全注意、緊急時案内 | なし | 危険時の導線がない |
| 生年月日 / 年齢表示 | 出すなら自己申告年齢として説明 | 生年月日入力、年齢/年代表示、Age Rating、App Privacy、未成年者の保護者同意・現地交換安全説明 | 生年月日入力又は年齢表示を隠すならオンボーディング/プロフィール/メタデータから外す | 年齢確認済み、本人確認済み、保護者同意確認済みと誤説明 |
| 公開プロフィール / 性別 / 活動エリア | 出すなら自己申告プロフィール情報として説明 | 表示範囲、性別/活動エリア/評価/支払い方法要約、App Privacy、FAQ、Review Notesの非保証説明 | 隠すならプロフィール、ホーム候補、交換条件、FAQ、Review Notesから外す | 本人確認済み、安全確認済み、法的性別確認済み、支払能力確認済み、運営推薦と誤説明 |
| 会員間支払い | 初回で出すならPayment Infoと金融非関与を揃える | 支払い設定、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定、成立後支払い情報スナップショット、合意後表示、保持、相手保存リスク、目的外利用禁止、外部決済サービス非関与、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR非保証 | 隠すなら支払い設定、金額指定、支払い方法要約、FAQ、Review Notes、App Privacyから外す | Megrumが決済代行、資金移動、収納代行、回収、返金、チャージバック、エスクロー、口座名義確認、本人確認、支払能力確認又は外部サービス確認をするように見える |
| ホーム候補 / 検索 / レコメンド | 出すなら参考表示として説明 | 候補表示、検索結果、マッチ/条件一致ラベル、検索候補、人気検索、表示順、Plus優先表示、広告挿入、Product Personalization、Search History / Usage Data回答、非保証説明 | 隠すならホーム候補、検索候補、人気検索、Plus優先表示、広告挿入、FAQ、Review Notesから外す | 本人確認済み、安全確認済み、信用保証、真贋確認済み、取引成立保証、運営推薦に見える。検索ログや人気検索を使うのにApp Privacy未反映 |
| 評価 / 通報 / ブロック / モデレーション | 出すなら安全運用と非保証を説明 | 評価コメント注意、虚偽/報復通報禁止、通報者秘匿の限界、ブロック後も過去記録保持、緊急時外部連絡、App Privacy | 隠すなら取引完了、プロフィール、検索/ホーム、FAQ、Review Notes、App Privacyから外す | 評価/通報が削除保証、緊急通報、本人確認、安全確認、信用保証、法的判断に見える |
| グルーム | 出すならUGC対応必須 | 投稿、通報、ブロック、モデレーション、作成時の緯度経度、公開範囲、距離判定、生活圏推測リスクの説明 | 未完成投稿導線を隠す | UGCが見えるのに通報不可。近距離表示が匿名化/安全確認に見える |
| スポット掲示板 | 未完成なら隠す | 投稿、返信、通報、ブロック、削除/非表示。近くの掲示板や返信範囲判定で精密座標、作成座標、閲覧者座標、1km/3km判定を使う場合はPrecise Location説明 | タブ、説明、FAQ、スクショから外す | 未完成投稿画面が見える。精密座標を使うのにCoarse Locationだけで説明している。1km/3kmを匿名/安全保証として説明している |
| めぐり | 3Dなしで出す候補 | 3Dなしでも主要体験が破綻しない。近くのグルーム、掲示板、地図表示、逆ジオコーディングで精密座標、作成位置、閲覧者位置を使う場合はPrivacy/App Privacy/FAQを揃える | 未完成3D導線を外す | 未完成3Dが表示される。精密位置、作成位置、閲覧者位置、地図サービス説明が不足 |
| 有料機能 | IAP未完なら隠す。チェックイン既定は `MEGRUM_PLUS_IAP_ENABLED=NO` で購入/復元/商品照会を停止 | IAP商品、価格、復元、解約、特商法、Purchases回答 | Premium、めぐりPlus、ブースト導線を外し、購入/復元ボタンと価格が出ないことを確認 | 有料導線が見えるのにIAP未設定 |
| 広告 / AdMob | 初回で出すなら実広告・通報・App Privacyを揃える | Google Mobile Ads SDK初期化、広告リクエスト画面、App Privacy、Privacy Manifest、ATT/Tracking、SKAdNetworkItems、test ads除去、広告通報 | 現チェックイン既定は広告OFF。広告を出さないなら広告unit id、FAQ、スクショ、Review Notesから外し、SDK初期化/広告リクエストが発生しないことを確認 | 広告を有効化したままApp Privacy/ATT/Google開示が未整備。Googleデモunit idやtest adsを一般公開する |
| 外部AI | 初回は隠す又はオンデバイス限定推奨 | 送信情報、送信先、OpenAI等外部AI名、画像又は画像URL、web search利用、保持、学習利用、削除可否、同意又は任意性、Privacy、App Privacy | AI送信ボタン、説明、FAQ露出を外す | 外部送信が見えるのに説明/同意なし。「画像からシリーズ名称の候補を出す」ボタンが見えるのにOpenAI/web_search/保持/学習利用/第三者画像禁止を説明していない |
| 外部画像URL | 初回はSupabase保存画像中心推奨 | 外部ホスト通信、第三者ポリシー、Content Rights、権利確認責任、Privacy回答 | 外部URL入力、AI/検索候補画像、外部画像プレビューを外す | 外部画像URLが見えるのにPrivacy/Content Rights説明が不足 |
| カメラ / 写真ライブラリ / 共有シート | 出すならApp Privacyと権限説明を揃える | Info.plist権限文言、画像メタデータ、Photos or Videos / Location / Device Info回答、共有用画像/テキスト、外部共有後の非管理説明 | 写真アップロード、共有シート、外部SNS共有を隠すなら画面/FAQ/Review Notesから外す | 権限文言が実用途より狭い。写真メタデータ又は外部共有後の保存/公開/再共有/削除非管理を説明していない |
| 実在IP / 公式関係 | スクショ、初期データ、メタデータでは原則使わない | 実在名称、タグ、候補、商品名、商標を表示するなら、公式/公認/提携/代理ではない説明、権利確認責任、真贋非保証、取引可否非保証をTerms/FAQ/Review Notes/Content Rightsで揃える | 実在IP、商標、公式名称、公式画像、権利未確認素材を外す | 公式サービス、権利者承認済み、真贋確認済み、取引可能確認済みのように見える |
| 顔候補付け | 初回は隠す又はオンデバイス検出のみ推奨 | 本人確認/Face IDではない説明、第三者画像禁止、Sensitive Info回答、削除/利用停止、`member_face_profiles` のembedding/source image URL読み取り範囲、補正履歴/学習データ追加可否 | 顔候補画面、顔特徴量/画像特徴量保存、FAQ露出を外す | 顔候補付けが見えるのにApp Privacy/説明が不足。`member_face_profiles` が広く読める又は学習データ追加が既定trueのまま説明できない |
| 住所/電話番号入力 | 初回では出さない | 出すならPrivacy/App Privacy/法務レビューやり直し | 入力欄、設定、FAQ、App Privacyから外す | 収集しない前提なのに入力欄が見える |
| 未完成管理/デバッグ | 隠す | なし | debug表示、内部ID、fixture、管理画面導線を外す | スクショや画面に内部情報が出る |

## 3. 画面監査チェック

完成候補ビルドで、次を1つずつ確認する。

| 画面/導線 | 見ること | 判定 |
|---|---|---|
| Welcome / Auth | Terms / Privacyリンクが提出対象の最新本文へ到達し、ログイン方法、Keychain/session保存、認証リンク秘密性、未完成機能訴求なしを確認 | TODO |
| Auth Links | Googleログイン、認証メール、パスワードリセットが公式ドメインを経由し、URL scheme/Redirect URL/Review Notes/FAQが一致。リンクや認証コードを第三者へ送らない説明がある | TODO |
| Onboarding | 生年月日入力の目的、自己申告年齢説明、性別/活動エリアの表示範囲、不要な住所/電話番号を求めていないこと | TODO |
| Home | 現地交換MVPの説明と実機状態が一致。候補表示が本人確認済み/安全確認済み/信用保証/取引成立保証に見えない。Plus優先表示、通知状態、評価、支払い方法要約、位置又は日程条件の扱いを説明できる | TODO |
| Payment Settings / Agreement | 会員間支払いを出す場合、合意前の支払い方法要約と合意後の支払い情報スナップショットの表示範囲、Payment Info、保持、金融/決済サービス非関与、送金リンク/QR/外部IDを求めない注意を説明できる。隠す場合は導線なし | TODO |
| Inventory | 在庫登録が正常。公式画像利用を促していない。写真ライブラリ元画像メタデータと権限説明がPrivacy/App Privacyと一致 | TODO |
| Face candidate suggestion | 初回で隠すなら導線なし。出すなら本人確認/Face IDではない説明、第三者画像禁止、App Privacy整合あり | TODO |
| Wish | wish登録が正常。初回スコープ外の条件を出しすぎない | TODO |
| Search / Match | 候補表示が空でも破綻しない。未完成3Dへ飛ばない。「マッチしてるよ！」「交換できるかも？」「全一致」等が参考表示として説明でき、検索ログ/人気検索/検索候補/表示順/Product PersonalizationのApp Privacy回答と矛盾しない | TODO |
| Proposal | 打診内容、待ち合わせ、交換条件が現地交換前提 | TODO |
| Negotiation | 条件調整、合意、キャンセルが説明できる | TODO |
| Trade Chat | 現地合流、服装写真、現在地共有、安全注意、相手保存/スクリーンショット/通知/端末キャッシュの説明がある | TODO |
| Share Sheet | 共有用画像/テキストが表示名、グッズ画像、グッズ名、グループ/メンバー、タグ、ハッシュタグ等を含む場合、外部共有後の公開範囲・保存・削除非管理を説明できる | TODO |
| Completion / Rating | 完了、評価、異議申し立てが説明できる。評価コメントが公開され得ること、個人情報/名誉毀損/虚偽/報復目的が禁止されていること | TODO |
| Report / Block | UGCから通報/ブロックできる。直接ボタンがない対象はsupport@フォールバックが説明できる。通報者秘匿の限界、過去記録保持、緊急時外部連絡が説明できる | TODO |
| Account Deletion | アプリ内削除入口がある | TODO |
| Settings / Legal | Terms、Privacy、Support、FAQへ辿れる。アプリ内法務要約を正式本文として扱わず、公開本文リンク又は同等導線が最新本文へ到達する | TODO |
| Paid surfaces | 初回で隠すなら購入/復元導線なし、`MEGRUM_PLUS_IAP_ENABLED=NO`、StoreKit商品照会なし。出すならIAP文書と一致 | TODO |
| AI surfaces | 初回で隠すなら導線なし。出すならOpenAI/外部AI、画像又は画像URL、web search、保持/学習利用、第三者/未成年/権利未処理画像禁止の送信前説明あり | TODO |
| Meguri / 3D | 未完成3Dが露出しない。近くのグルーム/掲示板、地図表示、逆ジオコーディングが見える場合はPrecise Location回答と精密座標、作成位置、閲覧者位置、1km/3km非保証、地図サービス説明がある | TODO |

## 4. メタデータ監査チェック

| 対象 | 見ること | 判定 |
|---|---|---|
| App Name / Subtitle | 初回で出す機能だけを表す | TODO |
| Promotional Text | 外部AI、有料機能、未完成機能を訴求していない | TODO |
| Description | 現地交換MVPと実ビルドが一致 | TODO |
| Keywords | 実在IPに寄りすぎない。未完成機能を入れない。公式/公認/提携/代理を連想させる語を入れない | TODO |
| Review Notes | デモアカウント、主要フロー、安全/UGC/削除説明がある | TODO |
| Screenshots | 実住所、実在IP、内部ID、debug、未完成機能がない | TODO |
| Age Rating | UGC、チャット、位置情報、IAP、AI、生年月日/年齢表示、Age Assuranceなしの実態と一致 | TODO |
| App Privacy | 実ビルドで収集するデータだけ回答。生年月日/年齢、性別、活動エリア、公開プロフィール、評価コメント、通報/ブロック/モデレーション状態、認証callback/deep link、写真ライブラリ元画像メタデータ、共有用生成画像、候補表示、検索語、検索結果件数、人気検索、Product Personalization、Precise Location、Push通知本文、未読バッジ、ロック画面表示も照合 | TODO |
| Public URLs | Support、Privacy、Terms、FAQが200で開く。`/terms` / `/privacy` / `/legal/terms` / `/legal/privacy` の到達本文、最終更新日、リダイレクトが提出内容と一致 | TODO |

## 5. 公開文書監査チェック

| 文書 | 見ること | 判定 |
|---|---|---|
| Terms | 初回で出す機能と矛盾しない。Keychain/session管理、認証リンク秘密性、評価、通報、ブロック、モデレーション、AI/IAPは条件付き説明 | TODO |
| Privacy | 実ビルドの収集データ、外部サービス、保存期間、通報者情報の扱いと一致。Keychain/session保存、access token、refresh token、認証callback、通知linkPath、精密位置、写真メタデータ、外部AI/web_search、AdMob/ATTを含む | TODO |
| Support | 問い合わせ先、削除、通報、ブロック、評価、緊急時外部連絡、Privacy請求へ辿れる | TODO |
| FAQ | 初回で出さない有料機能/外部AI/顔候補付け/Push通知/未完成機能を断定しない。年齢確認済み、本人確認済み、安全確認済み、法的性別確認済み、通報者絶対秘匿、削除保証と誤解させない | TODO |
| Commerce | 有料機能を出す場合だけ価格/解約/返金が一致 | TODO |
| App Review response | 指摘時に説明する機能範囲が実ビルドと一致 | TODO |

## 6. 証跡フォーマット

| 項目 | 値 |
|---|---|
| 監査日 | TODO |
| 監査者 | TODO |
| App Version / Build | TODO |
| TestFlight build | TODO |
| デモアカウント | TODO |
| 対象commit | TODO |
| Scope判定 | Pass / Conditional / Fail |
| 隠した機能 | TODO |
| 出す機能 | TODO |
| メタデータ修正要否 | TODO |
| 公開文書修正要否 | TODO |
| No-Go残件 | TODO |

## 7. No-Go

次に該当する場合は提出しない。

- 初回で隠すはずの有料機能、外部AI、外部画像URL、未完成3D、未完成掲示板、住所/電話番号入力が画面に見える。
- ホーム候補、検索結果、検索候補、人気検索、表示順、Plus優先表示、広告挿入、Product Personalizationが見えるのに、参考表示であり本人性、安全性、信用、所有権、真贋、支払い、発送、現地合流又は取引成立を保証しない説明とApp Privacy回答が揃っていない。
- 外部AI又はAI/検索候補画像が見えるのに、OpenAI等外部AI、画像又は画像URL、web search、保持、学習利用、削除可否、外部ホスト通信、第三者ポリシー、Content Rights、権利確認責任、Privacy回答の説明がない。
- カメラ/写真ライブラリ/共有シートが見えるのに、Info.plist権限文言、写真ライブラリ由来メタデータ、共有用生成画像/テキスト、外部共有後の保存/公開/再共有/削除非管理の説明がない。
- 近くのグルーム、スポット掲示板、現在地共有、位置情報メッセージ、待ち合わせ候補、現地交換モード、地図表示又は逆ジオコーディングが見えるのに、Precise Location回答、MapKit/CoreLocation/CLGeocoder等のOS・地図関連処理、精密座標のサーバー送信/保存、作成位置、閲覧者位置、半径、距離、公開範囲、保持/削除例外、地図・距離・場所名の非保証が未確認。
- 近く、1km圏内、3km圏内、同じスポット、同じ都道府県を、匿名化、安全確認、本人確認、所在確認、ストーカー防止又は推測防止として説明している。
- 顔候補付け、顔特徴量又は画像特徴量保存が見えるのに、Sensitive Info回答、Face ID非利用説明、削除/利用停止、外部送信有無、`member_face_profiles`読み取り範囲、学習データ追加可否の説明がない。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、Google公式データ開示、App Privacy、Privacy Manifest、ATT/Tracking、SKAdNetworkItems、test ads除去、広告通報導線が揃っていない。
- 実在IP、商標、公式名称、AI/検索候補、外部画像URLが見えるのに、公式/公認/提携/代理ではない説明、権利確認責任、真贋非保証、取引可否非保証がTerms/FAQ/Review Notes/Content Rightsで揃っていない。
- 生年月日又は年齢表示が見えるのに、App Privacy、Age Rating、FAQ、Review Notesで自己申告年齢として説明していない。
- 年齢確認機構、身分証確認、保護者同意確認又は保護者管理機能が未実装なのに、年齢確認済み、本人確認済み、保護者同意確認済みと説明している。
- 性別、活動エリア、評価、完了取引数、支払い方法要約が見えるのに、本人確認済み、安全確認済み、法的性別確認済み、支払能力確認済み、運営推薦ではない説明がない。
- 支払い設定、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定又は成立後支払い情報スナップショットが見えるのに、Payment Info、合意後表示、保持、相手保存リスク、金融/決済サービス非関与、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR非保証が揃っていない。
- 評価コメント、通報、異議申し立て、ブロック、モデレーションが見えるのに、緊急通報、法的判断、本人確認、安全確認、信用保証、削除/解決保証ではない説明がない。
- 通報者情報を絶対非開示と保証している、又はブロックで過去取引、チャット、証跡、評価、通報記録が当然に削除されるように説明している。
- 画面には見えないが、App Store説明文、スクショ、FAQ、Review Notesで未完成機能を説明している。
- App Privacyで回答しないデータを、実ビルドで入力又は送信している。
- App Store Privacy Policy URL、登録同意リンク、Support関連リンクが、2026-06-26短縮Terms/Privacyのままで、2026-06-29版のKeychain/session保存、認証callback、写真メタデータ、精密位置、外部AI/web_search、AdMob/ATT等を含む正式本文へ到達しない。
- UGCが見えるのに通報、ブロック、問い合わせ導線がない。
- アカウント作成があるのにアプリ内削除入口がない。
- スクショに実住所、実在IP、内部ID、debug表示がある。

## 8. 関連文書

- App Store提出パック: `notes/24_app_store_submission_pack.md`
- オーナー作業表: `notes/30_owner_release_action_sheet.md`
- スクリーンショット台本: `notes/28_app_store_screenshot_storyboard.md`
- App Store Connect転記: `notes/40_app_store_connect_copy_paste_sheet.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- App Privacy回答: `notes/43_app_privacy_connect_answer_sheet.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
- 公開FAQ下書き: `notes/55_public_help_faq_draft.md`
- アプリ内法務・安全コピー: `notes/56_in_app_legal_safety_copy_deck.md`
