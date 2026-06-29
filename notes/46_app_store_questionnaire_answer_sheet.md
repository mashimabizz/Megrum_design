# 46. App Store質問票回答シート

最終更新: 2026-06-29

ステータス: Draft v1.6（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / 精密位置・MapKit・CoreLocation・逆ジオコーディング / EU DSA・配信地域 / 公式非提携・権利物 / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search / 顔特徴量RLS・学習データ可否 / Content Rights / Sensitive Info確認を追加）

## 目的

App Store Connectで入力するAge Rating、Content Rights、Export Compliance、Kidsカテゴリ、License Agreement周辺の回答候補を、初回提出スコープに合わせて整理する。

この文書は提出前の回答シートであり、コード、Info.plist、App Store Connect設定は変更しない。実回答は、完成ビルドの機能、SDK、公開地域、法務レビュー結果と照合してから行う。

## 1. 現時点の読み取り事実

| 項目 | 現状 |
|---|---|
| `LSApplicationCategoryType` | `public.app-category.social-networking` |
| `ITSAppUsesNonExemptEncryption` | `false` |
| 初回提出スコープ | 現地交換MVP |
| UGC | プロフィール、画像、取引チャット、グルーム/掲示板を出す場合あり |
| チャット | 取引チャット、めぐりメッセージを出す場合あり |
| 評価 / 通報 / ブロック / モデレーション | 取引評価コメント、ユーザー/グッズ/グルーム/掲示板通報、異議申し立て、ブロック、運営対応statusを扱う経路あり。評価や通報は本人確認、安全確認、信用保証、緊急通報、法的判断の代替ではない |
| 生年月日 / 年齢 | 初回設定で生年月日入力が必須。未来日以外の最低年齢制限は未確認。算出年齢をプロフィール等で表示する経路あり |
| 公開プロフィール / 性別 / 活動エリア | 性別、活動エリア、年齢、評価、完了取引数、支払い方法要約等がプロフィール、ホーム候補、交換条件等で表示され得る。本人確認、法的性別確認、安全確認、支払能力確認ではない |
| 会員間支払い | 支払い設定、銀行振込、口座番号、口座名義、PayPay対応可否、現金交換、金額指定、成立後支払い情報スナップショットを出す場合あり。Financial Info / Payment Info候補であり、Megrumは送金、収納代行、回収、返金、チャージバック、エスクロー、本人確認、口座名義確認、支払能力確認、外部ID/送金リンク/QR真正性確認を行わない |
| 位置情報 / 地図 | 近くのグルーム、スポット掲示板、返信範囲、現在地共有、待ち合わせ候補、現地交換モード、作成位置、閲覧者位置、地図表示、場所名表示、逆ジオコーディングを出す場合あり。Swift NativeではCoreLocation、MapKit、CLGeocoder、精密な緯度経度、精度、時刻、場所名、半径、距離/近接判定、公開範囲を扱い得る |
| IAP | 初回で隠すならNo、出すならYes。出す場合は手動有料権限上書きが購入証明や返金確定に見えない説明も確認 |
| 広告 | Google Mobile Ads SDK / AdMob / SKAdNetwork構成あり。`MEGRUM_ADS_ENABLED=YES`、test ads有効、検索native/やりとりbanner unit idあり。出す場合はAdvertising回答、App Privacy、ATT/Tracking、test ads除去、広告通報導線を確認 |
| 外部AI | 初回で隠す又は送信前説明/同意を必須。出す場合はOpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否を確認 |
| 顔候補付け | 初回で出す場合、Face ID/本人確認ではない説明、Sensitive Info回答、`member_face_profiles`読み取り範囲、学習データ追加可否を確認 |
| Kidsカテゴリ | No |

## 2. Age Rating回答候補

AppleのAge Ratingは、App Store Connectの質問票への回答で算出される。UGCとユーザー間メッセージがあるため、Kidsカテゴリにはしない。

