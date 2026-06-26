# 22. Swift Native Migration

最終更新: 2026-06-27
ステータス: Active（iter1220）

## 目的

MegrumはiOS一本で勝つ方針に切り替え済み。これ以降のユーザー向けiOS体験は、Swift / SwiftUI / UIKit / Apple標準フレームワークを正とする。Expo / React Native版、旧JSX mockup、旧画面案素材は iter1214 で削除済みのため、通常作業では参照元・rollback線として扱わない。

## 参照した外部方針

- npaka「Codex のiOSアプリ開発のためのプロンプトまとめ」
- OpenAI Developers「Native development」
- Apple Developer「Adopting Liquid Glass」
- Apple Developer「Applying Liquid Glass to custom views」
- OpenAI Developers内の Native development collection に含まれる方針:
  - SwiftUI app shell はCLI-firstの小さな `xcodebuild` ループで作る
  - 大きなSwiftUI画面はMV firstで小さなViewへ分割する
  - Liquid Glassは監査してから高頻度フローへ限定導入し、古いOS向けfallbackを持つ
  - iOS Simulatorではアクセシビリティ階層・スクリーンショット・ログ・スタックを使って検証する

## バックアップ

Swift全面移行前の復元点を作成済み。

- Git backup branch: `backup/pre-swift-migration-20260531-030401`
- Backup base commit: `590c8834ea59de233ac3cf644f14d5f45cd433de`
- Local backup directory: `/Users/michitaka/Desktop/Megrum_backups/pre-swift-migration-20260531-030401`
- Local backup contents:
  - `HEAD.txt`
  - `current-branch.txt`
  - `git-status-short.txt`
  - `tracked-worktree.patch`
  - `staged.patch`
  - `untracked-files.tgz`
  - `untracked-files.zlist`

復元の基本手順:

```bash
git switch backup/pre-swift-migration-20260531-030401
git switch -c restore/pre-swift-migration
git apply /Users/michitaka/Desktop/Megrum_backups/pre-swift-migration-20260531-030401/tracked-worktree.patch
tar -xzf /Users/michitaka/Desktop/Megrum_backups/pre-swift-migration-20260531-030401/untracked-files.tgz
```

## 移行方針

### 1. Swift Nativeを単独主線にする

- `ios-native/` をユーザー向けiOSアプリの主作業場にする。
- `mobile/` は削除済み。Expo / EAS / OTA前提の運用は現在の対象外。
- 旧mockupの見た目へ戻すのではなく、Swift Nativeの実装とiOS標準体験を正とする。
- 最終段階で、App Store Connectの本番Bundle IDへSwift版を接続する。

### 2. Swift版の技術方針

- Minimum target: iOS 17以上を基本線にする。
- iOS 26以上ではLiquid GlassのネイティブAPIを優先する。
- iOS 17/18/旧実行環境では `Material` / UIKit standard material / 独自最小fallbackで可読性を維持する。
- UIはSwiftUIを主軸にし、カメラ・写真・地図・通知・共有・購入・権限などは必要に応じてUIKit / Apple frameworkを直接使う。
- Swift Native版のデザインは、legacy Expo版の見た目を完全再現することを目的にしない。オーナーの実機レビューでは、Swift版のiOS標準感を維持し、最終デザインも無理に旧アプリへ寄せ戻さない方針で確定した。
- Megrumらしい色・余白・情報設計は継承するが、操作部品、シート、ナビゲーション、カメラ、地図、通知、設定画面はApple標準の自然な挙動と質感を優先する。
- アーキテクチャはMV firstを基本にする。不要なMVVMや巨大ViewModelを増やさない。
- 共有状態は `@Observable` / `@State` / `@Environment` を優先し、非同期処理はSwift Concurrencyで整理する。
- 画面が直接fixtureを読む構造にしない。`MegrumAppState` と `MegrumRepository` を通し、Supabase接続へ差し替えられる境界を保つ。

### 3. MegrumでSwift化の恩恵が大きい領域

優先度高:

1. ホーム / 検索 / Liquid Glass操作レイヤー
2. グルーム閲覧・投稿・MapKit表示
3. 取引チャット、画像拡大、証跡撮影、通報導線
4. 在庫 / Wish / 個別募集の高密度グリッドと長押しメニュー
5. 左ドロワー、タブバー、階層ナビゲーション
6. 通知、設定、ブロック、評価一覧

### 4. Supabase / DBは当面維持する

- DBスキーマとRLSは既存Supabaseを継続する。
- Swift版はまず `MegrumData` の薄いPostgREST clientで同じデータを読む。必要性が明確になった段階でSupabase Swift SDK導入を判断する。
- DB変更はSwift移行そのものとは分ける。画面移行中にスキーマまで同時に壊さない。

## 実装フェーズ

### Phase 0: Native foundation

- `ios-native/` にSwift Packageを追加する。
- `MegrumCore` に状態名・主要モデル・ドメイン型を置く。
- `MegrumDesign` に色、タイポグラフィ、Liquid Glass primitiveを置く。
- `swift build` / `swift test` でCLI-first検証を作る。Codex Desktop上ではSwiftPMのbuild databaseが不安定になる場合があるため、testは `/tmp` のscratch pathを使う。

### Phase 1: App shell

- `ios-native/MegrumNative.xcodeproj` と `App/MegrumNativeApp.swift` でSwiftUI App hostを追加済み。
- Swift Package側では `MegrumApp` にRootView、TabView、主要タブ画面の骨格を置く。
- `MegrumAppState` と `MegrumRepository` で初期データロード境界を追加済み。
- `MegrumData` にSupabase設定とPostgRESTリクエスト境界を追加済み。環境/Info.plistに公開設定とviewer idがあればlive repository、なければpreview repositoryにfallbackする。
- iter355で、Xcode targetが `Config/MegrumNative.xcconfig` を読み込むようにし、gitignoreされた `MegrumNative.local.xcconfig` からSupabase URL、publishable key、viewer id、メール認証redirect URLを安全に注入できるようにした。未設定または未解決のbuild setting placeholderはPreview dataへfallbackする。
- Bundle IDは最初は比較用Previewを分け、最終的に本番IDへ寄せる。
- TabView / NavigationStack / deep link / auth restore / app lifecycleを組む。

### Phase 2: Auth and account

