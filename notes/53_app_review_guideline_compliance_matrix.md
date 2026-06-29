# 53. App Review Guideline 適合マトリクス

最終更新: 2026-06-29

ステータス: Draft v2.2（提出前・実機確認前、会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 手動有料権限・権限上書き / 運営通知・通知本文統制 / 公式連絡・フィッシング / 広告宣伝メール・販促通知 / App Store評価・公開レビュー返信 / UGC・App Review 1.2 / カスタムURL scheme・認証リダイレクト・ディープリンク / カメラ・写真ライブラリ・共有シート / ホーム候補・検索・レコメンド・Product Personalization / APNs主線・legacy Expo条件付き・Push通知4.5.4 / 精密位置・MapKit/CoreLocation・逆ジオコーディング / 公式非提携・権利物 / AdMob実設定・ATT・テスト広告No-Go / 外部AIシリーズ候補のOpenAI/web_search / 顔特徴量RLS・学習データ可否 / Sensitive Info / 広告通報論点を追加）

## 目的

Megrumの初回App Store提出前に、Apple App Review Guidelinesの主要論点を、Megrumの機能、証跡、No-Go、Review Notes説明へ紐づける。

この文書は審査適合チェック表であり、コード、DB、App Store Connect設定、公開ページは変更しない。

## 1. 使い方

1. 完成候補ビルドで `notes/42` のP0スモークテストを実施する。
2. App Privacy、公開URL、IAP、AI、削除、UGCの証跡を `notes/36` に残す。
3. この文書の各Guideline行について、Pass / Conditional Go / No-Goを記録する。
4. No-Goが残る場合は提出しない。
5. Conditional Goの場合は、該当機能を完全に隠し、App Store説明文、スクショ、Review Notesからも外す。

## 2. 最重要Guideline対応表