| 質問カテゴリ | 回答候補 | 理由 |
|---|---|---|
| Made for Kids | No | UGC、ユーザー間メッセージ、位置情報、取引調整がある |
| User-Generated Content | Yes | プロフィール、画像、投稿、取引チャット、評価コメント、通報対象コンテンツ等 |
| Messaging and Chat | Yes | 取引チャット、めぐりメッセージ等 |
| Unrestricted Web Access | No | 任意ブラウザ機能を提供しない前提 |
| Advertising | 初回広告なしならNo | 広告SDK初期化、広告リクエスト又は広告表示がある場合はYes候補。不適切又は年齢に合わない広告の通報導線、test ads除去、App Privacy/ATT/Tracking回答を実装/サポートで説明 |
| In-App Purchases | 有料機能を隠すならNo、出すならYes | メグルムプラス、Premium互換、めぐりPlus互換、ブーストの露出次第。手動上書きはIAPの代替として説明しない |
| Gambling | No | 賭博機能なし |
| Loot Boxes | No | ランダム課金や景品抽選として提供しない |
| Contests | No | コンテスト機能なし |
| Simulated Gambling | No | 該当なし |
| Mature or Suggestive Themes | None又はInfrequent | UGC上の発生可能性は通報/モデレーションで対応 |
| Sexual Content / Nudity | None又はInfrequent | UGC上の発生可能性は通報/モデレーションで対応 |
| Violence / Horror / Weapons | None又はInfrequent | グッズ画像やUGC次第。初期データでは使わない |
| Alcohol / Tobacco / Drug References | None | 初期データでは使わない |
| Medical / Treatment Information | No | 医療アプリではない |
| Age Assurance | No候補 | 初回で公的年齢確認、身分証確認、保護者同意確認、保護者管理機能なし。生年月日/年齢は自己申告として扱う |
| Parental Controls | No候補 | 保護者管理機能なし |

推奨:
- 算出結果が低く出すぎる場合、UGC/チャット/現地交換の実態に合わせてOverride to Higher Age Ratingを検討する。
- 利用規約で最低年齢を設定する場合は、Appleの説明どおり、その要件に合わせて上位年齢へOverrideが必要になる可能性がある。
- スクショとデモデータは、年齢制限を上げる原因になり得る文言や画像を使わない。
- 生年月日や年齢を表示する場合でも、App Store説明文、Review Notes、FAQ、利用規約で「年齢確認済み」「保護者同意確認済み」「本人確認済み」と誤認させない。
- 性別、活動エリア、評価、支払い方法要約などを表示する場合でも、「法的性別確認済み」「安全確認済み」「支払能力確認済み」「運営者推薦」と誤認させない。銀行口座又は支払い情報が見える場合も、口座名義確認、本人確認、残高確認、外部決済サービス確認済みと説明しない。
- 評価コメントや通報導線がある場合でも、運営が投稿内容を常時監視し、真実性を確認し、通報者秘匿や削除/解決を保証すると誤認させない。

## 3. Content Rights回答候補

AppleのApp Informationでは、第三者コンテンツを含む、表示する、又はアクセスするアプリは、各国/地域の法律上必要な権利又は許諾を持つ必要がある。

Megrumの整理:

| 項目 | 方針 |
|---|---|
| ユーザー投稿画像 | UGCとして扱い、利用規約で権利侵害を禁止 |
| グッズ写真 | ユーザーが権限を持つ写真のみ登録する前提 |
| 外部画像URL | ユーザー又はAI/検索候補由来の外部画像URLは、公式情報又は権利確認済み素材として扱わない |
| AI/検索候補画像 | 参考情報として扱い、公式情報、権利確認済み素材又は正確な商品情報として保証しない。権利、出典、真偽、適法性はユーザー確認前提 |
| 画像シリーズ候補AI | OpenAI Responses API及びweb searchを使う場合、画像又は画像URL、推し文脈、既存候補を外部AIへ送ることを説明し、第三者/未成年/権利未処理画像を送らない注意を出す |
| 顔が写る画像 | 顔候補付けを出す場合、第三者の私的写真・未成年者写真・無許諾画像を登録しない注意を出す。顔特徴量、source image URL、補正履歴、学習データ追加可否の扱いを説明する |
| 公式画像 | 運営提供素材としては初回で使わない |
| 実在アーティスト/作品名 | App Storeメタデータ、スクショ、初期データでは原則使わない |
| 実在IP / 公式関係 | 実在の名称、タグ、候補、商品名、商標を参考表示する場合でも、公式、公認、提携、代理、権利者承認、権利許諾、真贋確認又は取引可能性を意味しない説明を揃える |
| スクショ | 架空グループ、架空グッズ、権利クリア素材のみ |
| 通報 | 権利侵害やなりすましを通報できる |
| 評価コメント / 通報補足 | ユーザー入力UGCとして扱い、権利侵害、名誉毀損、個人情報、虚偽又は報復目的の記載を禁止 |