- 新規登録、ログイン、メールリンク復帰、プロフィール、推し設定、住所設定をSwift化する。
- キーボード回避、フォームvalidation、権限説明をiOS標準で作る。
- iter304で、Swift側に `AuthUser` / `AuthSession`、Supabase Auth client、`MegrumAuthState`、メール/パスワードのログイン・登録画面を追加した。
- iter305で、`AuthSessionStore`、`KeychainAuthSessionStore`、`InMemoryAuthSessionStore` を追加し、Swift版がログインsessionを保存・復元できる境界を持った。
- iter306で、保存済みまたはログイン直後の `AuthSession` を `MegrumAppStateFactory.repository(authSession:)` に渡し、session access tokenとuser idを `SupabaseMegrumRepository` へ反映できるようにした。
- iter307で、Supabase Authの新規登録成功後に `public.users` のMegrumプロフィール行をupsertする `SupabaseAccountClient` を追加した。
- iter308で、`users.account_status` を `AccountStatus` としてSwift型化し、`registered / verified / onboarding` のユーザーを初回プロフィール設定画面へ分岐できるようにした。
- iter309で、`OshiKind` / `OshiGroup` / `OshiCharacter` / `UserOshiSelection` と `SupabaseOshiClient` を追加し、`groups_master` と `characters_master` をSwift側から読める境界を作った。
- iter310で、初回プロフィール設定画面に推しグループ/メンバー選択を追加し、`user_oshi` を差し替え保存してから `users.account_status='active'` へ進めるようにした。
- iter1220で、認証後オンボーディングを Welcome / 推し設定 / 活動エリア / 名前 / ユーザーID / 生年月日 / 性別 / 完了の8ステップへ分割した。推し設定はL1マスタ選択から入り、メンバー選択が必要なL1だけL2選択画面を表示する。完了時は `handle` / `display_name` / `primary_area` / `birth_date` / `age` / `gender` / `user_oshi` / `account_status='active'` を保存する。
- iter311で、設定一覧と住所設定フォームを追加し、`user_mailing_addresses` をSwift側から取得/upsertできる境界を作った。
- iter312で、郵便番号7桁入力からzipcloud公式APIで住所候補を取得し、住所設定フォームへ反映する境界を追加した。
- iter313で、Supabase redirect URLのquery / fragmentからsession tokenを復元し、SwiftUI `.onOpenURL` でアプリへ反映する境界を追加した。
- iter314で、設定一覧に「ブロックした人」を追加し、`groom_user_blocks` の一覧取得と解除をSwift版へ移植した。
- iter315で、設定一覧に通知入口と未読バッジを追加し、`notifications` の一覧取得・既読化・大分類遷移をSwift版へ移植した。
- iter337で、設定一覧にモバイル通知の標準Toggleを追加し、`user_notification_settings.push_enabled` の読み込み/upsert境界をSwift版へ移植した。
- iter376で、ホーム左上の自分アイコンから開く左ドロワーをNative overlayへ戻し、プロフィール、通知、住所設定、ブロックした人、設定とプライバシー、ログアウトへ遷移できる導線を優先実装した。
- iter376で、Preview用local xcconfigにSupabase URL / publishable key / auth redirect URLを注入し、実機Debug installでも未ログイン時に新規登録・ログイン画面へ入れる状態へ寄せた。
- iter376で、ログアウト時はAPNs device token revokeを試みてからSupabase Auth sessionを破棄する流れへ接続した。
- iter377で、設定一覧にヘルプ、利用規約、プライバシーポリシー、アカウント概要の下層導線を追加し、左ドロワー配下の設定項目を触れる範囲を広げた。
- iter377で、メール/パスワード認証の入力validation、password reset、メール確認待ちsign-up成功表示、古いfeedbackのclear、keyboard dismissを補強した。
- iter377で、プロフィール編集時に既存 `user_oshi` を読み込み、推し設定の編集画面が空状態から始まらないようにした。
- iter378で、ホーム画面へ `MegrumAppState` を直接渡し、左ドロワーから触る現地交換モードや持参候補が共通状態を確実に参照するようにした。
- iter379で、ログアウト時にremote sign outが失敗してもlocal sessionとsession storeを破棄し、Previewでも自動再ログインせず認証画面へ戻れるようにした。保存済みsession復元失敗時も再ログイン導線へ寄せた。
- iter379で、左ドロワーの主要遷移先をプロフィール、通知、住所設定、ブロックした人、設定とプライバシーへ整理し、項目タップ後に対象画面へ遷移するようにした。
- iter379で、設定一覧にセキュリティ/プライバシー、ヘルプ、法的文書、アカウント概要、住所、通知、ブロック、ログアウトの入口を整理し、住所入力のkeyboard toolbarも補強した。
- iter379で、自分プロフィール編集を `users` PATCHへ接続し、表示名、ハンドル、アイコンURL、性別、都道府県を保存できるようにした。
- iter380で、初回プロフィール設定/プロフィール編集の保存完了alert、推し選択UIのアクセシビリティlabel/hint、設定/ヘルプ配下の利用規約・プライバシーポリシー・特定商取引法に基づく表記入口、アカウント概要のID/status表示を追加した。
- iter381で、左ドロワーに「推し設定」を追加し、初回設定と同じNative選択画面を編集モードで開けるようにした。ドロワー項目は閉じるアニメーション後に遷移するようにし、閉じている途中の誤反応を減らした。
- iter402で、推し設定画面をReact Native版に近い編集体験へ拡張した。グループごとの推しメンバーchip、`+ 追加` からのメンバー候補表示、左下固定の「推しを追加」、ジャンル別L1マスタ分類、推し追加リクエストをSwift Nativeへ接続した。
- iter402で、`swift build` / 推し関連テスト / 実機向け `xcodebuild` は成功した。iPhoneへのinstallはCoreDevice上で端末が `unavailable` のため、端末復帰待ち。
- iter409で、推し設定画面からメンバー追加リクエスト導線を削除し、各グループ内の `+ 追加` からマスタ上の追加可能メンバーだけを選ぶ仕様へ寄せた。メンバーchipと追加候補chipはRN版の密度に近づくよう小型化した。
- iter381で、通知一覧を共有 `NotificationCenterScreen` に統一し、`linkPath` からホーム、在庫、Wish、やりとり、めぐり、相手プロフィール、評価一覧へ進む `NotificationRouteIntent` を追加した。
- iter382で、左端スワイプから左ドロワーを開けるNative gesture layerを追加し、ドロワー項目選択後の遷移を次run loopへ逃がして「閉じるだけで遷移しない」不安定さを減らした。
- iter382で、設定のログイン/セキュリティ画面へ現在の `MegrumAuthState` を渡し、メール、Auth user ID、profile ID、設定状態、account status、パスワード再設定、ログアウトが実セッションを見るようにした。
- iter338で、Swift Native iOS版のAPNs device tokenを `notification_devices.push_provider='apns'` / `native_device_token` へupsertする境界を追加した。APNs実配送は後続で接続する。
- iter339で、XcodeアプリホストにiOS標準の通知許可リクエスト、APNs登録、device tokenをAppStateへ渡すdelegate bridgeを追加した。
- iter340で、端末通知タップ時の `linkPath` を既存通知一覧と同じ規則でNativeタブへ変換し、該当カテゴリへ移れるbridgeを追加した。
- iter341で、Xcode targetに `App/MegrumNative.entitlements` を接続し、Debugはdevelopment、ReleaseはproductionのAPNs entitlementを使えるようにした。
- iter342で、ログアウト時に登録済みAPNs device tokenの `revoked_at` を更新する境界と設定画面のログアウト導線を追加した。
- iter343で、SwiftUI標準の `SignInWithAppleButton`、nonce生成、Supabase Authの `grant_type=id_token` 境界、Sign in with Apple entitlementを追加した。
- iter344で、`send-apns-notification` Supabase Edge Functionを追加し、信頼済みサーバー側呼び出しからAPNsへ通知を配送できる入口を作った。DBトリガー直結は秘密情報の置き場を確定してから接続する。
- iter345で、`notifications` insert後のDB triggerから、DB設定値が揃っている場合だけ `send-apns-notification` Edge Functionを呼ぶようにした。dispatch secretはmigrationに書かず、プロジェクト設定で注入する。
- iter365で、TestFlight前提のSwift Native App設定を並列実装バッチで見直し、明示的なInfo.plist、URL scheme、権限文言、Privacy Manifest、Team ID、Release/Debug設定を整理した。
- iter366で、AppIcon asset catalogを追加してXcode targetへ接続し、TestFlight upload validation前のAppIcon不足を解消した。
- iter366で、カメラ利用文言を証跡撮影とグルーム投稿の両方に合わせて更新した。
- iter366で、APNs device token upsertのconflict targetをDB側の通常unique indexと一致させ、Preview Supabase DBへ未適用migrationを反映した。
- iter367で、認証フォームのdisabled状態、入力正規化、ハンドル名validation、Supabase error表示を補強した。live設定がない場合はAppleログインボタンを無効化し、preview fallback時の誤操作を減らした。
- iter367で、Google OAuth authorize URL / request builderを追加し、UI接続前にrequest生成をテストできるようにした。
- iter369で、Googleログインボタンを `ASWebAuthenticationSession` へ接続し、Supabase OAuth callbackを既存redirect復元境界へ渡せるようにした。
- iter370で、OAuth callback schemeを `MEGRUM_URL_SCHEME` build settingから導出するようにし、Apple / Googleなどの外部ID Provider error stateを汎用名へ整理した。
- iter371で、初回設定と設定後の推し設定を共通化し、複数グループ/複数メンバーの推し選択、自分プロフィール概要、設定一覧からのプロフィール/推し設定導線を追加した。
- 現時点のAuthはメール/パスワード、Appleログイン、Googleログインの最小導線まで追加済み。Google側のProvider設定と実機callback許可はSupabase/Apple側の設定確認が残る。

