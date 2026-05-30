# 22. Swift Native Migration

最終更新: 2026-05-31
ステータス: Active draft（iter327）

## 目的

MegrumはiOS一本で勝つ方針に切り替える。これ以降のユーザー向けiOS体験は、Swift / SwiftUI / UIKit / Apple標準フレームワークを正とし、Expo / React Native版は移行元・バックアップ・仕様参照として扱う。

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

### 1. 既存アプリを消さずに並走する

- `mobile/` は当面残す。
- `ios-native/` をSwift版の主作業場にする。
- Swift版が機能同等になるまでは、TestFlight配布の主線を急に切り替えない。
- 最終段階で、App Store Connectの本番Bundle IDへSwift版を接続する。

### 2. Swift版の技術方針

- Minimum target: iOS 17以上を基本線にする。
- iOS 26以上ではLiquid GlassのネイティブAPIを優先する。
- iOS 17/18/旧実行環境では `Material` / UIKit standard material / 独自最小fallbackで可読性を維持する。
- UIはSwiftUIを主軸にし、カメラ・写真・地図・通知・共有・購入・権限などは必要に応じてUIKit / Apple frameworkを直接使う。
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
- iter311で、設定一覧と住所設定フォームを追加し、`user_mailing_addresses` をSwift側から取得/upsertできる境界を作った。
- iter312で、郵便番号7桁入力からzipcloud公式APIで住所候補を取得し、住所設定フォームへ反映する境界を追加した。
- iter313で、Supabase redirect URLのquery / fragmentからsession tokenを復元し、SwiftUI `.onOpenURL` でアプリへ反映する境界を追加した。
- iter314で、設定一覧に「ブロックした人」を追加し、`groom_user_blocks` の一覧取得と解除をSwift版へ移植した。
- iter315で、設定一覧に通知入口と未読バッジを追加し、`notifications` の一覧取得・既読化・大分類遷移をSwift版へ移植した。
- 現時点のAuthはApple/Google OAuthまでは未完了。次のPhase 2作業でApple/Googleへ広げる。

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

### Phase 4: Meguri core

- グルーム、グルームマップ、スポット掲示板、掲示板マップ、めぐりメッセージをSwift化する。
- MapKit、PhotosUI、AVFoundation、UserNotificationsをネイティブに使う。
- iter324で、`list_groom_feed_nearby` と `list_meguri_board_threads_for_viewer` を呼ぶSwift Native RPC境界を追加し、めぐりホームが `MegrumAppState` 経由でグルーム/掲示板を再読込できるようにした。
- iter325で、掲示板スレッド詳細、返信一覧、返信送信のSwift Native RPC境界を追加し、めぐりホームからチャット形式の掲示板詳細へ進めるようにした。
- iter326で、めぐりホームの「地図で見る」からグルーム/掲示板のMapKit画面を開き、ピンと範囲円を表示できるようにした。
- iter327で、CoreLocation境界と位置情報利用文言を追加し、めぐりのfeed再読込とMapKit初期中心を現在地に寄せられるようにした。

### Phase 5: Cutover

- Swift版PreviewをTestFlight配布する。
- 既存RN版との画面・機能差分をチェックリスト化する。
- App Store提出前に、Bundle ID、Associated Domains、通知、権限文言、Privacy Manifest、規約リンクを最終確認する。

## 完了条件

- 主要フローがSwift版で完走できる。
- 既存のP0バグがSwift版で再現しない。
- iOS Simulator / 実機 / TestFlightで確認済み。
- `notes/09_state_machines.md` と画面実装の状態名が一致している。
- rollback branchとローカルbackupから旧版へ戻せる。