回答メモ:
- 運営が第三者IP素材を提供しない。
- ユーザーが投稿するUGCについては、規約と通報/削除運用で対応する。
- 外部画像URL又はAI/検索候補画像を表示する場合も、公式素材や権利処理済み素材として誤認させない説明を、利用規約、プライバシーポリシー、FAQ、Review Notes又はサポート導線と一致させる。
- 実在のアーティスト名、グループ名、メンバー名、作品名、キャラクター名、商品名、商標等を表示する場合は、Megrumが権利者、所属事務所、興行主、販売者又は公式ファンクラブの公式、公認、提携又は代理サービスではないこと、名称は検索、分類、識別又は説明のための参考情報であることを説明する。
- 初回提出では、権利許諾が必要な画像、楽曲、映像、ブランドロゴ、公式キャラクター画像をスクショや初期データに入れない。

No-Go:
- 実在IPの画像や名称をスクショに入れる。
- 運営提供の素材として公式画像を入れる。
- 実在IP、商標、公式名称、外部画像URL又はAI/検索候補が見えるのに、公式/公認/提携/代理ではない説明、権利確認責任、真贋非保証、取引可否非保証を揃えていない。
- AI/検索候補画像を権利確認済み、公式、推奨素材のように表示する。
- 画像シリーズ候補AIが見えるのに、OpenAI/外部AI、画像又は画像URL、web search、保持/学習利用、第三者/未成年/権利未処理画像禁止を説明していない。
- 外部画像URLが見えるのに、外部ホストへの通信と第三者ポリシーを説明していない。
- UGCがあるのに権利侵害通報の説明がない。
- 評価コメントや通報補足があるのに、権利侵害、名誉毀損、個人情報、虚偽通報、報復目的利用の禁止を説明していない。

## 4. Export Compliance回答候補

現時点のSwift Native `Info.plist` では `ITSAppUsesNonExemptEncryption=false`。

Apple公式ヘルプの整理では、Apple OS内の暗号化に限定される場合、App Store Connectで追加書類は不要とされている。一方、独自暗号、非標準暗号、Apple OS外の標準暗号ライブラリ、特定地域配布に関わる場合は再確認が必要。

| 質問 | 回答候補 | 確認 |
|---|---|---|
| Encryption used? | HTTPS、認証、Apple標準機能の範囲ならApple OS内暗号化の利用として整理 | 完成ビルドのSDK確認 |
| Non-exempt encryption? | No候補 | `ITSAppUsesNonExemptEncryption=false` と一致 |
| Proprietary or non-standard cryptography? | No | 独自暗号を入れない |
| Documentation required? | No候補 | Apple OS内暗号化に限定される場合 |
| France-specific declaration | 不要候補 | 独自/外部暗号を入れない前提 |

提出前確認:
- Supabase、Sign in with Apple、Google Sign-In、IAP、AI SDK、Analytics/Crash SDKが独自暗号や追加書類を必要としないか確認する。
- `Info.plist` の `ITSAppUsesNonExemptEncryption=false` と実ビルドの実態が一致しているか確認する。
- 独自暗号、VPN、セキュアストレージ専用機能、暗号化メッセージング機能として訴求しない。

## 5. License Agreement / EULA

候補:
- 初回提出ではApple標準EULAを使い、Megrum利用規約URLをアプリ内とWebに掲載する。Apple標準EULAはアプリライセンス、Megrum利用規約はサービス利用条件として整理する。
- 独自EULAをApp Store Connectに登録する場合は、`notes/legal/01_terms_of_service_draft.md`、Apple Minimum Terms、弁護士レビュー結果、代表者/事業者情報の公開方針、公開URLを照合してから行う。
- 独自EULAを使う場合、保守/サポート、製品請求、知的財産権侵害、法令遵守、第三者受益者、連絡先表示などAppleの最低条項を落とさない。