### Phase 3: Exchange core

- ホーム、検索、在庫、Wish、個別募集、打診、取引チャットをSwift化する。
- 取引の状態名は `notes/09_state_machines.md` と完全一致させる。
- iter316で、在庫/Wish共通グリッドにタップ詳細シートとiOS標準の長押しアクションメニューを追加した。各アクションのDB接続は、該当フローSwift化時に接続する。
- iter317で、在庫/Wish一覧に3/4/5列切り替えアイコンと左下の追加ボタン土台を追加した。追加フォーム本体は次のSwift化対象として残す。
- iter318で、`goods_types_master` 読み込みと `goods_inventory` 作成境界を追加し、在庫/Wishの左下追加ボタンからNative sheetで最小登録できるようにした。
- iter319で、在庫/Wish一覧にグループとグッズ種別のNative filter chipsを追加し、マスタ読み込み済みの一覧を端末内で絞り込めるようにした。
- iter320で、検索画面をSwift Nativeの `goods_inventory` 検索境界につなぎ、結果を「マッチしてるよ！」「交換できるかも？」「マッチなし」に分類して表示できるようにした。
- iter321で、`proposals` の読み込み/作成境界をSwift Nativeへ追加し、検索結果から打診作成sheetを開いて最小proposalを作れるようにした。
- iter322で、やりとり画面を「打診中」「進行中」に分け、フッター上のNative切り替えバーと横スワイプ切り替え、取引詳細sheetを追加した。
- iter323で、`messages` の読み込み/送信境界をSwift Nativeへ追加し、取引詳細sheetでNativeの取引チャットを表示・送信できるようにした。
- iter346で、検索結果やホームの相手所有グッズから相手プロフィールを開き、評価サマリから評価一覧へ進めるSwift Native導線と公開RPC境界を追加した。
- iter347で、Swift Nativeの取引詳細sheetから `chat-photos` への証跡写真追加、`proposal_evidence_photos` 追記、`proposals.approved_by_*` 承認、`status='completed'` 遷移、`user_evaluations` 投稿までの最小完了フローを追加した。
- iter348で、証跡写真追加をPhotosPickerだけでなくiOSカメラ起動に接続し、Native app targetへ `NSCameraUsageDescription` を追加した。
- iter349で、グルーム追加も共通のiOSカメラ起動に接続し、写真ライブラリ選択をfallback導線として残した。
- iter350で、取引チャットの写真メッセージと証跡写真をタップで全画面表示できるNative画像ビューアへ接続した。
- iter351で、取引詳細sheetの右上からSwift Nativeの通報sheetを開き、既存 `disputes` テーブルへ `submitted` の申告を作成できる境界を追加した。受付後は取引チャットにsystem messageを残す。
- iter352で、在庫/Wishグリッドの長押しメニューから本人所有グッズを `status='archived'` にする非表示処理と、本人所有行の削除処理を `goods_inventory` へ接続した。
- iter353で、他ユーザー所有グッズの長押しメニューからSwift Nativeの通報sheetを開き、新規 `goods_reports` テーブルへグッズ単位の通報を保存できる境界を追加した。
- iter356で、Swift Native版の個別募集モデル、`listings` / `listing_wish_options` の読み書き境界、AppState状態、Wishタブ内の「Wish / 個別募集」切り替えと作成sheetを追加した。
- iter357で、Wish一覧の自分のアイテムを長押しして「これで個別募集する」から作成sheetへ進める導線を追加した。対象Wishは作成sheetの「受け取る」側へ最初から選択される。
- iter358で、相手プロフィールに「譲る候補 / 個別募集」のNative segmented controlを追加し、相手の公開グッズや個別募集から打診作成sheetへ進める導線を接続した。個別募集起点の打診では既存 `proposals.listing_id` を保持する。
- iter359で、Swift Native版の取引詳細から届いた打診を「この内容で承諾」または「断る」導線へ接続した。`proposals.agreed_by_sender` / `agreed_by_receiver` を読み書きし、両者合意で `agreed`、片側合意で `agreement_one_side`、断る場合は `rejected` へ進める。
- iter360で、`exchange_method='both'` の打診を承諾する時に、Native segmented pickerで `hand` または `mail` を選ばせ、その選択値を `proposals.exchange_method` へPATCHしてから合意へ進めるようにした。
- iter361で、取引詳細の返答パネルから「条件を変えて再打診」を開けるようにした。元 Proposal を直接変更せず、参加者視点で提示物を反転コピーし、Native sheetで交換手段・交換条件タグ・メッセージを調整した `status='negotiating'` の新しい打診を作成する。再打診作成者は自分の条件に合意済みとして `agreed_by_sender=true` にする。
- iter362で、取引チャットのメッセージ入力欄の上からも同じ再打診sheetを開けるようにした。再打診は `sent` / `negotiating` / `agreement_one_side` のProposalに限定し、Swift版のiOS標準デザイン感を最終方針として維持する。
- iter363で、取引チャットのメッセージ入力欄上に「スケジュール」ボタンを追加し、Native sheetで自分と相手の予定を週（5日）/月で確認できるようにした。`schedules` テーブルの `place_name` を含む読み込み境界も追加し、旧Expo版の見た目ではなくSwiftUI標準のsheet / segmented picker / materialで表示する。
- iter365で、並列実装バッチとして、打診作成sheetの `listing_id` 保持、`ProposalMeetupInput` による現地系打診validation、在庫/Wishグリッドのローディング/空状態/長押し操作、検索/相手プロフィール/個別募集起点の打診導線、取引返答・拒否・証跡承認のRPC化をまとめて補強した。
- iter365で、Supabase migration `20260531013000_harden_proposal_response_rpc.sql` を追加し、`respond_to_proposal_for_viewer` と `approve_trade_evidence_for_viewer` で行ロックしながら合意・拒否・完了・在庫/個別募集更新を行う方針へ寄せた。
- iter366で、Swift Nativeの打診作成sheetから `hand` / `both` を送れるように待ち合わせ候補入力を追加し、有効な `ProposalMeetupInput` を送信payloadへ含めるようにした。
- iter366で、完了RPCを再定義し、双方承認時に数量減算、受け取り側keep作成、譲渡履歴作成、個別募集closed化を同一トランザクションで行うようにした。
- iter367で、検索画面の下部フィルター導線を検索前から使えるようにし、グループ選択後だけメンバーとグッズタグ候補を表示するNative sheetへ整理した。現地交換日付は複数日、現地交換場所は都道府県として選択できる。
- iter367で、取引チャットの入力欄を `safeAreaInset` に寄せ、スケジュール、再打診、通報などを入力欄上のメニューへ整理した。写真、位置情報、system、到着状態のメッセージrequest builderも追加した。
- iter367で、取引チャットの共有写真ビューアをピンチズーム、ズーム中ドラッグ、ダブルタップリセットに対応させた。
- iter368で、検索の `GoodsSearchInput` に `memberID` を追加し、`goods_inventory.character_id` をlive requestへ渡せるようにした。Preview repositoryとテストも同じ条件に揃えた。
- iter368で、検索フィルターのグッズ種別とグッズタグを分離し、グループ未選択時はメンバーとグッズタグ候補を非表示にした。グッズタグ候補は最大20件まで表示する。
- iter369で、在庫/Wishグリッドの列数・spacing・スケルトン数を共有する `GoodsGridLayout` にまとめ、3/4/5列切り替え、空状態、長押しメニュー、数量バッジ、アクセシビリティを補強した。
- iter369で、取引チャット系request境界を補強し、位置情報message、到着状態meta、写真message type validation、申告memo validation、証跡承認/評価送信validationを追加した。
- iter370で、取引チャット入力欄上に到着ステータス、現在地共有、服装写真共有のNative affordanceを追加した。到着ステータスは既存text message境界で送信し、typed location / arrival messageのAppState接続は後続で実装する。
- iter371で、検索結果/相手プロフィールからの打診作成を専用 `ProposalCreateFlow` に置き換え、「私が出す」「受け取る」「待ち合わせ」「確認」の段階で複数提示物と現地/郵送/どちらもOKを扱えるようにした。
- iter371で、取引チャットの現在地共有と到着ステータスをAppState/repositoryへ接続し、`messages.location_lat/location_lng/location_label` と `meta.status` を使うtyped messageとして送れるようにした。
- iter372で、ホームに現地交換モードカードと編集sheetを追加し、会場/現在地、時間枠、半径、持参グッズ概要を表示できるようにした。現時点では端末内保存で、Supabase AW接続は後続対象。
- iter372で、在庫/WishのNative編集画面を追加し、タイトル、種別、グループ、メンバー、グッズ種別、数量、ステータス、タグ、写真選択入口をまとめた。保存境界未接続の項目は保存前に明示して、黙って欠落させない。
- iter372で、打診送信後に完了画面を表示し、送信後に入力ステップへ戻りにくい構造へ寄せた。
- iter372で、遅刻/キャンセルの連絡を異議申告ではなく取引チャットのsystem messageとして送る境界へ整理した。
- iter372で、異議詳細、タイムライン、返信、取り下げ、遅刻/キャンセルdraftのNative scaffoldを追加した。取引詳細からの本接続と実データ接続は後続対象。
- iter373で、取引チャットの服装写真共有を `PhotosPicker` から `chat-photos` Storage upload、署名URL作成、`messages.message_type='outfit_photo'` 作成まで接続した。
- iter373で、在庫/Wish編集向けに `goods_inventory` の本人所有PATCH境界とrequest testsを追加した。編集画面からの呼び出し接続は後続対象。
- iter373で、異議詳細のload、異議返信、取り下げPATCHのlive境界とrequest testsを追加した。scaffold画面からの呼び出し接続は後続対象。
- iter375で、在庫/Wish編集画面から `updateGoodsEntry` を呼び、本人所有 `goods_inventory` PATCH境界へ接続した。既存画像・既存タグは保存blockerにせず、変更されたタグと新規ローカル写真だけを後続対象として明示する。
- iter375で、在庫/Wish作成payloadに `character_id` と `status` を含め、新規登録時にもメンバー/状態を落とさないようにした。
- iter375で、異議詳細画面をload/reply/withdrawの非同期storeへ拡張し、live repositoryへ接続できる画面状態へ進めた。取引詳細からのrouting接続は後続対象。
- iter375で、`activity_windows` と `user_local_mode_settings` のSwift Data境界を追加した。Home現地交換モード/AW UIからの本接続は後続対象。
- iter375で、遅刻、キャンセル申請、キャンセル承認などの取引チャットsystem messageをRN互換metadataで作るrequest境界を追加した。入力欄上メニューからのtyped接続と表示デザイン調整は後続対象。
- iter376で、在庫/Wish作成・編集時のローカル写真を `goods-photos` storageへアップロードし、返却URLを `goods_inventory.photo_urls` へ保存する流れへ接続した。HEICなどは可能な範囲でJPEGへ変換し、対応済み画像形式はcontent typeを維持する。
- iter376で、`attach_inventory_tag` / `detach_inventory_tag` RPCと `goods_inventory_tags` 読み込みをSwift Data境界へ追加し、作成・検索・公開在庫読み込み・更新でタグを保持できるようにした。
- iter377で、個別募集編集をNative Formから `listings` PATCH と `listing_wish_options` PATCH/insertへ接続し、画面内だけでなくSupabaseへ保存される境界まで進めた。
- iter377で、ホーム現地交換モードの持参候補が相手グッズではなく自分の在庫を優先するように修正した。
- iter378で、在庫/Wish保存失敗時に入力・タグ・選択写真を保持し、再試行または写真を外して保存できる復帰UIを追加した。
- iter378で、取引チャットの遅刻連絡とキャンセル申請を `messages.meta.action` 付きのtyped system messageとしてAppState / repository / Supabase message clientへ接続した。
- iter378で、異議詳細の役割別アクション、証跡表示、反論時の `disputes` 更新をlive Data境界へ追加した。
- iter379で、在庫/Wish編集画面に既存写真/選択済み写真のpreview、画像読み込み中/失敗時fallback、10MB超過の保存前validationを追加し、失敗後も入力内容・タグ・選択写真を保持したまま再試行できるようにした。
- iter379で、`goods-photos` uploadのContent-Type正規化、空/未対応/過大ファイルのrequest validation、グリッド/詳細の画像fallbackを補強した。
- iter379で、ホーム現地交換モード、打診作成カレンダー/マップ、取引詳細の当日/異議系表示、送信後導線の統合分を取り込んだ。
- iter380で、ホーム現地交換モードON時にiOS位置情報を取得し、座標を `activity_windows.center_lat/lng` と `user_local_mode_settings.last_location_lat/lng` へ保存/復元する境界まで接続した。
- iter380で、打診作成の待ち合わせ候補を最大3件まで追加/選択/削除できるdraftへ拡張し、MapKit上で選んだ座標を候補へ反映できるようにした。
- iter380で、取引チャットの服装写真共有を `NativeCameraCaptureView` に接続し、カメラ直撮りから `messages.message_type='outfit_photo'` の写真送信へ進める入口を追加した。到着状態/現在地共有/system messageのpresentationも整理した。
- iter381で、グッズ編集/追加画面でもiOSカメラ直撮りをローカル写真アップロードdraftへ追加できるようにした。写真ライブラリ選択、validation、保存復帰の既存経路は維持する。
- iter381で、取引チャット内の相手からのキャンセル申請に対し、「キャンセルに同意する」CTAを表示し、`proposals.status='cancelled'` と承認system message作成まで接続した。自分が出した申請や承認済みの申請ではCTAを出さない。
- iter381で、Swift Nativeホーム用の `SupabaseHomeClient` を追加し、RN版のmatch/possible候補に近いlive data request境界を用意した。AppState/Home UIへの本接続は次の優先対象として残す。
- iter382で、自分プロフィール編集のプロフィール画像を写真ライブラリ/カメラ/削除から扱えるようにし、`profile-photos` Storage upload と `users.avatar_url` 更新をlive repositoryへ接続した。Supabase側のbucket/RLS確認は残る。
- iter382で、`SupabaseHomeClient` をAppState/Home UIへ本接続し、`HomeCandidateComposer` で相手在庫、viewer wish、相手wish/個別募集候補から「マッチしてるよ！」「交換できるかも？」をcomposeするようにした。live data失敗時は既存fallbackを維持する。
- iter382で、在庫/Wish一覧に集計chip、読み込み状態、context別空表示、remote image fallbackを追加し、3/4/5列切替や長押し操作は維持した。
- iter382で、やりとり一覧を「打診中」「進行中」「完了済み」の3分類に拡張し、完了済み取引を進行中から分離した。
- iter392で、Wish取得に `photo_urls` / `quantity` を通し、Wish一覧でも登録画像を表示するようにした。
- iter392で、在庫取得に `kind,status` を通し、「譲る候補」「自分用キープ」「過去に譲った」の3タブへ分類した。
- iter392で、グッズ画像を明示frame + clipで描画し、ホーム/在庫/Wishの縦横比違い画像が枠外へはみ出さないようにした。
- iter392で、やりとり一覧の受け取る/私が出す欄に実グッズ画像サムネイルを表示するようにした。
- iter392で、左ドロワーの推し設定を専用Native画面へ分け、登録済み推し、グループ検索、メンバー選択、箱推し、保存導線をReact Native版の情報設計に近づけた。
- iter392で、ホーム現地交換モードのユーザー向け表示から旧AW表記を外し、現在地取得後の逆ジオコーディングで建物名または住所を表示できるようにした。
- iter395で、保存済みの旧座標テキストもユーザー向けには表示せず、保存済み座標から住所/施設名の再解決を試みるようにした。
- iter409で、ホームの「マッチしてるよ！」パネルから関係図sheetを開き、対象グッズ、相手個別募集、自分個別募集、「私が出す」「受け取る」候補を選んで打診作成へ進めるSwift Native導線を追加した。関係図で選んだ自分の提示物は `ProposalCreateFlow` の初期選択へ引き継ぐ。
- iter409で、関係図の候補抽出・個別募集条件からの提示物推定・fallbackを `MatchRelationScreenTests` で検証し、`swift build` とSimulator向け `xcodebuild` を通した。
- iter410で、Swift Native打診作成の複数待ち合わせ候補を `ProposalCreateInput.meetupCandidates` から `proposals.meetup_candidates` へ保存するpayloadへ拡張した。主候補は既存 `meetup_*` 5列へミラーし、JSON側はRN版互換の `startAt/endAt/placeName/lat/lng/mode` 形を保つ。
- iter411で、関係図をRN版 `match-detail` と同じ「個別募集の中で候補を選ぶ」構造へ修正した。自分/相手の個別募集を一つ選ぶUIを廃止し、wish候補・譲る候補の選択を集計して打診へ進む。
- iter412で、RN版 `proposal-select` / `proposal-confirm` をサブエージェント監査から日本語仕様整理し、Swift Nativeの提示物選択/送信内容確認へ反映した。相手から受け取る候補を相手の公開在庫から選択できるようにし、私が出す/受け取る双方のフィルター、交換手段による待ち合わせタブ出し分け、確認画面の交換条件タグ/住所確認、関係図起点の初期ステップを整理した。
- iter413で、ホーム/関係図起点の `match_type` 引き継ぎ、確認画面の `expose_calendar`、住所未登録時の住所設定導線、送信完了後の `打診一覧に飛ぶ` / `まだ他に探す` 導線、受け取る候補未選択時の送信ブロックを追加した。