| Guideline | Apple側の主な観点 | Megrumで見るもの | 必要証跡 | No-Go |
|---|---|---|---|---|
| Before You Submit | クラッシュ、正確なメタデータ、連絡先、デモアカウント、backend稼働、Review Notes | P0スモークテスト、デモアカウント、公開URL、Review Notes | `notes/35`, `notes/36`, `notes/40`, `notes/42` | デモログイン不可、backend停止、説明不足 |
| 1.2 User-Generated Content | 不適切投稿のフィルタ、通報、対応、ブロック、公開連絡先。ランダム/匿名チャット、Chatroulette風体験、実在人物の外見評価、脅迫、いじめを主目的にしない | プロフィール、グッズ画像、グルーム、掲示板、取引チャット、証跡、評価コメント、顔が写る画像、削除申出 | 投稿前/投稿時の注意又は入力制限、通報入口、ブロック入口、問い合わせURL、運用SOP、評価コメント注意、削除申出の受付方針。画面内通報がない対象はsupport@フォールバック | UGCや評価コメントが見えるのに、投稿前/投稿時のフィルタ又は制限、通報、ブロック、連絡先、モデレーション説明がない。掲示板等でDB通報関数だけがありSwift画面導線又はsupport@フォールバックが説明できない。ランダム/匿名チャット、出会い、外見評価、脅迫、いじめ用途に見える。削除申出を7日以内削除、常時監視、申出どおり削除、発信者情報開示として過剰保証している |
| 1.4 Physical Harm | 身体的危険を招く機能や誘導を避ける | 現地交換、待ち合わせ、現在地共有、服装写真、地図/距離/場所名の誤差、危険誘導対応 | 安全注意、通報、取引チャット内対応、Review Notes、地図/距離/場所名の非保証説明 | 危険な合流を助長し、止める導線がない。地図、距離、場所名、現在地又は到着状況が正確又は安全保証であるように説明している |
| 1.5 Developer Information | アプリとSupport URLに連絡手段がある | `support@megrum.jp`, `/support`, アプリ内問い合わせ | URL 200応答、メール送受信、サポートテンプレ | Support URL不通、連絡先不明 |
| 1.6 Data Security | ユーザー情報の適切な保護、無断利用/開示/第三者アクセス防止 | Supabase、Storage、RLS、APNs token、通知本文、外部サービス、認証callback token、URL scheme、事故対応 | `notes/48`, `notes/49`, `notes/52`, `notes/54` | 他人データ表示、公開bucket、secret露出、通知本文の過剰露出疑い。認証callbackのaccess token/refresh token、認証コード、リンクを共有してよいように説明している |
| 2.1 App Completeness | 最終版、URL完全稼働、placeholderなし、実機安定、デモアカウント | P0全機能、URL、スクショ、IAP可視性、未完成機能非露出 | `notes/36`, `notes/42`, `notes/50` | クラッシュ、空画面、仮文言、未完成3D露出 |
| 2.3 Accurate Metadata | 説明、スクショ、Privacy情報が実体験を正確に反映 | App Store説明文、スクショ、Keywords、Review Notes、App Privacy、ホーム候補/検索/表示順/Plus優先表示/広告挿入、カメラ/写真/共有機能の説明 | `notes/31`, `notes/40`, `notes/43` | 出ない機能を宣伝、出る機能を説明しない。候補表示を本人確認済み、安全確認済み、信用保証、真贋確認済み、取引成立保証又は運営推薦に見せる。写真メタデータ又は外部共有後の扱いを誤説明する |
| 2.3.2 IAP Metadata | IAPがある場合、説明・スクショ・Previewで追加購入が分かる | メグルムプラス、Premium互換、めぐりPlus互換、ブースト、手動上書きとの区別 | `notes/33`, `notes/40` | 有料機能が見えるのに価格/商品/復元が不明。又は手動上書きを購入完了、返金確定、無償提供継続として説明している |
| 2.3.6 Age Rating | 年齢質問票を正直に回答 | UGC、チャット、位置情報、AI、IAP、権利物、生年月日/年齢表示、Age Assuranceなし | `notes/46` | UGC/チャット/年齢表示を過小回答、年齢確認済みと誤説明 |
| 2.5.18 Advertising | 広告を表示する場合、不適切又は年齢に合わない広告を報告できる。テスト広告やデモunit idを一般公開しない | AdMob、広告枠、広告通報、サポート導線、test ads除去 | `notes/25`, `notes/36`, `notes/56` | 広告が見えるのに広告通報導線がない。`MEGRUM_ADMOB_TEST_ADS_ENABLED=YES` やGoogleデモunit idのまま一般公開しようとしている |
| 3.1.1 In-App Purchase | アプリ内機能解放はIAP、復元、消耗/非消耗の扱い | メグルムプラス、Premium互換、めぐりPlus互換、ブースト、Stripe露出有無、手動有料権限上書き | IAP商品、Sandbox購入、復元、特商法、手動上書きの理由/期限/監査ログ | 外部決済でアプリ内機能解放、IAP未設定。手動上書きを購入証明、返金完了、補償又は無償提供継続として扱う |
| 3.1.3(e) Goods and Services Outside of the App / 3.2.2(viii) Financial Services | 物理的な商品・サービスの対価はIAPではなく外部購入方法を使う一方、金融取引・資金管理・暗号資産等は必要な許認可と説明が必要 | グッズ交換の差額、銀行振込、PayPay対応可否、現金交換、成立後支払い情報スナップショット、外部決済サービスの非検証 | 規約/Privacy/FAQ/Review Notes、Payment Info回答、画面コピー、サポートテンプレ | Megrumが決済代行、資金移動、収納代行、回収、返金、チャージバック、エスクロー、口座名義確認、本人確認、支払能力確認又は金融サービス事業者として振る舞う。外部サービスID、送金リンク、送金用QRの真正性を保証する |
| 3.1.2 Subscriptions | 継続価値、期間、価格、解約、復元、重複防止 | サブスクを出す場合のPremium/めぐりPlus | `notes/33`, `notes/45` | 解約案内なし、価格/期間不一致 |
| 4.2 Minimum Functionality | 単なるWebラッパーでなく、十分なアプリ機能がある | Swift Nativeの在庫、wish、打診、取引、通知、地図/カメラ | 実機スクショ、P0テスト | 主要体験が空、Web表示だけ |
| 4.5.4 Push Notifications | Push通知はアプリ機能の必須条件にせず、機微情報を送らず、販促通知は明示同意と停止手段を用意する | APNs token登録、通知許可、通知payload、アプリ内通知設定、ロック画面/通知センター/連携端末表示、運営通知、広告宣伝メール又は販促通知の同意/停止導線 | `notes/legal/01`, `notes/legal/02`, `notes/27`, `notes/43`, `notes/48`, `notes/56` | Push通知を許可しないと登録又は主要機能を使えない。正確な現在地、住所、銀行口座、認証コード、本人確認書類、通報/異議申し立て詳細本文をPush本文又は運営通知本文に入れる。販促Push又は広告宣伝メールに同意記録・停止手段・送信者情報・問い合わせ先がない。運営通知の全体送信に宛先/対象件数/本文/リンク先/送信理由の確認と監査ログがない |
| 4.8 Login Services | 第三者ログインを使う場合、同等のプライバシー配慮ログインが必要 | Appleログイン、Googleログイン、メールログイン、ASWebAuthenticationSession、OAuth中継、native callback scheme | 実装有無、Review Notes、削除時連携解除、redirect設定証跡 | GoogleだけでAppleログインなし。OAuth中継URL、callback scheme、Supabase/Google redirect設定が不一致 |
| 5.1.1 Privacy Policy | データ収集、利用、第三者、保持/削除、同意撤回/削除請求を明示 | Privacy URL、アプリ内Privacy導線、保持/削除表、評価/通報/ブロック/モデレーション記録、通知本文/ロック画面、認証callback/deep link、画像メタデータ、精密位置/MapKit/CoreLocation/逆ジオコーディング、外部AI送信、顔候補付け説明、検索ログ、候補表示、Product Personalization、Plus優先表示、手動有料権限上書き、AdMob/広告SDK送信 | `notes/legal/02`, `notes/25`, `notes/52` | Privacy URLなし、保持/削除説明なし、評価/通報/ブロック/モデレーション記録、通知本文、認証callback token/deep link、写真メタデータ、精密位置、検索語/人気検索/候補表示、手動有料権限上書き、OpenAI/web_search送信、顔特徴量又はAdMob広告SDK送信を説明しない |
| 5.1.1 Permission | データ収集の同意、目的文字列、同意撤回、不要権限を求めない | カメラ、写真ライブラリ、位置情報、通知、AI、分析、共有シート | Info.plist文言、アプリ内説明、App Privacy、Precise Location回答、Photos or Videos回答 | カメラ/写真ライブラリの権限文言が実用途より狭い。位置情報/通知を必須化して主要機能を塞ぐ。精密座標をサーバーへ送る導線があるのに、粗い地域だけ又は端末内処理だけとして説明している |
| 5.1.1 Data Minimization | コア機能に必要なデータだけ取得 | 生年月日/年齢表示、住所/電話番号、写真picker、位置共有の任意性 | `notes/27`, `notes/43`, `notes/52` | 生年月日収集の目的が説明不能、不要な住所/電話番号を求める |
| 5.1.1 Account Sign-In | 重要なアカウント機能がないならログインなし利用。作成ありならアプリ内削除 | Megrumは在庫、wish、取引、通報がアカウント依存。退会申請、削除予定日、保持対象、外部連携解除未確認を説明 | `notes/35`, `notes/45`, Review Notes | 削除入口なし、ログイン必須の理由が説明不能。30日後完了又は復旧を未確認のまま保証 |
| 5.1.2 Data Use and Sharing | 目的外利用、無断共有、追跡、広告利用を避ける | 外部AI、OpenAI Responses API、web_search、外部画像URL、共有シート、顔候補付け、検索ログ、Product Personalization、Plus優先表示、分析、広告、Map API、サポートツール、ATT/Tracking | `notes/27`, `notes/43`, `notes/48` | App Privacyで未申告の外部送信、検索語/候補表示/Plus優先表示/広告挿入、外部ホスト通信、外部共有後の非管理、AdMob送信又はSensitive Info未回答。IDFA/Tracking/PFPI/パーソナライズ/メディエーションをATT/同意なしで有効化。外部AIへ画像又は画像URLを送るのにOpenAI/web_search/保持/学習利用を説明していない |
| 5.2 Intellectual Property | 第三者権利物、商標、公式画像、公式/公認/提携/代理の誤認表示を避ける | スクショ、デモデータ、グッズ画像、外部画像URL、AI/検索候補画像、実在名称、商標、Keywords、Review Notes | `notes/28`, `notes/46`, `notes/55` | 公式画像、AI/検索候補画像、実在IPを権利確認なしに掲載。公式、公認、提携、権利者承認、真贋確認、取引可能性を誤認させる |
| 5.6 Developer Code of Conduct | Apple・ユーザーへの説明が正確。レビュー返信に個人情報、秘密情報、マーケティング、スパム、攻撃的表現を入れない | Resolution Center返信、レビュー返信、サポート返信、concern report | `notes/34`, `notes/41`, `notes/51`, `notes/74` | 断定できない事実を断定、個人情報や取引情報を返信に含める、評価変更依頼、値引き誘導、公開返信で相手会員処分や内部ログを書く |