No-Go:
- 利用規約URLが未公開。
- アプリ内の利用規約とWeb公開文面がズレている。
- App Store Connectで独自EULAを入れるのに、規約ドラフトが弁護士レビュー前又はApple Minimum Terms未照合。

## 6. 韓国GRAC / 地域別注意

初回方針:
- ゲーム、ギャンブル、コンテスト、ルートボックスを提供しない。
- Primary CategoryはLifestyle又はSocial Networking候補で、Gamesにはしない。
- 韓国向けに追加のRating Classification Numberが必要になる特徴がないか、App Store Connectの実質問に沿って確認する。

配信地域、EU DSA trader status、IAP Availabilityの判断は `notes/68_app_store_territory_dsa_iap_availability.md` を使う。
初回はJapanのみ候補とし、EU又はAll Countries or Regionsを選ぶ場合は、trader status、App Store商品ページに表示されるProvider/Seller/contact情報、代表者情報非公表方針との差分、英語/現地語サポート可否、IAP Availabilityをオーナー確認済みにしてから回答する。

## 7. 転記前チェックリスト

| 項目 | 状態 |
|---|---|
| 完成ビルドでUGC/チャット/掲示板の露出を確認 | 未 |
| 評価、通報、ブロック、モデレーション導線と非保証説明を確認 | 未 |
| 有料機能が見えるか、IAP/Review Notes/手動有料権限上書きの非保証説明が一致するか確認 | 未 |
| 外部AIが見えるか確認 | 未（OpenAI、画像又は画像URL、web search、保持、学習利用、削除可否、Content Rights説明） |
| 顔候補付け、顔特徴量、画像特徴量、補正履歴保存が見えるか確認 | 未（Sensitive Info、Face ID非利用、`member_face_profiles`、`shouldAddTrainingData`、削除/利用停止） |
| Push通知が見えるか、通知本文/未読バッジ/ロック画面表示が説明と一致するか確認 | 未 |
| 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、現地交換モード、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示が見えるか確認 | 未（Precise Location、MapKit/CoreLocation/CLGeocoder、精密座標のサーバー送信/保存、作成位置、閲覧者位置、保持/削除例外、地図/距離/場所名の非保証、1km/3km非保証） |
| 生年月日入力、年齢表示、自己申告年齢、未成年者の保護者同意/現地交換安全説明が実ビルド/Support URL/Review Notesと一致するか確認 | 未 |
| 公開プロフィール、性別、活動エリア、評価、支払い方法要約の表示と、自己申告/非保証説明が実ビルド/Support URL/Review Notesと一致するか確認 | 未 |
| 支払い設定、銀行口座、PayPay対応可否、現金交換、金額指定、成立後支払い情報スナップショットが見えるか、Payment Info、合意後表示、保持、金融/決済サービス非関与、口座名義/本人性/支払能力/外部ID/送金リンク/QR非保証が実ビルド/Support URL/Review Notesと一致するか確認 | 未 |
| 退会申請、削除予定日、復旧/取消未保証、外部連携解除未確認の説明が実ビルド/Support URL/Review Notesと一致するか確認 | 未 |
| 現在地共有、服装写真、取引チャット写真の保存期間説明が、30日後自動削除又は完全削除保証ではなく、運用目標・反映遅延あり・例外保持ありとして一致するか確認 | 未 |
| 広告が見えるか、不適切/年齢不相応広告の通報導線があるか確認 | 未 |
| 配信地域、EU DSA trader status、IAP Availability、商品ページ表示連絡先を確認 | 未 |
| License AgreementがApple標準EULA又は照合済み独自EULAか確認 | 未 |
| スクショに実在IP/権利物がない | 未 |
| App Store説明文に実在IP/権利物がない | 未 |
| `ITSAppUsesNonExemptEncryption=false` とSDK構成が一致 | 未 |
| Kidsカテゴリを選ばない | 未 |
| Override to Higher Age Ratingの要否を判断 | 未 |
| App Store Connect入力値を `notes/36` に証跡保存 | 未 |