### Phase 4: Meguri core

- グルーム、グルームマップ、スポット掲示板、掲示板マップ、めぐりメッセージをSwift化する。
- MapKit、PhotosUI、AVFoundation、UserNotificationsをネイティブに使う。
- iter324で、`list_groom_feed_nearby` と `list_meguri_board_threads_for_viewer` を呼ぶSwift Native RPC境界を追加し、めぐりホームが `MegrumAppState` 経由でグルーム/掲示板を再読込できるようにした。
- iter325で、掲示板スレッド詳細、返信一覧、返信送信のSwift Native RPC境界を追加し、めぐりホームからチャット形式の掲示板詳細へ進めるようにした。
- iter326で、めぐりホームの「地図で見る」からグルーム/掲示板のMapKit画面を開き、ピンと範囲円を表示できるようにした。
- iter327で、CoreLocation境界と位置情報利用文言を追加し、めぐりのfeed再読込とMapKit初期中心を現在地に寄せられるようにした。
- iter328で、グルーム横並びから全画面ビューアを開き、画像読み込み中はローディングだけを表示するNative閲覧導線を追加した。
- iter329で、めぐりホーム右下の「スレッドを立てる」からNative composer sheetを開き、`meguri_board_threads` へ作成できるPostgREST insert境界を追加した。
- iter330で、掲示板の3km圏内/都道府県表示をNative画面で切り替えられるようにし、プロフィール都道府県を初期値にしながら変更後の都道府県を `AppStorage` へ保存する導線を追加した。
- iter331で、Supabase Storageのアップロード/署名URL境界と `groom_posts` 作成境界を追加し、めぐりホームのグルーム横並びからPhotosPickerで投稿できる最小Native導線を追加した。
- iter332で、`groom_views` と `groom_reactions` のSwift Native更新境界を追加し、グルーム全画面ビューアから閲覧済み登録といいね/取り消しを行えるようにした。
- iter333で、`groom_replies` 作成と `notifications.kind='groom_reply'` のSwift Native境界を追加し、グルーム全画面ビューアから返信を送れるようにした。
- iter334で、`list_meguri_messages_for_viewer` RPCと `meguri_messages` text insert境界をSwift Nativeに追加し、めぐりメッセージをAppStateで読み書きできるようにした。
- iter335で、Swift Native通知一覧から `groom_reply` / `meguri_message` のリンクを解釈し、相手別のめぐりメッセージ画面へpushして送信できる最小導線を追加した。
- iter336で、めぐりメッセージ会話を開いた時に受信メッセージの `read_at` を更新するSwift Native既読化境界を追加した。
- iter365で、位置情報拒否/未許可/許可後の表示、MapKit初期中心と範囲円、カメラ不可端末、グルーム画像読み込み失敗、掲示板返信送信時の座標引き継ぎを補強した。
- iter366で、グルーム画像のsigned URL作成に失敗してもpath-only rowをfeedから落とさず、UIが回復可能に扱える相対URLとして保持するようにした。
- iter367で、めぐり掲示板詳細の余分なヘッダー/操作群を減らし、スレッド本文を開始メッセージ、返信をチャット風の吹き出しとして表示する方向へ整理した。
- iter367で、グルームマップのstatus表示を現在地から1km範囲の確認用途に寄せた。範囲外ピンの完全な閲覧制御は、distance/canViewを返すRPC拡張と合わせて後続で詰める。
- iter368で、Previewの掲示板scopeを分離し、都道府県表示に3km圏内スレッドが混ざらないようにした。
- iter368で、グルームマップ上の1km圏外グルームをタップした時は詳細を開かず、範囲外で見られない旨を表示するようにした。liveで1km外ピンを含めて表示するには、feed RPC側が全件または周辺広域とcanViewを返す拡張が必要。
- iter369で、グルーム/掲示板mapの初期cameraを現在地の範囲円とpinが収まるように調整し、範囲外グルームpinのロック表示を追加した。
- iter369で、掲示板詳細をチャット寄りに整理し、Lazy stack、最新返信へのscroll、interactive keyboard dismissal、safe-area composerを追加した。掲示板RPC requestもscopeに応じて緯度経度または都道府県だけを送るようにした。
- iter370で、ホーム用グルームfeedとマップ用グルームfeedを分離し、Swift Nativeのグルームマップは3km圏内のpinを取得できる `loadGroomMapPosts` を使うようにした。通常feedは1km上限のまま維持する。
- iter370で、Preview Supabaseの `list_groom_feed_nearby` server-side clampを3kmへ広げるmigrationを適用し、liveでもマップ用広域pinを取得できる条件を整えた。