## 3. Megrum固有の審査説明メモ

### 3.1 ログイン必須の説明

Megrumは、在庫、wish、打診、取引チャット、通報、ブロック、評価、アカウント削除がユーザーIDに強く紐づくため、主要機能はアカウントベースである。

Review Notesでは次を説明する。
- 審査用デモアカウントを提供する。
- アカウントは、ユーザー間の取引安全、通報、ブロック、削除請求、取引履歴確認に必要。
- アカウント削除はアプリ内設定から開始できる。削除予定日は処理予定の目安であり、保持対象や外部連携解除の未確認事項は公開Support/Privacyと一致させる。

外部認証、メール認証又はパスワードリセットを出す場合:
- `MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Supabase Redirect URLs、Google OAuth redirect、Web中継Route、App Store Review Notesを同じbuildの値へ合わせる。
- Review Notesでは、Google OAuthは公式Web中継URLから開始し、native callback schemeへ戻ること、メールcallbackは公式ドメインを経由することを説明する。
- 認証callback fragmentにはsession tokenが入り得るため、FAQ/Privacy/アプリ内コピーでは、認証リンク、パスワードリセットリンク、認証コード、callback URL、スクリーンショットを共有しないよう案内する。
- custom URL schemeはOS/端末/外部ブラウザ/メールアプリ/インストール済みアプリに依存するため、Universal Linksや本人確認済みリンクと同等の安全保証をしない。

### 3.2 UGCの説明

Review Notesでは次を短く説明する。
- UGC領域はプロフィール、グッズ画像、グルーム、掲示板、取引チャット、証跡、評価コメント。
- UGCと会員間連絡はアカウントベースで、推し活グッズ交換と関連する情報共有のための機能であり、ランダム/匿名チャット、Chatroulette風体験、出会い、性的接触、実在人物の外見評価、脅迫、いじめを主目的とする機能ではない。
- 不適切投稿を防ぐため、投稿前/投稿時の注意、入力制限、投稿頻度制限、URL/画像/添付形式/アカウント状態/通報履歴/NGワード等に基づくフィルタリング、自動検知、手動確認、投稿保留又は投稿拒否のどれを実ビルドで使っているかを確認し、Review Notesには実装済みの範囲だけを書く。
- 不適切コンテンツは通報できる。
- 迷惑ユーザーはブロックできる。
- `support@megrum.jp` と `/support` で連絡できる。
- 運営側で通報確認と非表示/制限対応を行う。
- 評価、通報、ブロック、モデレーションは緊急通報、法的判断、本人確認、安全確認、信用保証、削除/解決保証ではない。
- 権利侵害、名誉毀損、プライバシー侵害等の削除申出はサポート又はアプリ内通報で受け付けるが、法令上必要な場合を除き、一定期間内の回答、申出どおりの削除、発信者情報開示、常時監視を保証しない。

提出前No-Go:
- 投稿前/投稿時の不適切コンテンツ対策、通報、ブロック、公開連絡先が実ビルドで説明できない状態で、グルーム、掲示板、取引チャット、評価コメントなどのUGCを露出する。
- Review Notesに、未実装のフィルタ、自動検知、即時対応、全件監視、全件削除保証を書く。
- めぐり又は掲示板をランダム/匿名チャット、出会い、外見評価、脅迫、いじめ用途に見せるスクショ、説明、デモデータを入れる。

### 3.3 現地交換の安全説明

Review Notesでは次を必要に応じて説明する。
- Megrumはユーザー同士の現地交換を補助する。
- 現在地共有と服装写真は任意。
- 近くのグルーム/スポット掲示板、地図表示、投稿/返信範囲判定又は逆ジオコーディングを出す場合、精密な緯度経度を扱い得ること、位置/距離/場所名は補助情報で正確性や安全を保証しないことを説明する。
- 危険・個人情報露出・規約違反は通報できる。
- 運営者は取引当事者ではないが、安全対応と規約違反対応を行う。

### 3.4 有料機能の説明

初回で有料機能を隠す場合:
- App Store説明文、スクショ、Review Notesから有料機能の訴求を削る。
- IAP商品を同時提出しない。
- 画面にPremium/ブースト導線が出ない証跡を残す。

出す場合:
- IAP商品、価格、復元、権限付与、特商法、App Privacyを揃える。
- Review Notesに購入経路とSandbox確認方法を書く。
- サポート又は運営による手動有料権限上書きは、購入証明、返金確定、補償又は無償提供継続ではなく、理由、期限、対象確認、変更前後、監査ログを持つ運用上の暫定・補正手段として説明する。

### 3.5 AI機能の説明

初回で外部AIを隠す場合:
- 外部AI送信ボタン、説明、スクショ、Review Notesから該当機能を外す。

出す場合:
- 送信情報、送信先、OpenAI等外部AI名、画像又は画像URL、web search利用、利用目的、保存期間、削除可否、学習利用有無、濫用監視ログ、ユーザー確認責任を明示する。
- AI出力をユーザーが確認・修正できる証跡を残す。
- App Privacyとプライバシーポリシーに反映する。
- 第三者の顔、未成年者、住所、チケット、注文履歴、QRコード、秘密情報、権利未処理画像を送らない注意を送信前に出す。

### 3.6 顔候補付けの説明

顔候補付けを出す場合:
- Review Notesでは、グッズ画像からメンバー/キャラクター候補を提示する補助機能であり、Face ID、本人確認、年齢確認、出入場管理、信用判断ではないことを説明する。
- 実ビルドで顔特徴量又は画像特徴量を生成・保存・照合する場合、App PrivacyのSensitive Info / biometric data相当を回答候補に上げる。
- プライバシーポリシー、サポートページ、保持/削除マトリクスに、利用目的、保存、削除、外部送信有無、同意記録、`member_face_profiles` のembedding/source image URL読み取り範囲、補正履歴の学習データ追加可否を反映する。
- 第三者の顔写真、未成年者の写真、権利者許可のない画像を登録しない注意喚起を出す。

### 3.7 外部画像URLとContent Rightsの説明

外部画像URL又はAI/検索候補画像を出す場合:
- Review Notes又は公開サポートでは、候補画像や名称は参考情報であり、公式情報、権利者承認、権利確認済み素材ではないことを説明する。
- プライバシーポリシーでは、外部画像ホスト/CDNへIP、端末/アプリ通信情報、アクセス時刻等が送信される可能性を説明する。
- スクショ、デモデータ、App Storeメタデータに、実在IP、公式画像、商標ロゴ、権利未確認素材を含めない。
- ユーザーが登録する画像URLについて、利用規約で必要な権利・権限の保有と権利侵害時の責任を明示する。
- 実在のアーティスト名、グループ名、メンバー名、作品名、キャラクター名、商品名、商標等を検索、分類、識別又は説明の参考として表示する場合も、Megrumが権利者、所属事務所、興行主、販売者又は公式ファンクラブの公式、公認、提携又は代理サービスではないこと、承認、協賛、権利許諾、真贋確認又は取引可能性を意味しないことを説明する。

### 3.8 写真メタデータの説明

写真アップロードを出す場合:
- 写真ライブラリから読み込んだ元データを保存する経路では、EXIF、撮影日時、GPS位置情報、端末情報などの画像メタデータが残る可能性を確認する。
- カメラ撮影画像がJPEG再生成される経路があっても、全端末、全OS、全画像処理、全外部共有先でメタデータ削除を保証できるものとして説明しない。
- `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` が、グッズ、プロフィール、取引チャット、服装写真、証跡、グルーム、掲示板、AI又は顔候補付け用途と矛盾しないか確認する。
- 共有シートで外部アプリへ生成画像又は共有文を渡す場合、共有後の保存、公開範囲、再共有、削除、広告利用、アクセス解析、メタデータ利用をMegrumが管理しないことを説明する。
- プライバシーポリシー、FAQ、アプリ内注意文に、写り込みだけでなく画像メタデータの確認を説明する。
- App Privacyでは、Photos or Videosに加え、GPS位置情報又は端末情報が画像ファイル内で収集される場合のLocation / Device Info回答要否を確認する。

### 3.9 広告表示の説明

広告を出す場合:
- Review Notes又は公開サポートで、不適切又は年齢に合わない広告を通報できることを説明する。
- アプリ内又はサポート導線で、表示画面、表示日時、広告のスクリーンショットを添えて報告できるようにする。
- App Privacy、プライバシーポリシー、広告SDK台帳で、広告識別子、広告リクエスト、広告表示/クリック、トラッキング有無を実ビルドと照合する。
- `MEGRUM_ADS_ENABLED`、`MEGRUM_ADMOB_TEST_ADS_ENABLED`、Googleデモunit id、production unit id、SDK初期化条件、ATT/Tracking、UMP等の同意管理要否を提出前に証跡化する。

### 3.10 通知本文 / ロック画面

Push通知を出す場合:
- APNs又はExpo Pushへ送信されるpayloadは、通知タイトル、本文、通知ID、リンク先、未読バッジ、soundを含むため、Device IDだけでなくUser Content / Usage Dataの影響を確認する。
- 現行Swift Nativeでは、取引チャット本文の短縮プレビュー、写真共有、服装写真共有、現在地共有、到着状況、証跡、評価、キャンセル要請等の概要が通知bodyに入り得る。グルーム、めぐりメッセージ、スポット掲示板系で本文を入れない場合でも、通知タイトルだけで相手、行動又は文脈が推測される。
- 通知本文には必要最小限の概要だけを入れ、正確な位置、住所、銀行口座、内部ID、不要な個人情報、通報や異議申し立ての詳細本文を出さない。
- 管理者画面又はサーバー側処理から作成する運営通知は、全有効会員、一部会員又は特定会員に送られ、通知タイトル、本文、リンク先がAPNs payloadやアプリ内通知に反映され得る。全体送信では宛先区分、対象件数、本文、リンク先、送信理由、監査ログを確認する。
- ロック画面、通知センター、連携端末、OS通知プレビューで見える内容について、Privacy Policy、FAQ、アプリ内コピー、Review Notesが矛盾しないようにする。
- Push通知を許可しないと登録できない、又は主要機能を使えない設計にしない。プロモーション、キャンペーン、広告宣伝又は直接マーケティング目的のPush、メール、アプリ内通知は、明示的同意、同意記録、送信者情報、問い合わせ先、配信停止又は通知設定変更手段を用意する。
- 取引、安全、認証、課金、規約変更、法令対応の必要連絡と、広告宣伝メール又は販促通知の同意/停止を混同させない。停止後も必要連絡が残ることをFAQ、アプリ内コピー、Privacyで説明する。

### 3.11 未成年 / 生年月日 / 年齢表示の説明

生年月日又は年齢表示を出す場合:
- Review Notesや公開FAQでは、生年月日は自己申告であり、公的年齢確認、身分証確認、保護者同意確認又は本人確認が完了したことを意味しないと整理する。
- 未成年者は親権者その他法定代理人の同意を得る前提とし、現地交換、位置情報、服装写真、郵送先情報、会員間支払い情報、取引チャットについては保護者相談・同伴推奨と安全上の制限可能性を説明する。
- Age Ratingでは、UGC、チャット、位置情報、広告、IAP、Age Assuranceなし、Parental Controlsなしの回答が実ビルドと一致するか確認する。

### 3.12 ホーム候補 / 検索 / レコメンドの説明

ホーム候補、検索結果、マッチ/条件一致ラベル、検索候補、人気検索、表示順、レコメンド、Product Personalization、Plus優先表示又は広告挿入を出す場合:
- Review NotesとFAQでは、候補表示がプロフィール、在庫、wish、個別条件、タグ、交換方法、活動エリア、位置又は日程設定、支払い方法要約、評価、完了取引数、ブロック関係、通知状態、有料権限等に基づく参考表示であることを説明する。
- 「マッチしてるよ！」「交換できるかも？」「全一致」等は、本人性、安全性、信用、所有権、真贋、支払い、発送、現地合流、条件一致又は取引成立の保証ではないことを明示する。
- 検索ログ又は人気検索を有効にする場合、検索語、`normalized_term`、`result_count`、検索時刻、30日集計等をSearch History / Usage Data / Product PersonalizationとしてApp Privacy候補に上げる。
- メグルムプラス優先表示や広告挿入がある場合、organic結果、広告、スポンサー/広告表示、Plus優先表示がユーザーを誤認させない証跡を残す。

## 4. Guideline別提出前チェック

| ID | Guideline | 判定 | 証跡 | 担当 |
|---|---|---|---|---|
| AG-001 | Before You Submit | TODO | TODO | TODO |
| AG-002 | 1.2 UGC | TODO | TODO | TODO |
| AG-003 | 1.5 Developer Information | TODO | TODO | TODO |
| AG-004 | 1.6 Data Security | TODO | TODO | TODO |
| AG-005 | 2.1 App Completeness | TODO | TODO | TODO |
| AG-006 | 2.3 Metadata | TODO | TODO | TODO |
| AG-007 | 2.3.6 Age Rating | TODO | TODO | TODO |
| AG-008 | 2.5.18 Advertising report | TODO | TODO | TODO |
| AG-009 | 3.1.1 IAP | TODO | TODO | TODO |
| AG-010 | 4.2 Minimum Functionality | TODO | TODO | TODO |
| AG-011 | 4.8 Login Services | TODO | TODO | TODO |
| AG-012 | 5.1.1 Privacy Policy | TODO | TODO | TODO |
| AG-013 | 5.1.1 Permission | TODO | TODO | TODO |
| AG-014 | 5.1.1 Account Sign-In / Deletion | TODO | TODO | TODO |
| AG-015 | 5.1.2 Data Use and Sharing | TODO | TODO | TODO |
| AG-016 | 5.1.2 Sensitive Info / Face candidate data | TODO | TODO | TODO |
| AG-017 | 5.2 Intellectual Property | TODO | TODO | TODO |
| AG-018 | 5.6 Conduct / Review Responses | TODO | TODO | TODO |
| AG-019 | 2.3 / 5.1.1 Home/Search/Product Personalization | TODO | TODO | TODO |
| AG-020 | 2.3 / 5.1.1 Camera/Photos/Share Sheet | TODO | TODO | TODO |
| AG-021 | 3.1.3(e) / 3.2.2(viii) Member Payment Boundary | TODO | TODO | TODO |

## 5. No-Go

- Appleの主要Guidelineに対して証跡がなく、Review Notesで説明もできない。
- UGCが見えるのに、通報、ブロック、公開連絡先がない。
- 評価コメント、通報、ブロック、モデレーションが見えるのに、緊急通報、法的判断、本人確認、安全確認、信用保証、削除/解決保証ではない説明がない。
- 通報者情報を絶対非開示と保証している、又はブロックで過去取引、チャット、証跡、評価、通報記録が当然に削除されるように説明している。
- アカウント作成があるのにアプリ内削除入口がない。
- 有料機能が見えるのにIAP、価格、復元、特商法、App Privacyが揃っていない。
- 支払い方法、銀行口座、口座名義、PayPay対応可否、現金交換、金額指定又は成立後支払い情報スナップショットが見えるのに、Payment Info回答、合意後表示、保持、相手保存リスク、目的外利用禁止、金融/決済サービス非関与、口座名義/本人性/支払能力/外部ID/送金リンク/QR非保証の説明がない。
- App Store説明文、Review Notes、FAQ、画面コピー又はサポート返信で、Megrumが資金移動業、収納代行、決済代行、回収代行、返金窓口、チャージバック窓口、エスクロー、金融機関、資金管理サービス、暗号資産交換又は投資/貸付/債権回収サービスであるように見える。
- App Store公開レビュー又は開発者返信で、個人情報、取引情報、認証情報、金融機関情報、証跡URL、スクリーンショット、内部ログ、相手会員への措置、返金/補償断定、評価変更依頼、値引き誘導、マーケティング又は攻撃的表現を出す。
- Review Notes、公開レビュー返信、FAQ、サポート返信、アプリ内コピー、広告又はキャンペーン文面で、Megrum公式がパスワード、認証コード、認証リンク、金融機関ログイン情報、暗証番号、クレジットカード番号、送金用QRコード、送金リンク、外部決済サービスIDを求めるように読める。
- 外部AIが見えるのにOpenAI等の送信先、画像又は画像URL、web search、保持、学習利用、濫用監視ログ、削除可否、説明、同意又は任意性、Privacy回答がない。
- プッシュ通知が見えるのに、APNs/Expo token、通知本文、未読バッジ、ロック画面表示、App Privacy回答、アプリ内説明が一致していない。
- Push通知を許可しないと登録又は主要機能を使えない、機微情報をPush本文又は運営通知本文へ出す、又は販促Push/広告宣伝メールに同意記録、停止手段、送信者情報、問い合わせ先がない。
- 運営通知を全体送信できるのに、宛先区分、対象件数、本文、リンク先、送信理由、監査ログ、誤送信時のIncident手順を説明できない。
- 顔候補付け、顔特徴量又は画像特徴量の保存/照合が見えるのにSensitive Info回答、Face IDではない説明、削除/保持/同意、`member_face_profiles`読み取り範囲、学習データ追加可否の説明がない。
- 広告が見える、又はAdMob SDKが初期化/広告リクエストするのに、不適切又は年齢に合わない広告の通報導線、サポート説明、Google公式データ開示、ATT/Tracking回答、test ads除去の証跡がない。
- App Store説明文、スクショ、Review Notesに実ビルドと違う機能がある。
- ホーム候補、検索結果、「マッチしてるよ！」「交換できるかも？」「全一致」等が見えるのに、参考表示であり本人性、安全性、信用、所有権、真贋、支払い、発送、現地合流又は取引成立を保証しない説明がない。
- 検索語、`normalized_term`、`result_count`、検索時刻、人気検索、検索候補、表示順、Plus優先表示、広告挿入又はProduct Personalizationが有効なのに、App Privacy、Privacy、FAQ、Review Notesへ反映していない。
- カメラ/写真ライブラリの権限文言が実用途より狭い、写真ライブラリ由来のEXIF/GPS/撮影日時/端末情報が残る経路を確認していない、又は共有シート/外部SNS共有後の保存・公開・再共有・削除非管理を説明していない。
- 生年月日又は年齢表示があるのに、App Privacy、Age Rating、FAQ、Review Notesで自己申告年齢として説明していない。
- 年齢確認機構、身分証確認、保護者同意確認又は保護者管理機能が未実装なのに、年齢確認済み、本人確認済み、保護者同意確認済みと説明している。
- Privacy URL、Support URL、問い合わせ先が不通。
- 実在IP、公式画像、実住所、内部ID、デバッグ表示をスクショに含める。
- 実在IP、商標、公式名称、AI/検索候補、外部画像URLが見えるのに、公式/公認/提携/代理ではない説明、権利確認責任、真贋非保証、取引可否非保証がない。
- 近くのグルーム、スポット掲示板、現在地共有、位置情報メッセージ、地図表示又は逆ジオコーディングが見えるのに、Precise Location回答、MapKit/CoreLocation/CLGeocoder等のOS・地図関連処理、精密座標のサーバー送信/保存、保持/削除例外、地図・距離・場所名の非保証がない。

## 6. 関連文書

- App Store提出パック: `notes/24_app_store_submission_pack.md`
- Trust & Safety SOP: `notes/26_trust_safety_release_sop.md`
- App Privacyデータインベントリ: `notes/27_app_privacy_data_inventory.md`
- スクショ台本: `notes/28_app_store_screenshot_storyboard.md`
- App Store Connect入力表: `notes/31_app_store_connect_metadata_worksheet.md`
- IAP商品設定: `notes/33_iap_product_setup_worksheet.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- App Review指摘対応テンプレート: `notes/41_app_review_response_templates.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- 提出前セキュリティ監査チェックリスト: `notes/54_prelaunch_security_audit_checklist.md`
- アカウント削除・個人情報請求: `notes/45_account_deletion_privacy_request_runbook.md`
- App Store質問票回答シート: `notes/46_app_store_questionnaire_answer_sheet.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- 提出後・公開初日ランブック: `notes/51_post_submission_release_day_runbook.md`

## 7. 公式参照

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Apple Minimum Terms for Developer's EULA: https://www.apple.com/legal/internet-services/itunes/dev/minterms/
- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- 財務省関東財務局 資金移動業関係: https://lfb.mof.go.jp/kantou/kinyuu/pagekt_cnt_20250516001sikinidou.html
- 金融庁 令和7年資金決済法改正に係る政令の公布及びパブリックコメントの結果等: https://www.fsa.go.jp/news/r7/sonota/20260522/20260522.html