## 8. No-Go

- Kidsカテゴリを選ぶ。
- UGC/チャットが見えるのに、Age Ratingで該当機能を回答していない。
- 生年月日又は年齢表示があるのに、Age Rating、App Privacy、FAQ、Review Notesで自己申告年齢として説明していない。
- 年齢確認機構、保護者同意確認又は保護者管理機能が未実装なのに、年齢確認済み、保護者同意確認済み、本人確認済みと説明している。
- 性別、活動エリア、評価、支払い方法要約が見えるのに、法的性別確認、安全確認、支払能力確認、運営者推薦ではない説明がない。
- 支払い設定、銀行口座、PayPay対応可否、現金交換、金額指定又は成立後支払い情報スナップショットが見えるのに、Payment Info、金融/決済サービス非関与、口座名義確認/本人確認/支払能力確認/外部ID/送金リンク/QR真正性確認ではない説明がない。
- 評価コメント、通報、ブロック、モデレーションが見えるのに、緊急通報、本人確認、安全確認、信用保証、法的判断、削除保証ではない説明がない。
- 有料機能が見えるのに、Age Rating / IAP / Review Notesで整合していない。
- 手動有料権限上書きを、購入完了、返金確定、補償又は無償提供継続として説明している。
- 外部AIが見えるのに、OpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、削除可否、App Privacyや説明文と整合していない。
- 顔候補付け又は顔特徴量/画像特徴量保存が見えるのに、Sensitive Info回答、Face IDではない説明、削除/同意/保持、`member_face_profiles`読み取り範囲、学習データ追加可否の説明がない。
- Push通知が見えるのに、通知本文、未読バッジ、ロック画面表示、APNs/Expo token、App Privacy回答、アプリ内説明が一致していない。
- 近くのグルーム、スポット掲示板、現在地共有、待ち合わせ候補、現地交換モード、作成位置、閲覧者位置、地図表示、逆ジオコーディング、場所名又は距離表示が見えるのに、Precise Location回答、MapKit/CoreLocation/CLGeocoder等の外部処理、精密座標のサーバー送信/保存、作成位置、閲覧者位置、保持/削除例外、地図/距離/場所名の非保証、1km/3km非保証を説明していない。
- 退会申請の30日後実削除、申請取消/復旧、Apple/Google連携解除、APNs token無効化が未確認なのに、Support URL又はReview Notesで完了又は復旧を保証している。
- 現在地共有又は服装写真の30日後自動削除、完全削除、即時反映が未確認なのに、Support URL、Privacy Policy URL又はReview Notesで保証している。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、不適切又は年齢に合わない広告の通報導線、サポート説明、App Privacy回答、Google公式データ開示、ATT/Tracking回答、test ads除去、同意管理要否がない。
- 外部画像URL又はAI/検索候補画像が見えるのに、Content Rights、外部ホスト通信、権利確認責任、FAQ/Privacy説明が一致していない。
- 独自EULAを選ぶのに、Apple Minimum Terms、利用規約、公開URL、弁護士レビューの照合がない。
- 実在IP画像、公式画像、権利未確認素材をスクショに入れている。
- 実在IP、商標、公式名称が見えるのに、公式、公認、提携、代理、権利者承認、権利許諾、真贋確認又は取引可能性を意味しない説明がない。
- 初回Japan-only方針なのに、EU又はAll Countries or Regionsを含むAvailability、広すぎるIAP Availability、又は未確認のDSA trader statusで提出する。
- `ITSAppUsesNonExemptEncryption=false` なのに、独自暗号又は追加書類が必要なSDKが入っている。

## 9. 公式参照

- Apple Set an app age rating: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- Apple App Information reference: https://developer.apple.com/help/app-store-connect/reference/app-information
- Apple Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Apple Minimum Terms for Developer's EULA: https://www.apple.com/legal/internet-services/itunes/dev/minterms/
- Apple Overview of export compliance: https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- Apple Export compliance documentation for encryption: https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/
- App Store配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`