### Phase 5: Cutover

- Swift版PreviewをTestFlight配布する。
- 既存RN版との画面・機能差分をチェックリスト化する。
- App Store提出前に、Bundle ID、Associated Domains、通知、権限文言、Privacy Manifest、規約リンクを最終確認する。
- iter365で、RN parity / QAのread-only監査を実施し、Swift版に残るP0/P1差分を「TestFlightで見るべき通しシナリオ」として統合役が保持する運用にした。
- iter367で、Swift Native PreviewのBuildを `2` に更新し、`ITSAppUsesNonExemptEncryption=false` をInfo.plistへ追加した。
- iter367で、`MTO’s phone` 向けに署名付きDebugビルドを作成し、`tokyo.megrum.native.preview` を直接インストールできることを確認した。端末ロック中のため自動launchはOSに拒否されたが、インストール自体は成功済み。
- iter368で、前回更新と今回更新を含めた署名付きDebugビルドを `MTO’s phone` へ再インストールし、`tokyo.megrum.native.preview` の起動まで確認した。
- iter369で、並列実装バッチの更新を含む署名付きDebugビルドを `MTO’s phone` へ再インストールし、`tokyo.megrum.native.preview` の起動まで確認した。
- iter370で、署名付きiPhone向けDebugビルドまでは成功した。`MTO’s phone` はUSB上に見えているがCoreDevice/Xcode上で `available=false` のため、自動installは端末ロック解除・接続復帰待ち。
- iter371で、RN parity backlogのP0から自分プロフィール/推し設定、打診作成、取引チャット当日アクションを先に実装した。Home/AW、在庫/Wish編集、異議/遅刻/キャンセル詳細は引き続きP0として残る。
- iter371で、`swift build` / `swift test` 202件 / `xcodebuild` Simulator build / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` はCoreDeviceで `unavailable` のため、自動installは端末接続復帰待ち。
- iter372で、RN parity backlogのP0からHome現地交換モード、在庫/Wish編集画面、打診送信後完了画面、取引チャットの遅刻/キャンセル連絡、異議詳細scaffoldを追加した。
- iter372で、`swift build` / `swift test` 222件 / `xcodebuild` Simulator build / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` はCoreDeviceで `unavailable` のため、自動installは未完了。
- iter373で、RN parity backlogのP0から取引チャット服装写真共有、在庫/Wish編集PATCH境界、異議詳細live境界を追加した。
- iter373で、`swift build` / `swift test` 236件 / `xcodebuild` Simulator build / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` はCoreDeviceで `unavailable` のため、自動installは未完了。
- iter375で、RN parity backlogのP0から在庫/Wish編集画面の保存接続、在庫/Wish作成payloadのメンバー/status保持、異議詳細画面のlive-ready化、AW Data境界、取引チャット運用系system message境界を追加した。
- iter375で、`swift build` / `swift test` 262件 / `xcodebuild` Simulator build / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` はCoreDeviceで `unavailable` のため、自動installは端末接続復帰待ち。
- iter376で、左ドロワー/設定/ログアウト/Auth実環境接続、在庫/Wish写真アップロード、タグ保存境界を優先補強した。
- iter376で、`swift build` / `swift test` 276件 / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` へのinstallも成功した。自動launchのみ端末ロック中のためOSに拒否された。
- iter377で、左ドロワー配下設定、認証入力、プロフィール編集、個別募集編集、現地交換モード持参候補を優先補強した。
- iter377で、`swift build` / `swift test` 299件 / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` への上書きinstallと自動launchまで成功した。
- iter378で、優先P0としてホーム状態注入、在庫/Wish保存失敗復帰、遅刻/キャンセルtyped message、異議詳細live actionを補強した。
- iter378で、`swift build` / `swift test` 316件 / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` への上書きinstallは成功し、自動launchのみ端末ロック中のためOSに拒否された。
- iter379で、左ドロワー/設定、ログアウト/Auth復帰、自分プロフィール保存、在庫/Wish写真編集/アップロード復帰、ホーム/打診/取引の統合分を優先補強した。
- iter379で、`swift build` / `swift test` 344件 / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` への上書きinstallも成功した。
- iter380で、現地交換モードの位置保存、打診待ち合わせ候補/地図選択、取引チャットのカメラ直撮り入口、初回設定/設定/法的文書入口を優先補強した。
- iter380で、`swift build` / `swift test` 355件 / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` はCoreDeviceで `unavailable` のため、自動installは端末接続復帰待ち。
- iter381で、左ドロワー/設定/通知/推し設定、グッズ編集カメラdraft、キャンセル申請承認、ホーム用request境界を優先補強した。
- iter381で、`swift build` / `swift test` 372件 / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` はCoreDeviceで `unavailable` のため、自動installは端末接続復帰待ち。
- iter382で、左ドロワーedge swipe、設定ログイン/セキュリティ、自分プロフィール画像upload、ホーム候補live data接続、在庫/Wish表示、やりとり完了済み分類を優先補強した。
- iter382で、`swift build` / `swift test` 386件 / 署名付きiPhone向けDebug build は成功した。`MTO’s phone` はUSB interfaceとして検出されるがCoreDeviceで `available=false` / `tunnelState=unavailable` のため、自動installは端末接続復帰待ち。
- iter392で、Wish画像、やりとり一覧画像、在庫3分類、推し設定専用画面、現地交換モードの現在地表示、iPhone実機インストールまでを優先補強した。
- iter392で、`swift build` / 対象 `swift test` 90件 / 署名付きiPhone向けDebug build が成功した。`MTO’s phone` への上書きinstallと自動launchまで成功した。
- iter395で、現地交換モードの保存済み旧座標テキストを数字表示しないようにし、`MTO’s phone` への上書きinstallと自動launchまで成功した。
- iter412で、RN仕様へ寄せた提示物選択/送信内容確認の更新を含む署名付きDebugビルドを `MTO’s phone` へ上書きinstallした。自動launchのみ端末ロック中のためOSに拒否された。

## RN parity backlog（iter370監査 / iter380更新）

画面上の不足が多く見えるというオーナー指摘を受け、React Native版とSwift Native版のread-only差分監査を実施した。Swift版はiOS標準感を維持しつつ、以下の順に不足機能を埋める。

### P0

1. Home / Local Mode / Current Location
   - iter372で、ホームに現地交換モード、会場/現在地、半径、時間枠、持参グッズ概要、LIVE/OFF/終了表示のNative入口を追加した。
   - iter375で、`activity_windows` と `user_local_mode_settings` のData境界を追加した。
   - iter377で、現地交換モードの持参候補は自分の在庫を優先して表示するようにした。
   - iter380で、現地交換モードON時の現在地座標を取得し、内部のActivity Window centerとlocal mode last locationへ保存/復元するUI/AppState/repository境界を接続した。
   - iter382で、ホーム実データのマッチ候補compositionを `SupabaseHomeClient` / `HomeCandidateComposer` / AppStateへ接続した。
   - iter392で、ユーザー向け表示を現地交換モード/現在地の更新に寄せ、現在地座標は建物名または住所へ解決して表示するようにした。
   - iter395で、旧保存値の `現在地 34...` 形式も非表示化し、住所解決中/未解決時は数字ではない文言で表示するようにした。
   - 残: 相手から見える現地交換モードの表示確認、ホーム上のグルーム導線整理。
   - 主な対象: `ios-native/Sources/MegrumApp/HomeScreen.swift`, `ios-native/Sources/MegrumApp/MegrumAppState.swift`
2. Inventory / Wish Creation and Editing
   - iter372で、在庫/WishのNative編集画面を追加し、写真選択入口、タグ、メンバー、status、数量などの入力UIを先に載せた。
   - iter373で、`goods_inventory` の本人所有PATCH境界とrequest testsを追加した。
   - iter375で、編集画面からPATCH境界を呼ぶ接続と、作成時のメンバー/status保持を追加した。
   - iter376で、写真Uploadとタグjoin table保存をlive repositoryへ接続した。
   - iter378で、保存失敗時に入力・タグ・写真を保持し、再試行または写真を外して保存できるUIを追加した。
   - iter379で、既存/選択写真preview、画像fallback、10MB超過validation、Content-Type正規化を追加した。
   - 残: 複数カード切り抜き、Storage/RLS実機データでの権限確認。
   - 主な対象: `ios-native/Sources/MegrumApp/CollectionScreens.swift`, 新規 `GoodsEditorScreen.swift`
3. Proposal Creation / Confirm
   - iter371で専用 `ProposalCreateFlow` を追加し、譲る/受け取る/待ち合わせ/確認、複数提示物、現地/郵送/どちらもOKの入口は実装済み。
   - iter372で送信完了画面を追加し、送信後に入力ステップへ戻りにくい構造へ寄せた。
   - iter377で、個別募集の編集保存を `listings` / `listing_wish_options` のlive repositoryへ接続した。
   - iter379で、打診作成カレンダー/マップの統合分と、viewer/partner両方の予定を含むテストを取り込んだ。
   - iter380で、待ち合わせ候補を最大3件まで持てるdraft、候補追加/選択/削除、MapKit座標選択、スケジュール場所候補の重複排除を追加した。
   - iter410で、複数待ち合わせ候補をDBへそのまま保存するpayload拡張を追加した。
   - iter411で、関係図からの打診起点をRN版同様に候補選択型へ修正し、複数個別募集を単一 `listingID` へ無理に丸めない集計へ寄せた。
   - iter412で、`proposal-select` / `proposal-confirm` をRN版から仕様整理し、相手在庫からの受け取り候補選択、私が出す/受け取るのフィルター、交換手段別タブ、確認画面の交換条件タグ/住所確認、関係図起点の初期ステップを補強した。
   - iter413で、`match_type` / `expose_calendar` / 送信完了後導線 / 住所未登録導線 / 受け取る候補必須validationを補強した。
   - 残: liveスケジュール背景の密度調整、複数個別募集を完全に保持するDB/API拡張、相手条件の送信直前再検証。
   - 主な対象: `ios-native/Sources/MegrumApp/ProposalCreateFlow.swift`, `ios-native/Sources/MegrumApp/SearchScreen.swift`, `ios-native/Sources/MegrumApp/PublicUserProfileScreen.swift`
4. Trade Chat Day-Of Actions
   - iter371で現在地共有と到着ステータスはtyped messageとして接続済み。
   - iter372で遅刻/キャンセル相談を取引チャット内のsystem messageとして送る導線を追加した。
   - iter373で服装写真共有を `PhotosPicker` から取引チャット写真メッセージ送信まで接続した。
   - iter375で、遅刻/キャンセル申請/キャンセル承認のRN互換metadata request境界を追加した。
   - iter378で、入力欄上メニューからの遅刻連絡/キャンセル申請をtyped system messageへ接続した。
   - iter379で、取引詳細の当日/異議系表示の統合分を取り込んだ。
   - iter380で、服装写真共有のカメラ直撮り入口と、到着状態/現在地共有/system messageのpresentation調整を追加した。
   - 残: キャンセル申請を相手が承認して取引をキャンセルへ進める導線。
   - 主な対象: `ios-native/Sources/MegrumApp/TradesScreen.swift`, `ios-native/Sources/MegrumData/SupabaseMessageClient.swift`
5. Dispute / Cancel / Late Flow
   - iter372で異議詳細、返信、タイムライン、取り下げ、キャンセル/遅刻draftのNative scaffoldを追加した。
   - iter373で `disputes` のload、`dispute_messages` の返信作成、取り下げPATCHのlive境界とrequest testsを追加した。
   - iter375で、異議詳細画面をload/reply/withdraw非同期storeへ拡張した。
   - iter378で、viewer role別アクション、証跡表示、反論時の `disputes.status/respondent_response/respondent_responded_at` 更新を追加した。
   - 残: 取引詳細からのrouting、取引詳細へのbanner反映。
   - 主な対象: `ios-native/Sources/MegrumApp/TradesScreen.swift`, 新規 `DisputeDetailScreen.swift`
6. Onboarding / Own Profile
   - iter371で複数推し/メンバー、自分プロフィール、設定からのプロフィール/推し設定導線は追加済み。
   - iter376で、左ドロワーからプロフィール、通知、住所設定、ブロック、設定とプライバシー、ログアウトへ入る基本導線を実機反映した。
   - iter377で、設定内のヘルプ/法的文書/アカウント概要の下層画面と、プロフィール編集時の推し設定復元を追加した。
   - iter379で、ログアウト/Auth復帰、左ドロワー項目遷移、設定一覧、自分プロフィール保存、性別保存を補強した。
   - iter380で、初回設定/プロフィール編集の完了alert、推し選択のアクセシビリティ、法的文書入口、アカウント概要のID/status表示を追加した。
   - iter1220で、認証後オンボーディングを8ステップ化し、推しL1/L2、活動エリア、名前、ユーザーID、生年月日、性別を保存してからホームへ入る流れへ更新した。
   - 残: 法的文書/ヘルプ本文の最終整合。
   - 主な対象: `ios-native/Sources/MegrumApp/AuthScreen.swift`, `ios-native/Sources/MegrumApp/AccountSetupScreen.swift`, `ios-native/Sources/MegrumApp/SettingsScreen.swift`

### P1

1. Meguri Messages / Plus / Profile Adjacent Screens
   - Swiftはグルーム、掲示板、マップ、通知経由の最小メッセージはあるが、見えるめぐりメッセージ入口、Plus、プロフィール編集、実績、共有が不足している。
2. Board Detail Moderation and Rich Replies
   - Swiftの掲示板詳細はチャット風に寄せたが、非表示/通報/ブロック/共有、画像返信、編集/削除、reaction、draftが不足している。
3. Settings / Legal / Help
   - Swift設定は通知、住所、ブロック、ログアウト、ヘルプ、法的文書、アカウント概要まで入口ができた。
   - 残: App Store提出前の正式URL、法的文書本文、サポート文面の最終整合。
4. Notification Deep Links
   - Swift通知は主にタブ遷移。RN版の取引、異議、掲示板、評価、証跡、プロフィールなどの詳細画面直行が不足している。

## 完了条件

- 主要フローがSwift版で完走できる。
- 既存のP0バグがSwift版で再現しない。
- iOS Simulator / 実機 / TestFlightで確認済み。
- `notes/09_state_machines.md` と画面実装の状態名が一致している。
- rollback branchとローカルbackupから旧版へ戻せる。
